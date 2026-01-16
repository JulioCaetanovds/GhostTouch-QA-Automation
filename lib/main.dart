import 'package:flutter/material.dart';
import 'services/automation_driver.dart';
import 'scripts/calculator_test.dart';
import 'scripts/contacts_test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('GhostTouch QA 👻'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
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
  // Instancia o Driver
  final AutomationDriver _driver = AutomationDriver();

  final TextEditingController _calcInputController = TextEditingController();

  @override
  void dispose() {
    _calcInputController.dispose();
    super.dispose();
  }

  String _status = "Pronto para testar.";
  String _finalResult = "";
  String _selectedMode = "Calculadora"; // Modo padrão

  // Método chamado pelo botão
  Future<void> _startTest() async {
    // Limpa estado anterior
    setState(() {
      _status = "Inicializando...";
      _finalResult = "";
    });

    if (!mounted) return;

    if (_selectedMode == "Calculadora") {
      // --- MODO CALCULADORA ---
      final testScript = CalculatorTest(
        driver: _driver,
        onStatusChanged: (newStatus) {
          setState(() => _status = newStatus);
        },
      );
      final result = await testScript.run(_calcInputController.text.trim());
      if (!mounted) return;
      setState(() {
        _finalResult = result;
      });
    } else {
      // --- MODO CONTATOS ---
      final testScript = ContactsTest(
        driver: _driver,
        onStatusChanged: (newStatus) {
          setState(() => _status = newStatus);
        },
      );
      await testScript.run();
      if (!mounted) return;
      setState(() {
        _finalResult = "Teste Fim";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            size: 60,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 10),
          const Text(
            "Automação Híbrida",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Flutter + Android Accessibility Service",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 30),

          // --- SELETOR DE MODO ---
          DropdownButtonFormField<String>(
            initialValue: _selectedMode,
            decoration: const InputDecoration(
              labelText: "Selecione o Cenário de Teste",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.layers),
            ),
            items: const [
              DropdownMenuItem(
                value: "Calculadora",
                child: Text("Calculadora (Math)"),
              ),
              DropdownMenuItem(
                value: "Contatos",
                child: Text("Agenda (Input Text)"),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMode = value);
              }
            },
          ),
          const SizedBox(height: 20),

          // Mostra Input apenas se for Calculadora
          if (_selectedMode == "Calculadora")
            TextField(
              controller: _calcInputController,
              keyboardType: TextInputType.visiblePassword,
              decoration: const InputDecoration(
                labelText: 'Digite a conta (ex: 42*4)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
                helperText: 'Suporta +, -, *, /',
              ),
            ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _startTest,
              icon: const Icon(Icons.play_circle_fill),
              label: const Text('EXECUTAR TESTE E2E'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),

          // Área de Status (Console Log Visual)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LOG DE EXECUÇÃO:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(_status, style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
          ),

          // Exibição do Resultado Final
          if (_finalResult.isNotEmpty && _finalResult != "Erro") ...[
            const SizedBox(height: 20),
            const Text(
              "RESULTADO CAPTURADO:",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _finalResult,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
