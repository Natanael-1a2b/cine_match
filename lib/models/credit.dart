// Modelo para créditos: cast / crew
import 'package:flutter/foundation.dart';

class Cast {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;
  final double? popularity;

  Cast({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.popularity,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'],
      profilePath: json['profile_path'],
      popularity: (json['popularity'] != null) ? (json['popularity'] as num).toDouble() : null,
    );
  }
}

class Crew {
  final int id;
  final String name;
  final String? job;
  final String? department;
  final String? profilePath;

  Crew({
    required this.id,
    required this.name,
    this.job,
    this.department,
    this.profilePath,
  });

  factory Crew.fromJson(Map<String, dynamic> json) {
    return Crew(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      job: json['job'],
      department: json['department'],
      profilePath: json['profile_path'],
    );
  }
}

class CreditResponse {
  final List<Cast> cast;
  final List<Crew> crew;

  CreditResponse({required this.cast, required this.crew});

  factory CreditResponse.fromJson(Map<String, dynamic> json) {
    final castList = (json['cast'] as List<dynamic>? ?? []).map((e) => Cast.fromJson(Map<String, dynamic>.from(e))).toList();
    final crewList = (json['crew'] as List<dynamic>? ?? []).map((e) => Crew.fromJson(Map<String, dynamic>.from(e))).toList();
    return CreditResponse(cast: castList, crew: crewList);
  }
}