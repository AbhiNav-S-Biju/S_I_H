// ==============================================================================
// NIRVANA - Social media account encryption key derivation
// Description: Derives a *per-patient* AES-GCM key for encrypting social media
//   account passwords. Accounts are account-specific (scoped by patient_id),
//   so every device paired to the same patient must derive the identical key in
//   order to decrypt the shared rows. The key is derived deterministically with
//   HKDF and cached in platform-protected secure storage.
// ==============================================================================

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'social_media_account_repository.dart';

class SocialAccountEncryptionKey {
  SocialAccountEncryptionKey({required SecureStorageClient storage})
    : _storage = storage;

  /// Storage key prefix. The full key is suffixed with the patient id so each
  /// patient has an independent cached key on the device.
  static const storageKeyPrefix =
      'nirvana.social_media_accounts.patient_key.v1';

  /// A fixed, app-wide pepper. Combined with the patient id via HKDF this
  /// yields a stable key that is identical across all of the patient's devices
  /// without requiring an extra network round-trip.
  static const applicationPepper =
      'nirvana.social_media_accounts.patient_scoped.v1';

  static const _keyLengthInBytes = 32;

  final SecureStorageClient _storage;

  /// Returns the AES key for [patientId], deriving and caching it on first use.
  Future<SecretKey> keyFor(String patientId) async {
    final storageKey = '$storageKeyPrefix.$patientId';
    final stored = await _storage.read(key: storageKey);
    if (stored != null && stored.isNotEmpty) {
      return SecretKey(base64Decode(stored));
    }

    final key = await derive(patientId);
    final keyBytes = await key.extractBytes();
    await _storage.write(key: storageKey, value: base64Encode(keyBytes));
    return key;
  }

  /// Deterministically derives the per-patient key (no storage involved).
  static Future<SecretKey> derive(String patientId) {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: _keyLengthInBytes);
    return hkdf.deriveKey(
      secretKey: SecretKey(utf8.encode(applicationPepper)),
      info: utf8.encode('social-media-account.$patientId'),
    );
  }
}
