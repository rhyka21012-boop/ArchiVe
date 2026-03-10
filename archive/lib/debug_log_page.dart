import 'package:flutter/material.dart';

class DebugLogPage extends StatelessWidget {
  final List<String> logs;

  const DebugLogPage({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug Logs")),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(logs[index], style: const TextStyle(fontSize: 12)),
          );
        },
      ),
    );
  }
}
