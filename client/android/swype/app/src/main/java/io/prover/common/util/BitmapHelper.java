package io.prover.common.util;

import android.graphics.Bitmap;
import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

public class BitmapHelper {

    public static void saveRGB(int[] rgb, int width, int height, String path) {
        if (!path.startsWith("/")) {
            path = Environment.getExternalStorageDirectory().getPath() + File.separator + path;
        }

        Bitmap bitmap = Bitmap.createBitmap(rgb, width, height, Bitmap.Config.ARGB_8888);
        try {
            OutputStream os = new FileOutputStream(path);
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, os);
            os.close();
        } catch (IOException e) {
            Log.e("BitmapHelper", e.getLocalizedMessage(), e);
        }

    }
}
