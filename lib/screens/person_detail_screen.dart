import 'package:flutter/material.dart';
import 'package:cinematch/models/person.dart';
import 'package:cinematch/services/tmdb_extra.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class PersonDetailScreen extends StatefulWidget {
  final int personId;
  const PersonDetailScreen({Key? key, required this.personId}) : super(key: key);

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  Person? person;
  bool loading = true;
  List<Map<String, dynamic>> filmography = [];
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
      person = await TMDBExtra.getPerson(widget.personId);
      filmography = await TMDBExtra.getPersonMovieCredits(widget.personId);
      filmography.sort((a, b) {
        final da = a['release_date'] ?? '';
        final db = b['release_date'] ?? '';
        return db.compareTo(da);
      });
    } catch (e) {
      error = e.toString();
      debugPrint('Person load error: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _shimmerImage(double h) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(height: h, color: Colors.white10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = person?.profilePath != null ? TMDBExtra.imageBase + person!.profilePath! : null;

    return Scaffold(
      appBar: AppBar(title: Text(person?.name ?? 'Persona')),
      body: loading
          ? Center(child: _shimmerImage(300))
          : error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Error: $error'), const SizedBox(height: 8), ElevatedButton(onPressed: _load, child: const Text('Reintentar'))]))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'person-${person!.id}',
              child: imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (c, u) => _shimmerImage(300),
                errorWidget: (c, u, e) => Container(height: 300, color: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
              )
                  : Container(height: 300, color: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(person!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (person!.birthday != null) Text('Nacimiento: ${person!.birthday}'),
                if (person!.placeOfBirth != null) Text('Lugar: ${person!.placeOfBirth}'),
                const SizedBox(height: 12),
                if (person!.biography != null && person!.biography!.isNotEmpty) ...[
                  const Text('Biografía', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(person!.biography!),
                  const SizedBox(height: 12),
                ],
                const Text('Filmografía', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  children: filmography.map((m) {
                    final title = m['title'] ?? m['original_title'] ?? '';
                    final year = (m['release_date'] ?? '').toString().split('-').first;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(title),
                      subtitle: Text(year),
                      onTap: () {
                        final id = m['id'];
                        if (id != null) {
                          Navigator.of(context).pushNamed('/detail', arguments: id); // si usas rutas, o usa MaterialPageRoute
                        }
                      },
                    );
                  }).toList(),
                )
              ]),
            )
          ],
        ),
      ),
    );
  }
}