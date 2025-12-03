import 'package:flutter/material.dart';
import 'package:cinematch/services/tmdb_service.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/widgets/movie_carousel.dart';
import 'package:cinematch/screens/search_screen.dart';
import 'package:cinematch/screens/favorites_screen.dart';
import 'package:cinematch/widgets/movie_card.dart';
import 'package:cinematch/screens/recommendations_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  List<Movie> popular = [];
  List<Movie> trending = [];
  List<Movie> movies2025 = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      popular = await TMDBService.getPopular();
      trending = await TMDBService.getTrending();
      // Cargar películas del año 2025
      movies2025 = await TMDBService.getDiscover({'primary_release_year': '2025', 'sort_by': 'popularity.desc'});
    } catch (e) {
      error = e.toString();
      print('Home load error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CineMatch'),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SearchScreen()))),
          IconButton(icon: Icon(Icons.favorite), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FavoritesScreen()))),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Error cargando datos', style: TextStyle(fontSize: 18, color: Colors.redAccent)),
            SizedBox(height: 8),
            Text(error ?? '', textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: Text('Reintentar')),
          ]),
        ),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 12),
          children: [
            MovieCarousel(title: 'Populares', movies: popular),
            SizedBox(height: 12),
            if (movies2025.isNotEmpty) ...[
              MovieCarousel(title: 'Películas 2025', movies: movies2025),
              SizedBox(height: 12),
            ],
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Tendencias', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            SizedBox(height: 8),
            Container(
              height: 320,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                itemBuilder: (context, i) => Padding(padding: EdgeInsets.all(8), child: MovieCard(movie: trending[i])),
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Para ti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 8),
            RecommendationsPreview(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class RecommendationsPreview extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RecommendationsPreviewState();
}

class _RecommendationsPreviewState extends State<RecommendationsPreview> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RecommendationsScreen())),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        height: 140,
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text('Ver recomendaciones personalizadas', style: TextStyle(fontSize: 16))),
      ),
    );
  }
}