import 'dart:async';
import '../services/automation_driver.dart';

class CalculatorTest {
  final AutomationDriver driver;
  // Callback para avisar a UI sobre o progresso (substituto do setState)
  final Function(String status) onStatusChanged;

  CalculatorTest({required this.driver, required this.onStatusChanged});

  /// Executa o fluxo completo: Home -> Calc -> Conta -> Leitura -> Volta
  Future<String> run(String input) async {
    if (input.isEmpty) return "";

    _updateStatus("Iniciando Automação...\nMinimize o app se necessário.");

    // 1. Vai para Home
    await driver.performGlobalAction("HOME");
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 2. Abre a Calculadora
      _updateStatus("Abrindo Calculadora...");
      try {
        await driver.clickByText('Calculadora');
      } catch (e) {
        await driver.clickByText('Calculator');
      }

      await Future.delayed(const Duration(seconds: 3));

      // --- PASSO DE LIMPEZA (AC/C) ---
      _updateStatus("Limpando tela anterior...");
      try {
        await driver.clickByText('AC');
      } catch (e) {}
      try {
        await driver.clickByText('C');
      } catch (e) {}
      try {
        await driver.clickByText('Limpar');
      } catch (e) {}
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Digita a conta
      for (int i = 0; i < input.length; i++) {
        String char = input[i];
        String textToClick = char;

        // Tradução de Símbolos
        if (char == '*') textToClick = '×';
        if (char == '/') textToClick = '÷';
        if (char == '-') textToClick = '−';

        _updateStatus("Digitando: $textToClick");

        try {
          await driver.clickByText(textToClick);
        } catch (e) {
          // Fallback de nomes
          if (char == '*')
            await driver.clickByText('Vezes');
          else if (char == '/')
            await driver.clickByText('Dividir');
          else if (char == '-')
            await driver.clickByText('Menos');
          else if (char == '-')
            await driver.clickByText('-');
          else if (char == '+')
            await driver.clickByText('Mais');
        }
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // 4. Clica em Igual
      _updateStatus("Calculando...");
      try {
        await driver.clickByText('=');
      } catch (e) {
        await driver.clickByText('Igual');
      }

      await Future.delayed(const Duration(seconds: 4));

      // 5. LÊ A TELA
      _updateStatus("Lendo resultado...");
      final List<dynamic> screenTexts = await driver.readScreen();

      // Analisa o resultado
      String cleanResult = _extractCleanResult(screenTexts);

      // 6. VOLTA PARA O APP (Round-trip)
      _updateStatus("Voltando... Resultado detectado: $cleanResult");
      await driver.performGlobalAction("RECENTS");
      await Future.delayed(const Duration(seconds: 2));

      bool voltou = false;
      try {
        await driver.clickByText('GhostTouch QA');
        voltou = true;
      } catch (e) {}

      if (!voltou) {
        try {
          await driver.clickByText('GhostTouch');
        } catch (e) {
          // Fallback: Blind Click no meio
          await driver.click(500.0, 1000.0);
        }
      }

      _updateStatus("Ciclo Concluído!");
      return cleanResult;
    } catch (e) {
      _updateStatus("Erro Crítico: $e");
      return "Erro";
    }
  }

  void _updateStatus(String msg) {
    onStatusChanged(msg);
  }

  // Parser Inteligente (Lógica pura)
  String _extractCleanResult(List<dynamic> rawTexts) {
    // 1. Prioridade: Texto explícito
    for (var text in rawTexts) {
      String t = text.toString().toLowerCase();
      if (t.contains("resultado") ||
          t.contains("result") ||
          t.contains("calculation")) {
        return text.toString().replaceAll(RegExp(r'[^0-9.,]'), '');
      }
    }

    // 2. Fallback: Heurística numérica
    for (var text in rawTexts) {
      String t = text.toString();
      if (double.tryParse(t.replaceAll(',', '.')) != null) {
        if (t.length > 1 || t.contains(',') || t.contains('.')) {
          return t;
        }
      }
    }
    return "Não identificado";
  }
}
