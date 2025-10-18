import 'package:bingo/modules/home/presents/home_page.dart';
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
        routes: {'/': (context) => const HomePage()},
      ),
    );
  }
}
