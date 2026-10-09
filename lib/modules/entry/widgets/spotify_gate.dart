import 'package:bingo/modules/entry/presents/entry_page.dart';
import 'package:bingo/modules/entry/services/spotify_auth.dart';
import 'package:bingo/modules/home/presents/home_page.dart';
import 'package:flutter/material.dart';

/// Checks the OAuth session before opening the app, including direct /home URLs.
class SpotifyGate extends StatefulWidget {
  const SpotifyGate({super.key});

  @override
  State<SpotifyGate> createState() => _SpotifyGateState();
}

class _SpotifyGateState extends State<SpotifyGate> {
  late final _session = SpotifyAuth.restore();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const HomePage() : const EntryPage();
      },
    );
  }
}
