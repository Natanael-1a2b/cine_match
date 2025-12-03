import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinematch/providers/recommendation_provider.dart';
import 'package:cinematch/widgets/movie_card.dart';

class RecommendationsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RecState();
}

class _RecState extends State<RecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    final rp = Provider.of<RecommendationProvider>(context, listen: false);
    rp.buildRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<RecommendationProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Para ti')),
      body: rp.loading
          ? Center(child: CircularProgressIndicator())
          : rp.recommendations.isEmpty
          ? Center(child: Text('No hay recomendaciones todavía. Mira algunas películas para que el sistema aprenda.'))
          : ListView.builder(itemCount: rp.recommendations.length, itemBuilder: (_, i) => Padding(padding: EdgeInsets.all(8), child: MovieCard(movie: rp.recommendations[i]))),
    );
  }
}