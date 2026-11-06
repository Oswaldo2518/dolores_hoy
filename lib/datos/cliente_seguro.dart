import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../dominio/excepciones.dart';

/// Único punto de salida a internet de toda la app.
/// Aquí aplicamos las medidas de seguridad.
class ClienteSeguro {
  final http.Client _cliente;
  final Duration espera;
  final int maxBytes;

  ClienteSeguro(
    this._cliente, {
    this.espera = const Duration(seconds: 8),
    this.maxBytes = 1024 * 1024,
  });

  static const _cabeceras = {
    'Accept': 'application/json',
    'User-Agent': 'DoloresHoy/1.0 (curso Flutter UTNG)',
  };

  Future<dynamic> obtenerJson(Uri uri) async {
    // Solo se permiten conexiones HTTPS.
    if (uri.scheme != 'https') {
      throw const ConexionInseguraException();
    }

    http.Response r;

    try {
      r = await _cliente.get(uri, headers: _cabeceras).timeout(espera);
    } on SocketException {
      throw const SinConexionException();
    } on TimeoutException {
      throw const SinConexionException();
    } on http.ClientException {
      throw const SinConexionException();
    }

    // Validar el código HTTP.
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ErrorServidorException(r.statusCode);
    }

    // Validar el tamaño de la respuesta.
    if (r.bodyBytes.length > maxBytes) {
      throw const RespuestaDemasiadoGrandeException();
    }

    // Convertir la respuesta a JSON.
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      throw const RespuestaInvalidaException();
    }
  }

  /// Oculta las claves que aparecen en las URLs.

  static String redactar(Uri uri) {
    const secretos = {'api_key', 'apikey', 'key', 'token', 'access_token'};

    final params = uri.queryParameters.map(
      (k, v) => MapEntry(k, secretos.contains(k.toLowerCase()) ? '***' : v),
    );

    final url = uri
        .replace(queryParameters: params.isEmpty ? null : params)
        .toString();

    return url.replaceAll('%2A%2A%2A', '***');
  }
}

/// Convierte JSON en objetos y controla errores de formato.
T convertir<T>(T Function() f) {
  try {
    return f();
  } catch (_) {
    throw const RespuestaInvalidaException();
  }
}
