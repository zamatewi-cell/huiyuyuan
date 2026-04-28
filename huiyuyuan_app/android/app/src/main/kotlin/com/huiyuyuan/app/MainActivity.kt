package com.huiyuyuan.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var appUpdateManager: AppUpdateManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appUpdateManager = AppUpdateManager(
            context = applicationContext,
            activityProvider = { this },
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AppUpdateManager.channelName,
        ).setMethodCallHandler { call, result ->
            result.success(appUpdateManager.handle(call))
        }
    }
}
