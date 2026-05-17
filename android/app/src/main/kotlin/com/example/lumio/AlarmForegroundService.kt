package com.example.lumio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.view.KeyEvent
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class AlarmForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "alarm_plus_active"
        const val NOTIFICATION_ID = 9999
        const val ACTION_START = "alarmplus.START_ALARM_SERVICE"
        const val ACTION_STOP = "alarmplus.STOP_ALARM_SERVICE"
        const val ACTION_SNOOZE_FROM_NOTIFICATION = "alarmplus.SNOOZE_FROM_NOTIFICATION"
        const val ACTION_STOP_FROM_NOTIFICATION = "alarmplus.STOP_FROM_NOTIFICATION"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val METHOD_CHANNEL = "alarmplus/alarm_controls"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var volumeReceiver: BroadcastReceiver? = null
    private var actionReceiver: BroadcastReceiver? = null
    private var alarmId: Int = 0

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        alarmId = intent?.getIntExtra(EXTRA_ALARM_ID, 0) ?: 0

        startForeground(NOTIFICATION_ID, buildNotification(alarmId))
        acquireWakeLock()
        registerVolumeReceiver()
        registerActionReceiver()

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releaseWakeLock()
        unregisterVolumeReceiverSafe()
        unregisterActionReceiverSafe()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Notification ────────────────────────────────────────────────────────

    private fun buildNotification(alarmId: Int): Notification {
        // Full-screen intent — opens the app on lock screen
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra(EXTRA_ALARM_ID, alarmId)
        }
        val fsFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE or
                PendingIntent.FLAG_NO_CREATE.inv()  // ensure creation
        else
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        val fullScreenPi = PendingIntent.getActivity(this, 0, fullScreenIntent, fsFlags)

        // Snooze action
        val snoozePi = PendingIntent.getBroadcast(
            this, 1,
            Intent(ACTION_SNOOZE_FROM_NOTIFICATION).setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Stop action
        val stopPi = PendingIntent.getBroadcast(
            this, 2,
            Intent(ACTION_STOP_FROM_NOTIFICATION).setPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Alarm Ringing")
            .setContentText("Tap to dismiss • Swipe for options")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(fullScreenPi, true)
            .addAction(android.R.drawable.ic_media_pause, "Snooze 5 min", snoozePi)
            .addAction(android.R.drawable.ic_delete, "Stop", stopPi)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenPi)
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active Alarm",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Shown while alarm is ringing"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setBypassDnd(true)
            enableVibration(false)
        }
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(channel)
    }

    // ── Wake lock ────────────────────────────────────────────────────────────

    private fun acquireWakeLock() {
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        wakeLock = pm.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "alarmplus:AlarmWakeLock"
        ).apply { acquire(10 * 60 * 1000L) }
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    // ── Volume button → snooze ───────────────────────────────────────────────

    private fun registerVolumeReceiver() {
        volumeReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action != Intent.ACTION_MEDIA_BUTTON) return
                val event = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_KEY_EVENT) as? KeyEvent
                }
                if (event?.action == KeyEvent.ACTION_DOWN &&
                    (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN ||
                     event.keyCode == KeyEvent.KEYCODE_VOLUME_UP)) {
                    sendSnoozeToFlutter()
                }
            }
        }
        val filter = IntentFilter(Intent.ACTION_MEDIA_BUTTON).apply {
            priority = IntentFilter.SYSTEM_HIGH_PRIORITY
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(volumeReceiver, filter, RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(volumeReceiver, filter)
        }
    }

    private fun unregisterVolumeReceiverSafe() {
        try { volumeReceiver?.let { unregisterReceiver(it) } } catch (_: Exception) {}
        volumeReceiver = null
    }

    // ── Notification action buttons → snooze / stop ──────────────────────────

    private fun registerActionReceiver() {
        actionReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    ACTION_SNOOZE_FROM_NOTIFICATION -> sendSnoozeToFlutter()
                    ACTION_STOP_FROM_NOTIFICATION   -> sendStopToFlutter()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(ACTION_SNOOZE_FROM_NOTIFICATION)
            addAction(ACTION_STOP_FROM_NOTIFICATION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(actionReceiver, filter, RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(actionReceiver, filter)
        }
    }

    private fun unregisterActionReceiverSafe() {
        try { actionReceiver?.let { unregisterReceiver(it) } } catch (_: Exception) {}
        actionReceiver = null
    }

    // ── Flutter MethodChannel calls ──────────────────────────────────────────

    private fun sendSnoozeToFlutter() {
        invokeFlutterMethod("snooze", alarmId)
    }

    private fun sendStopToFlutter() {
        invokeFlutterMethod("stopFromNotification", alarmId)
        // Also self-stop the service so the notification disappears immediately
        stopSelf()
    }

    private fun invokeFlutterMethod(method: String, arg: Any?) {
        try {
            val engine = FlutterEngineCache.getInstance().get("main_engine")
            engine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, METHOD_CHANNEL).invokeMethod(method, arg)
            }
        } catch (_: Exception) {}
    }
}
