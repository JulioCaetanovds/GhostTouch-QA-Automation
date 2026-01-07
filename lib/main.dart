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
  final TextEditingController _textController =
      TextEditingController(); // Controlador do texto
  String status = "Digite o nome de um app ou botão";

  Future<void> clickElement() async {
    final textToFind = _textController.text;
    if (textToFind.isEmpty) return;

    setState(() => status = "Minimize AGORA! Buscando '$textToFind' em 4s...");

    // Tempo maior para você navegar até onde quer testar
    await Future.delayed(const Duration(seconds: 4));

    try {
      await platform.invokeMethod('clickByText', {'text': textToFind});
      setState(() => status = "Sucesso! Cliquei em '$textToFind'.");
    } on PlatformException catch (e) {
      if (e.code == "NOT_FOUND") {
        setState(() => status = "Não achei nada escrito '$textToFind'.");
      } else {
        setState(() => status = "Erro: ${e.message}");
      }
    }
  }

  Future<void> sendGlobalAction(String action) async {
    try {
      await platform.invokeMethod('globalAction', {'action': action});
    } catch (e) {
      print("Erro global: $e");
    }
  }

  // O "Grand Finale": Uma macro completa
  Future<void> runTestScript() async {
    setState(() => status = "Rodando Script de Teste...");

    // Passo 1: Ir para Home para garantir estado limpo
    await sendGlobalAction("HOME");
    await Future.delayed(const Duration(seconds: 2));

    // Passo 2: Procurar a Play Store (ou outro app que você testou e funcionou)
    // Tente usar o nome exato que funcionou no seu teste anterior
    try {
      await platform.invokeMethod('clickByText', {'text': 'Play Store'});
    } catch (e) {
      setState(() => status = "Falha ao abrir app: $e");
      return;
    }

    // Passo 3: Esperar o app abrir
    await Future.delayed(const Duration(seconds: 3));

    // Passo 4: Voltar para a Home (Simulando que o usuário desistiu)
    await sendGlobalAction("HOME");

    setState(() => status = "Script finalizado com sucesso! 🤖");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Campo de Texto
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Texto para clicar (ex: Play Store)',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          // Status
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Botão 1: Buscar e Clicar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: clickElement,
              icon: const Icon(Icons.smart_button),
              label: const Text('BUSCAR E CLICAR'),
              style: ElevatedButton.styleFrom(
                // Ajustei a cor pra ficar visível, pois branco no branco some
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // --- CÓDIGO NOVO ABAIXO ---
          const SizedBox(height: 30), // Espaço maior
          const Divider(), // Linha divisória
          const SizedBox(height: 10),

          Text("Automação de Fluxo", style: TextStyle(color: Colors.grey[700])),

          const SizedBox(height: 10),

          // Botão 2: Rodar Macro
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: runTestScript, // Chama a função da Macro
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('RODAR MACRO (HOME -> APP -> HOME)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
