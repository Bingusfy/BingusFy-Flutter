import 'package:bingo/appwidget.dart';
import 'package:bingo/modules/entry/presents/entry_page.dart';
import 'package:bingo/modules/rooms/presents/room_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('a room deep link does not mount the login redirect underneath', (
    tester,
  ) async {
    Get.testMode = true;
    final runtimeFonts = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/room/invalid';
    addTearDown(() {
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue();
      GoogleFonts.config.allowRuntimeFetching = runtimeFonts;
      Get.reset();
    });

    await tester.pumpWidget(const Appwidget());
    await tester.pump();

    expect(find.byType(RoomPage), findsOneWidget);
    expect(find.byType(EntryPage, skipOffstage: false), findsNothing);
    expect(find.text('Link de sala inválido.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
