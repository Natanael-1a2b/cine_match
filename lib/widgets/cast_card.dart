import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinematch/models/credit.dart';
import 'package:cinematch/services/tmdb_extra.dart';
import 'package:cinematch/screens/person_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class CastCard extends StatelessWidget {
  final Cast cast;
  final double width;
  final double height;

  const CastCard({Key? key, required this.cast, this.width = 100, this.height = 140}) : super(key: key);

  Widget _shimmer(double w, double h) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(width: w, height: h, color: Colors.white10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poster = cast.profilePath != null ? TMDBExtra.imageBase + cast.profilePath! : null;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: cast.id)));
      },
      child: SizedBox(
        width: width,
        child: Column(
          // Evita que la columna ocupe todo el eje vertical y centra su contenido
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: 'person-${cast.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: poster != null
                    ? CachedNetworkImage(
                  imageUrl: poster,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => _shimmer(width, height),
                  errorWidget: (c, u, e) => Container(width: width, height: height, color: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
                )
                    : Container(width: width, height: height, color: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 8),
            // Limitar líneas y centrar para evitar crecimiento vertical inesperado
            Text(
              cast.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            if (cast.character != null)
              Text(
                cast.character!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}