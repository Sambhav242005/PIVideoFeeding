import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:isolate';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoStreamApp extends StatefulWidget {
  final String serverIp;
  const VideoStreamApp({super.key, required this.serverIp});

  @override
  _VideoStreamAppState createState() => _VideoStreamAppState();
}

class _VideoStreamAppState extends State<VideoStreamApp> {
  late IOWebSocketChannel channel;
  Uint8List? imageBytes;
  bool isProcessing = false;
  SendPort? isolateSendPort;
  late ReceivePort receivePort;

  // Upload control
  DateTime? lastUploadTime;

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _startFrameProcessing();
  }

  void _connectToServer() {
    String url = 'ws://${widget.serverIp}:8765';
    channel = IOWebSocketChannel.connect(url);

    channel.stream.listen(
      (data) {
        try {
          List<int> decompressed = zlib.decode(data);
          Uint8List frame = Uint8List.fromList(decompressed);

          if (isolateSendPort != null) {
            isolateSendPort!.send(
              frame,
            ); // Send frame to isolate for processing
          }
        } catch (e) {
          if (kDebugMode) print("Error decoding frame: $e");
        }
      },
      onError: (error) {
        if (kDebugMode) print("WebSocket error: $error");
      },
    );
  }

  void _startFrameProcessing() async {
    receivePort = ReceivePort();
    Isolate.spawn(_frameProcessingIsolate, receivePort.sendPort);

    receivePort.listen((data) {
      if (data is SendPort) {
        isolateSendPort = data; // Get the isolate's send port
      } else if (data is Uint8List) {
        setState(() {
          imageBytes = data;
        });

        // Upload frame every 1 second
        if (lastUploadTime == null ||
            DateTime.now().difference(lastUploadTime!) > Duration(milliseconds: 100)) {
          lastUploadTime = DateTime.now();
          _uploadFrame(data);
        }
      }
    });
  }

  static void _frameProcessingIsolate(SendPort mainSendPort) {
    ReceivePort isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort); // Send sendPort back

    isolateReceivePort.listen((frame) {
      if (frame is Uint8List) {
        Uint8List optimizedFrame = _processImage(frame);
        mainSendPort.send(optimizedFrame);
      }
    });
  }

  static Uint8List _processImage(Uint8List frame) {
    return frame; // Placeholder for future processing
  }

  Future<void> _uploadFrame(Uint8List frame) async {
    final supabase = Supabase.instance.client;
    final fileName =
        'frames/frame_${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await supabase.storage.from('videoframes').uploadBinary(fileName, frame);
      if (kDebugMode) print("Uploaded frame: $fileName");
    } catch (error) {
      if (kDebugMode) print("Error uploading frame: $error");
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    receivePort.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Stream (Optimized)")),
      body: Center(
        child:
            imageBytes == null
                ? CircularProgressIndicator()
                : Image.memory(imageBytes!, gaplessPlayback: true),
      ),
    );
  }
}
