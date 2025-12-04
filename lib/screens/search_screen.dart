import 'package:flutter/material.dart';
import 'package:cinematch/services/tmdb_service.dart';
import 'package:cinematch/models/movie.dart';
import 'package:cinematch/widgets/movie_card.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cinematch/providers/favorites_provider.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SearchState();
}

class _SearchState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Movie> results = [];
  Timer? _debounce;
  bool loading = false;

  // filtros
  int? selectedGenre;
  String? year;
  bool onlyFavorites = false;
  double minRating = 0;

  Map<int, String> genresMap = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      genresMap = await TMDBService.getGenres();
      setState(() {});
    } catch (e) {
      print('Error loading genres: $e');
    }
  }

  void _onTextChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 400), () => _search());
  }

  Future<void> _search() async {
    final q = _controller.text.trim();

    // Si solo favoritas está activo, filtramos localmente
    if (onlyFavorites) {
      setState(() => loading = true);
      try {
        final favProv = Provider.of<FavoritesProvider>(context, listen: false);
        await favProv.refresh(); // asegurar datos actualizados
        List<Movie> favs = favProv.favorites;
        if (q.isNotEmpty) {
          favs = favs.where((m) => m.title.toLowerCase().contains(q.toLowerCase())).toList();
        }
        if (selectedGenre != null) {
          favs = favs.where((m) => m.genreIds.contains(selectedGenre)).toList();
        }
        if (year != null && year!.isNotEmpty) {
          favs = favs.where((m) => (m.releaseDate ?? '').startsWith(year!)).toList();
        }
        if (minRating > 0) {
          favs = favs.where((m) => (m.voteAverage ?? 0) >= minRating).toList();
        }
        results = favs;
      } catch (e) {
        print('Error filtering favorites: $e');
        results = [];
      } finally {
        setState(() => loading = false);
      }
      return;
    }

    // Si hay filtros por año/genero/rating, usar discover (más fiable para esos filtros)
    final hasServerFilters = selectedGenre != null || (year != null && year!.isNotEmpty) || minRating > 0;

    if (hasServerFilters) {
      setState(() => loading = true);
      try {
        final params = <String, String>{};
        if (selectedGenre != null) params['with_genres'] = '$selectedGenre';
        if (year != null && year!.isNotEmpty) params['primary_release_year'] = year!;
        if (minRating > 0) params['vote_average.gte'] = '${minRating.toInt()}';
        params['sort_by'] = 'popularity.desc';
        // Si escribiste texto, no existe parámetro directo en discover para búsqueda libre,
        // así que obtenemos discover y filtramos localmente por título.
        List<Movie> fetched = await TMDBService.getDiscover(params);
        if (q.isNotEmpty) {
          fetched = fetched.where((m) => m.title.toLowerCase().contains(q.toLowerCase())).toList();
        }
        results = fetched;
      } catch (e) {
        print('Discover search error: $e');
        results = [];
      } finally {
        setState(() => loading = false);
      }
      return;
    }

    // Búsqueda en TMDB (sin filtros complejos)
    if (q.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);
    try {
      results = await TMDBService.searchMovies(q);
    } catch (e) {
      print('Search error: $e');
      results = [];
    }
    setState(() => loading = false);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _filters() {
    final yearItems = List.generate(30, (i) => (DateTime.now().year - i).toString()); // últimos 30 años

    final List<DropdownMenuItem<String?>> yearDropdownItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(child: Text('Cualquiera'), value: null),
      ...yearItems.map((y) => DropdownMenuItem<String?>(child: Text(y), value: y)).toList(),
    ];

    final List<DropdownMenuItem<int?>> genreDropdownItems = <DropdownMenuItem<int?>>[
      DropdownMenuItem<int?>(child: Text('Todos'), value: null),
      ...genresMap.entries.map((e) => DropdownMenuItem<int?>(child: Text(e.value), value: e.key)).toList(),
    ];

    // Limitamos la altura total del panel de filtros y hacemos su contenido scrollable internamente
    return ExpansionTile(
      title: Text('Filtros'),
      childrenPadding: EdgeInsets.zero,
      // Al desplegar, el contenido estará dentro de un SingleChildScrollView con maxHeight
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final screenH = MediaQuery.of(context).size.height;
          // Permitir hasta 42% de la altura de pantalla, ajusta si necesitas más/menos
          final maxPanelHeight = screenH * 0.42;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxPanelHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primera fila: género + año
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int?>(
                          isExpanded: true,
                          value: selectedGenre,
                          decoration: const InputDecoration(
                            labelText: 'Género',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: genreDropdownItems,
                          onChanged: (v) {
                            setState(() => selectedGenre = v);
                            _search();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String?>(
                          isExpanded: true,
                          value: year,
                          decoration: const InputDecoration(
                            labelText: 'Año',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: yearDropdownItems,
                          onChanged: (v) {
                            setState(() => year = v);
                            _search();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Segunda fila: rating + solo favoritas (se eliminó el botón "Aplicar")
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Min rating'),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: DropdownButton<double>(
                          isExpanded: true,
                          value: minRating,
                          items: [0, 5, 6, 7, 8].map((v) => DropdownMenuItem<double>(child: Text('$v'), value: v.toDouble())).toList(),
                          onChanged: (d) {
                            setState(() => minRating = d ?? 0);
                            _search();
                          },
                        ),
                      ),
                      const Spacer(),
                      // Checkbox y etiqueta agrupados para no empujar el layout
                      GestureDetector(
                        onTap: () {
                          setState(() => onlyFavorites = !onlyFavorites);
                          _search();
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(value: onlyFavorites, onChanged: (v) {
                              setState(() => onlyFavorites = v ?? false);
                              _search();
                            }),
                            const SizedBox(width: 8),
                            const Text('Solo favoritas'),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Si el contenido anterior se hace muy alto, se podrá scrollear internamente
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final favProv = Provider.of<FavoritesProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Buscar películas...')),
        ),
        // Mantener el comportamiento por defecto frente al teclado
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _filters(),
              if (loading) const LinearProgressIndicator(minHeight: 4),
              Expanded(
                child: results.isEmpty
                    ? Center(child: Text(onlyFavorites ? 'No hay favoritos que cumplan los filtros' : 'No hay resultados'))
                    : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: results.length,
                  itemBuilder: (_, i) => MovieCard(movie: results[i]),
                ),
              )
            ],
          ),
        ));
  }
}