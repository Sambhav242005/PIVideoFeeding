import 'package:permission_handler/permission_handler.dart';

Future<bool> requestLocationPermission() async {
  PermissionStatus status = await Permission.location.request();

  if (status.isGranted) {
    print("✅ Location permission granted!");
    return true;
  } else if (status.isDenied) {
    print("❌ Location permission denied.");
    return false;
  } else if (status.isPermanentlyDenied) {
    print("⚠️ Location permission permanently denied. Open settings.");
    await openAppSettings();
    return false;
  }

  return false;
}
