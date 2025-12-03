import 'package:flutter/material.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/services/db_service.dart';

class FavoritesProvider extends ChangeNotifier {
  List<Movie> _favorites = [];
  bool _loading = false;

  FavoritesProvider() {
    _load();
  }

  List<Movie> get favorites => _favorites;
  bool get loading => _loading;

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      _favorites = await DBService.instance.getFavorites();
    } catch (e) {
      print('FavoritesProvider _load error: $e');
      _favorites = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> add(Movie m) async {
    try {
      await DBService.instance.addFavorite(m);
      _favorites.add(m);
      notifyListeners();
    } catch (e) {
      print('FavoritesProvider add error: $e');
    }
  }

  Future<void> remove(int id) async {
    try {
      await DBService.instance.removeFavorite(id);
      _favorites.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      print('FavoritesProvider remove error: $e');
    }
  }

  Future<bool> isFavorite(int id) async {
    try {
      return await DBService.instance.isFavorite(id);
    } catch (e) {
      print('FavoritesProvider isFavorite error: $e');
      return false;
    }
  }
}