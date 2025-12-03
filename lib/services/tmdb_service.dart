import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cinematch/models/movie.dart';

class TMDBService {
  static const String _base = 'https://api.themoviedb.org/3';

  // API Key v3 (puedes usar --dart-define=TMDB_API_KEY=...)
  static const String TMDB_API_KEY = '05a10bf0f881a848a9f1c31dd5355b02';
  static const String TMDB_BEARER = String.fromEnvironment('TMDB_BEARER', defaultValue: '');

  static const String imageBase = 'https://image.tmdb.org/t/p/w500';

  static void _ensureKeyPresent() {
    if (TMDB_BEARER.isEmpty && TMDB_API_KEY.isEmpty) {
      throw Exception('TMDB API key missing. Ejecuta la app con --dart-define=TMDB_API_KEY=TU_V3_KEY o ponla en el servicio para pruebas.');
    }
  }

  static Uri _uri(String path, [Map<String, String>? params]) {
    _ensureKeyPresent();
    final m = <String, String>{'language': 'es-ES'};
    if (params != null) m.addAll(params);
    if (TMDB_BEARER.isEmpty && TMDB_API_KEY.isNotEmpty) m['api_key'] = TMDB_API_KEY;
    return Uri.parse('$_base$path').replace(queryParameters: m);
  }

  static Future<http.Response> _get(Uri uri) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (TMDB_BEARER.isNotEmpty) headers['Authorization'] = 'Bearer $TMDB_BEARER';
    return http.get(uri, headers: headers);
  }

  static Future<List<Movie>> getPopular({int page = 1}) async {
    final uri = _uri('/movie/popular', {'page': '$page'});
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final results = (jsonBody['results'] ?? []) as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      print('TMDB getPopular failed: ${res.statusCode} ${res.body}');
      throw Exception('Error fetching popular: ${res.statusCode}');
    }
  }

  static Future<List<Movie>> getTrending({int page = 1}) async {
    final uri = _uri('/trending/movie/day', {'page': '$page'});
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final results = (jsonBody['results'] ?? []) as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      print('TMDB getTrending failed: ${res.statusCode} ${res.body}');
      throw Exception('Error fetching trending: ${res.statusCode}');
    }
  }

  // Discover genérico: acepta parámetros (with_genres, primary_release_year, sort_by, vote_average.gte, etc.)
  static Future<List<Movie>> getDiscover(Map<String, String> params) async {
    final uri = _uri('/discover/movie', params);
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final results = (jsonBody['results'] ?? []) as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      print('TMDB discover failed: ${res.statusCode} ${res.body}');
      throw Exception('Error fetching discover: ${res.statusCode}');
    }
  }

  static Future<List<Movie>> searchMovies(String query, {int page = 1, Map<String, String>? extras}) async {
    final params = {'query': query, 'page': '$page'};
    if (extras != null) params.addAll(extras);
    final uri = _uri('/search/movie', params);
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final results = (jsonBody['results'] ?? []) as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      print('TMDB searchMovies failed: ${res.statusCode} ${res.body}');
      throw Exception('Error searching movies: ${res.statusCode}');
    }
  }

  static Future<Movie> getDetails(int movieId) async {
    final uri = _uri('/movie/$movieId');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      return Movie.fromJson(jsonBody);
    } else {
      print('TMDB getDetails failed: ${res.statusCode} ${res.body}');
      throw Exception('Error fetching details: ${res.statusCode}');
    }
  }

  static Future<List<Movie>> getRecommendations(int movieId) async {
    final uri = _uri('/movie/$movieId/recommendations');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final results = (jsonBody['results'] ?? []) as List;
      return results.map((e) => Movie.fromJson(e)).toList();
    } else {
      print('TMDB getRecommendations failed: ${res.statusCode} ${res.body}');
      return [];
    }
  }

  static Future<String?> getTrailerKey(int movieId) async {
    final uri = _uri('/movie/$movieId/videos');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final results = (jsonBody['results'] ?? []) as List;
      if (results.isEmpty) return null;
      final yt = results.firstWhere(
            (v) => v['site'] == 'YouTube' && v['type'] == 'Trailer',
        orElse: () => results[0],
      );
      if (yt != null) return yt['key'];
    } else {
      print('TMDB getTrailerKey failed: ${res.statusCode} ${res.body}');
    }
    return null;
  }

  static Future<Map<int, String>> getGenres() async {
    final uri = _uri('/genre/movie/list');
    final res = await _get(uri);
    if (res.statusCode == 200) {
      final jsonBody = json.decode(res.body);
      final genres = (jsonBody['genres'] ?? []) as List;
      final map = <int, String>{};
      for (var g in genres) map[g['id']] = g['name'];
      return map;
    } else {
      print('TMDB getGenres failed: ${res.statusCode} ${res.body}');
      return {};
    }
  }
}