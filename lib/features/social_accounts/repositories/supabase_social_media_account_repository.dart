import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/social_media_account.dart';
import 'social_media_account_repository.dart';

class SupabaseSocialMediaAccountRepository
    implements SocialMediaAccountRepository {
  SupabaseSocialMediaAccountRepository({
    required SupabaseClient client,
    required SecureStorageClient secureStorage,
    required String deviceId,
    Uuid? uuid,
  }) : _client = client,
       _secureStorage = secureStorage,
       _deviceId = deviceId,
       _uuid = uuid ?? const Uuid();

  static const _encryptionKeyStorageKey =
      'nirvana.social_media_accounts.encryption_key.v1';

  final SupabaseClient _client;
  final SecureStorageClient _secureStorage;
  final String _deviceId;
  final Uuid _uuid;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<SecretKey> _getEncryptionKey() async {
    final storedKey = await _secureStorage.read(key: _encryptionKeyStorageKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return SecretKey(base64Decode(storedKey));
    }

    final key = await _cipher.newSecretKey();
    final keyBytes = await key.extractBytes();
    await _secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: base64Encode(keyBytes),
    );
    return key;
  }

  String _requirePatientId(String patientId) {
    final normalized = patientId.trim();
    if (normalized.isEmpty) {
      throw const FormatException('A patient ID is required.');
    }
    return normalized;
  }

  SocialMediaAccount _fromRow(Map<String, dynamic> row, SecretKey key) {
    return SocialMediaAccount(
      id: row['id'] as String,
      platform: SocialPlatform.values.firstWhere(
        (platform) => platform.name == row['platform'],
        orElse: () => throw const FormatException('Invalid social platform.'),
      ),
      usernameOrEmail: row['username_or_email'] as String,
      password: '',
    );
  }

  Future<String> _decryptPassword(
    Map<String, dynamic> row,
    SecretKey key,
  ) async {
    final box = SecretBox(
      base64Decode(row['password_ciphertext'] as String),
      nonce: base64Decode(row['password_nonce'] as String),
      mac: Mac(base64Decode(row['password_mac'] as String)),
    );
    final bytes = await _cipher.decrypt(box, secretKey: key);
    return utf8.decode(bytes);
  }

  @override
  Future<List<SocialMediaAccount>> getAll(String patientId) async {
    final normalizedPatientId = _requirePatientId(patientId);
    final key = await _getEncryptionKey();
    final rows =
        await _client.rpc(
              'get_social_media_accounts_for_device',
              params: {
                'p_patient_id': normalizedPatientId,
                'p_device_id': _deviceId,
              },
            )
            as List<dynamic>;

    final accounts = <SocialMediaAccount>[];
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      final account = _fromRow(row, key);
      accounts.add(
        account.copyWith(password: await _decryptPassword(row, key)),
      );
    }
    return accounts;
  }

  @override
  Future<SocialMediaAccount> save(
    String patientId,
    SocialMediaAccount account,
  ) async {
    final normalizedPatientId = _requirePatientId(patientId);
    if (account.usernameOrEmail.trim().isEmpty) {
      throw const FormatException('Username or email is required.');
    }
    if (account.password.isEmpty) {
      throw const FormatException('Password is required.');
    }

    final key = await _getEncryptionKey();
    final box = await _cipher.encrypt(
      utf8.encode(account.password),
      secretKey: key,
    );
    final saved = account.id.isEmpty
        ? account.copyWith(id: _uuid.v4())
        : account;

    await _client.rpc(
      'upsert_social_media_account_for_device',
      params: {
        'p_id': saved.id,
        'p_patient_id': normalizedPatientId,
        'p_device_id': _deviceId,
        'p_platform': saved.platform.name,
        'p_username_or_email': saved.usernameOrEmail.trim(),
        'p_password_ciphertext': base64Encode(box.cipherText),
        'p_password_nonce': base64Encode(box.nonce),
        'p_password_mac': base64Encode(box.mac.bytes),
        'p_encryption_version': 1,
      },
    );
    return saved;
  }

  @override
  Future<void> delete(String patientId, String id) async {
    final normalizedPatientId = _requirePatientId(patientId);
    await _client.rpc(
      'delete_social_media_account_for_device',
      params: {
        'p_patient_id': normalizedPatientId,
        'p_device_id': _deviceId,
        'p_id': id,
      },
    );
  }
}
