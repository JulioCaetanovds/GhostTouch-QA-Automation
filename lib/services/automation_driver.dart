import 'package:flutter/services.dart';

class AutomationDriver {
  // Canal de comunicação com o Nativo (Kotlin)
  static const _platform = MethodChannel(
    'com.example.ghost_touch/accessibility',
  );

  /// Clica em uma coordenada específica (X, Y)
  Future<void> click(double x, double y) async {
    await _platform.invokeMethod('click', {'x': x, 'y': y});
  }

  /// Tenta encontrar um elemento pelo texto e clicar nele
  Future<void> clickByText(String text) async {
    await _platform.invokeMethod('clickByText', {'text': text});
  }

  /// Realiza um swipe (arrastar) de A para B
  Future<void> swipe(
    double startX,
    double startY,
    double endX,
    double endY, {
    int duration = 500,
  }) async {
    await _platform.invokeMethod('swipe', {
      'startX': startX,
      'startY': startY,
      'endX': endX,
      'endY': endY,
      'duration': duration,
    });
  }

  /// Executa ações globais (HOME, BACK, RECENTS, NOTIFICATIONS)
  Future<void> performGlobalAction(String action) async {
    await _platform.invokeMethod('globalAction', {'action': action});
  }

  /// Lê todo o texto visível na tela atual (Screen Scraping)
  Future<List<dynamic>> readScreen() async {
    final List<dynamic> result = await _platform.invokeMethod('readScreen');
    return result;
  }

  /// Insere texto no campo focado ou busca um campo editável
  Future<void> inputText(String text) async {
    await _platform.invokeMethod('inputText', {'text': text});
  }

  /// Clica em um elemento buscando pela descrição de conteúdo (acessibilidade)
  Future<void> clickByDescription(String desc) async {
    await _platform.invokeMethod('clickByDescription', {'desc': desc});
  }

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool isEnabled = await _platform.invokeMethod('isServiceActive');
      return isEnabled;
    } catch (e) {
      // ignore: avoid_print
      print("Erro ao verificar serviço: $e");
      return false;
    }
  }
}
