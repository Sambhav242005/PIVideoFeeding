import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
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
  Queue<Uint8List> frameQueue = Queue<Uint8List>();

  // Variables to control frame upload frequency
  DateTime? lastUploadTime;
  int frameCounter = 0;

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
        if (kDebugMode) {
          print("Error decoding frame: $e");
        }
      }
    }, onError: (error) {
      if (kDebugMode) {
        print("WebSocket error: $error");
      }
    });
  }

  void _processFrames() async {
    while (true) {
      if (frameQueue.isNotEmpty && !isProcessing) {
        isProcessing = true;
        Uint8List frame = frameQueue.removeFirst();

        // Process the frame asynchronously (if any processing is needed)
        Uint8List optimizedFrame = await compute(_processImage, frame);

        setState(() {
          imageBytes = optimizedFrame;
        });

        // Upload one frame per second
        if (lastUploadTime == null ||
            DateTime.now().difference(lastUploadTime!) > Duration(seconds: 1)) {
          frameCounter++;
          await _uploadFrame(optimizedFrame, frameCounter);
          lastUploadTime = DateTime.now();
        }

        isProcessing = false;
      }

      await Future.delayed(Duration(milliseconds: 15)); // Control frame rate
    }
  }

  // A placeholder for any image processing logic
  static Uint8List _processImage(Uint8List frame) {
    return frame;
  }

  /// Uploads a frame to Supabase Storage under the bucket "video_frames".
  Future<void> _uploadFrame(Uint8List frame, int frameNumber) async {
    final supabase = Supabase.instance.client;
    final fileName = 'frames/frame_$frameNumber.png';

    try {
      // Upload the binary frame. The method returns the file path on success.
      final filePath = await supabase.storage.from('videoframes').uploadBinary(fileName, frame);
      if (kDebugMode) {
        print("Uploaded frame: $filePath");
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error uploading frame: $error");
      }
    }
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
