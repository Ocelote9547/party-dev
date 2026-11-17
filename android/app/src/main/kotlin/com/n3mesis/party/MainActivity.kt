package com.n3mesis.party

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var cameraMaxPlugin: CameraMaxPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cameraMaxPlugin = CameraMaxPlugin(this, flutterEngine)
    }
}
