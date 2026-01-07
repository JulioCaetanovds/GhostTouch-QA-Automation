import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GhostTouch QA 👻')),
        body: const GhostControl(),
      ),
    );
  }
}

class GhostControl extends StatefulWidget {
  const GhostControl({super.key});

  @override
  State<GhostControl> createState() => _GhostControlState();
}

class _GhostControlState extends State<GhostControl> {
  static const platform = MethodChannel(
    'com.example.ghost_touch/accessibility',
  );

  // Controladores para o input da conta
  final TextEditingController _calcInputController = TextEditingController();

  String status = "Digite uma conta (ex: 7+9)";
  String capturedResult = "";

  // Ações Básicas
  Future<void> sendGlobalAction(String action) async {
    try {
      await platform.invokeMethod('globalAction', {'action': action});
    } catch (e) {
      print(e);
    }
  }

  // Função para limpar a bagunça e achar o número
  String _extractCleanResult(List<dynamic> rawTexts) {
    // 1. Prioridade: Texto que o Android diz explicitamente ser o resultado
    for (var text in rawTexts) {
      String t = text.toString().toLowerCase();
      if (t.contains("resultado") ||
          t.contains("result") ||
          t.contains("calculation")) {
        // Remove tudo que não for número ou vírgula/ponto
        // Ex: "168 resultado..." vira "168"
        String numbersOnly = text.toString().replaceAll(
          RegExp(r'[^0-9.,]'),
          '',
        );
        return numbersOnly;
      }
    }

    // 2. Fallback: Tenta achar o número puro (se a calc não disser "resultado")
    // Geralmente o resultado é o texto mais longo que é puramente numérico
    // e não é um botão isolado (tamanho > 1 ou contém ponto/vírgula)
    for (var text in rawTexts) {
      String t = text.toString();
      // Se for um número e tiver mais de 1 dígito (ex: "168")
      // Ou se for um número decimal (ex: "2.5")
      if (double.tryParse(t.replaceAll(',', '.')) != null) {
        if (t.length > 1 || t.contains(',') || t.contains('.')) {
          return t;
        }
      }
    }

    return "Não identificado";
  }

  Future<void> runInteractiveCalc() async {
    final input = _calcInputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      status = "Iniciando Automação...\nMinimize o app se necessário.";
      capturedResult = "";
    });

    // 1. Vai para Home
    await sendGlobalAction("HOME");
    await Future.delayed(const Duration(seconds: 2));

    try {
      // 2. Abre a Calculadora
      setState(() => status = "Abrindo Calculadora...");
      // Se o nome do seu app for diferente, ajuste aqui (ex: Calculator)
      try {
        await platform.invokeMethod('clickByText', {'text': 'Calculadora'});
      } catch (e) {
        await platform.invokeMethod('clickByText', {'text': 'Calculator'});
      }

      await Future.delayed(const Duration(seconds: 3));

      // --- [NOVO] PASSO DE LIMPEZA ---
      // Tenta clicar em tudo que possa significar "Limpar" para garantir conta nova
      setState(() => status = "Limpando tela anterior...");
      try {
        await platform.invokeMethod('clickByText', {'text': 'AC'});
      } catch (e) {} // All Clear
      try {
        await platform.invokeMethod('clickByText', {'text': 'C'});
      } catch (e) {} // Clear
      try {
        await platform.invokeMethod('clickByText', {'text': 'Limpar'});
      } catch (e) {}
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Digita a conta caractere por caractere
      for (int i = 0; i < input.length; i++) {
        String char = input[i];
        String textToClick = char;

        // --- [NOVO] TRADUÇÃO DE SÍMBOLOS ---
        // Traduz do teclado do PC para os símbolos da Calculadora Android
        if (char == '*') textToClick = '×';
        if (char == '/') textToClick = '÷';
        // O menos e mais geralmente são iguais, mas garantimos:
        if (char == '-')
          textToClick = '−'; // O menos matemático às vezes é diferente do hífen

        setState(() => status = "Digitando: $textToClick");

        try {
          // Tenta clicar no símbolo traduzido
          await platform.invokeMethod('clickByText', {'text': textToClick});
        } catch (e) {
          // SE FALHAR, tenta os nomes por extenso (Fallback)
          print("Falha ao clicar em $textToClick, tentando nomes...");
          if (char == '*')
            await platform.invokeMethod('clickByText', {'text': 'Vezes'});
          else if (char == '/')
            await platform.invokeMethod('clickByText', {'text': 'Dividir'});
          else if (char == '-')
            await platform.invokeMethod('clickByText', {
              'text': 'Menos',
            }); // Tenta "Menos" se o símbolo falhar
          else if (char == '-')
            await platform.invokeMethod('clickByText', {
              'text': '-',
            }); // Tenta o hífen normal
          else if (char == '+')
            await platform.invokeMethod('clickByText', {'text': 'Mais'});
        }
        await Future.delayed(const Duration(milliseconds: 600));
      }

      // 4. Clica em Igual
      setState(() => status = "Calculando...");
      try {
        await platform.invokeMethod('clickByText', {'text': '='});
      } catch (e) {
        await platform.invokeMethod('clickByText', {'text': 'Igual'});
      }

      // Aumentei o tempo para dar tempo da animação do resultado terminar
      await Future.delayed(const Duration(seconds: 4));

      // 5. LÊ A TELA (Scraping)
      setState(() => status = "Lendo resultado...");
      final List<dynamic> screenTexts = await platform.invokeMethod(
        'readScreen',
      );

      // GUARA O LOG BRUTO (para debug)
      capturedResult = screenTexts.join(" | ");

      // EXTRAI O OURO (O número limpo)
      String cleanNumber = _extractCleanResult(screenTexts);

      // 6. VOLTA PARA O NOSSO APP
      setState(() => status = "Voltando... Resultado detectado: $cleanNumber");
      await sendGlobalAction("RECENTS");
      await Future.delayed(const Duration(seconds: 2));

      // Tenta achar o app no Recents
      bool voltou = false;
      try {
        await platform.invokeMethod('clickByText', {'text': 'GhostTouch QA'});
        voltou = true;
      } catch (e) {}

      if (!voltou) {
        try {
          await platform.invokeMethod('clickByText', {'text': 'GhostTouch'});
        } catch (e) {
          // Fallback: Clica no meio da tela
          await platform.invokeMethod('click', {'x': 500.0, 'y': 1000.0});
        }
      }

      setState(() => status = "Ciclo Concluído!");
    } catch (e) {
      setState(() => status = "Erro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Icon(Icons.calculate_outlined, size: 50, color: Colors.teal),
          const SizedBox(height: 10),
          const Text(
            "Automação Bidirecional",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _calcInputController,
            keyboardType:
                TextInputType.visiblePassword, // Teclado numérico com símbolos
            decoration: const InputDecoration(
              labelText: 'Digite a conta (ex: 15+25)',
              border: OutlineInputBorder(),
              helperText: 'Use apenas números simples e + - / *',
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: runInteractiveCalc,
              icon: const Icon(Icons.play_arrow),
              label: const Text('CALCULAR E TRAZER RESULTADO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          const Text(
            "Status / Resultado:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            color: Colors.grey[200],
            child: Text(status),
          ),

          if (capturedResult.isNotEmpty) ...[
            const SizedBox(height: 30),

            // MOSTRAR O RESULTADO LIMPO EM DESTAQUE
            const Text(
              "RESULTADO FINAL:",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              _extractCleanResult(
                capturedResult.split(' | '),
              ), // Usa nossa função de limpeza
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 20),

            // Log bruto (para provar que lemos a tela toda)
            const Text(
              "Log Bruto (Debug):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Container(
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              color: Colors.grey[200],
              child: Text(
                capturedResult,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
