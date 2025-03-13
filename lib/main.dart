import 'package:flutter/material.dart';
import 'live_stream.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final TextEditingController ipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Raspberry Pi IP")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: ipController,
              decoration: InputDecoration(labelText: "Enter Pi IP Address"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String ip = ipController.text;
                if (ip.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VideoStreamApp(serverIp: ip)),
                  );
                }
              },
              child: Text("Connect & Stream"),
            ),
          ],
        ),
      ),
    );
  }
}
