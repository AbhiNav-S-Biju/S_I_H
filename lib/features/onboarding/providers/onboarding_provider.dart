// ==============================================================================
// NIRVANA - Onboarding Provider
// Description: Riverpod state management for first-time onboarding completion.
// ==============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier({bool initialCompleted = false}) : super(initialCompleted);

  void completeOnboarding() {
    state = true;
  }

  void resetOnboarding() {
    state = false;
  }
}

final onboardingCompletedProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});
