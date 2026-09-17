// ==============================================================================
// NIRVANA - Patient Device Panel Widget
// Description: Caregiver dashboard widget showing linked device status and
// allowing generation of a one-time 6-digit pairing code with countdown timer.
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';
import 'package:nirvana/features/caregiver/services/sms_service.dart';
import 'package:nirvana/features/caregiver/utils/phone_format.dart';

class PatientDevicePanel extends ConsumerStatefulWidget {
  const PatientDevicePanel({super.key});

  @override
  ConsumerState<PatientDevicePanel> createState() => _PatientDevicePanelState();
}

class _PatientDevicePanelState extends ConsumerState<PatientDevicePanel> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  /// True while an SMS hand-off is in flight (contact lookup + composer launch).
  bool _isSendingPasscode = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _updateRemaining(expiresAt);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining(expiresAt);
    });
  }

  void _updateRemaining(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    setState(() => _remainingSeconds = diff > 0 ? diff : 0);
    if (_remainingSeconds == 0) {
      _countdownTimer?.cancel();
    }
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _generateCode(String patientId) async {
    // A brand-new passcode replaces the previous one entirely — the actions row
    // always acts on whatever `pairingCodeProvider` now holds, so an old
    // passcode can never be copied or sent once regenerated.
    await ref.read(pairingCodeProvider.notifier).generate(patientId);
    final code = ref.read(pairingCodeProvider).code;
    if (code != null && mounted) {
      _startCountdown(code.expiresAt);
    }
  }

  /// Copies the currently displayed passcode to the clipboard.
  Future<void> _copyPasscode(PairingCodeInfo code) async {
    await Clipboard.setData(ClipboardData(text: code.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passcode copied to clipboard')),
    );
  }

  /// Opens the SMS flow for the CURRENTLY displayed passcode.
  ///
  /// Delivery goes through [SmsService]; on MVP that is the free native SMS
  /// composer. We never send SMS programmatically from the client, and success
  /// here means the composer opened — not that a message was delivered.
  Future<void> _sendPasscodeSms(
    PatientSummary patient,
    PairingCodeInfo code,
  ) async {
    if (_remainingSeconds <= 0 || code.isExpired) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This passcode has expired. Generate a new one to send it.',
            ),
          ),
        );
      }
      return;
    }

    final contact = await ref.read(patientContactProvider.future);

    setState(() => _isSendingPasscode = true);

    final result = await ref
        .read(smsServiceProvider)
        .sendPasscode(
          PasscodeSmsRequest(
            patientId: patient.id,
            patientName: patient.preferredName ?? patient.fullName,
            patientPhone: contact?.patientPhone,
            passcode: code.code,
          ),
        );

    if (!mounted) return;
    setState(() => _isSendingPasscode = false);

    if (result.isSuccess) {
      // Honest wording: the composer was opened; the caregiver still sends it.
      final isComposer =
          result.channel == SmsDeliveryChannel.nativeComposer;
      final to = result.maskedRecipient != null
          ? 'To ${result.maskedRecipient}'
          : null;
      final text = isComposer
          ? 'SMS composer opened. Press Send to deliver the passcode.'
          : 'Passcode sent successfully.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ElderColors.successText,
          duration: const Duration(seconds: 4),
          content: Text(to == null ? text : '$text $to'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ElderColors.gentleErrorPrimary,
          duration: const Duration(seconds: 4),
          content: Text(
            result.message ?? 'Could not send the passcode. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _revokeDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Revoke Device Access?'),
        content: const Text(
          'This will disconnect the patient\'s device. '
          'They will need to pair again using a new code.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ElderColors.gentleErrorPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final selected = ref.read(selectedPatientProvider);
        await ref.read(pairingRepositoryProvider).revokeDevice(deviceId);
        if (selected != null) {
          await ref
              .read(caregiverEventNotificationServiceProvider)
              .notifyDeviceRevoked(
                patientId: selected.id,
                patientName: selected.preferredName ?? selected.fullName,
              );
        }
        ref.invalidate(patientLinkedDeviceProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not revoke device. Try again.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedPatientProvider);
    if (selected == null) return const SizedBox.shrink();

    final deviceAsync = ref.watch(patientLinkedDeviceProvider);
    final pairingState = ref.watch(pairingCodeProvider);
    final contactAsync = ref.watch(patientContactProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ElderColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ElderColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.smartphone_rounded,
                    color: ElderColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Patient Device',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                // Refresh device status
                IconButton(
                  onPressed: () => ref.invalidate(patientLinkedDeviceProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  color: ElderColors.textMuted,
                  tooltip: 'Refresh device status',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Patient Information — name, registered phone, send actions.
            _PatientInformationSection(
              contactAsync: contactAsync,
              patientName: selected.preferredName ?? selected.fullName,
            ),

            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Device status
            _DeviceStatusSection(
              deviceAsync: deviceAsync,
              onRevoke: () {
                final device = deviceAsync.value;
                if (device != null) _revokeDevice(device.deviceId);
              },
            ),

            // Pairing code section
            if (pairingState.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: pairingState.errorMessage!),
            ],

            if (pairingState.code != null &&
                !pairingState.code!.isExpired &&
                _remainingSeconds > 0) ...[
              const SizedBox(height: 16),
              _PairingCodeDisplay(
                code: pairingState.code!,
                patientName: selected.preferredName ?? selected.fullName,
                remainingSeconds: _remainingSeconds,
                formattedCountdown: _formatCountdown(_remainingSeconds),
              ),
              const SizedBox(height: 12),
              // Copy the passcode, or hand it to the SMS flow for the patient.
              PasscodeActionsRow(
                passcode: pairingState.code!.code,
                isSending: _isSendingPasscode,
                onCopy: () => _copyPasscode(pairingState.code!),
                onSend: () =>
                    _sendPasscodeSms(selected, pairingState.code!),
              ),
            ],

            const SizedBox(height: 16),

            // Generate code button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: pairingState.isLoading
                    ? null
                    : () => _generateCode(selected.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElderColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: pairingState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.generating_tokens_rounded, size: 20),
                label: Text(
                  pairingState.isLoading
                      ? 'Generating…'
                      : (pairingState.code != null &&
                                !pairingState.code!.isExpired &&
                                _remainingSeconds > 0
                            ? 'Generate New Code'
                            : 'Generate Pairing Code'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// SUB-WIDGETS
// ==============================================================================

class _DeviceStatusSection extends StatelessWidget {
  final AsyncValue<PatientDeviceSummary?> deviceAsync;
  final VoidCallback onRevoke;

  const _DeviceStatusSection({
    required this.deviceAsync,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return deviceAsync.when(
      data: (device) {
        if (device != null && device.isActive) {
          return _ConnectedDeviceCard(device: device, onRevoke: onRevoke);
        }
        return const _NotConnectedCard();
      },
      loading: () => const _LoadingCard(),
      error: (_, __) => const _NotConnectedCard(),
    );
  }
}

class _NotConnectedCard extends StatelessWidget {
  const _NotConnectedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ElderColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: ElderColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Device',
            style: TextStyle(
              fontSize: 14,
              color: ElderColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ElderColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Not Connected',
              style: TextStyle(
                fontSize: 12,
                color: ElderColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ElderColors.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  final PatientDeviceSummary device;
  final VoidCallback onRevoke;

  const _ConnectedDeviceCard({required this.device, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: ElderColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ElderColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ElderColors.successText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        device.deviceName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ElderColors.successText,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (device.lastSeenAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 16),
                    child: Text(
                      'Last seen ${_formatRelative(device.lastSeenAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ElderColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRevoke,
            style: TextButton.styleFrom(
              foregroundColor: ElderColors.gentleErrorPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _PairingCodeDisplay extends StatelessWidget {
  final PairingCodeInfo code;
  final String patientName;
  final int remainingSeconds;
  final String formattedCountdown;

  const _PairingCodeDisplay({
    required this.code,
    required this.patientName,
    required this.remainingSeconds,
    required this.formattedCountdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActiveCodeCard(
          code: code,
          patientName: patientName,
          remainingSeconds: remainingSeconds,
          formattedCountdown: formattedCountdown,
        ),
        const SizedBox(height: 10),
        const _ShareTipCard(),
      ],
    );
  }
}

class _ActiveCodeCard extends StatelessWidget {
  final PairingCodeInfo code;
  final String patientName;
  final int remainingSeconds;
  final String formattedCountdown;

  const _ActiveCodeCard({
    required this.code,
    required this.patientName,
    required this.remainingSeconds,
    required this.formattedCountdown,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = remainingSeconds < 120; // < 2 min = amber warning

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isUrgent
            ? ElderColors.supportiveBg
            : ElderColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? ElderColors.supportiveBorder
              : ElderColors.primary.withAlpha(80),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Show this code to $patientName',
            style: TextStyle(
              fontSize: 14,
              color: isUrgent
                  ? ElderColors.supportiveText
                  : ElderColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          // Large spaced code display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: code.code.split('').asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  right: entry.key == 2 ? 12 : 4,
                  left: entry.key == 3 ? 8 : 0,
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: isUrgent
                        ? ElderColors.supportiveText
                        : ElderColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: isUrgent
                    ? ElderColors.supportiveIcon
                    : ElderColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                'Expires in $formattedCountdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isUrgent
                      ? ElderColors.supportiveIcon
                      : ElderColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareTipCard extends StatelessWidget {
  const _ShareTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ElderColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: ElderColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Make sure the patient device has the app open.',
              style: TextStyle(fontSize: 13, color: ElderColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ElderColors.gentleErrorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ElderColors.gentleErrorBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: ElderColors.gentleErrorPrimary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: ElderColors.gentleErrorText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ==============================================================================
// PATIENT INFORMATION + PASSCODE SMS WIDGETS
// ==============================================================================

/// Clean, caregiver/elder-friendly "Patient Information" block.
///
/// Shows the patient name and registered phone number with country-code
/// formatting, plus a Copy Number action. When no number is on file it states
/// "Phone number not available" explicitly (never fails silently) and points
/// the caregiver at the onboarding flow to add one.
class _PatientInformationSection extends StatelessWidget {
  final AsyncValue<PatientContactInfo?> contactAsync;
  final String patientName;

  const _PatientInformationSection({
    required this.contactAsync,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ElderColors.primaryContainer,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.badge_outlined,
                color: ElderColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Patient Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ElderColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        _InfoRow(label: 'Name', value: patientName),

        const SizedBox(height: 12),

        contactAsync.when(
          loading: () => const _InfoRow(
            label: 'Phone',
            value: 'Loading…',
            isMuted: true,
          ),
          error: (_, __) => const _PhoneUnavailable(),
          data: (contact) {
            final phone = contact?.patientPhone;
            if (contact == null || phone == null || phone.trim().isEmpty) {
              return const _PhoneUnavailable();
            }
            return _PhoneAvailable(phone: phone);
          },
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMuted;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ElderColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isMuted
                  ? ElderColors.textMuted
                  : ElderColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown when the patient has no registered phone number on file.
class _PhoneUnavailable extends StatelessWidget {
  const _PhoneUnavailable();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 74,
          child: Text(
            'Phone:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ElderColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ElderColors.supportiveBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ElderColors.supportiveBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_disabled_rounded,
                      size: 15,
                      color: ElderColors.supportiveText,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Phone number not available',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ElderColors.supportiveText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add a phone number for this patient from "Add Loved One" '
                '(Emergency Contact Phone) to enable passcode SMS.',
                style: TextStyle(fontSize: 13, color: ElderColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when a phone number exists — with country-code formatting + copy.
class _PhoneAvailable extends StatelessWidget {
  final String phone;

  const _PhoneAvailable({required this.phone});

  @override
  Widget build(BuildContext context) {
    final formatted = PhoneFormat.format(phone);
    final isValid = PhoneFormat.isValid(phone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 74,
              child: Text(
                'Phone:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ElderColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                formatted,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ElderColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        if (!isValid) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ElderColors.gentleErrorBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ElderColors.gentleErrorBorder),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: ElderColors.gentleErrorPrimary,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This phone number looks invalid. Update it before sending.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ElderColors.gentleErrorText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Actions attached to the currently-generated passcode:
///   [ Copy Passcode ]  [ Send Passcode ]
///
/// Public (not `_`-private) so it can be exercised directly in widget tests.
/// Feedback is delivered via SnackBar by the parent, so this widget never
/// renders a success state it did not observe — it cannot fake an SMS result.
class PasscodeActionsRow extends StatelessWidget {
  /// The exact passcode currently displayed. Copied/sent verbatim.
  final String passcode;

  final bool isSending;
  final VoidCallback onCopy;
  final VoidCallback onSend;

  const PasscodeActionsRow({
    super.key,
    required this.passcode,
    required this.onCopy,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('copy_passcode_button'),
            onPressed: passcode.isEmpty ? null : onCopy,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: ElderColors.primary,
              side: const BorderSide(color: ElderColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text(
              'Copy Passcode',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('send_passcode_button'),
            onPressed: (passcode.isEmpty || isSending) ? null : onSend,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: ElderColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: ElderColors.border,
              disabledForegroundColor: ElderColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sms_rounded, size: 18),
            label: Text(
              isSending ? 'Opening…' : 'Send Passcode',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


