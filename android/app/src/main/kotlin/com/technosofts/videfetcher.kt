package com.technosofts.videotoaudioconverter

import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VideoFetcher: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.video_to_audio")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getVideoFiles" -> {
                val videos = getVideoFiles()
                result.success(videos)
            }
            "getAudioFiles" -> {
                val audios = getAudioFiles()
                result.success(audios)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getVideoFiles(): List<Map<String, Any>> {
        val videoList = mutableListOf<Map<String, Any>>()
        val contentResolver: ContentResolver = context.contentResolver
        val uri: Uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_ADDED
        )

        val cursor: Cursor? = contentResolver.query(uri, projection, null, null, null)

        cursor?.use {
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)

            while (it.moveToNext()) {
                val data = it.getString(dataColumn)
                val dateAdded = it.getLong(dateAddedColumn)

                // Adding video details to the list
                videoList.add(
                    mapOf(
                        "path" to data,
                        "dateAdded" to dateAdded
                    )
                )
            }
        }
        return videoList
    }

    private fun getAudioFiles(): List<Map<String, Any>> {
        val audioList = mutableListOf<Map<String, Any>>()
        val contentResolver: ContentResolver = context.contentResolver
        val uri: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DATE_ADDED
        )

        val cursor: Cursor? = contentResolver.query(uri, projection, null, null, null)

        cursor?.use {
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)

            while (it.moveToNext()) {
                val data = it.getString(dataColumn)
                val dateAdded = it.getLong(dateAddedColumn)

                // Adding audio details to the list
                audioList.add(
                    mapOf(
                        "path" to data,
                        "dateAdded" to dateAdded
                    )
                )
            }
        }
        return audioList
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
