import 'dart:io';

void main() async {
  final port = 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Esel Web App running at http://localhost:$port');

  await for (final request in server) {
    try {
      var reqPath = request.uri.path;
      if (reqPath == '/' || reqPath.isEmpty) reqPath = '/index.html';

      // Security check
      if (reqPath.contains('..')) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        continue;
      }

      var file = File('build/web$reqPath');
      if (!await file.exists()) {
        file = File('build/web/index.html');
      }

      if (await file.exists()) {
        final pathLower = file.path.toLowerCase();
        if (pathLower.endsWith('.html')) {
          request.response.headers.contentType = ContentType.html;
        } else if (pathLower.endsWith('.js')) {
          request.response.headers.contentType = ContentType('application', 'javascript', charset: 'utf-8');
        } else if (pathLower.endsWith('.wasm')) {
          request.response.headers.contentType = ContentType('application', 'wasm');
        } else if (pathLower.endsWith('.css')) {
          request.response.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
        } else if (pathLower.endsWith('.png')) {
          request.response.headers.contentType = ContentType('image', 'png');
        } else if (pathLower.endsWith('.jpg') || pathLower.endsWith('.jpeg')) {
          request.response.headers.contentType = ContentType('image', 'jpeg');
        } else if (pathLower.endsWith('.json')) {
          request.response.headers.contentType = ContentType.json;
        }

        // Allow CORS & caching
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        await request.response.addStream(file.openRead());
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }
}
