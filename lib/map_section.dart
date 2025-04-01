import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'permissions.dart'; // Import your permission utility

class OsmMapViewer extends StatefulWidget {
  @override
  _OsmMapViewerState createState() => _OsmMapViewerState();
}

class _OsmMapViewerState extends State<OsmMapViewer> {
  LatLng _currentLocation = LatLng(37.7749, -122.4194); // Default: San Francisco
  double _currentSpeed = 0.0; // Speed in meters per second (m/s)
  late final MapController _mapController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _handleLocationPermissionAndStartTracking();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Stop timer when widget is disposed
    super.dispose();
  }

  Future<void> _handleLocationPermissionAndStartTracking() async {
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) return;

    // Get initial position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
    _updateLocation(position);

    // Start a timer to fetch location every 2 seconds
    _timer = Timer.periodic(Duration(seconds: 2), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      _updateLocation(position);
    });
  }

  void _updateLocation(Position position) {
    double filteredSpeed = position.speed < 0.5 ? 0.0 : position.speed; // Ignore noise below 0.5 m/s

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentSpeed = filteredSpeed; // Store filtered speed
      _mapController.move(_currentLocation, _mapController.camera.zoom);
    });

    print("📍 Location: ${_currentLocation.latitude}, ${_currentLocation.longitude} | 🚀 Speed: ${(_currentSpeed / 3.6).toStringAsFixed(2)} m/s");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Speed: ${(_currentSpeed / 3.6).toStringAsFixed(2)} m/s", // Convert to km/h
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: 300,
          child: FlutterMap(
            mapController: _mapController, // Attach the controller
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 12,
              onTap: (tapPosition, latLng) {
                print("📌 Tapped Location: ${latLng.latitude}, ${latLng.longitude}");
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
