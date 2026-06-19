import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rang Adda Lobby')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select a Game', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.push('/table/thulla'),
              child: const Text('Play Thulla'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => context.push('/table/rang'),
              child: const Text('Play Rang'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () => context.push('/table/bluff'),
              child: const Text('Play Bluff'),
            ),
          ],
        ),
      ),
    );
  }
}
