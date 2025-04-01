import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'live_stream.dart';

// Global variable to store streamer token
String _streamerToken = "";

class StartStreamPage extends StatefulWidget {
  const StartStreamPage({super.key});

  @override
  _StartStreamPageState createState() => _StartStreamPageState();
}

class _StartStreamPageState extends State<StartStreamPage> {
  final TextEditingController ipController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLastIp();
  }

  Future<void> _fetchLastIp() async {
    try {
      final response = await supabase
          .from('stream_ips')
          .select('ip')
          .limit(1)
          .maybeSingle();
      if (response != null && response['ip'] != null) {
        setState(() {
          ipController.text = response['ip'];
        });
      }
    } catch (error) {
      print("⚠️ Error fetching IP: $error");
    }
  }

  Future<void> _saveIp(String ip) async {
    try {
      await supabase.from('stream_ips').upsert({'id': 1, 'ip': ip});
    } catch (error) {
      print("⚠️ Error saving IP: $error");
    }
  }

  Future<void> _fetchAndUploadTokens() async {
    setState(() => _isLoading = true);

    const String apiUrl = "http://192.168.60.64:7000/generate_tokens";
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final output = jsonDecode(response.body);
        final String streamerToken = output['streamer_token'];
        final String viewerToken = output['viewer_token'];

        // Save the streamer token globally
        _streamerToken = streamerToken;

        // Delete all previous tokens
        await supabase.from('livekit_tokens').delete().not('id', 'is', null);

        // Generate a new UUID
        final uuid = Uuid().v4();

        // Insert new tokens
        await supabase.from('livekit_tokens').insert({
          'id': uuid,
          'streamer_token': streamerToken,
          'viewer_token': viewerToken,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ LiveKit tokens updated successfully!")),
        );

        String ip = ipController.text.trim();
        if (ip.isNotEmpty) {
          await _saveIp(ip);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoStreamApp(
                serverIp: ip,
                liveKitToken: _streamerToken, // Pass the token
              ),
            ),
          );
        }
      } else {
        throw Exception("Server responded with ${response.statusCode}: ${response.body}");
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error fetching tokens: $error")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Start Streaming")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(labelText: "Enter Raspberry Pi IP"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchAndUploadTokens,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Generate Token & Start Stream"),
            ),
          ],
        ),
      ),
    );
  }
}
