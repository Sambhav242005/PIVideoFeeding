import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';

class VideoStreamApp extends StatefulWidget {
  final String serverIp;
  const VideoStreamApp({Key? key, required this.serverIp}) : super(key: key);

  @override
  _VideoStreamAppState createState() => _VideoStreamAppState();
}

class _VideoStreamAppState extends State<VideoStreamApp> {
  late IOWebSocketChannel channel;
  Uint8List? imageBytes;
  bool isProcessing = false;
  Queue<Uint8List> frameQueue = Queue<Uint8List>();

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _processFrames();
  }

  void _connectToServer() {
    String url = 'ws://${widget.serverIp}:8765';
    channel = IOWebSocketChannel.connect(url);

    channel.stream.listen((data) {
      try {
        List<int> decompressed = zlib.decode(data);
        Uint8List frame = Uint8List.fromList(decompressed);

        if (frameQueue.length < 10) { // Buffer up to 10 frames
          frameQueue.add(frame);
        }
      } catch (e) {
        print("Error decoding frame: $e");
      }
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  void _processFrames() async {
    while (true) {
      if (frameQueue.isNotEmpty && !isProcessing) {
        isProcessing = true;
        Uint8List frame = frameQueue.removeFirst();

        Uint8List optimizedFrame = await compute(_processImage, frame);

        setState(() {
          imageBytes = optimizedFrame;
        });

        isProcessing = false;
      }

      await Future.delayed(Duration(milliseconds: 15)); // Control frame rate
    }
  }

  static Uint8List _processImage(Uint8List frame) {
    return frame; // No processing now, but can add enhancements later
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Stream (Optimized)")),
      body: Center(
        child: imageBytes == null
            ? CircularProgressIndicator()
            : Image.memory(imageBytes!, gaplessPlayback: true),
      ),
    );
  }
}
