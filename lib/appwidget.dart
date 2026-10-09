import 'package:bingo/modules/entry/presents/entry_page.dart';
import 'package:bingo/modules/entry/widgets/spotify_gate.dart';
import 'package:bingo/modules/rooms/presents/room_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'global/services/navigator_global_key.dart';

class Appwidget extends StatelessWidget {
  const Appwidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      left: false,
      right: false,
      top: false,
      child: GetMaterialApp(
        theme: ThemeData(
          fontFamily: GoogleFonts.inter().fontFamily,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1ED760),
            surface: Color(0xFF0A0A0A),
          ),
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        title: 'BingusFy',
        navigatorKey: AppGlobalNavigatorKey.navigatorKey,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
        ),
        debugShowCheckedModeBanner: false,
        // A deep link must start with just its destination. The default initial
        // stack also mounts '/', whose Spotify restore redirects room owners.
        onGenerateInitialRoutes: (name) => [
          if (name.startsWith('/room/'))
            MaterialPageRoute(
              settings: RouteSettings(name: name),
              builder: (_) => RoomPage(roomId: name.substring(6)),
            )
          else
            MaterialPageRoute(
              settings: RouteSettings(name: name == '/home' ? '/home' : '/'),
              builder: (_) =>
                  name == '/home' ? const SpotifyGate() : const EntryPage(),
            ),
        ],
        routes: {
          '/': (context) => const EntryPage(),
          '/home': (context) => const SpotifyGate(),
        },
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          if (name.startsWith('/room/')) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => RoomPage(roomId: name.substring(6)),
            );
          }
          return null;
        },
      ),
    );
  }
}
