// ==============================================================================
// NIRVANA - Phone Number Formatting Helpers
// Description: Lightweight, display-only phone helpers shared by the caregiver
// Patient Information section. Formatting is cosmetic — validation of the
// *sendable* number always happens against the server-side normalization rules.
//
// No third-party dependency is introduced: we keep digits and a leading '+', and
// group them for readability (e.g. "+91 98765 43210").
// ==============================================================================

class PhoneFormat {
  const PhoneFormat._();

  /// True when [raw] can plausibly be dialed/texted once separators are removed
  /// (8-15 digits, optional leading '+'), matching the backend's rules.
  static bool isValid(String? raw) {
    if (raw == null) return false;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  /// Human-readable grouping that preserves an explicit country code when the
  /// stored value includes one. Falls back to the raw (trimmed) value rather
  /// than dropping data the caregiver entered.
  static String format(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return '';

    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return trimmed;

    // 2-digit country code (India, UK, etc.), then groups of 5 — the common
    // readability pattern for the +91 XXXXX style in the design brief.
    if (hasPlus && digits.length > 10) {
      final country = digits.substring(0, digits.length - 10);
      final national = digits.substring(digits.length - 10);
      final first = national.substring(0, 5);
      final second = national.substring(5);
      return '+$country $first $second';
    }

    // Without an explicit country code, group in 3-4-4 for readability.
    final buffer = StringBuffer(hasPlus ? '+' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Country code assumed for a bare national number.
  ///
  /// NIRVANA ships in India first, so a 10-digit number with no explicit country
  /// code is completed as +91. This matters: carriers reject a bare national
  /// number passed to an SMS intent, and Google Messages renders it without a
  /// country code, which is what makes the message fail to send.
  static const defaultCountryCode = '91';

  /// The value handed to the clipboard / tel: URI — digits plus a leading '+'.
  static String toDialable(String raw) {
    final hasPlus = raw.trim().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return hasPlus ? '+$digits' : digits;
  }

  /// The value handed to an SMS intent — ALWAYS carrying a country code.
  ///
  /// Android's `ACTION_SENDTO` + `sms:` needs a number the carrier can route.
  /// A bare national number (e.g. `9876543210`) is accepted by the composer but
  /// resolves to an unroutable local address, so the send fails. We therefore:
  ///
  ///   * keep an explicit `+<cc>` exactly as given;
  ///   * convert a national trunk prefix (`0` + 10 digits) to `+91`;
  ///   * complete a bare 10-digit Indian number to `+91`;
  ///   * leave anything already carrying a country code untouched.
  static String toSmsDialable(String raw) {
    final trimmed = raw.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    // Already international — trust the explicit country code.
    if (trimmed.startsWith('+')) return '+$digits';

    // National trunk form: 0XXXXXXXXXX (11 digits) -> drop the trunk 0.
    if (digits.length == 11 && digits.startsWith('0')) {
      return '+$defaultCountryCode${digits.substring(1)}';
    }

    // Bare Indian mobile number (10 digits) -> add the country code.
    if (digits.length == 10) {
      return '+$defaultCountryCode$digits';
    }

    // Longer values already embed a country code (e.g. 919876543210).
    if (digits.length > 10) return '+$digits';

    // Shorter than a full national number: hand it over unchanged rather than
    // inventing digits, so the composer shows the caregiver what is on file.
    return digits;
  }

  /// Only ever exposes the last 4 digits — for confirmations and logs. The full
  /// number is never echoed back to the UI or written to a log.
  static String mask(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 4) return '****';
    return '****${digits.substring(digits.length - 4)}';
  }
}
