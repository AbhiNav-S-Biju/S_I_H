// ==============================================================================
// NIRVANA - SMS Service Abstraction
// Description: Provider-independent passcode SMS delivery.
//
// The caregiver UI depends only on the [SmsService] interface, so the delivery
// mechanism can be swapped without touching the UI:
//
//   SmsService
//     ├── NativeSmsService  (MVP / free)  -> opens the device SMS composer
//     └── BackendSmsService (production)  -> Supabase Edge Function -> provider
//
// Delivery semantics are deliberately honest:
//   * [SmsDeliveryChannel.nativeComposer] means we handed a pre-filled message to
//     the OS composer. The caregiver still has to press Send, so we do NOT claim
//     the SMS was delivered — only that the composer was opened.
//   * [SmsDeliveryChannel.backend] means a server confirmed the provider accepted
//     the message.
//
// No SMS provider credentials exist anywhere in this layer. A native composer
// needs no permission at all (we never read or send SMS ourselves).
// ==============================================================================

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/phone_format.dart';

/// Which transport actually handled the request.
enum SmsDeliveryChannel {
  /// The OS SMS composer was opened pre-filled. Delivery is user-confirmed.
  nativeComposer,

  /// A backend (Supabase Edge Function -> SMS provider) accepted the message.
  backend,
}

/// Why a send attempt did not proceed.
enum SmsFailureReason {
  noPhoneNumber,
  invalidPhoneNumber,

  /// The device could not resolve/open an SMS app.
  composerUnavailable,

  /// Backend/provider rejected or was unavailable.
  backendFailure,

  /// The caller is not authorized for this patient.
  unauthorized,

  /// Offline, or no network path to the backend.
  networkUnavailable,
}

/// Outcome of a passcode SMS attempt.
class SmsSendResult {
  final bool isSuccess;
  final SmsDeliveryChannel? channel;

  /// Reason when [isSuccess] is false — drives the user-facing message.
  final SmsFailureReason? reason;

  /// Optional detail (already user-safe). Never contains a passcode or secrets.
  final String? message;

  /// Masked recipient, e.g. `****3210`. The full number is never echoed.
  final String? maskedRecipient;

  const SmsSendResult._({
    required this.isSuccess,
    this.channel,
    this.reason,
    this.message,
    this.maskedRecipient,
  });

  factory SmsSendResult.composerOpened({String? maskedRecipient}) =>
      SmsSendResult._(
        isSuccess: true,
        channel: SmsDeliveryChannel.nativeComposer,
        maskedRecipient: maskedRecipient,
      );

  factory SmsSendResult.backendSent({String? maskedRecipient}) =>
      SmsSendResult._(
        isSuccess: true,
        channel: SmsDeliveryChannel.backend,
        maskedRecipient: maskedRecipient,
      );

  factory SmsSendResult.failure(SmsFailureReason reason, {String? message}) =>
      SmsSendResult._(isSuccess: false, reason: reason, message: message);
}

/// Context for a passcode SMS attempt.
class PasscodeSmsRequest {
  final String patientId;
  final String patientName;
  final String? patientPhone;

  /// The passcode currently displayed — the exact value that must be sent.
  final String passcode;

  const PasscodeSmsRequest({
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.passcode,
  });
}

/// Core composer text, shared by every implementation so the message the patient
/// receives is identical regardless of transport.
///
/// The passcode is left as plain text (no links, no obfuscation) so it stays
/// selectable and copyable in the messaging app.
String buildPasscodeSmsBody(String passcode) =>
    'NIRVANA Passcode: $passcode\n'
    'Use this passcode to connect/access your NIRVANA account. '
    'Do not share this code with anyone else.';

/// Provider-independent passcode SMS delivery.
abstract class SmsService {
  /// Which transport this implementation uses.
  SmsDeliveryChannel get channel;

  /// Delivers [request].passcode to [request].patientPhone.
  ///
  /// Implementations MUST validate the phone number and MUST return a failure
  /// result (never a synthetic success) when they cannot proceed.
  Future<SmsSendResult> sendPasscode(PasscodeSmsRequest request);
}

// ==============================================================================
// MVP implementation — device SMS composer (free, no permissions)
// ==============================================================================

/// Opens the device's native SMS composer, pre-filled with the recipient and the
/// passcode message. The caregiver reviews and presses Send themselves.
///
/// This uses the Android-recommended `ACTION_SENDTO` + `sms:` URI via
/// url_launcher, which requires NO SMS permission: we never read, intercept, or
/// programmatically send messages. It works in a release APK.
///
/// Why `sms:` and not `smsto:`: `ACTION_SENDTO` with the `sms:` scheme is the
/// documented way to pre-fill both the recipient AND the body. Some apps (Google
/// Messages among them) treat `smsto:` as recipient-only and silently drop a
/// `?body=` parameter, which composes a blank message that then shows as
/// "Not sent".
class NativeSmsService implements SmsService {
  NativeSmsService({Future<bool> Function(Uri uri, LaunchMode mode)? launcher})
    : _launchUrl = launcher ?? _defaultLaunch;

  /// Injectable launcher so the behaviour is unit-testable without a device.
  final Future<bool> Function(Uri uri, LaunchMode mode) _launchUrl;

  static Future<bool> _defaultLaunch(Uri uri, LaunchMode mode) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  SmsDeliveryChannel get channel => SmsDeliveryChannel.nativeComposer;

  @override
  Future<SmsSendResult> sendPasscode(PasscodeSmsRequest request) async {
    final rawPhone = request.patientPhone?.trim() ?? '';

    // 1. Missing number -> explicit error. Never silently no-op.
    if (rawPhone.isEmpty) {
      return SmsSendResult.failure(
        SmsFailureReason.noPhoneNumber,
        message: 'Patient phone number is not available.',
      );
    }

    // 2. Validate format BEFORE opening the composer.
    if (!PhoneFormat.isValid(rawPhone)) {
      return SmsSendResult.failure(
        SmsFailureReason.invalidPhoneNumber,
        message:
            'Patient phone number is not valid. Please update it and try again.',
      );
    }

    // 3. Hand a pre-filled message to the OS composer.
    //
    // `ACTION_SENDTO` + `sms:` is what Android documents for this:
    //   sms:<recipient>?body=<percent-encoded message>
    //
    // The recipient goes in the URI path and the body MUST be percent-encoded
    // exactly once. Newlines become %0A, which is what messaging apps expect;
    // a raw newline in the query string truncates the message at the first line.
    //
    // Built as a literal string rather than via Uri(queryParameters:) so the
    // "+" in a +91 number stays a country code instead of being re-read as a
    // space, and so the encoding of the body is explicit and single-pass.
    //
    // `toSmsDialable` (not `toDialable`) guarantees a country code is present.
    // A bare national number reaches the composer fine but resolves to an
    // unroutable local address, so the message fails to send.
    final dialable = PhoneFormat.toSmsDialable(rawPhone);
    final body = Uri.encodeComponent(buildPasscodeSmsBody(request.passcode));
    final uri = Uri.parse('sms:$dialable?body=$body');

    try {
      final launched = await _launchUrl(uri, LaunchMode.externalApplication);
      if (!launched) {
        return SmsSendResult.failure(
          SmsFailureReason.composerUnavailable,
          message: 'Could not open the SMS app on this device.',
        );
      }
      return SmsSendResult.composerOpened(
        maskedRecipient: PhoneFormat.mask(rawPhone),
      );
    } on PlatformException {
      return SmsSendResult.failure(
        SmsFailureReason.composerUnavailable,
        message: 'Could not open the SMS app on this device.',
      );
    } catch (_) {
      // Never surface raw errors (they can carry the number/URI).
      return SmsSendResult.failure(
        SmsFailureReason.composerUnavailable,
        message: 'Could not open the SMS app on this device.',
      );
    }
  }
}

// ==============================================================================
// Production implementation — Supabase Edge Function (future)
// ==============================================================================

/// Delegates to a backend that talks to a real SMS provider.
///
/// The UI already renders this identically, so switching from the composer to
/// automatic delivery is a one-line provider change. Credentials live in the
/// Edge Function's secrets and never reach the client.
///
/// NOTE: wired but not enabled by default — see [nativeSmsServiceProvider].
class BackendSmsService implements SmsService {
  /// Invokes the backend for [request], returning a normalised result.
  ///
  /// Injected so this class has no compile-time dependency on a specific
  /// repository, and so it can be unit-tested with a fake.
  final Future<SmsSendResult> Function(PasscodeSmsRequest request) _invoke;

  BackendSmsService(this._invoke);

  @override
  SmsDeliveryChannel get channel => SmsDeliveryChannel.backend;

  @override
  Future<SmsSendResult> sendPasscode(PasscodeSmsRequest request) {
    // Local validation still applies: don't spend a round trip on a number we
    // already know is unusable.
    final rawPhone = request.patientPhone?.trim() ?? '';
    if (rawPhone.isEmpty) {
      return Future.value(
        SmsSendResult.failure(
          SmsFailureReason.noPhoneNumber,
          message: 'Patient phone number is not available.',
        ),
      );
    }
    if (!PhoneFormat.isValid(rawPhone)) {
      return Future.value(
        SmsSendResult.failure(
          SmsFailureReason.invalidPhoneNumber,
          message:
              'Patient phone number is not valid. Please update it and try again.',
        ),
      );
    }
    return _invoke(request);
  }
}

// ==============================================================================
// Providers
// ==============================================================================

/// The active passcode SMS transport.
///
/// MVP: the free native composer. To move to production SMS later, override this
/// to return a [BackendSmsService] — no UI change is required.
final smsServiceProvider = Provider<SmsService>((ref) {
  return NativeSmsService();
});
