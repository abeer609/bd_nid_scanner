import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:playground/main.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/src/exception.dart';

class WebSocketForm extends StatefulWidget {
  final WebSocketChannel socket;

  const WebSocketForm({super.key, required this.socket});

  @override
  State<WebSocketForm> createState() => _WebSocketFormState();
}

class _WebSocketFormState extends State<WebSocketForm> {
  int port = 13254;

  late WebSocketChannel socket;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    socket = widget.socket;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nid Scanner"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
              onPressed: () {
                socket.sink.add('hello');
              },
              child: const Text("Connect")),
          ElevatedButton(
            child: const Text("Disconnect"),
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const MyHomePage(title: "Home page")));
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.sink.close(status.goingAway);
    super.dispose();
  }
}
