package com.example.ghost_touch_qa // <--- CONFIRA SE O PACOTE É ESSE MESMO NO SEU ARQUIVO

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Bundle
import android.util.Log
import android.view.accessibility.AccessibilityEvent

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
        val gestureDescription =
                builder.addStroke(GestureDescription.StrokeDescription(path, 10, 100)).build()

        dispatchGesture(gestureDescription, null, null)
    }

    fun swipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long) {
        Log.d("GhostTouch", "Swipe de ($startX, $startY) para ($endX, $endY) em ${duration}ms")

        val path = Path()
        path.moveTo(startX, startY)
        path.lineTo(endX, endY)

        val builder = GestureDescription.Builder()
        // O segundo parâmetro '0' é o atraso inicial, o terceiro é a duração do gesto
        val stroke = GestureDescription.StrokeDescription(path, 0, duration)

        builder.addStroke(stroke)
        dispatchGesture(builder.build(), null, null)
    }

    fun performGlobal(actionId: Int): Boolean {
        // actionId 1 = Home, 2 = Back, etc (definidos pelo Android)
        Log.d("GhostTouch", "Executando Ação Global ID: $actionId")
        return performGlobalAction(actionId)
    }

    // Função recursiva para ler TUDO na tela
    fun dumpScreenText(): List<String> {
        val rootNode = rootInActiveWindow ?: return emptyList()
        val textList = mutableListOf<String>()

        collectText(rootNode, textList)
        return textList
    }

    private fun collectText(
            node: android.view.accessibility.AccessibilityNodeInfo?,
            list: MutableList<String>
    ) {
        if (node == null) return

        if (node.text != null && node.text.isNotEmpty()) {
            list.add(node.text.toString())
        }

        for (i in 0 until node.childCount) {
            collectText(node.getChild(i), list)
        }
    }

    companion object {
        var instance: SimpleAccessibilityService? = null
    }

    fun clickByText(text: String): Boolean {
        Log.d("GhostTouch", "Procurando por texto: $text")

        val rootNode = rootInActiveWindow ?: return false

        // Busca TODOS os elementos que CONTÉM o texto
        val list = rootNode.findAccessibilityNodeInfosByText(text)

        if (list.isNullOrEmpty()) {
            Log.d("GhostTouch", "Texto '$text' não encontrado.")
            return false
        }

        // --- LÓGICA NOVA: PRIORIDADE PARA MATCH EXATO ---

        // 1. Tenta achar alguém que seja CLICÁVEL E tenha o texto EXATO (Igualzinho)
        // Isso evita clicar no visor que tem "25 +" quando queremos só "2"
        var targetNode =
                list.firstOrNull { node ->
                    val nodeText = node.text?.toString() ?: ""
                    val nodeDesc = node.contentDescription?.toString() ?: ""

                    node.isClickable &&
                            (nodeText.equals(text, ignoreCase = true) ||
                                    nodeDesc.equals(text, ignoreCase = true))
                }

        // 2. Se não achar exato, tenta achar apenas CLICÁVEL (Fallback)
        if (targetNode == null) {
            Log.d("GhostTouch", "Match exato não encontrado. Tentando match parcial...")
            targetNode = list.firstOrNull { it.isClickable }
        }

        // 3. Se nem assim achar, desiste (ou pega o primeiro da lista se você quiser forçar)
        if (targetNode == null) {
            Log.d("GhostTouch", "Nenhum elemento clicável encontrado para '$text'.")
            return false
        }

        val rect = android.graphics.Rect()
        targetNode.getBoundsInScreen(rect)

        val centerX = rect.centerX().toFloat()
        val centerY = rect.centerY().toFloat()

        Log.d(
                "GhostTouch",
                "Alvo: '${targetNode.text}'. Rect: $rect. Clicando em: $centerX, $centerY"
        )

        click(centerX, centerY)

        // Limpa a memória
        list.forEach { it.recycle() }

        return true
    }

    fun inputText(text: String): Boolean {
        Log.d("GhostTouch", "Tentando digitar texto: $text")
        val rootNode = rootInActiveWindow ?: return false

        // 1. Tenta encontrar o elemento que está FOCADO (o cursor está nele)
        val focusedNode =
                rootNode.findFocus(android.view.accessibility.AccessibilityNodeInfo.FOCUS_INPUT)

        if (focusedNode != null && focusedNode.isEditable) {
            Log.d("GhostTouch", "Elemento focado encontrado. Digitando...")
            val arguments = Bundle()
            arguments.putCharSequence(
                    android.view.accessibility.AccessibilityNodeInfo
                            .ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    text
            )
            focusedNode.performAction(
                    android.view.accessibility.AccessibilityNodeInfo.ACTION_SET_TEXT,
                    arguments
            )
            focusedNode.recycle()
            return true
        }

        // 2. Fallback: Se nada estiver focado, procura o primeiro EditText na tela
        Log.d("GhostTouch", "Nenhum elemento focado. Buscando EditText na tela...")
        val queue = java.util.ArrayDeque<android.view.accessibility.AccessibilityNodeInfo>()
        queue.add(rootNode)

        while (!queue.isEmpty()) {
            val node = queue.removeFirst()

            if (node.isEditable) {
                Log.d("GhostTouch", "EditText encontrado! Digitando...")
                val arguments = Bundle()
                arguments.putCharSequence(
                        android.view.accessibility.AccessibilityNodeInfo
                                .ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                        text
                )
                node.performAction(
                        android.view.accessibility.AccessibilityNodeInfo.ACTION_SET_TEXT,
                        arguments
                )
                node.recycle()
                return true
            }

            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                if (child != null) queue.add(child)
            }
        }

        Log.d("GhostTouch", "Nenhum campo de texto encontrado.")
        return false
    }

    fun clickByDescription(desc: String): Boolean {
        Log.d("GhostTouch", "Procurando por ContentDescription: $desc")
        return clickByText(desc)
    }
}
