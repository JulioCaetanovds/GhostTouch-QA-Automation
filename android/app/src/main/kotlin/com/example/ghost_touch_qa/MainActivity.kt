package com.example.ghost_touch_qa

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ghost_touch/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                    val actionId = when (actionName) {
                        "HOME" -> android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME // = 2
                        "BACK" -> android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK // = 1
                        "RECENTS" -> android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_RECENTS // = 3
                        "NOTIFICATIONS" -> android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_NOTIFICATIONS // = 4
                        else -> 0
                    }

                    if (actionId != 0) {
                        val success = service.performGlobal(actionId)
                        result.success(success)
                    } else {
                        result.error("INVALID_ACTION", "Ação '$actionName' desconhecida.", null)
                    }
                }
            }
        }
    }
}
