package com.mercurio.chat

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MercurioApplication : Application() {
    companion object {
        const val CHANNEL_ID = "mercurio_messages"
        const val CHANNEL_NAME = "Mercurio Messages"
        const val CHANNEL_DESC = "New message notifications for Mercurio"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_HIGH).apply {
                description = CHANNEL_DESC
                enableVibration(true)
                setShowBadge(true)
            }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
