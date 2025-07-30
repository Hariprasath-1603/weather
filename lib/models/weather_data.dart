class CurrentWeather {
  final String city;
  final int temperature;
  final String description;
  final int humidity;
  final int windSpeed;
  final String iconCode;
  final String date;

  CurrentWeather({
    required this.city,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.iconCode,
    required this.date,
  });
}

class DailyForecast {
  final String date;
  final int maxTemp;
  final int minTemp;
  final int avgTemp;
  final String description;
  final String iconCode;
  final int humidity;
  final int windSpeed;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.avgTemp,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
  });
}
