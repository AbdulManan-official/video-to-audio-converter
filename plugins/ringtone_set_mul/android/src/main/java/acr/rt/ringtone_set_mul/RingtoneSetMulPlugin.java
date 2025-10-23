package acr.rt.ringtone_set_mul;

import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.provider.Settings;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class RingtoneSetMulPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private Context mContext;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        mContext = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "ringtone_set");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    private boolean isSystemWritePermissionGranted() {
        boolean retVal = true;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            retVal = Settings.System.canWrite(mContext);
        }
        return retVal;
    }

    private void requestSystemWritePermission() {
        if (!isSystemWritePermissionGranted()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
                intent.setData(Uri.parse("package:" + mContext.getPackageName()));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                mContext.startActivity(intent);
            }
        }
    }

    private static String guessMimeTypeFromExtension(String path) {
        String mimeType = null;
        String fileExtension = "";
        int i = path.lastIndexOf('.');
        if (i > 0) fileExtension = path.substring(i + 1);
        if (!fileExtension.isEmpty()) {
            mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(fileExtension);
        }
        return mimeType;
    }

    private static String guessMimeTypeFromStream(InputStream is) throws IOException {
        if (!is.markSupported()) return null;
        is.mark(16);
        int c1 = is.read();
        int c2 = is.read();
        int c3 = is.read();
        int c4 = is.read();
        int c5 = is.read();
        int c6 = is.read();
        int c7 = is.read();
        int c8 = is.read();
        int c9 = is.read();
        int c10 = is.read();
        int c11 = is.read();
        is.reset();

        if (c1 == 0x2E && c2 == 0x73 && c3 == 0x6E && c4 == 0x64) return "audio/basic";
        if (c1 == 0x64 && c2 == 0x6E && c3 == 0x73 && c4 == 0x2E) return "audio/basic";
        if (c1 == 'R' && c2 == 'I' && c3 == 'F' && c4 == 'F') return "audio/x-wav";
        if (c1 == 0x23 && c2 == 0x21 && c3 == 0x41 && c4 == 0x4D && c5 == 0x52) return "audio/amr";
        if (c1 == 0x66 && c2 == 0x74 && c3 == 0x79 && c4 == 0x70 && c5 == 0x69 && c6 == 0x73
                && c7 == 0x6F && c8 == 0x6D) return "audio/mp4";
        if (c1 == 0x00 && c2 == 0x00 && c3 == 0x00 && c4 == 0x20 && c5 == 0x66 && c6 == 0x74
                && c7 == 0x79 && c8 == 0x70 && c9 == 0x4D && c10 == 0x34 && c11 == 0x41) return "audio/mp4";
        if (c1 == 0x4D && c2 == 54 && c3 == 68 && c4 == 64) return "audio/midi";
        if (c1 == 0x1A && c2 == 0x45 && c3 == 0xDF && c4 == 0xA3) return "audio/x-matroska";
        if (c1 == 0x30 && c2 == 0x26 && c3 == 0xB2 && c4 == 0x75 && c5 == 0x8E && c6 == 0x66
                && c7 == 0xCF && c8 == 0x11) return "audio/x-ms-wma";
        if (c1 == 0x4F && c2 == 0x67 && c3 == 0x67 && c4 == 0x53) return "audio/ogg";
        if (c1 == 0x49 && c2 == 0x44 && c3 == 0x33) return "audio/mpeg";
        if (c1 == 0xFF && (c2 == 0xFB || c2 == 0xF3 || c2 == 0xF2)) return "audio/mpeg";

        return null;
    }

    private static String getMIMEType(String absolutePath, String downloadedMimeType) {
        String mimeType = guessMimeTypeFromExtension(absolutePath);
        if (mimeType != null) return mimeType;
        try (InputStream inputStream = new BufferedInputStream(new FileInputStream(absolutePath))) {
            mimeType = guessMimeTypeFromStream(inputStream);
        } catch (Exception e) {
            e.printStackTrace();
        }
        if (mimeType != null) return mimeType;
        if (downloadedMimeType != null) return downloadedMimeType.equals("audio/wav") ? "audio/x-wav" : downloadedMimeType;
        return "audio/mpeg";
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    private void setThings(String path, String downloadedMimeType, boolean isRingt, boolean isNotif, boolean isAlarm) {
        requestSystemWritePermission();
        File mFile = new File(path);
        if (!mFile.exists()) return;

        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DATA, mFile.getAbsolutePath());
        values.put(MediaStore.MediaColumns.TITLE, "Custom ringtone");
        values.put(MediaStore.MediaColumns.MIME_TYPE, getMIMEType(mFile.getAbsolutePath(), downloadedMimeType));
        values.put(MediaStore.MediaColumns.SIZE, mFile.length());
        values.put(MediaStore.Audio.Media.ARTIST, "Ringtone app");
        values.put(MediaStore.Audio.Media.IS_RINGTONE, isRingt);
        values.put(MediaStore.Audio.Media.IS_NOTIFICATION, isNotif);
        values.put(MediaStore.Audio.Media.IS_ALARM, isAlarm);
        values.put(MediaStore.Audio.Media.IS_MUSIC, false);

        Uri newUri;
        if (Build.VERSION.SDK_INT > 28) {
            newUri = mContext.getContentResolver().insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values);
        } else {
            Uri uri = MediaStore.Audio.Media.getContentUriForPath(mFile.getAbsolutePath());
            mContext.getContentResolver().delete(uri, MediaStore.MediaColumns.DATA + "=\"" + mFile.getAbsolutePath() + "\"", null);
            newUri = mContext.getContentResolver().insert(uri, values);
        }

        if (isNotif) RingtoneManager.setActualDefaultRingtoneUri(mContext, RingtoneManager.TYPE_NOTIFICATION, newUri);
        if (isRingt) RingtoneManager.setActualDefaultRingtoneUri(mContext, RingtoneManager.TYPE_RINGTONE, newUri);
        if (isAlarm) RingtoneManager.setActualDefaultRingtoneUri(mContext, RingtoneManager.TYPE_ALARM, newUri);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String path;
        String mimeType;
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + Build.VERSION.RELEASE);
                break;
            case "getPlatformSdk":
                result.success(Build.VERSION.SDK_INT);
                break;
            case "setRingtone":
                path = call.argument("path");
                mimeType = call.argument("mimeType");
                setThings(path, mimeType, true, false, false);
                result.success(true);
                break;
            case "setNotification":
                path = call.argument("path");
                mimeType = call.argument("mimeType");
                setThings(path, mimeType, false, true, false);
                result.success(true);
                break;
            case "setAlarm":
                path = call.argument("path");
                mimeType = call.argument("mimeType");
                setThings(path, mimeType, false, false, true);
                result.success(true);
                break;
            case "setMultiple":
                path = call.argument("path");
                mimeType = call.argument("mimeType");
                boolean isRingt = call.argument("isRingt");
                boolean isNotif = call.argument("isNotif");
                boolean isAlarm = call.argument("isAlarm");
                setThings(path, mimeType, isRingt, isNotif, isAlarm);
                result.success(true);
                break;
            case "isWriteGranted":
                result.success(isSystemWritePermissionGranted());
                break;
            case "reqSystemPermissions":
                requestSystemWritePermission();
                result.success(true);
                break;
            default:
                result.notImplemented();
        }
    }
}
