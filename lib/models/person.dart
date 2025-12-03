// Modelo de persona (actor / director)
class Person {
  final int id;
  final String name;
  final String? biography;
  final String? profilePath;
  final String? birthday;
  final String? placeOfBirth;
  final double? popularity;

  Person({
    required this.id,
    required this.name,
    this.biography,
    this.profilePath,
    this.birthday,
    this.placeOfBirth,
    this.popularity,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      biography: json['biography'],
      profilePath: json['profile_path'],
      birthday: json['birthday'],
      placeOfBirth: json['place_of_birth'],
      popularity: (json['popularity'] != null) ? (json['popularity'] as num).toDouble() : null,
    );
  }
}