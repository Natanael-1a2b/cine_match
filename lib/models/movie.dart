class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final double? voteAverage;
  final String? releaseDate;
  final List<int> genreIds;
  final List<String>? genres;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.genreIds,
    this.posterPath,
    this.voteAverage,
    this.releaseDate,
    this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    List<int> g = [];
    if (json['genre_ids'] != null) {
      g = List<int>.from(json['genre_ids'].map((x) => x as int));
    } else if (json['genres'] != null) {
      g = List<int>.from(json['genres'].map((x) => x['id'] as int));
    }
    return Movie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      voteAverage: json['vote_average'] != null ? (json['vote_average'] as num).toDouble() : null,
      releaseDate: json['release_date'],
      genreIds: g,
      genres: json['genres'] != null
          ? List<String>.from(json['genres'].map((g) => g['name'] as String))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterPath': posterPath,
      'voteAverage': voteAverage,
      'releaseDate': releaseDate,
      'genreIds': genreIds.join(','),
    };
  }

  factory Movie.fromMap(Map<String, dynamic> m) {
    List<int> g = [];
    if (m['genreIds'] != null && (m['genreIds'] as String).isNotEmpty) {
      g = (m['genreIds'] as String).split(',').map((s) => int.tryParse(s) ?? 0).toList();
    }
    return Movie(
      id: m['id'],
      title: m['title'],
      overview: m['overview'],
      posterPath: m['posterPath'],
      voteAverage: m['voteAverage'] != null ? (m['voteAverage'] as num).toDouble() : null,
      releaseDate: m['releaseDate'],
      genreIds: g,
    );
  }
}