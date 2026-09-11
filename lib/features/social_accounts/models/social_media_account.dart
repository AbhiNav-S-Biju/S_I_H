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
    final platformName = json['platform'] as String?;
    final platform = SocialPlatform.values.firstWhere(
      (value) => value.name == platformName,
      orElse: () => throw const FormatException('Invalid social platform.'),
    );
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
