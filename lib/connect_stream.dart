import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:livekit_client/livekit_client.dart';

class ConnectStreamPage extends StatefulWidget {
  const ConnectStreamPage({super.key});

  @override
  _ConnectStreamPageState createState() => _ConnectStreamPageState();
}

class _ConnectStreamPageState extends State<ConnectStreamPage> {
  final supabase = Supabase.instance.client;
  List<String> availableRooms = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  Future<void> _fetchAvailableRooms() async {
    setState(() => isLoading = true);
    const String apiUrl = "https://smarthelmet-tasvhq0j.livekit.cloud/api/rooms";
    const String apiKey = "YOUR_LIVEKIT_API_KEY"; // Replace with your LiveKit API key

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $apiKey"},
      );

      if (response.statusCode == 200) {
        List<dynamic> rooms = jsonDecode(response.body);
        setState(() {
          availableRooms = rooms.map((room) => room['name'].toString()).toList();
        });
      } else {
        throw Exception("Failed to fetch rooms. Status: ${response.statusCode}");
      }
    } catch (error) {
      print("⚠️ Error fetching rooms: $error");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _joinRoom(String roomName) async {
    try {
      final response = await supabase
          .from('livekit_tokens')
          .select('viewer_token')
          .limit(1)
          .maybeSingle();

      if (response != null && response['viewer_token'] != null) {
        String viewerToken = response['viewer_token'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WatchStreamPage(
              roomName: roomName,
              viewerToken: viewerToken,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No viewer token found for this room!")),
        );
      }
    } catch (error) {
      print("⚠️ Error fetching viewer token: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Live Streams")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : availableRooms.isEmpty
              ? const Center(child: Text("No active streams available."))
              : ListView.builder(
                  itemCount: availableRooms.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(availableRooms[index]),
                      trailing: const Icon(Icons.play_circle),
                      onTap: () => _joinRoom(availableRooms[index]),
                    );
                  },
                ),
    );
  }
}

// Dummy WatchStreamPage for testing
class WatchStreamPage extends StatelessWidget {
  final String roomName;
  final String viewerToken;

  const WatchStreamPage({super.key, required this.roomName, required this.viewerToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Watching: $roomName")),
      body: const Center(child: Text("🎥 Stream will be displayed here.")),
    );
  }
}
