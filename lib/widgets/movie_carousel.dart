import 'package:flutter/material.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/widgets/movie_card.dart';

class MovieCarousel extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  MovieCarousel({required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Icon(Icons.chevron_right)
      ])),
      SizedBox(height: 8),
      // Incrementamos la altura para evitar overflow
      Container(
        height: 320,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: movies.length,
          itemBuilder: (context, i) => Padding(padding: EdgeInsets.all(8), child: MovieCard(movie: movies[i])),
        ),
      )
    ]);
  }
}