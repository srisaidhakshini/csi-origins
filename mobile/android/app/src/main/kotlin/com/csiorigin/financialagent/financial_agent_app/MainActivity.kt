package com.csiorigin.financialagent.financial_agent_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "OriginSMS"
    private val SMS_CHANNEL = "com.csiorigin.financialagent/sms_stream"
    private val SMS_READER_CHANNEL = "com.csiorigin.financialagent/sms_reader"
    private val SMS_PERMISSION_CODE = 101

    private var eventSink: EventChannel.EventSink? = null
    private var smsReceiver: BroadcastReceiver? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingLimit: Int = 100

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Real-Time Incoming SMS Stream (Broadcast Receiver)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    ensurePermissionsAndListen()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterSmsReceiver()
                    eventSink = null
                }
            }
        )

        // 2. Historical SMS Inbox Reader MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_READER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (hasSmsPermissions()) {
                        result.success(true)
                    } else {
                        pendingResult = result
                        requestSmsPermissions()
                    }
                }
                "readInboxSms" -> {
                    val limit = call.argument<Int>("limit") ?: 100
                    if (!hasSmsPermissions()) {
                        pendingResult = result
                        pendingLimit = limit
                        requestSmsPermissions()
                    } else {
                        val pastSmsList = fetchInboxSms(limit)
                        result.success(pastSmsList)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasSmsPermissions(): Boolean {
        val readGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
        val receiveGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
        return readGranted && receiveGranted
    }

    private fun requestSmsPermissions() {
        Log.d(TAG, "Requesting runtime SMS permissions from user...")
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_SMS, Manifest.permission.RECEIVE_SMS),
            SMS_PERMISSION_CODE
        )
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == SMS_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            Log.d(TAG, "SMS Permission Request Result: granted = $granted")

            if (granted) {
                registerSmsReceiver()
            }

            pendingResult?.let { res ->
                if (granted) {
                    val list = fetchInboxSms(pendingLimit)
                    res.success(list)
                } else {
                    res.success(emptyList<Map<String, Any>>())
                }
                pendingResult = null
            }
        }
    }

    private fun ensurePermissionsAndListen() {
        if (hasSmsPermissions()) {
            registerSmsReceiver()
        } else {
            requestSmsPermissions()
        }
    }

    private fun fetchInboxSms(limit: Int): List<Map<String, Any>> {
        val smsList = mutableListOf<Map<String, Any>>()

        try {
            val uri: Uri = Uri.parse("content://sms/inbox")
            val projection = arrayOf(
                "address",
                "body",
                "date"
            )

            val sortOrder = if (limit > 0) "date DESC LIMIT $limit" else "date DESC LIMIT 500"

            val cursor: Cursor? = contentResolver.query(
                uri,
                projection,
                null,
                null,
                sortOrder
            )

            Log.d(TAG, "Querying SMS inbox: cursor = $cursor, count = ${cursor?.count ?: 0}")

            cursor?.use {
                val addressIdx = it.getColumnIndex("address")
                val bodyIdx = it.getColumnIndex("body")
                val dateIdx = it.getColumnIndex("date")

                while (it.moveToNext()) {
                    val sender = if (addressIdx != -1) it.getString(addressIdx) ?: "" else ""
                    val body = if (bodyIdx != -1) it.getString(bodyIdx) ?: "" else ""
                    val date = if (dateIdx != -1) it.getLong(dateIdx) else System.currentTimeMillis()

                    if (body.isNotBlank()) {
                        smsList.add(
                            mapOf(
                                "sender" to sender,
                                "body" to body,
                                "timestamp" to date
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error querying content://sms/inbox: ${e.message}", e)
        }

        Log.d(TAG, "Fetched ${smsList.size} SMS messages from inbox")
        return smsList
    }

    private fun registerSmsReceiver() {
        if (smsReceiver != null) return

        smsReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (Telephony.Sms.Intents.SMS_RECEIVED_ACTION == intent?.action) {
                    val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                    if (!messages.isNullOrEmpty()) {
                        val sender = messages[0].originatingAddress ?: "Unknown"
                        val fullBody = messages.joinToString(separator = "") { it.messageBody ?: "" }
                        val timestamp = messages[0].timestampMillis

                        Log.d(TAG, "Live SMS Broadcast Received from: $sender")

                        val payload = mapOf(
                            "sender" to sender,
                            "body" to fullBody,
                            "timestamp" to timestamp
                        )

                        runOnUiThread {
                            eventSink?.success(payload)
                        }
                    }
                }
            }
        }

        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
        registerReceiver(smsReceiver, filter)
        Log.d(TAG, "Live SMS BroadcastReceiver registered successfully")
    }

    private fun unregisterSmsReceiver() {
        smsReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {}
            smsReceiver = null
        }
    }

    override fun onDestroy() {
        unregisterSmsReceiver()
        super.onDestroy()
    }
}
