import 'dart:convert';
import 'package:http/http.dart' as http;

class BoldService {
  final String backendUrl;

  BoldService({this.backendUrl = 'https://api.soportee.store'});

  /// Genera la URL de checkout de Bold para un usuario
  Future<String> generarCheckoutUrl(String userId) async {
    print("🔐 Solicitando firma para userId: $userId");

    final uri = Uri.parse('$backendUrl/api/firmas/generar-firma');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error generando firma Bold: ${response.body}');
    }

    final data = jsonDecode(response.body);

    final orderId = data['orderId'];
    final amount = data['amount'];
    final currency = data['currency'];
    final firma = data['firma'];

    if (orderId == null || amount == null || currency == null || firma == null) {
      throw Exception('Datos incompletos al generar la firma Bold.');
    }

    // URL oficial de checkout Bold
    final url =
        'https://checkout.bold.co/pay/$orderId?amount=$amount&currency=$currency&signature=$firma';

    print("✅ URL generada correctamente: $url");
    return url;
  }

  /// Confirma el pago con tu backend
  Future<void> confirmarPago(String orderId, String userId) async {
    print("📡 Confirmando pago para orderId: $orderId, userId: $userId");

    final uri = Uri.parse('$backendUrl/api/pagos/confirmar');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'orderId': orderId, 'userId': userId}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error confirmando pago: ${response.body}');
    }

    final data = jsonDecode(response.body);
    print("✅ Pago confirmado en backend: $data");
  }
}
