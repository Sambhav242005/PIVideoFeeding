import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:archive/archive.dart'; // For zlib decompression
import 'package:livekit_client/livekit_client.dart'; // LiveKit
import 'dart:convert';

class VideoStreamApp extends StatefulWidget {
  final String serverIp;
  final String liveKitToken;

  const VideoStreamApp({
    super.key,
    required this.serverIp,
    required this.liveKitToken,
  });

  @override
  _VideoStreamAppState createState() => _VideoStreamAppState();
}

class _VideoStreamAppState extends State<VideoStreamApp> {
  late IOWebSocketChannel channel;
  ui.Image? lastFrame;
  bool isProcessingFrame = false; // ✅ Prevents frame loss
  Room? room;
  LocalVideoTrack? videoTrack;

  @override
  void initState() {
    super.initState();
    _connectToServer();
    _connectToLiveKit();
    print("🔑 Streamer Token Received: ${widget.liveKitToken}");
  }

  void _connectToServer() {
    String url = 'ws://${widget.serverIp}:8765';
    channel = IOWebSocketChannel.connect(url);

    channel.stream.listen((data) async {
      if (isProcessingFrame) return; // ✅ Skip if previous frame still processing
      isProcessingFrame = true;

      try {
        Uint8List compressedData;
        if (data is String) {
          compressedData = Uint8List.fromList(base64Decode(data));
        } else {
          compressedData = data as Uint8List;
        }

        List<int> decompressed = ZLibDecoder().decodeBytes(compressedData);
        ui.Image image = await decodeImageFromList(Uint8List.fromList(decompressed));

        if (mounted) {
          setState(() {
            lastFrame = image; // ✅ Keeps the previous frame until the new one is processed
          });
        }
      } catch (e) {
        print("❌ Error processing frame: $e");
      }

      isProcessingFrame = false; // ✅ Ready for next frame
    }, onError: (error) {
      print("❌ WebSocket error: $error");
    });
  }

  Future<void> _connectToLiveKit() async {
    room = Room();
    try {
      await room!.connect("wss://smarthelmet-tasvhq0j.livekit.cloud", widget.liveKitToken);
      print("✅ Connected to LiveKit");

      videoTrack = await LocalVideoTrack.createCameraTrack();
      await room!.localParticipant?.publishVideoTrack(videoTrack!);
      print("📡 Video track published to LiveKit");
    } catch (e) {
      print("❌ LiveKit connection error: $e");
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = 4 / 3;
    double screenHeight = screenWidth / aspectRatio;

    return Scaffold(
      appBar: AppBar(title: const Text("🎥 Streaming to Room1")),
      body: SafeArea(
        child: Center(
          child: lastFrame != null
              ? CustomPaint(
                  size: Size(screenWidth, screenHeight),
                  painter: VideoPainter(lastFrame!),
                )
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class VideoPainter extends CustomPainter {
  final ui.Image frame;
  VideoPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Rect dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(frame, Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()), dstRect, paint);
  }

  @override
  bool shouldRepaint(VideoPainter oldDelegate) {
    return true;
  }
}
