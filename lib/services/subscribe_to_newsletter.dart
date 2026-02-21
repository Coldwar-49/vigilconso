// lib/services/subscribe_to_newsletter.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> subscribeToNewsletter(String email) async {
  try {
    final response = await http.post(
      Uri.parse('https://api.vigilconso.fr/newsletter'), // Remplace par ton URL réelle
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Inscription réussie !'};
    } else {
      final body = jsonDecode(response.body);
      return {
        'success': false,
        'message': body['message'] ?? 'Une erreur s\'est produite.'
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur réseau. Veuillez réessayer plus tard.'
    };
  }
}

