import 'dart:convert';

import 'package:flutter/material.dart';

enum SocialPlatform {
  instagram('Instagram', Icons.camera_alt_rounded),
  facebook('Facebook', Icons.facebook),
  xTwitter('X / Twitter', Icons.alternate_email_rounded),
  linkedIn('LinkedIn', Icons.business_center_rounded),
  snapchat('Snapchat', Icons.chat_bubble_rounded),
  tikTok('TikTok', Icons.music_note_rounded),
  discord('Discord', Icons.forum_rounded);

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
