import 'dart:async';
import '../services/automation_driver.dart';

class ContactsTest {
  final AutomationDriver driver;
  final Function(String status) onStatusChanged;

  ContactsTest({required this.driver, required this.onStatusChanged});

  Future<void> run() async {
    _updateStatus("Iniciando...");
    if (!await driver.isAccessibilityServiceEnabled()) return;

    // --- 1. ABRIR APP ---
    await driver.performGlobalAction("HOME");
    await Future.delayed(const Duration(seconds: 2));

    // Swipe Up para gaveta
    try {
      await driver.swipe(500, 1500, 500, 400);
    } catch (e) {
      // Intentionally ignored
    }
    await Future.delayed(const Duration(seconds: 2));

    try {
      await driver.clickByText('Contatos');
    } catch (e) {
      await driver.clickByText('Contacts');
    }
    await Future.delayed(const Duration(seconds: 3));

    // --- 2. BOTÃO CRIAR ---
    bool addClicked = false;
    for (var t in ['Criar contato', 'Novo contato', 'Adicionar', 'Criar']) {
      try {
        await driver.clickByDescription(t);
        addClicked = true;
        break;
      } catch (e) {
        // Intentionally ignored
      }
    }
    if (!addClicked) {
      try {
        await driver.clickByText("Criar");
      } catch (e) {
        // Intentionally ignored
      }
    }
    await Future.delayed(const Duration(seconds: 2));

    // --- 3. PREENCHER NOME ---
    _updateStatus("Preenchendo Nome...");

    // Tenta clicar no campo Nome. No seu print ele aparece como "Nome" ou "Primeiro nome"
    bool nameClicked = false;
    try {
      await driver.clickByText("Nome");
      nameClicked = true;
    } catch (e) {
      // Intentionally ignored
    }

    if (!nameClicked) {
      try {
        await driver.clickByText("Primeiro nome");
      } catch (e) {
        // Intentionally ignored
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await driver.inputText("Ghost Bot");
    await Future.delayed(const Duration(seconds: 1));

    // --- 4. FECHAR TECLADO (Obrigatorio) ---
    _updateStatus("Fechando teclado...");
    await driver.performGlobalAction("BACK");
    await Future.delayed(const Duration(seconds: 2)); // Espera o teclado sumir

    // --- 5. PREENCHER TELEFONE ---
    _updateStatus("Preenchendo Telefone...");

    // Como o menu "Nome" está fechado (padrão), o Telefone é o próximo item.
    // Importante: Se clicar no texto "Telefone" falhar (por pegar o cabeçalho),
    // tentamos clicar levemente abaixo do meio da tela onde o campo costuma ficar.
    bool phoneClicked = false;
    try {
      await driver.clickByText("Telefone");
      phoneClicked = true;
    } catch (e) {
      // Intentionally ignored
    }

    // Se o texto falhar, usa coordenada aproximada baseada no print (Campo logo abaixo do Nome)
    if (!phoneClicked) {
      // Coordenada estimada para o segundo campo da lista
      await driver.click(500, 800);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await driver.inputText("99999999");

    // Fecha teclado novamente
    await driver.performGlobalAction("BACK");
    await Future.delayed(const Duration(seconds: 1));

    // --- 6. PREENCHER E-MAIL ---
    _updateStatus("Preenchendo E-mail...");

    // O E-mail é o terceiro campo.
    try {
      await driver.clickByText("E-mail");
    } catch (e) {
      try {
        await driver.clickByText("Email");
      } catch (e2) {
        // Fallback coordenada (logo abaixo do telefone)
        await driver.click(500, 1000);
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await driver.inputText("ghost@bot.com");

    // Fecha teclado final
    await driver.performGlobalAction("BACK");
    await Future.delayed(const Duration(seconds: 1));

    // --- 7. SALVAR ---
    _updateStatus("Salvando...");
    try {
      await driver.clickByText('Salvar');
    } catch (e) {
      // Intentionally ignored
    }

    await Future.delayed(const Duration(seconds: 3));

    // --- 8. VOLTAR ---
    _updateStatus("Voltando...");
    await driver.performGlobalAction("RECENTS");
    await Future.delayed(const Duration(seconds: 3));

    try {
      await driver.clickByText("GhostTouch QA");
    } catch (e) {
      await driver.click(540, 1200);
    }

    _updateStatus("Teste Concluído!");
  }

  void _updateStatus(String msg) {
    onStatusChanged(msg);
  }
}
