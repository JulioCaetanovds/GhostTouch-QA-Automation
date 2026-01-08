package com.example.ghost_touch_qa

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ghost_touch/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            val service = SimpleAccessibilityService.instance

            if (service == null) {
                result.error("SERVICE_OFF", "Serviço desligado. Ative nas configurações.", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "click" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    service.click(x, y)
                    result.success(true)
                }
                "swipe" -> {
                    val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                    val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                    val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                    val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 500L

                    service.swipe(startX, startY, endX, endY, duration)

                    // ESSENCIAL: Avisar o Flutter que terminou para ele destravar o await
                    result.success(true)
                }
                "clickByText" -> { // <--- NOVO COMANDO
                    val text = call.argument<String>("text") ?: ""
                    val found = service.clickByText(text)
                    if (found) {
                        result.success(true)
                    } else {
                        result.error("NOT_FOUND", "Texto '$text' não encontrado na tela.", null)
                    }
                }
                "globalAction" -> {
                    val actionName = call.argument<String>("action")
                    val service = SimpleAccessibilityService.instance

                    if (service == null) {
                        result.error("SERVICE_OFF", "Serviço desligado.", null)
                        return@setMethodCallHandler
                    }

                    // Mapeamento de Strings para Constantes do Android
                    val actionId =
                            when (actionName) {
                                "HOME" ->
                                        android.accessibilityservice.AccessibilityService
                                                .GLOBAL_ACTION_HOME // = 2
                                "BACK" ->
                                        android.accessibilityservice.AccessibilityService
                                                .GLOBAL_ACTION_BACK // = 1
                                "RECENTS" ->
                                        android.accessibilityservice.AccessibilityService
                                                .GLOBAL_ACTION_RECENTS // = 3
                                "NOTIFICATIONS" ->
                                        android.accessibilityservice.AccessibilityService
                                                .GLOBAL_ACTION_NOTIFICATIONS // = 4
                                else -> 0
                            }

                    if (actionId != 0) {
                        val success = service.performGlobal(actionId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ACTION", "Ação '$actionName' desconhecida.", null)
                    }
                }
                "readScreen" -> {
                    val texts = service.dumpScreenText()
                    result.success(texts)
                }
                "inputText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val success = service.inputText(text)
                    result.success(success)
                }
                "clickByDescription" -> {
                    val desc = call.argument<String>("desc") ?: ""
                    val found = service.clickByDescription(desc)
                    if (found) {
                        result.success(true)
                    } else {
                        result.error("NOT_FOUND", "Descrição '$desc' não encontrada.", null)
                    }
                }
                "isServiceActive" -> {
                    val service = SimpleAccessibilityService.instance
                    result.success(service != null)
                }
            }
        }
    }
}
