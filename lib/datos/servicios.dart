
import '../dominio/excepciones.dart';
import '../dominio/modelos.dart';
import 'cliente_seguro.dart';
import 'config_claves.dart';

// API 1: Open-Meteo - Clima de Dolores Hidalgo.
class ServicioClima {
  final ClienteSeguro _c;

  ServicioClima(this._c);

  // Coordenadas de Dolores Hidalgo.
  Future<Clima> actual({
    double lat = 21.1561,
    double lon = -100.9319,
  }) async {
    // Validar las coordenadas antes de consultar la API.
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      throw const EntradaInvalidaException(
        'coordenadas fuera de rango',
      );
    }

    // Construir una URL HTTPS segura.
    final json = await _c.obtenerJson(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '$lat',
        'longitude': '$lon',
        'current':
            'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'timezone': 'America/Mexico_City',
      }),
    );

    // Convertir la respuesta JSON en un objeto Clima.
    return convertir(
      () => Clima.desdeJson(json as Map<String, dynamic>),
    );
  }
}

// API 2: Frankfurter - Tipo de cambio.
class ServicioCambio {
  final ClienteSeguro _c;

  ServicioCambio(this._c);

  Future<TipoCambio> deMxn() async {
    final json = await _c.obtenerJson(
      Uri.https(
        'api.frankfurter.dev',
        '/v1/latest',
        {
          'base': 'MXN',
          'symbols': 'USD,EUR',
        },
      ),
    );

    return convertir(
      () => TipoCambio.desdeJson(json as Map<String, dynamic>),
    );
  }
}

// API 3: Nager.Date - Días festivos de México.
class ServicioFestivos {
  final ClienteSeguro _c;

  ServicioFestivos(this._c);

  // La fecha de hoy se puede modificar en las pruebas.
  Future<List<Festivo>> proximos({
    int? anio,
    DateTime? hoy,
    int cuantos = 3,
  }) async {
    final ahora = hoy ?? DateTime.now();
    final a = anio ?? ahora.year;

    // Validar que el año esté dentro del rango permitido.
    if (a < 2000 || a > 2100) {
      throw const EntradaInvalidaException(
        'año fuera de rango',
      );
    }

    // Consultar la API utilizando HTTPS.
    final json = await _c.obtenerJson(
      Uri.https(
        'date.nager.at',
        '/api/v3/PublicHolidays/$a/MX',
      ),
    );

    // Convertir el JSON en una lista de objetos Festivo.
    final todos = convertir(
      () => (json as List)
          .map(
            (e) => Festivo.desdeJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );

    // Obtener la fecha actual sin tomar en cuenta la hora.
    final dia = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    // Filtrar los días festivos que aún no han pasado.
    final futuros = todos
        .where((f) => !f.fecha.isBefore(dia))
        .toList()
      ..sort((x, y) => x.fecha.compareTo(y.fecha));

    // Regresar solamente la cantidad solicitada.
    return futuros.take(cuantos).toList();
  }
  
}

// API 4: Wikipedia en español.
// Validamos el texto que escribe el usuario.
class ServicioWikipedia {
  final ClienteSeguro _c;

  ServicioWikipedia(this._c);

  static String normalizarTema(String tema) {
    final t = tema.trim();

    if (t.isEmpty) {
      throw const EntradaInvalidaException(
        'escribe un tema',
      );
    }

    if (t.length > 80) {
      throw const EntradaInvalidaException(
        'tema demasiado largo',
      );
    }

    if (t.contains(RegExp(r'[\x00-\x1F]'))) {
      throw const EntradaInvalidaException(
        'caracteres no permitidos',
      );
    }

    return t.replaceAll(' ', '_');
  }

  Future<ResumenWiki> resumen(String tema) async {
    final t = normalizarTema(tema);

    // Construimos la URL usando segmentos seguros.
    final uri = Uri(
      scheme: 'https',
      host: 'es.wikipedia.org',
      pathSegments: [
        'api',
        'rest_v1',
        'page',
        'summary',
        t,
      ],
    );

    final json = await _c.obtenerJson(uri);

    return convertir(
      () => ResumenWiki.desdeJson(
        json as Map<String, dynamic>,
      ),
    );
  }
}

// API 5: NASA APOD - Foto astronómica del día.
class ServicioNasa {
  final ClienteSeguro _c;
  final ConfigClaves _claves;

  ServicioNasa(
    this._c,
    this._claves,
  );

  Future<FotoAstronomica> fotoDelDia() async {
    // Comprobar que la clave exista.
    _claves.validar();

    // Consultar NASA utilizando HTTPS.
    final json = await _c.obtenerJson(
      Uri.https(
        'api.nasa.gov',
        '/planetary/apod',
        {
          'api_key': _claves.nasa,
        },
      ),
    );

    // Convertir el JSON en un objeto FotoAstronomica.
    return convertir(
      () => FotoAstronomica.desdeJson(
        json as Map<String, dynamic>,
      ),
    );
  }
}




