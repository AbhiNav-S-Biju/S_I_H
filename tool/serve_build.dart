// Minimal static file server used ONLY to verify the prebuilt web bundle in a
// real browser (the same files GitHub Pages will serve).
//
//   dart run tool/serve_build.dart [port] [rootDir]
//
// Defaults to port 8099 and build/web. Not part of the app; safe to delete.
import 'dart:io';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8099;
  final root = Directory(args.length > 1 ? args[1] : 'build/web').absolute;
  if (!root.existsSync()) {
    stderr.writeln('Root not found: ${root.path}');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Serving ${root.path} at http://127.0.0.1:$port/');

  await for (final req in server) {
    var rel = Uri.decodeComponent(req.uri.path);
    // The bundle is built with --base-href /S_I_H/, so strip that prefix the
    // way GitHub Pages does before mapping the request onto a file.
    final prefix = args.length > 2 ? args[2] : '/S_I_H/';
    if (rel.startsWith(prefix)) rel = rel.substring(prefix.length);
    if (rel.startsWith('/')) rel = rel.substring(1);
    if (rel.isEmpty) rel = 'index.html';

    var file = File(
      '${root.path}${Platform.pathSeparator}'
      '${rel.replaceAll('/', Platform.pathSeparator)}',
    );

    // Mirror GitHub Pages' 404.html fallback for deep links.
    if (!file.existsSync() && !rel.contains('.')) {
      file = File('${root.path}${Platform.pathSeparator}index.html');
    }

    if (!file.existsSync()) {
      req.response.statusCode = HttpStatus.notFound;
      await req.response.close();
      continue;
    }

    final name = file.uri.pathSegments.last;
    req.response.headers.contentType = switch (name) {
      final n when n.endsWith('.html') => ContentType.html,
      final n when n.endsWith('.js') => ContentType('text', 'javascript'),
      final n when n.endsWith('.json') => ContentType.json,
      final n when n.endsWith('.wasm') => ContentType('application', 'wasm'),
      final n when n.endsWith('.css') => ContentType('text', 'css'),
      final n when n.endsWith('.png') => ContentType('image', 'png'),
      final n when n.endsWith('.ttf') => ContentType('font', 'ttf'),
      _ => ContentType.binary,
    };
    await req.response.addStream(file.openRead());
    await req.response.close();
  }
}
