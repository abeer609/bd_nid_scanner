import 'dart:io';

import 'package:flutter/material.dart';
import 'package:playground/components/barcode_scanner_controller.dart';
import 'package:playground/components/connection_refuesd_dialog.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Nid Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void connectWs() async {
    setState(() {
      isLoading = true;
    });
    socket = WebSocketChannel.connect(
      Uri.parse("ws://${hostController.text}:13254"),
    );
    try {
      await socket.ready;
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                BarcodeScannerWithController(socket: socket)));
      }
    } on SocketException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => ConnectionRefuesdDialog(message: e.message));
      }
    } on WebSocketException catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showDialog(
            context: context,
            builder: (context) => ConnectionRefuesdDialog(message: e.message));
      }
    }
  }

  final hostController = TextEditingController();
  late WebSocketChannel socket;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  @override
  void dispose() {
    hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Host address',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid host address';
                          } else if (!isValidAddress(value)) {
                            return 'Invalid host address';
                          } else {
                            return null;
                          }
                        },
                        controller: hostController,
                      ),
                      ElevatedButton.icon(
                        icon: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.keyboard_arrow_right),
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.blue.shade500),
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white)),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            !isLoading ? connectWs() : null;
                          }
                        },
                        label: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // const WebSocketForm(host: "192.168.1.116"),
          // const Expanded(
          //   child: BarcodeScannerWithController(),
          // ),
          // ElevatedButton(
          //     onPressed: () {
          //       Navigator.of(context).push(MaterialPageRoute(
          //         builder: (context) => const BarcodeScannerWithController(),
          //       ));
          //     },
          //     child: const Text('Scan Nid Card'))
        ],
      ),
    );
  }
}

bool isValidAddress(String address) {
  // Regular expression for IP address
  final ipRegExp = RegExp(
      r'^([01]?\d{1,2}|2[0-4]\d|25[0-5])\.([01]?\d{1,2}|2[0-4]\d|25[0-5])\.([01]?\d{1,2}|2[0-4]\d|25[0-5])\.([01]?\d{1,2}|2[0-4]\d|25[0-5])$');

  // Regular expression for domain name
  final domainRegExp = RegExp(
      r'^((ws|wss):\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,6}(:[0-9]{1,5})?(\/\S*)?$');

  return ipRegExp.hasMatch(address) || domainRegExp.hasMatch(address);
}
