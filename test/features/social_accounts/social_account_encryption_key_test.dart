// ==============================================================================
// NIRVANA — Social account encryption key test
// Description: Guards the account-specific (per-patient) encryption key. Social
//   media accounts are scoped by patient, so every device paired to the SAME
//   patient must derive an identical key (otherwise shared rows cannot be
//   decrypted), while DIFFERENT patients must never share a key.
// ==============================================================================

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/social_accounts/repositories/social_account_encryption_key.dart';
import 'package:nirvana/features/social_accounts/repositories/social_media_account_repository.dart';

class _MemorySecureStorage implements SecureStorageClient {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}

Future<String> _hexKey(SecretKey key) async {
  final bytes = await key.extractBytes();
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  const patientA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const patientB = 'bb-bbbb-4bbb-8bbb-bbbbbb';

  test('two devices of the same patient derive the identical key', () async {
    // Two separate secure-storage instances simulate two paired devices.
    final deviceOne = SocialAccountEncryptionKey(
      storage: _MemorySecureStorage(),
    );
    final deviceTwo = SocialAccountEncryptionKey(
      storage: _MemorySecureStorage(),
    );

    final keyOne = await deviceOne.keyFor(patientA);
    final keyTwo = await deviceTwo.keyFor(patientA);

    expect(await _hexKey(keyOne), await _hexKey(keyTwo));
  });

  test('different patients never share a key', () async {
    final keyA = await SocialAccountEncryptionKey.derive(patientA);
    final keyB = await SocialAccountEncryptionKey.derive(patientB);

    expect(await _hexKey(keyA), isNot(await _hexKey(keyB)));
  });

  test('derivation is stable and cached per patient', () async {
    final storage = _MemorySecureStorage();
    final keys = SocialAccountEncryptionKey(storage: storage);

    final first = await keys.keyFor(patientA);
    final second = await keys.keyFor(patientA);

    expect(await _hexKey(first), await _hexKey(second));
    // One cached entry per patient.
    expect(storage.values.keys, hasLength(1));
    expect(storage.values.keys.single, endsWith(patientA));
  });
}
