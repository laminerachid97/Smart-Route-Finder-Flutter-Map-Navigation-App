import 'package:permission_handler/permission_handler.dart';

Future<bool> getPermissionLocation() async {
  var status = await Permission.location.status;

  if (status.isPermanentlyDenied) {
    await openAppSettings();
    return false;
  }

  if (status.isDenied || status.isRestricted) {
    status = await Permission.location.request();
  }

  if (status.isGranted) {
    return true;
  } else {
    return false;
  }
}