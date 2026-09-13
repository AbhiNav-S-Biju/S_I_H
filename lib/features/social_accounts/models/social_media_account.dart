import 'dart:convert';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

enum SocialPlatform {
  instagram('Instagram', FontAwesomeIcons.instagram),
  facebook('Facebook', FontAwesomeIcons.facebookF),
  xTwitter('X / Twitter', FontAwesomeIcons.xTwitter),
  linkedIn('LinkedIn', FontAwesomeIcons.linkedinIn),
  snapchat('Snapchat', FontAwesomeIcons.snapchat),
  tikTok('TikTok', FontAwesomeIcons.tiktok),
  discord('Discord', FontAwesomeIcons.discord);

  const SocialPlatform(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Resolves a stored/remote `platform` value to a [SocialPlatform].
  ///
  /// Values written by other clients (or by hand in the Supabase dashboard)
  /// may use the enum *label* ('Instagram', 'X / Twitter') or a differently
  /// cased/separated variant of the enum *name* ('instagram', 'LINKEDIN').
  /// Matching is therefore case- and separator-insensitive so an unusual value
  /// does not break parsing of an otherwise valid account.
  ///
  /// Throws a [FormatException] when [rawPlatform] matches no known platform.
  static SocialPlatform fromStorage(Object? rawPlatform) {
    final raw = rawPlatform?.toString().trim() ?? '';
    if (raw.isEmpty) {
      throw const FormatException('Missing social platform.');
    }
    final normalized = _normalizePlatformToken(raw);
    for (final platform in SocialPlatform.values) {
      if (normalized == platform.name.toLowerCase() ||
          normalized == _normalizePlatformToken(platform.label)) {
        return platform;
      }
    }
    // A few legacy aliases that predate the current enum names.
    switch (normalized) {
      case 'twitter':
      case 'x':
        return SocialPlatform.xTwitter;
    }
    throw const FormatException('Invalid social platform.');
  }

  static String _normalizePlatformToken(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s/_-]+'), '');
}

class SocialMediaAccount {
  const SocialMediaAccount({
    required this.id,
    required this.platform,
    required this.usernameOrEmail,
    required this.password,
  });

  final String id;
  final SocialPlatform platform;
  final String usernameOrEmail;
  final String password;

  SocialMediaAccount copyWith({
    String? id,
    SocialPlatform? platform,
    String? usernameOrEmail,
    String? password,
  }) {
    return SocialMediaAccount(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      usernameOrEmail: usernameOrEmail ?? this.usernameOrEmail,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform.name,
    'usernameOrEmail': usernameOrEmail,
    'password': password,
  };

  factory SocialMediaAccount.fromJson(Map<String, dynamic> json) {
    final platform = SocialPlatform.fromStorage(json['platform']);
    return SocialMediaAccount(
      id: json['id'] as String,
      platform: platform,
      usernameOrEmail: json['usernameOrEmail'] as String,
      password: json['password'] as String,
    );
  }

  static String encodeList(List<SocialMediaAccount> accounts) => jsonEncode(
    accounts.map((account) => account.toJson()).toList(growable: false),
  );

  static List<SocialMediaAccount> decodeList(String value) {
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded
        .map(
          (item) => SocialMediaAccount.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
