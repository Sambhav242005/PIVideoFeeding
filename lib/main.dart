import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'live_stream.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env or use --dart-define values
  await dotenv.load();

  final supabaseUrl =
      dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final supabaseKey =
      dotenv.env['SUPABASE_KEY'] ?? const String.fromEnvironment('SUPABASE_KEY');

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    throw Exception(
        "Missing Supabase credentials! Check your .env file or pass them via --dart-define.");
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController ipController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  Future<void> _signUp() async {
    try {
      await supabase.auth.signUp(
        email: "sam@gmail.com",
        password: "sambhav",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup successful! Check your email.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLastIp(); // Retrieve last used IP from Supabase
    _signUp();
  }

  Future<void> _fetchLastIp() async {
    try {
      // Use maybeSingle() to safely retrieve a single record, if it exists
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
      print("Error fetching IP: $error");
    }
  }

  Future<void> _saveIp(String ip) async {
    try {
      // Upsert a single record (using id=1 here)
      await supabase.from('stream_ips').upsert({'id': 1, 'ip': ip});
    } catch (error) {
      print("Error saving IP: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Raspberry Pi IP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: ipController,
              decoration:
                  const InputDecoration(labelText: "Enter Pi IP Address"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String ip = ipController.text.trim();
                if (ip.isNotEmpty) {
                  await _saveIp(ip);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VideoStreamApp(serverIp: ip)),
                  );
                }
              },
              child: const Text("Connect & Stream"),
            ),
          ],
        ),
      ),
    );
  }
}
