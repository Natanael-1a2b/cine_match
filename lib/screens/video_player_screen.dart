import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoKey; // id de YouTube, p.ej. "wweDnEbMvtY"

  const VideoPlayerScreen({Key? key, required this.videoKey}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();

    // HTML con la YouTube IFrame API, captura onError y redirige a esquema personalizado
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <style>body, html { margin:0; height:100%; background-color:#000; } #player{width:100%;height:100%;}</style>
</head>
<body>
  <div id="player"></div>
  <script>
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

    function onYouTubeIframeAPIReady() {
      player = new YT.Player('player', {
        height: '100%',
        width: '100%',
        videoId: '${widget.videoKey}',
        playerVars: {
          'autoplay': 1,
          'playsinline': 1,
          'rel': 0,
          'modestbranding': 1
        },
        events: {
          'onReady': function(event) {
            // listo
          },
          'onError': function(e) {
            // e.data contiene el código de error (101,150, etc.)
            // Redirigimos a una url con esquema personalizado para que Flutter la intercepte
            window.location.href = 'yt-embed-error://' + e.data;
          }
        }
      });
    }
  </script>
</body>
</html>
''';

    final uri = Uri.dataFromString(html, mimeType: 'text/html', encoding: Encoding.getByName('utf-8'));

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => setState(() {
            _loading = false;
            _errorMsg = null;
          }),
          onWebResourceError: (err) {
            setState(() {
              _loading = false;
              _errorMsg = 'Error cargando reproductor: ${err.errorCode} - ${err.description}';
            });
          },
          onNavigationRequest: (req) {
            // Interceptamos redirecciones a nuestro esquema especial 'yt-embed-error://<code>'
            final uri = Uri.parse(req.url);
            if (uri.scheme == 'yt-embed-error') {
              // Extraer código de error y abrir externamente en YouTube como fallback
              final code = uri.host; // por cómo construimos la URL: yt-embed-error://<code>
              _openExternalAndShowMessage(code);
              return NavigationDecision.prevent;
            }

            // Si la navegación trata de abrir un watch?v= en youtube, lo abrimos externamente
            if (uri.host.contains('youtube.com') && uri.path.contains('/watch')) {
              _openExternal(uri);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _openExternal(Uri uri) async {
    final u = uri;
    if (await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir YouTube externamente')));
    }
  }

  Future<void> _openExternalAndShowMessage(String? errorCode) async {
    // Mensaje amigable para el usuario según errorCode (101/150 típicos)
    String friendly;
    if (errorCode == '101' || errorCode == '150') {
      friendly = 'El propietario del video no permite embeberlo. Abriendo en YouTube...';
    } else if (errorCode == '150' || errorCode == '153') {
      friendly = 'Restricción del reproductor. Abriendo en YouTube...';
    } else {
      friendly = 'Error del reproductor (código $errorCode). Abriendo en YouTube...';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
    final web = Uri.parse('https://www.youtube.com/watch?v=${widget.videoKey}');
    await _openExternal(web);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trailer'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Abrir en YouTube',
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            onPressed: () {
              final web = Uri.parse('https://www.youtube.com/watch?v=${widget.videoKey}');
              _openExternal(web);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Player (16:9)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const Center(child: CircularProgressIndicator(color: Colors.white)),
                if (_errorMsg != null)
                  Center(
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info / fallback area
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trailer', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Si el reproductor no funciona, abre en YouTube', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final web = Uri.parse('https://www.youtube.com/watch?v=${widget.videoKey}');
                      _openExternal(web);
                    },
                    icon: const Icon(Icons.open_in_new, color: Colors.white),
                    label: const Text('Abrir en YouTube', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}