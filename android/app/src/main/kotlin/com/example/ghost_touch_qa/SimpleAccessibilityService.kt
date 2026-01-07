package com.example.ghost_touch_qa // <--- CONFIRA SE O PACOTE É ESSE MESMO NO SEU ARQUIVO

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class SimpleAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("GhostTouch", "Serviço Conectado!")
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Aqui nós "ouvimos" o que acontece na tela (ex: app abriu, texto mudou)
        // Por enquanto, deixaremos vazio.
    }

    override fun onInterrupt() {
        Log.d("GhostTouch", "Serviço Interrompido")
        instance = null
    }

    // Função mágica para clicar em uma coordenada (X, Y)
    fun click(x: Float, y: Float) {
        Log.d("GhostTouch", "Tentando clicar em: $x, $y")
        val path = Path()
        path.moveTo(x, y)
        
        // Simula um toque rápido (tap)
        val builder = GestureDescription.Builder()
        val gestureDescription = builder
            .addStroke(GestureDescription.StrokeDescription(path, 10, 100))
            .build()

        dispatchGesture(gestureDescription, null, null)
    }

    fun performGlobal(actionId: Int): Boolean {
        // actionId 1 = Home, 2 = Back, etc (definidos pelo Android)
        Log.d("GhostTouch", "Executando Ação Global ID: $actionId")
        return performGlobalAction(actionId)
    }

    companion object {
        var instance: SimpleAccessibilityService? = null
    }

    fun clickByText(text: String): Boolean {
        Log.d("GhostTouch", "Procurando por texto: $text")
        
        // Pega a janela ativa
        val rootNode = rootInActiveWindow ?: return false
        
        // Busca todos os nós que contêm o texto (case insensitive)
        val list = rootNode.findAccessibilityNodeInfosByText(text)
        
        if (list.isNullOrEmpty()) {
            Log.d("GhostTouch", "Texto '$text' não encontrado.")
            return false
        }

        // Pega o primeiro elemento encontrado
        val node = list[0]
        
        // Descobre o retângulo (as bordas) desse elemento na tela
        val rect = android.graphics.Rect()
        node.getBoundsInScreen(rect)
        
        // Calcula o ponto central exato do elemento
        val centerX = rect.centerX().toFloat()
        val centerY = rect.centerY().toFloat()

        Log.d("GhostTouch", "Elemento encontrado em: $rect. Clicando no centro: $centerX, $centerY")
        
        // Reusa nossa função de clique por coordenada!
        click(centerX, centerY)
        
        // Limpa a memória do nó (boa prática em acessibilidade)
        node.recycle()
        return true
    }
}