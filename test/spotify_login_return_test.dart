import 'dart:async';

import 'package:bingo/modules/entry/presents/entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> showLogin(
    WidgetTester tester, {
    required Future<void> Function() signIn,
    required Future<bool> Function() restore,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: EntryPage(
          signIn: signIn,
          restoreSession: restore,
          spotifyConfigured: true,
        ),
        routes: {'/home': (_) => const Scaffold(body: Text('Login concluído'))},
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
  }

  testWidgets('successful native login opens home', (tester) async {
    final login = Completer<void>();
    var authenticated = false;
    await showLogin(
      tester,
      signIn: () => login.future,
      restore: () async => authenticated,
    );
    expect(find.text('Conectando...'), findsOneWidget);
    authenticated = true;
    login.complete();
    await tester.pumpAndSettle();
    expect(find.text('Login concluído'), findsOneWidget);
    expect(find.text('Conectando...'), findsNothing);
  });

  testWidgets('cancelled native login re-enables button', (tester) async {
    await showLogin(tester, signIn: () async {}, restore: () async => false);
    await tester.pumpAndSettle();
    expect(find.text('Conectando...'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('timed out native login shows error and permits retry', (
    tester,
  ) async {
    var authenticated = false;
    var attempts = 0;
    await showLogin(
      tester,
      signIn: () async {
        if (attempts++ == 0) throw TimeoutException('exchange');
        authenticated = true;
      },
      restore: () async => authenticated,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('O login demorou'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Login concluído'), findsOneWidget);
  });

  testWidgets('token failure clears spinner and shows a useful error', (
    tester,
  ) async {
    await showLogin(
      tester,
      signIn: () async => throw StateError('exchange failed'),
      restore: () async => false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Conectando...'), findsNothing);
    expect(find.textContaining('Não foi possível concluir'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
