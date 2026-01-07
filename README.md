# GhostTouch QA 👻
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Kotlin](https://img.shields.io/badge/Kotlin-0095D5?style=for-the-badge&logo=kotlin&logoColor=white) ![Android Native](https://img.shields.io/badge/Android-Native-3DDC84?style=for-the-badge&logo=android&logoColor=white) ![Automation](https://img.shields.io/badge/QA-Automation-FF6F00?style=for-the-badge&logo=selenium&logoColor=white)

**GhostTouch QA** é uma **Prova de Conceito (PoC)** de um driver de automação mobile personalizado, desenvolvido do zero para demonstrar os princípios fundamentais por trás de ferramentas padrão da indústria como **Appium** e **Maestro**.

Este projeto preenche a lacuna entre frameworks de UI de alto nível (Flutter) e recursos de baixo nível do sistema operacional Android, utilizando **Serviços de Acessibilidade** para realizar testes de caixa preta (black-box), injeção de gestos e inspeção de elementos de UI sem a necessidade de acesso root ou instrumentação externa.

---

## 🏗️ Arquitetura Técnica

A arquitetura baseia-se em um padrão de **Native Bridge** para permitir a comunicação bidirecional entre o controlador de teste de alto nível (Flutter) e o driver de nível de SO (Android Accessibility Service).

### 1. Comunicação Interprocessos (IPC)
A comunicação é gerenciada via **MethodChannels**, estabelecendo uma ponte entre o runtime do Dart e a camada nativa em Kotlin.
- **Canal**: `com.example.ghost_touch/accessibility`
- O cliente Flutter envia payloads de comando (ex: `clickByText`, `globalAction`) que são organizados e recebidos por um `MethodCallHandler` no `MainActivity.kt`.

### 2. Introspecção de Nós de Acessibilidade
Em vez de depender de View IDs (que são frequentemente ofuscados em apps de produção), o GhostTouch implementa uma **Estratégia de Localizador Inteligente** percorrendo a árvore de **AccessibilityNodeInfo**.
- **Travessia de Nós**: O serviço inspeciona o `rootInActiveWindow` para recuperar a hierarquia atual de nós da UI.
- **Resolução de Elementos**: Busca recursivamente por nós que correspondam a atributos de texto específicos (comportamento tipo OCR) para identificar elementos interativos dinamicamente.
- **Cálculo de Limites**: Uma vez que um nó é resolvido, o sistema extrai suas coordenadas de tela (`getBoundsInScreen`) para calcular o ponto central preciso para interação.

### 3. Injeção de Gestos
Para simular uma interação autêntica do usuário, a ferramenta ignora os cliques padrão de View e utiliza a **API `dispatchGesture`**.
- **Movimento (Path Motion)**: Um objeto `Path` é construído para definir a trajetória do toque (X, Y).
- **Descrição do Traço**: Um `GestureDescription` é construído, definindo a duração e a mecânica do toque ou deslizamento.
- **Execução**: O gesto é despachado diretamente para a fila de eventos de entrada do SO, permitindo interagir com *qualquer* aplicativo, não apenas o app hospedeiro.

---

## 🚀 Funcionalidades Chave

### 📍 Localizador Inteligente de Elementos
Um mecanismo de localização robusto que encontra e interage com elementos baseados em seu texto visível. Isso imita o comportamento de um testador humano escaneando a tela por palavras-chave específicas, tornando os testes resilientes a mudanças de layout, desde que o conteúdo permaneça consistente.

### 🤖 Scripting de Macro
Suporta a execução de cenários complexos e multi-etapas. O método `runTestScript` demonstra um fluxo de ponta a ponta:
1.  **Navegação do Sistema**: Força o dispositivo para a tela inicial (`GLOBAL_ACTION_HOME`).
2.  **Lançamento de App**: Localiza e abre um aplicativo externo (ex: "Play Store") via Native Bridge.
3.  **Estados de Espera**: Implementa atrasos assíncronos para lidar com tempos de carregamento do app.
4.  **Encerramento (Tear Down)**: Retorna ao estado inicial usando gestos globais de voltar/home.

### 🔄 Controle Global do Sistema
Controle direto sobre hardware e funções de nível de SO, gerenciando efetivamente o estado do "dispositivo sob teste".
- **Home / Back / Recents**: Aciona ações globais de acessibilidade para navegar no sistema operacional fora do contexto do app.

---

## 🛠️ Configuração e Instalação

> [!IMPORTANT]
> Como este app atua como um Driver de Automação, ele requer **Permissões de Acessibilidade do Android** para funcionar.

1.  **Clone e Build**:
    ```bash
    git clone https://github.com/seuusuario/ghost-touch-qa.git
    cd ghost-touch-qa
    flutter run
    ```

2.  **Ativar Serviço de Acessibilidade**:
    *   Após instalar, navegue até **Configurações** > **Acessibilidade** no dispositivo.
    *   Encontre **GhostTouch** na lista de serviços instalados.
    *   **Ative (Toggle ON)** para conceder permissões de controle.
    *   *Nota: Sem este passo, o `MethodChannel` retornará `SERVICE_OFF`.*

---

## 💻 Tech Stack

*   **Flutter (Dart)**: Interface de Controle e Orquestração de Testes.
*   **Kotlin**: Implementação do Serviço Nativo Android.
*   **Android Accessibility API**: Motor de automação principal (`AccessibilityService`, `AccessibilityNodeInfo`, `GestureDescription`).

---

*Este projeto foi desenvolvido para demonstrar proficiência avançada em Arquitetura de Automação Mobile e desenvolvimento Android Nativo para cargos de Engenharia de QA.*
