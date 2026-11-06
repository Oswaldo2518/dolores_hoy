
import '../dominio/excepciones.dart';

// Las claves entran mediante --dart-define.
// No se escriben directamente en el código.
class ConfigClaves {
  final String nasa;

  const ConfigClaves({
    required this.nasa,
  });

  // La clave se obtiene de las variables de compilación.
  factory ConfigClaves.desdeEntorno() => const ConfigClaves(
        nasa: String.fromEnvironment(
          'NASA_API_KEY',
          defaultValue: 'DEMO_KEY',
        ),
      );

  // Detecta si estamos utilizando la clave pública.
  bool get usaClaveDemo => nasa == 'DEMO_KEY';

  // Validar que exista una clave.
  void validar() {
    if (nasa.trim().isEmpty) {
      throw const ClaveFaltanteException('NASA_API_KEY');
    }
  }

  // Evita mostrar la clave completa.
  @override
  String toString() => 'ConfigClaves(nasa: ${_ocultar(nasa)})';

  static String _ocultar(String s) =>
      s.length <= 4
          ? '****'
          : '${s.substring(0, 2)}***${s.substring(s.length - 2)}';
}
