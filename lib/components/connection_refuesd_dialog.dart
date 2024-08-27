import 'package:flutter/material.dart';

class ConnectionRefuesdDialog extends StatelessWidget {
  final String message;
  const ConnectionRefuesdDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // icon: const Icon(Icons.error_outline),
      title: const Text("Connection Error"),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context, 'ok');
            },
            child: const Text('Ok'))
      ],
    );
  }
}
