import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nirvana/features/social_accounts/presentation/social_media_account_form.dart';

void main() {
  testWidgets('validates required fields and toggles password visibility', (
    tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialMediaAccountForm(onSave: (account) async => saved = true),
        ),
      ),
    );

    await tester.tap(find.text('Save account'));
    await tester.pump();
    expect(find.text('Enter a username or email.'), findsOneWidget);
    expect(find.text('Enter a password.'), findsOneWidget);
    expect(saved, isFalse);

    final passwordField = find.byType(TextFormField).last;
    await tester.enterText(passwordField, 'secret');
    final editableField = find.byType(EditableText).last;
    final obscureBefore = tester
        .widget<EditableText>(editableField)
        .obscureText;
    expect(obscureBefore, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_rounded));
    await tester.pump();
    expect(tester.widget<EditableText>(editableField).obscureText, isFalse);
  });
}
