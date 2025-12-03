import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cinematch/models/movie.dart';

class DBService {
  DBService._private();
  static final DBService instance = DBService._private();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cinematch.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY,
          title TEXT,
          overview TEXT,
          posterPath TEXT,
          voteAverage REAL,
          releaseDate TEXT,
          genreIds TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movieId INTEGER,
          title TEXT,
          visitedAt INTEGER,
          genreIds TEXT
        )
      ''');
    });
  }

  Future<void> addFavorite(Movie m) async {
    await _db!.insert('favorites', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(int movieId) async {
    await _db!.delete('favorites', where: 'id = ?', whereArgs: [movieId]);
  }

  Future<List<Movie>> getFavorites() async {
    final res = await _db!.query('favorites');
    return res.map((r) => Movie.fromMap(r)).toList();
  }

  Future<bool> isFavorite(int movieId) async {
    final res = await _db!.query('favorites', where: 'id = ?', whereArgs: [movieId]);
    return res.isNotEmpty;
  }

  Future<void> addHistory(Movie m) async {
    await _db!.insert('history', {
      'movieId': m.id,
      'title': m.title,
      'visitedAt': DateTime.now().millisecondsSinceEpoch,
      'genreIds': m.genreIds.join(','),
    });
    // opcional: mantener solo últimas N entradas
    await _db!.rawDelete('DELETE FROM history WHERE rowid NOT IN (SELECT rowid FROM history ORDER BY visitedAt DESC LIMIT 200)');
  }

  Future<List<int>> getTopGenres({int limit = 5}) async {
    final res = await _db!.query('history');
    final Map<int, int> counts = {};
    for (var row in res) {
      final g = (row['genreIds'] as String).split(',').where((s) => s.isNotEmpty).map((s) => int.tryParse(s) ?? 0);
      for (var id in g) {
        if (id == 0) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    // incluir géneros de favoritos
    final favs = await getFavorites();
    for (var f in favs) {
      for (var id in f.genreIds) {
        if (id == 0) continue;
        counts[id] = (counts[id] ?? 0) + 2;
      }
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    return sorted.take(limit).toList();
  }

  Future<List<int>> getLastViewedMovieIds({int limit = 5}) async {
    final res = await _db!.rawQuery('SELECT movieId FROM history ORDER BY visitedAt DESC LIMIT ?', [limit]);
    return res.map((r) => r['movieId'] as int).toList();
  }
}