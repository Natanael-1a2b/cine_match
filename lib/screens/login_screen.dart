import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);

    // Start small logo animation
    _animController.forward();

    // Prefill username if saved (no auto-login)
    _prefillUsername();
  }

  Future<void> _prefillUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('cinematch_username');
      if (saved != null && saved.isNotEmpty) {
        _nameController.text = saved;
      }
    } catch (e) {
      // ignore errors, proceed without prefill
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) {
      // Move focus back to name
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    final name = _nameController.text.trim();

    // Simular validación / login local
    await Future.delayed(Duration(milliseconds: 700));

    // Guardar el nombre localmente para prefill futuro (sin auto-login)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cinematch_username', name);
    } catch (e) {
      // ignorar error de guardado
    }

    setState(() => _loading = false);

    // Navegar al Home
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    await Future.delayed(Duration(milliseconds: 500));
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // cerrar teclado al tocar fuera
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B0B0D), Color(0xFF121214)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: Hero(
                        tag: 'logo',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.local_movies, color: Colors.redAccent, size: 46),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14),
                    Text('CineMatch', style: theme.textTheme.headlineSmall!.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Descubre y guarda tus películas favoritas', style: theme.textTheme.bodyMedium!.copyWith(color: Colors.white70)),
                    SizedBox(height: 20),

                    Card(
                      color: Colors.black87,
                      elevation: 10,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Campo usuario
                              TextFormField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                textInputAction: TextInputAction.done,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Nombre de usuario',
                                  labelStyle: TextStyle(color: Colors.white70),
                                  hintText: 'Ej. Naxe1a2b',
                                  hintStyle: TextStyle(color: Colors.white24),
                                  prefixIcon: Icon(Icons.person, color: Colors.white38),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Introduce un nombre';
                                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                                  return null;
                                },
                                onFieldSubmitted: (_) => _onContinue(),
                                enableSuggestions: true,
                                autocorrect: false,
                                keyboardType: TextInputType.text,
                              ),
                              SizedBox(height: 12),

                              // Botón continuar (texto en blanco)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _onContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white, // asegura texto blanco
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _loading
                                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text('Continuar', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                                ),
                              ),

                              SizedBox(height: 8),

                              // Continuar como invitado centrado
                              Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Center(
                                  child: TextButton(
                                    onPressed: _continueAsGuest,
                                    child: Text('Continuar como invitado', style: TextStyle(color: Colors.white70)),
                                  ),
                                ),
                              ),

                              SizedBox(height: 6),

                              SizedBox(height: 10),
                              TextButton(
                                onPressed: () async {
                                  // Mostrar modal de ayuda / privacidad
                                  await showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('Privacidad y uso'),
                                      content: Text('CineMatch guarda localmente solo tu nombre para prefill. No compartimos tu información.'),
                                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar'))],
                                    ),
                                  );
                                },
                                child: Text('¿Por qué iniciar sesión?', style: TextStyle(color: Colors.white54)),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 18),

                    // Accesibilidad y small footer
                    Opacity(
                      opacity: 0.9,
                      child: Text('Al continuar aceptas los términos de uso', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ),

                    SizedBox(height: 8),

                    // Small help row
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.white24),
                      SizedBox(width: 6),
                      Text('Mejor experiencia en dispositivo real', style: TextStyle(color: Colors.white24, fontSize: 12)),
                    ]),

                    SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}