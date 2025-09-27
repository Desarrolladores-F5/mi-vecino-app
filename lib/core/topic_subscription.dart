import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // para kDebugMode y debugPrint

class TopicSubscription {
  static const _prefsKeyCommunity = 'comunidad';
  static const _prefsKeyPrevTopic = 'prev_topic';

  /// Normaliza el nombre de la comunidad a un topic válido.
  /// FCM topics permiten [a-zA-Z0-9-_.~%] — dejamos algo simple y robusto.
  static String _toTopic(String communityName) {
    final s = communityName
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-\.~%]'), '');
    return 'comunidad_$s'; // prefijo para evitar choques
  }

  /// Lee la comunidad desde SharedPreferences y suscribe (si corresponde).
  static Future<void> subscribeFromLocalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final comunidad = prefs.getString(_prefsKeyCommunity);
    if (comunidad == null || comunidad.trim().isEmpty) {
      if (kDebugMode) {
      debugPrint('ℹ️ No hay comunidad guardada localmente. No se suscribe a ningún topic.');
      }
      return;
    }
    final topic = _toTopic(comunidad);
    final prev = prefs.getString(_prefsKeyPrevTopic);

    if (prev != null && prev.isNotEmpty && prev != topic) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(prev);
      if (kDebugMode) {
        debugPrint('🔕 Unsubscribed de topic previo: $prev');
      }
    }

    await FirebaseMessaging.instance.subscribeToTopic(topic);
    await prefs.setString(_prefsKeyPrevTopic, topic);
    if (kDebugMode) {
      debugPrint('🔔 Subscribed a topic: $topic (comunidad: $comunidad)');
    }
  }

  /// Guarda la comunidad elegida localmente y ajusta la suscripción.
  static Future<void> updateCommunityAndResubscribe(String comunidad) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyCommunity, comunidad);
    await subscribeFromLocalPrefs();
  }

  /// Opcional: para borrar la comunidad local (si alguna vez quisieras).
  static Future<void> clearCommunity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyCommunity);
    // Nota: Por política actual NO desuscribimos en logout.
  }
}
