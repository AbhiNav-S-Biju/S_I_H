import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/social_media_account.dart';

abstract interface class SecureStorageClient {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureStorageClient implements SecureStorageClient {
  FlutterSecureStorageClient({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

abstract interface class SocialMediaAccountRepository {
  Future<List<SocialMediaAccount>> getAll(String patientId);
  Future<SocialMediaAccount> save(String patientId, SocialMediaAccount account);
  Future<void> delete(String patientId, String id);
}

class CloudFirstSocialMediaAccountRepository
    implements SocialMediaAccountRepository {
  CloudFirstSocialMediaAccountRepository({
    required SocialMediaAccountRepository cloudRepository,
    required SocialMediaAccountRepository localRepository,
  }) : _cloudRepository = cloudRepository,
       _localRepository = localRepository;

  final SocialMediaAccountRepository _cloudRepository;
  final SocialMediaAccountRepository _localRepository;

  bool usedLocalFallback = false;

  @override
  Future<List<SocialMediaAccount>> getAll(String patientId) async {
    try {
      usedLocalFallback = false;
      final cloudAccounts = await _cloudRepository.getAll(patientId);
      final localAccounts = await _localRepository.getAll(patientId);
      final merged = <String, SocialMediaAccount>{
        for (final account in localAccounts) account.id: account,
      };
      for (final account in cloudAccounts) {
        merged[account.id] = account;
      }
      return merged.values.toList(growable: false);
    } catch (_) {
      usedLocalFallback = true;
      return _localRepository.getAll(patientId);
    }
  }

  @override
  Future<SocialMediaAccount> save(
    String patientId,
    SocialMediaAccount account,
  ) async {
    try {
      usedLocalFallback = false;
      final saved = await _cloudRepository.save(patientId, account);
      await _localRepository.save(patientId, saved);
      return saved;
    } catch (_) {
      usedLocalFallback = true;
      return _localRepository.save(patientId, account);
    }
  }

  @override
  Future<void> delete(String patientId, String id) async {
    try {
      usedLocalFallback = false;
      await _cloudRepository.delete(patientId, id);
      await _localRepository.delete(patientId, id);
    } catch (_) {
      usedLocalFallback = true;
      await _localRepository.delete(patientId, id);
    }
  }
}

class SecureSocialMediaAccountRepository
    implements SocialMediaAccountRepository {
  SecureSocialMediaAccountRepository({
    required SecureStorageClient storage,
    Uuid? uuid,
  }) : _storage = storage,
       _uuid = uuid ?? const Uuid();

  static const _storageKeyPrefix = 'nirvana.social_media_accounts.v1';

  final SecureStorageClient _storage;
  final Uuid _uuid;

  String _storageKey(String patientId) {
    final normalizedPatientId = patientId.trim();
    if (normalizedPatientId.isEmpty) {
      throw const FormatException('A patient ID is required.');
    }
    return '$_storageKeyPrefix.$normalizedPatientId';
  }

  @override
  Future<List<SocialMediaAccount>> getAll(String patientId) async {
    final encoded = await _storage.read(key: _storageKey(patientId));
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      return SocialMediaAccount.decodeList(encoded);
    } catch (_) {
      throw const FormatException('Saved social accounts could not be read.');
    }
  }

  @override
  Future<SocialMediaAccount> save(
    String patientId,
    SocialMediaAccount account,
  ) async {
    if (account.usernameOrEmail.trim().isEmpty) {
      throw const FormatException('Username or email is required.');
    }
    if (account.password.isEmpty) {
      throw const FormatException('Password is required.');
    }

    final storageKey = _storageKey(patientId);
    final accounts = [...await getAll(patientId)];
    final saved = account.id.isEmpty
        ? account.copyWith(id: _uuid.v4())
        : account;
    final index = accounts.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      accounts.add(saved);
    } else {
      accounts[index] = saved;
    }
    await _storage.write(
      key: storageKey,
      value: SocialMediaAccount.encodeList(accounts),
    );
    return saved;
  }

  @override
  Future<void> delete(String patientId, String id) async {
    final storageKey = _storageKey(patientId);
    final accounts = [...await getAll(patientId)]
      ..removeWhere((account) => account.id == id);
    if (accounts.isEmpty) {
      await _storage.delete(key: storageKey);
      return;
    }
    await _storage.write(
      key: storageKey,
      value: SocialMediaAccount.encodeList(accounts),
    );
  }
}
