// ==============================================================================
// NIRVANA - Phone Dialer Helper
// Description: Opens the device's own phone dialer via a `tel:` URI.
//
// This is intentionally NOT VoIP. We do not place calls, record audio, or
// handle call state — we simply hand a number to the OS dialer and let the
// user press the green button. Works on Android and iOS.
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneDialer {
  const PhoneDialer();

  /// Returns true when the OS accepted the dial intent.
  ///
  /// Only a sanitized reason is logged — never the phone number itself.
  Future<bool> dial(String? rawNumber) async {
    final number = rawNumber?.trim();
    if (number == null || number.isEmpty) {
      debugPrint('📞 Dialer skipped: no phone number on file');
      return false;
    }

    final normalized = _sanitize(number);
    final uri = Uri(scheme: 'tel', path: normalized);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('📞 Dialer could not be opened');
      }
      return launched;
    } catch (_) {
      debugPrint('📞 Dialer launch failed');
      return false;
    }
  }

  /// Keeps digits, plus, and common separators; strips anything else.
  ///
  /// Guards against a malformed number producing an invalid tel: URI.
  String _sanitize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'[0-9+\-() ]').hasMatch(ch)) {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }
}
