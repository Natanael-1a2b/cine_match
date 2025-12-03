import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/services/tmdb_service.dart';
import 'package:cinematch/screens/detail_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final double? width;
  final double? height;
  final double aspectRatio; // ancho / alto del póster

  const MovieCard({
    Key? key,
    required this.movie,
    this.width,
    this.height,
    this.aspectRatio = 2 / 3, // poster típico 2:3
  }) : super(key: key);

  Widget _shimmerPlaceholder({double? w, double? h}) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si se proporciona width/height, los usamos. Si no, calculamos con LayoutBuilder
    return LayoutBuilder(builder: (context, constraints) {
      // calcular dimensiones seguras
      double cardWidth;
      double cardHeight;

      if (width != null) {
        cardWidth = width!;
        cardHeight = height ?? (cardWidth / aspectRatio);
      } else if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
        // El padre nos dio un límite: usamos ese máximo
        cardWidth = constraints.maxWidth;
        cardHeight = height ?? (cardWidth / aspectRatio);
      } else {
        // Sin constraints (ej. ListView horizontal sin tamaño): usamos un tamaño por defecto
        cardWidth = 140;
        cardHeight = height ?? (cardWidth / aspectRatio);
      }

      final posterUrl = movie.posterPath != null ? TMDBService.imageBase + movie.posterPath! : null;

      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DetailScreen(movieId: movie.id),
            ),
          );
        },
        child: SizedBox(
          width: cardWidth,
          // asegurar que el widget no intenta expandirse infinitamente
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero on the poster
              Hero(
                tag: 'poster-${movie.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: posterUrl != null
                        ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      width: cardWidth,
                      height: cardHeight,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _shimmerPlaceholder(w: cardWidth, h: cardHeight),
                      errorWidget: (context, url, error) => Container(
                        width: cardWidth,
                        height: cardHeight,
                        color: Colors.white10,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                      ),
                    )
                        : Container(
                      width: cardWidth,
                      height: cardHeight,
                      color: Colors.white10,
                      child: const Center(child: Icon(Icons.local_movies, color: Colors.white24, size: 48)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Title
              SizedBox(
                width: cardWidth,
                child: Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}