import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinematch/providers/favorites_provider.dart';
import 'package:cinematch/widgets/movie_card.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favProv = Provider.of<FavoritesProvider>(context);
    final favs = favProv.favorites;
    return Scaffold(
      appBar: AppBar(title: Text('Favoritos')),
      body: favProv.loading
          ? Center(child: CircularProgressIndicator())
          : favs.isEmpty
          ? Center(child: Text('No hay favoritos aún'))
          : ListView.builder(
        itemCount: favs.length,
        itemBuilder: (_, i) => Dismissible(
          key: Key('${favs[i].id}'),
          direction: DismissDirection.endToStart,
          background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
          onDismissed: (_) => favProv.remove(favs[i].id),
          child: Padding(padding: EdgeInsets.all(8), child: MovieCard(movie: favs[i])),
        ),
      ),
    );
  }
}