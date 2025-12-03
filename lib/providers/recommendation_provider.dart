import 'package:flutter/material.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/services/db_service.dart';
import 'package:cinematch/services/tmdb_service.dart';

class RecommendationProvider extends ChangeNotifier {
  List<Movie> _recommendations = [];
  bool _loading = false;

  List<Movie> get recommendations => _recommendations;
  bool get loading => _loading;

  Future<void> buildRecommendations() async {
    _loading = true;
    notifyListeners();

    final List<Movie> aggregate = [];
    // 1) Géneros top
    final topGenres = await DBService.instance.getTopGenres(limit: 3);
    if (topGenres.isNotEmpty) {
      // buscar por género: TMDB search by with_genres via discover is possible but we use search endpoint with extras
      for (var g in topGenres) {
        try {
          final res = await TMDBService.searchMovies('', extras: {'with_genres': '$g', 'sort_by': 'popularity.desc'});
          aggregate.addAll(res);
        } catch (_) {}
      }
    }

    // 2) Últimas vistas: pedir recomendaciones por cada movieId
    final lastIds = await DBService.instance.getLastViewedMovieIds(limit: 5);
    for (var id in lastIds) {
      try {
        final rec = await TMDBService.getRecommendations(id);
        aggregate.addAll(rec);
      } catch (_) {}
    }

    // 3) Recomendaciones basadas en favoritos
    final favs = await DBService.instance.getFavorites();
    for (var f in favs.take(5)) {
      try {
        final rec = await TMDBService.getRecommendations(f.id);
        aggregate.addAll(rec);
      } catch (_) {}
    }

    // Filtrar duplicados y ordenar por popularidad simple (voteAverage)
    final map = <int, Movie>{};
    for (var m in aggregate) {
      map[m.id] = m;
    }
    final unique = map.values.toList();
    unique.sort((a, b) => (b.voteAverage ?? 0).compareTo(a.voteAverage ?? 0));
    _recommendations = unique.take(50).toList();

    _loading = false;
    notifyListeners();
  }
}