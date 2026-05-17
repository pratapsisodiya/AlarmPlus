import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuardianService {
  static const _webhookKey = 'guardian_webhook_url';

  static Future<String> getWebhookUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webhookKey) ?? '';
  }

  static Future<void> setWebhookUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webhookKey, url);
  }

  static Future<void> triggerAlert(int alarmId) async {
    final url = await getWebhookUrl();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      debugPrint('GuardianService: invalid webhook URL');
      return;
    }

    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'Alarm+ has been ringing for 10+ minutes without a response!',
          'alarmId': alarmId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      debugPrint('GuardianService: alert sent for alarm $alarmId');
    } catch (e) {
      debugPrint('GuardianService: failed to send alert: $e');
    }
  }
}
