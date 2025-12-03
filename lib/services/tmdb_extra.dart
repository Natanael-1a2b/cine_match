import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cinematch/models/credit.dart';
import 'package:cinematch/models/person.dart';
import 'package:cinematch/models/review.dart';

class TMDBExtra {
  // Puedes inyectar la API key en tiempo de ejecución con setApiKey
  static String? _overrideApiKey;

  // Puedes cambiar la imageBase si tu TMDBService la maneja distinto
  static String _imageBase = 'https://image.tmdb.org/t/p/w500';

  /// Set the TMDB API key programmatically (recommended for runtime tests)
  static void setApiKey(String key) => _overrideApiKey = key;

  /// Optionally set a different image base (e.g. from your TMDBService configuration)
  static void setImageBase(String base) => _imageBase = base;

  static String get imageBase => _imageBase;

  static String get _apiKey {
    // Priority:
    // 1. Programmatic override via setApiKey
    // 2. --dart-define TMDB_API_KEY
    // 3. Throw with clear instructions
    if (_overrideApiKey != null && _overrideApiKey!.isNotEmpty) {
      return _overrideApiKey!;
    }

    const fromEnv = String.fromEnvironment('TMDB_API_KEY', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    throw StateError(
        'TMDB API key not configured. Set it by calling TMDBExtra.setApiKey("YOUR_KEY") before using, '
            'or run the app with --dart-define=TMDB_API_KEY=YOUR_KEY');
  }

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Future<CreditResponse> getCredits(int movieId) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/credits?api_key=${_apiKey}&language=en-US');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load credits (${res.statusCode}): ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return CreditResponse.fromJson(json);
  }

  static Future<Person> getPerson(int personId) async {
    final url = Uri.parse('$_baseUrl/person/$personId?api_key=${_apiKey}&language=en-US');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load person (${res.statusCode}): ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return Person.fromJson(json);
  }

  static Future<List<Map<String, dynamic>>> getPersonMovieCredits(int personId) async {
    final url = Uri.parse('$_baseUrl/person/$personId/movie_credits?api_key=${_apiKey}&language=en-US');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load person credits (${res.statusCode}): ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final cast = (json['cast'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return cast;
  }

  static Future<List<Review>> getReviews(int movieId, {int page = 1}) async {
    final url = Uri.parse('$_baseUrl/movie/$movieId/reviews?api_key=${_apiKey}&language=en-US&page=$page');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load reviews (${res.statusCode}): ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (json['results'] as List<dynamic>? ?? [])
        .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return items;
  }
}