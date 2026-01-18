import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/gps.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  final GPS _gps = GPS();
  Position? _userPosition;

  void _handlePositionStream(Position position) {
    setState(() {
      _userPosition = position;
    });
  }

  @override
  void initState() {
    super.initState();
    _gps.startPostitionStream(_handlePositionStream);
  }

  @override
  void dispose() {
    _gps.stopPositionStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerätewart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          _userPosition?.toString() ?? 'GPS wird gestartet...',
        ),
      ),
    );
  }
}
