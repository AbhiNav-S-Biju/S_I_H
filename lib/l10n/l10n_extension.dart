// ==============================================================================
// NIRVANA - Localization context extension
// Description: Provides a non-null [AppLocalizations] from a [BuildContext].
//
// The generated `AppLocalizations.of(context)` is nullable, which forces every
// call site to use `?.` plus an English fallback string. This extension removes
// that boilerplate for screens that must always show translated copy (e.g. the
// whole patient dashboard), falling back to English only if the delegate is
// genuinely absent (as in a bare widget test).
// ==============================================================================

import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

extension AppLocalizationsX on BuildContext {
  /// The active [AppLocalizations], guaranteed non-null.
  ///
  /// Uses the mounted localization delegate when present and otherwise falls
  /// back to the English instance so UI code never has to null-check.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn();
}
