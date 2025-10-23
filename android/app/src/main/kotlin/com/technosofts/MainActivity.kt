package com.technosofts.videotoaudioconverter

import android.content.ContentResolver
import android.content.ContentValues
import android.database.Cursor
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.net.Uri
import android.content.ContentUris
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

import android.app.Activity
import android.content.Context
import android.media.RingtoneManager
import java.io.OutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.video_to_audio"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure the folder is created when the app starts
        createMergeMusicFolder()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "convertVideoToAudio" -> {
    val videoPath = call.argument<String>("videoPath") ?: ""
    val fileName = call.argument<String>("fileName") ?: "default_audio" // Use a default file name if not provided
    val audioPath = convertVideoToAudio(videoPath, fileName)
    if (audioPath != null) {
        result.success(audioPath)
    } else {
        result.error("ERROR", "Failed to convert video to audio", null)
    }}
            "setRingtone" -> {
            val filePath = call.argument<String>("filePath") ?: ""
            val success = setRingtone(filePath, this)
            if (success) {
                result.success("Ringtone set successfully!")
            } else {
                result.error("SET_RINGTONE_ERROR", "Failed to set ringtone", null)
            }
        }
                "getVideosFromMediaStore" -> {
                    val videoPaths = getAllVideoPaths()
                    result.success(videoPaths)
                }
                 "getAllAudioFiles" -> {
            val audioFiles = getAllAudioFiles()
            result.success(audioFiles)
        }
                "getFileFromUri" -> {
            val uri = call.argument<String>("uri")
            if (uri != null) {
                val byteArray = getFileFromUri(uri)
                if (byteArray != null) {
                    result.success(byteArray)
                } else {
                    result.error("FILE_READ_ERROR", "Failed to read file from URI", null)
                }
            } else {
                result.error("INVALID_ARGUMENT", "URI is null", null)
            }
        }
                "mergeAudioFiles" -> {
                     val filePaths = call.argument<List<String>>("filePaths")
                val outputFileName = call.argument<String>("outputFileName")
                if (filePaths != null && outputFileName != null) {
                    val success = mergeAudioFiles(filePaths, outputFileName)
                    if (success) {
                        result.success("Audio files merged successfully!")
                    } else {
                        result.error("MERGE_FAILED", "Failed to merge audio files", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "File paths or output file name missing", null)
                }
            }
                else -> result.notImplemented()
            }
        }
    }


private fun setRingtone(filePath: String, context: Context): Boolean {
    return try {
        val file = File(filePath)
        if (!file.exists()) {
            throw IllegalArgumentException("File does not exist: $filePath")
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "CustomRingtone.mp3") // Display name of the file
            put(MediaStore.MediaColumns.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.IS_RINGTONE, true)
        }

        val contentUri = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val newUri = context.contentResolver.insert(contentUri, values)

        if (newUri != null) {
            // Copy file content to the new Uri
            context.contentResolver.openOutputStream(newUri).use { outputStream ->
                file.inputStream().copyTo(outputStream!!)
            }

            // Set as default ringtone
            RingtoneManager.setActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE, newUri)
        }

        true
    } catch (e: Exception) {
        e.printStackTrace()
        false
    }
}


private fun createMergeMusicFolder() {
    val musicDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC)

    // Create "MergedAudio" folder
    val mergeMusicFolder = File(musicDir, "MergedAudio")
    if (!mergeMusicFolder.exists()) {
        if (mergeMusicFolder.mkdirs()) {
            println("Folder created: ${mergeMusicFolder.absolutePath}")
        } else {
            println("Failed to create folder: ${mergeMusicFolder.absolutePath}")
        }
    } else {
        println("Folder already exists: ${mergeMusicFolder.absolutePath}")
    }

    // Create "Format Converter" folder
    val formatConverterFolder = File(musicDir, "Format Converter")
    if (!formatConverterFolder.exists()) {
        if (formatConverterFolder.mkdirs()) {
            println("Folder created: ${formatConverterFolder.absolutePath}")
        } else {
            println("Failed to create folder: ${formatConverterFolder.absolutePath}")
        }
    } else {
        println("Folder already exists: ${formatConverterFolder.absolutePath}")
    }
}

private fun convertVideoToAudio(videoPath: String, fileName: String): String? {
    try {
        val extractor = MediaExtractor()
        extractor.setDataSource(videoPath)

        var audioTrackIndex = -1
        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME)
            if (mime?.startsWith("audio/") == true) {
                audioTrackIndex = i
                extractor.selectTrack(i)
                break
            }
        }

        if (audioTrackIndex == -1) {
            throw IllegalArgumentException("No audio track found in the video file.")
        }

        val audioFile = getAudioFile(fileName) ?: return null
        val muxer = MediaMuxer(audioFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val format = extractor.getTrackFormat(audioTrackIndex)
        val newTrackIndex = muxer.addTrack(format)
        muxer.start()

        val buffer = ByteArray(1024 * 1024)
        val byteBuffer = java.nio.ByteBuffer.wrap(buffer)
        val bufferInfo = android.media.MediaCodec.BufferInfo()

        while (true) {
            val sampleSize = extractor.readSampleData(byteBuffer, 0)
            if (sampleSize < 0) {
                break
            }
            bufferInfo.size = sampleSize
            bufferInfo.presentationTimeUs = extractor.sampleTime
            bufferInfo.flags = extractor.sampleFlags
            muxer.writeSampleData(newTrackIndex, byteBuffer, bufferInfo)
            extractor.advance()
        }

        muxer.stop()
        muxer.release()
        extractor.release()

        return audioFile.absolutePath
    } catch (e: Exception) {
        e.printStackTrace()
        return null
    }
}

private fun getAudioFile(fileName: String): File? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val contentValues = ContentValues().apply {
            put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_MUSIC + "/VideoMusic")
            put(MediaStore.Audio.Media.TITLE, fileName)
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mpeg")
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, contentValues)

        uri?.let {
            val tempFile = File.createTempFile("temp_audio", ".mp3")
            tempFile.renameTo(File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "VideoMusic/$fileName.mp3"))
            return File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC).toString() + "/VideoMusic/$fileName.mp3")
        }
        null
    } else {
        val musicDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "VideoMusic")
        if (!musicDir.exists()) {
            musicDir.mkdirs()
        }
        File(musicDir, "$fileName.mp3")
    }
}


private fun getAllAudioFiles(): List<String> {
    val audioFiles = mutableListOf<String>()
    val projection = arrayOf(
        MediaStore.Audio.Media._ID,
        MediaStore.Audio.Media.DATA // This column contains the file path
    )
    
    // Query for all audio files
    val selection = "${MediaStore.Audio.Media.DATA} LIKE ?"
    val selectionArgs = arrayOf("%/storage/emulated/0/%") // Filter for internal storage path

    val query = contentResolver.query(
        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
        projection,
        selection,
        selectionArgs,
        null
    )

    query?.use { cursor ->
        val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
        val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)

        while (cursor.moveToNext()) {
            val data = cursor.getString(dataColumn)  // Get the file path

            // Add file path directly to the list if it's in internal storage
            if (data.startsWith("/storage/emulated/0")) {
                audioFiles.add(data)  // Store the file path
            }
        }
    }

    return audioFiles
}






private fun getFileFromUri(uri: String): ByteArray? {
    return try {
        val parsedUri = Uri.parse(uri)
        contentResolver.openInputStream(parsedUri)?.use { inputStream ->
            inputStream.readBytes()
        }
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
}





    private fun mergeAudioFiles(filePaths: List<String>, outputFileName: String): Boolean {
        return try {
            val outputDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "MergedAudio")
            if (!outputDir.exists()) {
                outputDir.mkdirs()
            }
            val outputFile = File(outputDir, outputFileName)

            FileOutputStream(outputFile).use { fos ->
                filePaths.forEach { path ->
                    val file = File(path)
                    if (file.exists()) {
                        file.inputStream().use { input ->
                            input.copyTo(fos)
                        }
                    }
                }
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun getMixedAudioFolder(): File {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "MixedAudio")
        } else {
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "MixedAudio")
        }
    }

    private fun getAllVideoPaths(): List<String> {
        val videoPaths = mutableListOf<String>()
        val collection: Uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        val projection = arrayOf(MediaStore.Video.Media.DATA)

        val cursor: Cursor? = contentResolver.query(collection, projection, null, null, null)
        cursor?.use {
            val dataIndex = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA)
            while (it.moveToNext()) {
                videoPaths.add(it.getString(dataIndex))
            }
        }
        return videoPaths
    }
}
