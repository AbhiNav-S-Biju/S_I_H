import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../patient/providers/patient_pairing_providers.dart';
import '../models/social_media_account.dart';
import '../repositories/social_media_account_repository.dart';
import '../repositories/supabase_social_media_account_repository.dart';
import '../../../database/hive_database.dart';

final secureStorageClientProvider = Provider<SecureStorageClient>((ref) {
  return FlutterSecureStorageClient();
});

final socialMediaAccountRepositoryProvider =
    Provider<SocialMediaAccountRepository>((ref) {
      final secureStorage = ref.watch(secureStorageClientProvider);
      try {
        final client = Supabase.instance.client;
        if (SupabaseConfig.isConfigured && HiveDatabase.isDevicePaired) {
          final cloudRepository = SupabaseSocialMediaAccountRepository(
            client: client,
            secureStorage: secureStorage,
            deviceId: HiveDatabase.getOrCreateDeviceId(),
          );
          return CloudFirstSocialMediaAccountRepository(
            cloudRepository: cloudRepository,
            localRepository: SecureSocialMediaAccountRepository(
              storage: secureStorage,
            ),
          );
        }
      } catch (_) {
        // Supabase is optional for offline patient devices.
      }
      return SecureSocialMediaAccountRepository(storage: secureStorage);
    });

final socialMediaAccountsProvider =
    FutureProvider.family<List<SocialMediaAccount>, String>((ref, patientId) {
      return ref.watch(socialMediaAccountRepositoryProvider).getAll(patientId);
    });

final currentPatientSocialMediaAccountsProvider =
    FutureProvider<List<SocialMediaAccount>>((ref) {
      final patientId = ref.watch(localPatientSessionProvider)?.patientId;
      if (patientId == null || patientId.isEmpty) return const [];
      return ref.watch(socialMediaAccountsProvider(patientId).future);
    });
