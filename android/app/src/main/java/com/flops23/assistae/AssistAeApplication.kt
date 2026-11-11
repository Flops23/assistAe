package com.flops23.assistae

import android.Manifest
import android.app.Application
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.runBlocking

internal const val SOCIAL_CHANNEL = "assistae_social"

class AssistAeApplication : Application() {
    internal val backend by lazy { SupabaseClient(this) }
    internal var pushAvailable: Boolean = false
        private set

    override fun onCreate() {
        super.onCreate()
        val appId = BuildConfig.FIREBASE_APP_ID
        val projectId = BuildConfig.FIREBASE_PROJECT_ID
        val apiKey = BuildConfig.FIREBASE_API_KEY
        val senderId = BuildConfig.FIREBASE_SENDER_ID
        if (listOf(appId, projectId, apiKey, senderId).any(String::isBlank)) return
        val options = FirebaseOptions.Builder().setApplicationId(appId).setProjectId(projectId)
            .setApiKey(apiKey).setGcmSenderId(senderId).build()
        if (FirebaseApp.getApps(this).isEmpty()) FirebaseApp.initializeApp(this, options)
        getSystemService(NotificationManager::class.java).createNotificationChannel(
            NotificationChannel(SOCIAL_CHANNEL, "Convites e solicitações", NotificationManager.IMPORTANCE_DEFAULT).apply {
                lockscreenVisibility = Notification.VISIBILITY_PRIVATE
            },
        )
        pushAvailable = true
    }

    internal fun registerPush() {
        if (pushAvailable && canNotify(this)) FirebaseMessaging.getInstance().register()
    }
}

internal fun canNotify(context: Context): Boolean =
    (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
        PackageManager.PERMISSION_GRANTED) &&
        context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()

class AssistAeMessagingService : FirebaseMessagingService() {
    override fun onRegistered(installationId: String) {
        if (!canNotify(this)) return
        updateInstallation("register_push_installation", installationId)
    }

    override fun onUnregistered(installationId: String) {
        updateInstallation("unregister_push_installation", installationId)
    }

    private fun updateInstallation(operation: String, installationId: String) {
        val backend = (application as AssistAeApplication).backend
        try {
            runBlocking { backend.rpc(operation, json("p_fid" to installationId)) }
        } catch (_: Exception) {
            // A later registration callback resynchronizes the installation.
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        if (!canNotify(this)) return
        val kind = message.data["kind"]
        val (id, description) = when (kind) {
            "friend_request" -> 21 to "Você recebeu uma solicitação de amizade."
            "room_invite" -> 22 to "Você recebeu um convite para uma sala."
            else -> return
        }
        val tap = PendingIntent.getActivity(
            this, id, Intent(this, MainActivity::class.java).putExtra("kind", kind),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(this, SOCIAL_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("assistAe")
            .setContentText(description)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setContentIntent(tap)
            .setAutoCancel(true)
            .build()
        getSystemService(NotificationManager::class.java).notify(id, notification)
    }
}
