import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geolocator Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  Position? currentPosition;
  Position? lastKnownPosition;
  StreamSubscription<Position>? positionStream;
  StreamSubscription<ServiceStatus>? serviceStatusStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _getCurrentPosition(context),
                child: Text('Get Current Position'),
              ),
              if (currentPosition != null)
                Text('Current Position : $currentPosition'),
              ElevatedButton(
                onPressed: () => _getLastKnownPosition(context),
                child: Text('Get Last Known Position'),
              ),
              if (lastKnownPosition != null)
                Text('Last Known Position : $lastKnownPosition'),
              ListTile(
                title: Text('Get Position Stream'),
                subtitle: Text('Start Continuous Location Updates'),
                onTap: () => _getPositionStream(context),
              ),
              ListTile(
                title: Text('Stop Position Stream'),
                subtitle: Text('Stop Continuous Location Updates'),
                onTap: () {
                  positionStream?.cancel();
                },
              ),
              ListTile(
                title: Text('Start Service Status Stream'),
                subtitle: Text('Starts Location Service Status Stream'),
                onTap: () => _getServiceStatusStream(context),
              ),
              ListTile(
                title: Text('Stop Service Status Stream'),
                subtitle: Text('Stops Location Service Status Stream'),
                onTap: () {
                  serviceStatusStream?.cancel();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getServiceStatusStream(BuildContext context) async {
    serviceStatusStream = Geolocator.getServiceStatusStream().listen(
      (ServiceStatus status) {
        debugPrint(status.toString());
      },
    );
  }

  Future<void> _getPositionStream(BuildContext context) async {
    final hasPermission = await _handlePermission(context);

    if (!hasPermission) {
      return;
    }

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        debugPrint(position == null
            ? 'Unknown'
            : '${position.latitude.toString()}, ${position.longitude.toString()}');
      },
    );
  }

  Future<void> _getLastKnownPosition(BuildContext context) async {
    final hasPermission = await _handlePermission(context);

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getLastKnownPosition();

    setState(() {
      lastKnownPosition = position;
    });
  }

  Future<void> _getCurrentPosition(BuildContext context) async {
    final hasPermission = await _handlePermission(context);

    if (!hasPermission) {
      return;
    }

    final position = await _geolocatorPlatform.getCurrentPosition();

    setState(() {
      currentPosition = position;
    });
  }

  void _showConfirmationDialog(BuildContext context,
      {VoidCallback? okCallback,
      VoidCallback? cancelCallback,
      required String msg}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                if (cancelCallback != null) {
                  cancelCallback(); // Cancel action
                }
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                if (okCallback != null) {
                  okCallback(); // OK action
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _handlePermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      _showConfirmationDialog(
        context,
        msg: _kLocationServicesDisabledMessage,
        okCallback: _geolocatorPlatform.openLocationSettings,
      );
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        _showConfirmationDialog(context, msg: _kPermissionDeniedMessage);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _showConfirmationDialog(
        context,
        msg: _kPermissionDeniedForeverMessage,
        okCallback: _geolocatorPlatform.openAppSettings,
      );

      return false;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return true;
  }
}
