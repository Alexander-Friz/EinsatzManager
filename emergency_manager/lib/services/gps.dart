import 'dart:async';

import 'package:geolocator/geolocator.dart';
typedef PositionCallback = Function(Position position);

class GPS{

  late StreamSubscription<Position>? _positionStream;

  bool isAccessGranted(LocationPermission permission){
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }
  
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(isAccessGranted(permission)){
      return true;
    }
    permission =await Geolocator.requestPermission();
    return isAccessGranted(permission);
  }

  Future<void>startPostitionStream(PositionCallback callback)async{
    bool permissionGranted =await requestPermission();
    if(!permissionGranted){
      throw Exception("User did not grant GPS permissions!");
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      )
    ).listen(callback);
  }

  Future<void> stopPositionStream() async{
    await _positionStream?.cancel();
  }
}