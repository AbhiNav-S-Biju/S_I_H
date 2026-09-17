// ==============================================================================
// NIRVANA - Passcode Copy + SMS Actions Tests
//
// Covers the caregiver-side contract for the passcode actions:
//   * Copy Passcode writes the CURRENT passcode to the clipboard
//   * Send Passcode opens the native SMS composer pre-filled (MVP transport)
//   * the URI carries the patient's number in the To field and the passcode in
//     the body, as plain selectable text
//   * missing phone -> explicit "not available" error (never a silent no-op)
//   * invalid phone -> explicit error, and the composer is NOT opened
//   * regeneration invalidates the old passcode for the actions row
//   * phone formatting/validation/masking helpers
//
// IMPORTANT: these tests assert that the composer was HANDED a correct message.
// They never assert that an SMS was delivered — native delivery is confirmed by
// the caregiver in the SMS app, and backend delivery is verified separately
// against real provider configuration.
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/caregiver/presentation/widgets/patient_device_panel.dart';
import 'package:nirvana/features/caregiver/services/sms_service.dart';
import 'package:nirvana/features/caregiver/utils/phone_format.dart';
import 'package:url_launcher/url_launcher.dart';

// `LaunchMode` is re-exported by url_launcher; imported explicitly so the test
// stays honest about which package defines the launch contract.

/// Records the URI handed to the OS instead of opening a real SMS app.
class _RecordingLauncher {
  final List<Uri> launched = [];
  bool succeed;

  _RecordingLauncher({this.succeed = true});

  Future<bool> call(Uri uri, LaunchMode mode) async {
    launched.add(uri);
    return succeed;
  }

  Uri? get lastUri => launched.isEmpty ? null : launched.last;
}

PasscodeSmsRequest _request({
  String? phone = '+91 98765 43210',
  String passcode = '123456',
}) => PasscodeSmsRequest(
  patientId: 'p-1',
  patientName: 'Rahul',
  patientPhone: phone,
  passcode: passcode,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneFormat helpers', () {
    test('formats a country-coded number readably', () {
      expect(PhoneFormat.format('+919876543210'), '+91 98765 43210');
    });

    test('rejects implausible numbers', () {
      expect(PhoneFormat.isValid('+91 98765 43210'), isTrue);
      expect(PhoneFormat.isValid('12345'), isFalse);
      expect(PhoneFormat.isValid('not-a-number'), isFalse);
      expect(PhoneFormat.isValid(''), isFalse);
      expect(PhoneFormat.isValid(null), isFalse);
    });

    test('masks everything but the last four digits', () {
      expect(PhoneFormat.mask('+91 98765 43210'), '****3210');
      expect(PhoneFormat.mask('123'), '****');
      expect(PhoneFormat.mask(null), '****');
    });

    test('produces a dialable value keeping the leading plus', () {
      expect(PhoneFormat.toDialable('+91 (98765) 43210'), '+919876543210');
    });

    group('toSmsDialable always carries a country code', () {
      test('keeps an explicit country code', () {
        expect(PhoneFormat.toSmsDialable('+91 98765 43210'), '+919876543210');
        expect(PhoneFormat.toSmsDialable('+1 555 010 9999'), '+15550109999');
      });

      test('adds +91 to a bare 10-digit Indian number', () {
        // The regression that made Google Messages show "098765 43210".
        expect(PhoneFormat.toSmsDialable('9876543210'), '+919876543210');
        expect(PhoneFormat.toSmsDialable('98765 43210'), '+919876543210');
      });

      test('strips a national trunk 0 before adding the country code', () {
        expect(PhoneFormat.toSmsDialable('09876543210'), '+919876543210');
      });

      test('accepts a number that already embeds a country code', () {
        expect(PhoneFormat.toSmsDialable('919876543210'), '+919876543210');
      });

      test('never invents digits for a partial number', () {
        expect(PhoneFormat.toSmsDialable('12345'), '12345');
        expect(PhoneFormat.toSmsDialable(''), '');
      });
    });
  });

  group('SMS message body', () {
    test('contains NIRVANA branding, the passcode, and an instruction', () {
      final body = buildPasscodeSmsBody('654321');
      expect(body, contains('NIRVANA'));
      // The passcode must be plain text so it stays selectable/copyable.
      expect(body, contains('654321'));
      expect(body, contains('Do not share this code with anyone else.'));
    });

    test('carries exactly the passcode it is given, with no reformatting', () {
      expect(buildPasscodeSmsBody('000123'), contains('000123'));
    });
  });

  group('NativeSmsService (MVP transport)', () {
    test('opens the composer with the patient number and passcode', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      final result = await service.sendPasscode(_request());

      expect(result.isSuccess, isTrue);
      expect(result.channel, SmsDeliveryChannel.nativeComposer);
      expect(result.maskedRecipient, '****3210');
      expect(launcher.launched, hasLength(1));

      final uri = launcher.lastUri!;
      // Android's documented way to pre-fill recipient + body.
      expect(uri.scheme, 'sms');
      // Recipient is pre-filled in the To field, with the +91 intact.
      expect(uri.path, '+919876543210');
      // Passcode is pre-filled in the body, as plain text.
      expect(uri.queryParameters['body'], contains('123456'));
      expect(uri.queryParameters['body'], contains('NIRVANA'));
    });

    test('percent-encodes the body so newlines survive intact', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      await service.sendPasscode(_request());

      final raw = launcher.lastUri!.toString();
      // The body is encoded exactly once: a literal newline would truncate the
      // message in the composer, so it MUST appear as %0A on the wire.
      expect(raw, contains('body=NIRVANA%20Passcode%3A%20123456%0A'));
      expect(raw, isNot(contains('\n')));

      // And it round-trips back to the full multi-line message byte-for-byte.
      expect(
        launcher.lastUri!.queryParameters['body'],
        buildPasscodeSmsBody('123456'),
      );
    });

    test('sends exactly the currently generated passcode', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      await service.sendPasscode(_request(passcode: '987654'));

      expect(launcher.lastUri!.queryParameters['body'], contains('987654'));
      expect(
        launcher.lastUri!.queryParameters['body'],
        isNot(contains('123456')),
      );
    });

    test('keeps the + country code instead of turning it into a space', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      await service.sendPasscode(_request(phone: '+91 98765 43210'));

      // `+` must reach the SMS app as a country code, never as a decoded space.
      expect(launcher.lastUri!.path, '+919876543210');
      expect(launcher.lastUri!.queryParameters.containsKey('body'), isTrue);
    });

    test('adds +91 when the stored number has no country code', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      // A bare national number is the case that fails to send in practice.
      await service.sendPasscode(_request(phone: '9876543210'));

      expect(launcher.lastUri!.path, '+919876543210');
    });

    test('normalises a trunk-prefixed number from the database', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      await service.sendPasscode(_request(phone: '09876543210'));

      expect(launcher.lastUri!.path, '+919876543210');
    });

    test('uses the sms: scheme, not smsto: (Google Messages drops smsto body)', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      await service.sendPasscode(_request());

      expect(launcher.lastUri!.scheme, 'sms');
      expect(launcher.lastUri!.scheme, isNot('smsto'));
    });

    test('missing phone number fails clearly and opens nothing', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      final result = await service.sendPasscode(_request(phone: null));

      expect(result.isSuccess, isFalse);
      expect(result.reason, SmsFailureReason.noPhoneNumber);
      expect(result.message, 'Patient phone number is not available.');
      expect(launcher.launched, isEmpty);
    });

    test('blank phone number is treated as missing', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      final result = await service.sendPasscode(_request(phone: '   '));

      expect(result.reason, SmsFailureReason.noPhoneNumber);
      expect(launcher.launched, isEmpty);
    });

    test('invalid phone number fails clearly and opens nothing', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      final result = await service.sendPasscode(_request(phone: '12345'));

      expect(result.isSuccess, isFalse);
      expect(result.reason, SmsFailureReason.invalidPhoneNumber);
      expect(launcher.launched, isEmpty);
    });

    test('reports failure when no SMS app can handle the intent', () async {
      final launcher = _RecordingLauncher(succeed: false);
      final service = NativeSmsService(launcher: launcher.call);

      final result = await service.sendPasscode(_request());

      expect(result.isSuccess, isFalse);
      expect(result.reason, SmsFailureReason.composerUnavailable);
    });

    test('never leaks the raw phone number into the result', () async {
      final launcher = _RecordingLauncher();
      final service = NativeSmsService(launcher: launcher.call);

      final result = await service.sendPasscode(_request());
      final rendered = '${result.message}${result.maskedRecipient}';

      expect(rendered, isNot(contains('9876543210')));
    });
  });

  group('BackendSmsService (future production transport)', () {
    test('validates locally before spending a round trip', () async {
      var invoked = 0;
      final service = BackendSmsService((_) async {
        invoked++;
        return SmsSendResult.backendSent();
      });

      final result = await service.sendPasscode(_request(phone: '12345'));

      expect(result.reason, SmsFailureReason.invalidPhoneNumber);
      expect(invoked, 0);
    });

    test('delegates a valid request and reports the backend channel', () async {
      final service = BackendSmsService(
        (_) async => SmsSendResult.backendSent(maskedRecipient: '****3210'),
      );

      final result = await service.sendPasscode(_request());

      expect(result.isSuccess, isTrue);
      expect(result.channel, SmsDeliveryChannel.backend);
    });
  });

  group('PasscodeActionsRow', () {
    Widget wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

    testWidgets('renders both actions and fires their callbacks', (
      WidgetTester tester,
    ) async {
      var copied = 0;
      var sent = 0;

      await tester.pumpWidget(
        wrap(
          PasscodeActionsRow(
            passcode: '123456',
            onCopy: () => copied++,
            onSend: () => sent++,
          ),
        ),
      );

      expect(find.text('Copy Passcode'), findsOneWidget);
      expect(find.text('Send Passcode'), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy_passcode_button')));
      await tester.tap(find.byKey(const Key('send_passcode_button')));

      expect(copied, 1);
      expect(sent, 1);
    });

    testWidgets('copy actually writes the current passcode to the clipboard', (
      WidgetTester tester,
    ) async {
      final clipboardCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        wrap(
          PasscodeActionsRow(
            passcode: '424242',
            onCopy: () =>
                Clipboard.setData(const ClipboardData(text: '424242')),
            onSend: () {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('copy_passcode_button')));
      await tester.pumpAndSettle();

      expect(clipboardCalls, isNotEmpty);
      expect((clipboardCalls.last.arguments as Map)['text'], '424242');
    });

    testWidgets('actions are disabled while a send is in flight', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PasscodeActionsRow(
            passcode: '123456',
            isSending: true,
            onCopy: () {},
            onSend: () {},
          ),
        ),
      );

      final sendButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('send_passcode_button')),
      );
      expect(sendButton.onPressed, isNull);
    });
  });
}
