// ==============================================================================
// NIRVANA — Social platform parsing test
// Description: Guards tolerant parsing of the `platform` value returned by the
//   Supabase `social_media_accounts` table. Rows written by other clients (or by
//   hand in the dashboard) may use the enum label or a different casing; a
//   single unrecognised value used to abort the entire account load, hiding
//   every saved account on the patient dashboard.
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/social_accounts/models/social_media_account.dart';

void main() {
  group('SocialPlatform.fromStorage', () {
    test('parses canonical enum names', () {
      expect(SocialPlatform.fromStorage('instagram'), SocialPlatform.instagram);
      expect(SocialPlatform.fromStorage('xTwitter'), SocialPlatform.xTwitter);
      expect(SocialPlatform.fromStorage('linkedIn'), SocialPlatform.linkedIn);
      expect(SocialPlatform.fromStorage('tikTok'), SocialPlatform.tikTok);
    });

    test('parses display labels with slashes/spaces', () {
      expect(
        SocialPlatform.fromStorage('X / Twitter'),
        SocialPlatform.xTwitter,
      );
      expect(SocialPlatform.fromStorage('LinkedIn'), SocialPlatform.linkedIn);
      expect(SocialPlatform.fromStorage('Facebook'), SocialPlatform.facebook);
    });

    test('is case and separator insensitive', () {
      expect(SocialPlatform.fromStorage('INSTAGRAM'), SocialPlatform.instagram);
      expect(SocialPlatform.fromStorage('Linked_In'), SocialPlatform.linkedIn);
      expect(
        SocialPlatform.fromStorage('  snapchat '),
        SocialPlatform.snapchat,
      );
    });

    test('maps legacy aliases', () {
      expect(SocialPlatform.fromStorage('twitter'), SocialPlatform.xTwitter);
      expect(SocialPlatform.fromStorage('X'), SocialPlatform.xTwitter);
    });

    test('throws for empty or unknown values', () {
      expect(() => SocialPlatform.fromStorage(null), throwsFormatException);
      expect(() => SocialPlatform.fromStorage(''), throwsFormatException);
      expect(
        () => SocialPlatform.fromStorage('myspace'),
        throwsFormatException,
      );
    });
  });

  group('SocialMediaAccount.fromJson', () {
    test('decodes a row whose platform uses the display label', () {
      final account = SocialMediaAccount.fromJson({
        'id': 'a1',
        'platform': 'X / Twitter',
        'usernameOrEmail': 'henry',
        'password': 'pw',
      });
      expect(account.platform, SocialPlatform.xTwitter);
    });
  });
}
