// ==============================================================================
// NIRVANA - Patient Device Panel Widget
// Description: Caregiver dashboard widget showing linked device status and
// allowing generation of a one-time 6-digit pairing code with countdown timer.
// ==============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nirvana/app/theme/elder_theme.dart';
import 'package:nirvana/features/caregiver/models/caregiver_models.dart';
import 'package:nirvana/features/caregiver/providers/caregiver_providers.dart';

class PatientDevicePanel extends ConsumerStatefulWidget {
  const PatientDevicePanel({super.key});

  @override
  ConsumerState<PatientDevicePanel> createState() => _PatientDevicePanelState();
}

class _PatientDevicePanelState extends ConsumerState<PatientDevicePanel> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

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
    await ref.read(pairingCodeProvider.notifier).generate(patientId);
    final code = ref.read(pairingCodeProvider).code;
    if (code != null && mounted) {
      _startCountdown(code.expiresAt);
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
          await ref.read(caregiverEventNotificationServiceProvider).notifyDeviceRevoked(
            patientId: selected.id,
            patientName: selected.preferredName ?? selected.fullName,
          );
        }
        ref.invalidate(patientLinkedDeviceProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not revoke device. Try again.')),
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
                Text(
                  'Patient Device',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ElderColors.textPrimary,
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
          return _ConnectedDeviceCard(
            device: device,
            onRevoke: onRevoke,
          );
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

  const _ConnectedDeviceCard({
    required this.device,
    required this.onRevoke,
  });

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
          const Icon(Icons.lightbulb_outline, size: 18, color: ElderColors.primary),
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
