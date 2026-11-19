package com.example.alarm_ekstrem

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d("BootReceiver", "Perangkat selesai reboot. Memeriksa status alarm...")
            
            // Cek SharedPreferences lokal: jika alarm sedang berdering saat HP dimatikan
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isRinging = prefs.getBoolean("flutter.is_alarm_ringing", false)

            if (isRinging) {
                Log.w("BootReceiver", "Terdeteksi reboot saat alarm berdering! Meluncurkan aplikasi darurat...")
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                context.startActivity(launchIntent)
            }
        }
    }
}
