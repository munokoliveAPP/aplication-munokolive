import 'package:flutter/material.dart';

class TerminalMessageEditor extends StatelessWidget {
  const TerminalMessageEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Terminal Message Editor',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
