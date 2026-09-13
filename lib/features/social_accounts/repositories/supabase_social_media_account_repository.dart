import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/social_media_account.dart';
import 'social_account_encryption_key.dart';
import 'social_media_account_repository.dart';

class SupabaseSocialMediaAccountRepository
    implements SocialMediaAccountRepository {
  SupabaseSocialMediaAccountRepository({
    required SupabaseClient client,
    required SecureStorageClient secureStorage,
    required String deviceId,
    Uuid? uuid,
  }) : _client = client,
       _deviceId = deviceId,
       _uuid = uuid ?? const Uuid(),
       _keyDerivation = SocialAccountEncryptionKey(storage: secureStorage);

  final SupabaseClient _client;
  final String _deviceId;
  final Uuid _uuid;
  final AesGcm _cipher = AesGcm.with256bits();

  /// Derives the shared, per-patient encryption key (see
  /// [SocialAccountEncryptionKey]).
  final SocialAccountEncryptionKey _keyDerivation;

  Future<SecretKey> _getEncryptionKey(String patientId) =>
      _keyDerivation.keyFor(patientId);

  String _requirePatientId(String patientId) {
    final normalized = patientId.trim();
    if (normalized.isEmpty) {
      throw const FormatException('A patient ID is required.');
    }
    return normalized;
  }

  SocialMediaAccount _fromRow(Map<String, dynamic> row) {
    return SocialMediaAccount(
      id: row['id'] as String,
      // Tolerant parsing: rows written by other clients (or by hand) may use a
      // label or different casing for the platform value.
      platform: SocialPlatform.fromStorage(row['platform']),
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
    final key = await _getEncryptionKey(normalizedPatientId);
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
    int skippedRows = 0;
    for (final rawRow in rows) {
      final row = Map<String, dynamic>.from(rawRow);
      try {
        // Parse inside the try so a single malformed row (bad platform value,
        // missing column, etc.) is skipped instead of failing the whole load
        // and silently falling back to the empty local store.
        final account = _fromRow(row);
        final password = await _decryptPassword(row, key);
        accounts.add(account.copyWith(password: password));
      } catch (error) {
        skippedRows++;
        debugPrint(
          '⚠️ Skipped social account row ${row['id']} (platform: ${row['platform']}) - '
          'unreadable on this device ($error)',
        );
      }
    }
    if (skippedRows > 0) {
      debugPrint(
        'ℹ️ $skippedRows social media account(s) could not be read '
        '(encrypted with an older key, or malformed). Re-save them to make '
        'them available across all of this patient\'s devices.',
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

    final key = await _getEncryptionKey(normalizedPatientId);
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
