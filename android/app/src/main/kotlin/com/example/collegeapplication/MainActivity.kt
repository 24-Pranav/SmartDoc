package com.example.collegeapplication

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager.LayoutParams

class MainActivity: FlutterActivity() {
    override fun onResume() {
        super.onResume()
        window.addFlags(LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun onPause() {
        super.onPause()
        window.clearFlags(LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
