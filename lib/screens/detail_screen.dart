import 'package:flutter/material.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/services/tmdb_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:cinematch/providers/favorites_provider.dart';
import 'package:cinematch/services/db_service.dart';
import 'video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';

class DetailScreen extends StatefulWidget {
  final int movieId;
  DetailScreen({required this.movieId});

  @override
  State<StatefulWidget> createState() => _DetailState();
}

class _DetailState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  Movie? movie;
  bool loading = true;
  bool isFav = false;
  Map<int, String> genreMap = {};
  String? error;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      genreMap = await TMDBService.getGenres();
      movie = await TMDBService.getDetails(widget.movieId);
      await DBService.instance.addHistory(movie!);
      isFav = await DBService.instance.isFavorite(widget.movieId);
    } catch (e) {
      error = e.toString();
      print('Detail load error: $e');
    } finally {
      setState(() {
        loading = false;
      });
      // start fade animation for content
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _toggleFav() async {
    final favProv = Provider.of<FavoritesProvider>(context, listen: false);
    if (isFav) {
      await favProv.remove(movie!.id);
      setState(() => isFav = false);
    } else {
      await favProv.add(movie!);
      setState(() => isFav = true);
    }
  }

  void _openTrailer() async {
    final key = await TMDBService.getTrailerKey(widget.movieId);
    if (key != null && key.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoKey: key)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trailer no disponible')));
    }
  }

  Future<void> _openExternalWithKey(String videoKey) async {
    final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoKey');
    if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace en YouTube')));
    }
  }

  void _onOpenInYouTubePressed() async {
    final key = await TMDBService.getTrailerKey(widget.movieId);
    if (key != null && key.isNotEmpty) {
      await _openExternalWithKey(key);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trailer no disponible')));
    }
  }

  Widget _shimmerPoster({double? h}) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        height: h ?? 420,
        color: Colors.white10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie?.title ?? 'Detalle'),
        actions: [
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
            onPressed: movie == null ? null : _toggleFav,
          )
        ],
      ),
      body: loading
          ? Center(child: _shimmerPoster())
          : error != null
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Error: $error'),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _load, child: const Text('Reintentar'))
        ]),
      )
          : SingleChildScrollView(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero wrapped poster
              Hero(
                tag: 'poster-${movie!.id}',
                child: movie!.posterPath != null
                    ? CachedNetworkImage(
                  imageUrl: TMDBService.imageBase + movie!.posterPath!,
                  height: 420,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _shimmerPoster(h: 420),
                  errorWidget: (context, url, error) => Container(
                    height: 420,
                    color: Colors.white10,
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                  ),
                )
                    : Container(
                  height: 420,
                  color: Colors.white10,
                  child: const Center(child: Icon(Icons.local_movies, color: Colors.white24, size: 96)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(movie!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text('${movie!.voteAverage ?? 'N/A'}'),
                    const SizedBox(width: 16),
                    Text(movie!.releaseDate ?? ''),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: movie!.genreIds.map((id) {
                      final name = genreMap[id] ?? id.toString();
                      return Chip(label: Text(name));
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(movie!.overview),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ElevatedButton.icon(onPressed: _openTrailer, icon: const Icon(Icons.play_arrow), label: const Text('Ver Trailer')),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _onOpenInYouTubePressed,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Abrir en YouTube'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                      ),
                    ],
                  ),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}