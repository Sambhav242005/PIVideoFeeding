import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MicButton extends StatefulWidget {
  @override
  _MicButtonState createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String? filePath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await _recorder!.openRecorder();
  }

  Future<void> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    if (kDebugMode) {
      print("Recording to: ${dir.path}");
      
    }
    filePath = '${dir.path}/recorded_audio.aac';

    await _recorder!.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );
    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() => isRecording = false);
    print('Recording saved at: $filePath');
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (isRecording) {
          await stopRecording();
        } else {
          await startRecording();
        }
      },
      child: CircleAvatar(
        radius: 30,
        backgroundColor: isRecording ? Colors.red : Colors.green,
        child: Icon(Icons.mic, color: Colors.white, size: 30),
      ),
    );
  }
}
