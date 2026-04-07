package com.example.planet_kit_flutter.camera

import android.content.ContentResolver
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log

class BitmapUtil {
    companion object {
        private val TAG: String = "BitmapUtil"
        private fun calculateInSampleSize(
            options: BitmapFactory.Options,
            reqWidth: Int,
            reqHeight: Int
        ): Int {
            // Raw height and width of image
            val (height: Int, width: Int) = options.run { outHeight to outWidth }
            var inSampleSize = 1

            Log.d(
                TAG,
                "height=${height} width=${width} reqWidth=${reqWidth} reqHeight=${reqHeight}"
            )

            if (height > reqHeight || width > reqWidth) {

                val halfHeight: Int = height / 2
                val halfWidth: Int = width / 2

                // Calculate the largest inSampleSize value that is a power of 2 and keeps both
                // height and width larger than the requested height and width.
                while (halfHeight / inSampleSize >= reqHeight || halfWidth / inSampleSize >= reqWidth) {
                    inSampleSize *= 2
                }
            }

            Log.d(TAG, "inSampleSize=${inSampleSize}")
            return inSampleSize
        }

        fun decodeSampledBitmapFromByteArray(
            receiveBuffer: ByteArray,
            offset: Int,
            reqWidth: Int,
            reqHeight: Int
        ): Bitmap? {
            // First decode with inJustDecodeBounds=true to check dimensions
            return BitmapFactory.Options().run {
                inJustDecodeBounds = true
                BitmapFactory.decodeByteArray(
                    receiveBuffer,
                    0,
                    receiveBuffer.size, this
                )

                BitmapFactory.decodeByteArray(receiveBuffer, offset, receiveBuffer.size, this)

                // Calculate inSampleSize
                inSampleSize = calculateInSampleSize(this, reqWidth, reqHeight)

                // Decode bitmap with inSampleSize set
                inJustDecodeBounds = false

                BitmapFactory.decodeByteArray(receiveBuffer, offset, receiveBuffer.size, this)
            }
        }

        fun makeBitmap(
            uri: Uri,
            contentResolver: ContentResolver,
            reqWidth: Int,
            reqHeight: Int
        ): Bitmap? {
            val options = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
                contentResolver.openInputStream(uri)?.use { inputStream ->
                    BitmapFactory.decodeStream(inputStream, null, this)
                }
                inSampleSize = calculateInSampleSize(this, reqWidth, reqHeight)
                inJustDecodeBounds = false
            }

            return contentResolver.openInputStream(uri)?.use { inputStream ->
                BitmapFactory.decodeStream(inputStream, null, options)
            }
        }
    }
}