import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/social_accounts/models/social_media_account.dart';
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

class _FailingRepository implements SocialMediaAccountRepository {
  @override
  Future<List<SocialMediaAccount>> getAll(String patientId) =>
      Future<List<SocialMediaAccount>>.error(StateError('cloud unavailable'));

  @override
  Future<SocialMediaAccount> save(
    String patientId,
    SocialMediaAccount account,
  ) => Future<SocialMediaAccount>.error(StateError('cloud unavailable'));

  @override
  Future<void> delete(String patientId, String id) =>
      Future<void>.error(StateError('cloud unavailable'));
}

void main() {
  const patientOneId = 'patient-one';
  const patientTwoId = 'patient-two';
  late _MemorySecureStorage storage;
  late SecureSocialMediaAccountRepository repository;

  setUp(() {
    storage = _MemorySecureStorage();
    repository = SecureSocialMediaAccountRepository(storage: storage);
  });

  test('creates and reads accounts from secure storage', () async {
    final saved = await repository.save(
      patientOneId,
      const SocialMediaAccount(
        id: '',
        platform: SocialPlatform.instagram,
        usernameOrEmail: 'person@example.com',
        password: 'secret-value',
      ),
    );

    final accounts = await repository.getAll(patientOneId);
    expect(saved.id, isNotEmpty);
    expect(accounts.single.platform, SocialPlatform.instagram);
    expect(accounts.single.password, 'secret-value');
    expect(storage.values, isNotEmpty);
  });

  test('edits an existing account without creating a duplicate', () async {
    final created = await repository.save(
      patientOneId,
      const SocialMediaAccount(
        id: 'account-1',
        platform: SocialPlatform.facebook,
        usernameOrEmail: 'old-name',
        password: 'old-password',
      ),
    );

    await repository.save(
      patientOneId,
      created.copyWith(usernameOrEmail: 'new-name', password: 'new-password'),
    );

    final accounts = await repository.getAll(patientOneId);
    expect(accounts, hasLength(1));
    expect(accounts.single.usernameOrEmail, 'new-name');
    expect(accounts.single.password, 'new-password');
  });

  test('deletes an account and removes the secure record when empty', () async {
    await repository.save(
      patientOneId,
      const SocialMediaAccount(
        id: 'account-1',
        platform: SocialPlatform.discord,
        usernameOrEmail: 'person',
        password: 'password',
      ),
    );

    await repository.delete(patientOneId, 'account-1');

    expect(await repository.getAll(patientOneId), isEmpty);
    expect(storage.values, isEmpty);
  });

  test('rejects missing required credentials', () async {
    expect(
      () => repository.save(
        patientOneId,
        const SocialMediaAccount(
          id: '',
          platform: SocialPlatform.tikTok,
          usernameOrEmail: '',
          password: '',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('keeps each patient in a separate secure-storage record', () async {
    await repository.save(
      patientOneId,
      const SocialMediaAccount(
        id: 'patient-one-account',
        platform: SocialPlatform.instagram,
        usernameOrEmail: 'one@example.com',
        password: 'one-password',
      ),
    );
    await repository.save(
      patientTwoId,
      const SocialMediaAccount(
        id: 'patient-two-account',
        platform: SocialPlatform.facebook,
        usernameOrEmail: 'two@example.com',
        password: 'two-password',
      ),
    );

    expect(
      (await repository.getAll(patientOneId)).single.usernameOrEmail,
      'one@example.com',
    );
    expect(
      (await repository.getAll(patientTwoId)).single.usernameOrEmail,
      'two@example.com',
    );
    expect(storage.values, hasLength(2));
  });

  test(
    'falls back to local secure storage when Supabase is unavailable',
    () async {
      final fallback = CloudFirstSocialMediaAccountRepository(
        cloudRepository: _FailingRepository(),
        localRepository: repository,
      );

      final saved = await fallback.save(
        patientOneId,
        const SocialMediaAccount(
          id: '',
          platform: SocialPlatform.discord,
          usernameOrEmail: 'offline-user',
          password: 'offline-password',
        ),
      );

      expect(saved.id, isNotEmpty);
      expect(fallback.usedLocalFallback, isTrue);
      expect(
        (await repository.getAll(patientOneId)).single.usernameOrEmail,
        'offline-user',
      );
    },
  );
}
