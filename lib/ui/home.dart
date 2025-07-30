import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/models/city.dart';
import 'package:weather_app/models/constants.dart';
import 'package:weather_app/models/weather_data.dart';
import 'package:weather_app/ui/detail_page.dart';
import 'package:weather_app/widgets/weather_item.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Constants myConstants = Constants();
  final String _apiKey = "b73ae05075a1b5b6c3bac74264004234";
  CurrentWeather? _currentWeather;
  List<DailyForecast> _dailyForecasts = [];

  String location = 'London';
  List<String> cities = ['London'];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < City.getSelectedCities().length; i++) {
      cities.add(City.getSelectedCities()[i].city);
    }
    _fetchWeatherData(location);
  }

  Future<void> _fetchWeatherData(String city) async {
    if (_apiKey == "YOUR_OPENWEATHERMAP_API_KEY") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ENTER YOUR API_KEY")),
      );
      return;
    }

    setState(() {
      _currentWeather = null;
      _dailyForecasts = [];
    });

    try {
      final currentWeatherUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric';
      final currentWeatherResponse = await http.get(Uri.parse(currentWeatherUrl));

      if (currentWeatherResponse.statusCode == 200) {
        final Map<String, dynamic> currentData = json.decode(currentWeatherResponse.body);
        setState(() {
          _currentWeather = CurrentWeather(
            city: currentData['name'],
            temperature: currentData['main']['temp'].round(),
            description: currentData['weather'][0]['description'].toString().toCapitalized(),
            humidity: currentData['main']['humidity'],
            windSpeed: currentData['wind']['speed'].round(),
            iconCode: currentData['weather'][0]['icon'],
            date: DateFormat('EEEE, d MMMM').format(DateTime.now()),
          );
        });
      } else {
        _handleApiError(currentWeatherResponse.statusCode, currentData: json.decode(currentWeatherResponse.body));
        return;
      }

      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$_apiKey&units=metric';
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (forecastResponse.statusCode == 200) {
        final Map<String, dynamic> forecastData = json.decode(forecastResponse.body);
        _processForecastData(forecastData['list']);
      } else {
        _handleApiError(forecastResponse.statusCode, currentData: json.decode(forecastResponse.body));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching weather data: $e. Check internet connection.")),
      );
      debugPrint('Error fetching weather data: $e');
    }
  }

  void _processForecastData(List<dynamic> forecastList) {
    Map<String, List<Map<String, dynamic>>> dailyGroupedForecast = {};

    for (var item in forecastList) {
      final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final String dateKey = DateFormat('yyyy-MM-dd').format(dateTime);

      if (!dailyGroupedForecast.containsKey(dateKey)) {
        dailyGroupedForecast[dateKey] = [];
      }
      dailyGroupedForecast[dateKey]!.add(item);
    }

    List<DailyForecast> processedForecasts = [];
    dailyGroupedForecast.forEach((dateKey, dailyEntries) {
      if (dailyEntries.isEmpty) return;

      int maxTemp = -1000;
      int minTemp = 1000;
      double sumTemp = 0;
      int sumHumidity = 0;
      double sumWindSpeed = 0;
      String mainDescription = '';
      String mainIconCode = '';

      if (dailyEntries.isNotEmpty) {
        mainDescription = dailyEntries[0]['weather'][0]['description'].toString().toCapitalized();
        mainIconCode = dailyEntries[0]['weather'][0]['icon'];
      }

      for (var entry in dailyEntries) {
        final temp = entry['main']['temp'].round();
        maxTemp = temp > maxTemp ? temp : maxTemp;
        minTemp = temp < minTemp ? temp : minTemp;
        sumTemp += temp;
        sumHumidity += (entry['main']['humidity'] as num).round().toInt();
        sumWindSpeed += (entry['wind']['speed'] as num).round().toInt();
      }

      final avgTemp = (sumTemp / dailyEntries.length).round();
      final avgHumidity = (sumHumidity / dailyEntries.length).round();
      final avgWindSpeed = (sumWindSpeed / dailyEntries.length).round();

      processedForecasts.add(DailyForecast(
        date: DateFormat('EEEE').format(DateTime.parse(dateKey)).substring(0, 3),
        maxTemp: maxTemp,
        minTemp: minTemp,
        avgTemp: avgTemp,
        description: mainDescription,
        iconCode: mainIconCode,
        humidity: avgHumidity,
        windSpeed: avgWindSpeed,
      ));
    });

    setState(() {
      _dailyForecasts = processedForecasts;
    });
  }

  void _handleApiError(int statusCode, {Map<String, dynamic>? currentData}) {
    String message = "Failed to load weather data.";
    if (statusCode == 404) {
      message = "City not found. Please check the spelling.";
    } else if (statusCode == 401) {
      message = "Invalid API key. Please check your key.";
    } else if (currentData != null && currentData.containsKey('message')) {
      message = currentData['message'].toString().toCapitalized();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint('API Error: Status $statusCode, Message: ${currentData?['message']}');
  }

  final Shader linearGradient = const LinearGradient(
    colors: <Color>[Color(0xffABCFF2), Color(0xff9AC6F3)],
  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          width: size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: Image.asset(
                  'assets/profile.png',
                  width: 40,
                  height: 40,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/pin.png',
                    width: 20,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                        value: location,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: cities.map((String loc) {
                          return DropdownMenuItem<String>(
                              value: loc, child: Text(loc));
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              location = newValue;
                            });
                            _fetchWeatherData(location);
                          }
                        }),
                  )
                ],
              )
            ],
          ),
        ),
      ),
      body: _currentWeather == null
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)))
          : Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentWeather!.city,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30.0,
              ),
            ),
            Text(
              _currentWeather!.date,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Container(
              width: size.width,
              height: 200,
              decoration: BoxDecoration(
                  color: myConstants.primaryColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: myConstants.primaryColor.withOpacity(.5),
                      offset: const Offset(0, 25),
                      blurRadius: 10,
                      spreadRadius: -12,
                    )
                  ]),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -40,
                    left: 20,
                    child: Image.network(
                      'http://openweathermap.org/img/wn/${_currentWeather!.iconCode}@4x.png',
                      width: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.cloud, size: 150, color: Colors.white);
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    child: Text(
                      _currentWeather!.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _currentWeather!.temperature.toString(),
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()..shader = linearGradient,
                            ),
                          ),
                        ),
                        Text(
                          'o',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()..shader = linearGradient,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  weatherItem(
                    text: 'Wind Speed',
                    value: _currentWeather!.windSpeed,
                    unit: 'km/h',
                    imageUrl: 'assets/windspeed.png',
                  ),
                  weatherItem(
                      text: 'Humidity',
                      value: _currentWeather!.humidity,
                      unit: '%',
                      imageUrl: 'assets/humidity.png'),
                  weatherItem(
                    text: 'Max Temp',
                    value: _dailyForecasts.isNotEmpty ? _dailyForecasts[0].maxTemp : 0,
                    unit: 'C',
                    imageUrl: 'assets/max-temp.png',
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Today',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_dailyForecasts.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            dailyForecasts: _dailyForecasts,
                            selectedId: 0,
                            location: location,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Next 7 Days',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: myConstants.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dailyForecasts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final DailyForecast forecast = _dailyForecasts[index];
                      String todayDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
                      String forecastDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: index)));

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                dailyForecasts: _dailyForecasts,
                                selectedId: index,
                                location: location,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          margin: const EdgeInsets.only(
                              right: 20, bottom: 10, top: 10),
                          width: 80,
                          decoration: BoxDecoration(
                              color: forecastDateKey == todayDateKey
                                  ? myConstants.primaryColor
                                  : Colors.white,
                              borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 5,
                                  color: forecastDateKey == todayDateKey
                                      ? myConstants.primaryColor
                                      : Colors.black54.withOpacity(.2),
                                ),
                              ]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${forecast.avgTemp}°C',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: forecastDateKey == todayDateKey
                                      ? Colors.white
                                      : myConstants.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Image.network(
                                'http://openweathermap.org/img/wn/${forecast.iconCode}@2x.png',
                                width: 30,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.cloud, size: 30, color: Colors.grey);
                                },
                              ),
                              Text(
                                forecast.date,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: forecastDateKey == todayDateKey
                                      ? Colors.white
                                      : myConstants.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    }))
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}