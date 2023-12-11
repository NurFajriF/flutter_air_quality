import 'dart:convert';
import 'dart:developer';
import 'package:flutter_air_quality/data/air_quality.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_air_quality/data/api_key.dart';

Future<AirQuality?> fetchData() async {
  try {
    /// Determine the current position of the device.
    ///
    /// When the location services are not enabled or permissions
    /// are denied the `Future` will return an error.
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();

    var url = Uri.parse(
        'https://api.waqi.info/feed/geo:${position.latitude};${position.longitude}/?token=$API_KEY');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      AirQuality airQuality = AirQuality.fromJson(jsonDecode(response.body));

      if (airQuality.aqi >= 0 && airQuality.aqi <= 50) {
        airQuality.message =
            "Kualitas udara dianggap memuaskan, dan polusi udara hanya menimbulkan sedikit risiko atau bahkan tidak sama sekali";
        airQuality.emojiRef = "1.png";
      } else if (airQuality.aqi >= 51 && airQuality.aqi <= 100) {
        airQuality.message =
            "Kualitas udara dapat diterima; namun, untuk beberapa polutan mungkin terdapat masalah kesehatan yang moderat bagi sejumlah kecil orang yang sangat sensitif terhadap polusi udara";
        airQuality.emojiRef = "2.png";
      } else if (airQuality.aqi >= 101 && airQuality.aqi <= 150) {
        airQuality.message =
            "Anggota kelompok sensitif mungkin mengalami dampak kesehatan. Masyarakat umum kemungkinan besar tidak akan terpengaruh.";
        airQuality.emojiRef = "3.png";
      } else if (airQuality.aqi >= 151 && airQuality.aqi <= 200) {
        airQuality.message =
            "Setiap orang mungkin mulai mengalami dampak kesehatan; anggota kelompok sensitif mungkin mengalami dampak kesehatan yang lebih serius";
        airQuality.emojiRef = "4.png";
      } else if (airQuality.aqi >= 201 && airQuality.aqi <= 300) {
        airQuality.message =
            "Peringatan kesehatan tentang kondisi darurat. Seluruh populasi lebih mungkin terkena dampaknya.";
        airQuality.emojiRef = "5.png";
      } else if (airQuality.aqi >= 300) {
        airQuality.message =
            "Peringatan kesehatan: setiap orang mungkin mengalami dampak kesehatan yang lebih serius";
        airQuality.emojiRef = "6.png";
      }

      print(airQuality);
      return airQuality;
    }
    return null;
  } catch (e) {
    log(e.toString());
    rethrow;
  }
}
