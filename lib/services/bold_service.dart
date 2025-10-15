import 'dart:convert';
import 'package:http/http.dart' as http;

class BoldService {
  final String backendUrl;

  BoldService({this.backendUrl = 'https://api.soportee.store'});

  /// Oculta información sensible en los logs
  String _sanitize(String value, {int visibleChars = 4}) {
    if (value.isEmpty) return '***';
    if (value.length <= visibleChars) return '***';
    return '${value.substring(0, visibleChars)}***';
  }

  /// Genera la URL de checkout de Bold para un usuario
  Future<String> generarCheckoutUrl(String userId) async {
    print("🔐 Solicitando firma para userId: ${_sanitize(userId)}");

    final uri = Uri.parse('$backendUrl/api/firmas/generar-firma');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      print("📥 Respuesta recibida - Status: ${response.statusCode}");

      if (response.statusCode != 200) {
        print("❌ Error en respuesta: Status ${response.statusCode}");
        throw Exception('Error generando firma Bold: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      final orderId = data['orderId'];
      final amount = data['amount'];
      final currency = data['currency'];
      final firma = data['firma'];

      if (orderId == null || amount == null || currency == null || firma == null) {
        print("❌ Datos incompletos en respuesta");
        throw Exception('Datos incompletos al generar la firma Bold.');
      }

      // Log sanitizado
      print("✅ Firma generada:");
      print("   • OrderId: ${_sanitize(orderId, visibleChars: 6)}");
      print("   • Amount: $amount $currency");
      print("   • Firma: ${_sanitize(firma, visibleChars: 8)}");

      // URL oficial de checkout Bold
      final url =
          'https://checkout.bold.co/pay/$orderId?amount=$amount&currency=$currency&signature=$firma';

      print("✅ URL de checkout generada correctamente");
      return url;
    } catch (e) {
      print("❌ Excepción en generarCheckoutUrl: ${e.toString()}");
      rethrow;
    }
  }

  /// Confirma el pago con tu backend
  Future<void> confirmarPago(String orderId, String userId) async {
    print("📡 Confirmando pago:");
    print("   • OrderId: ${_sanitize(orderId, visibleChars: 6)}");
    print("   • UserId: ${_sanitize(userId)}");

    final uri = Uri.parse('$backendUrl/api/pagos/confirmar');
    
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': orderId, 'userId': userId}),
      );

      print("📥 Respuesta de confirmación - Status: ${response.statusCode}");

      if (response.statusCode != 201 && response.statusCode != 200) {
        print("❌ Error en confirmación: Status ${response.statusCode}");
        throw Exception('Error confirmando pago: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      
      // Log sanitizado del resultado
      print("✅ Pago confirmado exitosamente");
      if (data['paymentId'] != null) {
        print("   • PaymentId: ${_sanitize(data['paymentId'].toString(), visibleChars: 6)}");
      }
      if (data['status'] != null) {
        print("   • Status: ${data['status']}");
      }
    } catch (e) {
      print("❌ Excepción en confirmarPago: ${e.toString()}");
      rethrow;
    }
  }
}