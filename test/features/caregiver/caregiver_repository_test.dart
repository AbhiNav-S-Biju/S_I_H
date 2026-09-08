// ==============================================================================
// NIRVANA - Caregiver Repository Unit Tests
// Description: Tests caregiver authentication, patient onboarding, patient-scoped access,
// activity metrics, and offline resilience.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/core/network/connectivity_monitor.dart';
import 'package:nirvana/features/caregiver/caregiver.dart';

class MockOfflineConnectivityMonitor implements IConnectivityMonitor {
  @override
  Stream<NetworkStatus> get statusStream => const Stream.empty();

  @override
  Future<NetworkStatus> checkStatus() async => NetworkStatus.offline;
}

void main() {
  late ICaregiverRepository repository;

  setUp(() {
    repository = SupabaseCaregiverRepository(
      connectivityMonitor: MockOfflineConnectivityMonitor(),
    );
  });

  group('CaregiverRepository Authentication Tests', () {
    test(
      'login returns valid CaregiverProfile in offline fallback mode',
      () async {
        final profile = await repository.login(
          email: 'sarah.caregiver@example.com',
          password: 'SecurePassword123',
        );

        expect(profile.id, isNotEmpty);
        expect(profile.email, equals('sarah.caregiver@example.com'));
        expect(profile.role, equals('primary_caregiver'));
      },
    );

    test(
      'getCurrentCaregiver returns cached profile after login and null after logout',
      () async {
        await repository.login(email: 'test@example.com', password: 'pass');

        final current = await repository.getCurrentCaregiver();
        expect(current, isNotNull);
        expect(current!.email, equals('test@example.com'));

        await repository.logout();
        final afterLogout = await repository.getCurrentCaregiver();
        expect(afterLogout, isNull);
      },
    );
  });

  group('CaregiverRepository Patient Onboarding & Management Tests', () {
    test('createPatient creates valid patient summary in offline mode', () async {
      final input = CreatePatientInput(
        fullName: 'Robert Davis',
        preferredName: 'Bob',
        relationship: 'Father',
        dateOfBirth: DateTime(1948, 5, 12),
        emergencyContactPhone: '+1-555-0123',
        timezone: 'America/New_York',
        fontScale: 1.4,
        highContrast: true,
        largeText: true,
        initialReminders: [
          const InitialReminderInput(
            title: 'Morning Heart Medication',
            description: 'Take with glass of water',
            reminderType: 'medication',
            scheduleTime: '08:00:00',
            isEnabled: true,
          ),
        ],
      );

      final created = await repository.createPatient(
        input: input,
        caregiverId: 'caregiver-local-001',
      );

      expect(created.id, isNotEmpty);
      expect(created.fullName, equals('Robert Davis'));
      expect(created.preferredName, equals('Bob'));
      expect(created.relationship, equals('Father'));
      expect(created.primaryCaregiverId, equals('caregiver-local-001'));
      expect(created.emergencyContactPhone, equals('+1-555-0123'));

      // Verify newly created patient is in assigned patients list
      final assigned = await repository.getAssignedPatients('caregiver-local-001');
      expect(assigned.any((p) => p.id == created.id), isTrue);
    });

    test(
      'getAssignedPatients returns only patients assigned to caregiver',
      () async {
        final patients = await repository.getAssignedPatients(
          'caregiver-local-001',
        );

        expect(patients, isNotEmpty);
        for (final patient in patients) {
          expect(patient.primaryCaregiverId, equals('caregiver-local-001'));
          expect(patient.fullName, isNotEmpty);
          expect(patient.relationship, isNotEmpty);
        }
      },
    );

    test(
      'getGameHistory returns recent game activity without clinical progression labels',
      () async {
        final history = await repository.getGameHistory('patient-elena-01');

        expect(history, isNotEmpty);
        for (final game in history) {
          expect(game.gameTitle, isNotEmpty);
          expect(game.score, isNonNegative);
          expect(game.correctCount, isNonNegative);
          expect(game.totalCount, isPositive);
        }
      },
    );

    test(
      'getReminderStatus returns reminder records with completion status',
      () async {
        final reminders = await repository.getReminderStatus(
          'patient-elena-01',
        );

        expect(reminders, isNotEmpty);
        expect(reminders.any((r) => r.isCompleted), isTrue);
      },
    );

    test(
      'getSevenDayActivity calculates 7 daily summaries for the past week',
      () async {
        final summaries = await repository.getSevenDayActivity(
          'patient-elena-01',
        );

        expect(summaries.length, equals(7));
        for (final day in summaries) {
          expect(day.dayLabel, isNotEmpty);
          expect(
            day.totalActivities,
            equals(day.gamesCompleted + day.remindersCompleted),
          );
        }
      },
    );

    test('getSyncStatus returns proper offline status information', () async {
      final syncInfo = await repository.getSyncStatus('patient-elena-01');

      expect(syncInfo.isOnline, isFalse);
      expect(syncInfo.statusLabel, contains('Offline'));
    });
  });
}
