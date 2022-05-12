import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:udemy_clima_project/constants.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Position? _position;
  bool _initialized = false;
  String _cityName = '';
  String _temperature = '';
  String _weather = '';

  void getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Future.error("Location services are disabled");
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      returnCurrentLocation();
    }
    if (permission == LocationPermission.denied) {
      requestGPSPermission();
      return Future.error("Location permissions are denied");
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permissions are permanently denied, we cannot request permissions");
    }
    requestGPSPermission();
  }

  void requestGPSPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      returnCurrentLocation();
    } else {
      requestGPSPermission();
    }
  }

  void returnCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
    setState(() {
      _position = position;
      _initialized = true;
    });
  }

  void getData() async {
    double lat = 0.0;
    double lon = 0.0;
    if (_position != null) {
      lat = _position!.latitude;
      lon = _position!.longitude;
    } else {
      getCurrentLocation();
    }
    http.Response response = await http.get(
      Uri(
        scheme: 'https',
        host: 'api.openweathermap.org',
        path: 'data/2.5/weather',
        queryParameters: {
          'lat': '$lat',
          'lon': '$lon',
          'appid': openWeatherMapApiKey
        },
      ),
    );
    if (response.statusCode == 200) {
      String data = response.body;
      var decodedJsonData = jsonDecode(data);
      setState(() {
        _cityName = decodedJsonData['name'];
        _weather = decodedJsonData['weather'][0]['description'];
        _temperature = decodedJsonData['main']['temp'].toString();
      });
    } else {
      AlertDialog alert = AlertDialog(
        elevation: 10,
        title: const Text('Error'),
        content: Text(response.statusCode.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) => alert,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_initialized ? _position.toString() : "not initialized yet"),
            ElevatedButton(
              onPressed: getCurrentLocation,
              child: const Text('Get Location'),
            ),
            _initialized
                ? ElevatedButton(
                    onPressed: getData,
                    child: const Text("Get location weather data"),
                  )
                : const ElevatedButton(
                    onPressed: null,
                    child: Text("No location set yet"),
                  ),
            _cityName.isEmpty ? const Text('') : Text('City: $_cityName'),
            _temperature.isEmpty
                ? const Text('')
                : Text('Temperature : $_temperature'),
            _weather.isEmpty ? const Text('') : Text('Weather: $_weather'),
          ],
        ),
      ),
    );
  }
}
