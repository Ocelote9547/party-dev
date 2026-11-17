package com.n3mesis.party

import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CameraMetadata
import android.hardware.camera2.CaptureRequest
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.util.Size
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.Semaphore
import java.util.concurrent.TimeUnit

class CameraMaxPlugin(private val context: Context, engine: FlutterEngine) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.n3mesis.party/camera_max")
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    init {
        channel.setMethodCallHandler(this)
    }

    private fun startBackgroundThread() {
        backgroundThread = HandlerThread("CameraMaxBackground").also { it.start() }
        backgroundHandler = Handler(backgroundThread!!.looper)
    }

    private fun stopBackgroundThread() {
        backgroundThread?.quitSafely()
        try {
            backgroundThread?.join()
            backgroundThread = null
            backgroundHandler = null
        } catch (_: InterruptedException) {}
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isUltraHighResSupported" -> {
                result.success(isUltraHighResSupported())
            }
            "getMaxJpegSize" -> {
                result.success(getMaxJpegSize())
            }
            "takeUltraHighResPhoto" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "Missing path", null)
                    return
                }
                takeUltraHighResPhoto(path, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun isUltraHighResSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = getBackCameraId(manager) ?: return false
            val chars = manager.getCameraCharacteristics(cameraId)
            val caps = chars.get(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES) ?: return false
            caps.contains(CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES_ULTRA_HIGH_RESOLUTION_SENSOR)
        } catch (_: Exception) { false }
    }

    private fun getMaxJpegSize(): Map<String, Any>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        return try {
            val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = getBackCameraId(manager) ?: return null
            val chars = manager.getCameraCharacteristics(cameraId)
            val maxMap = chars.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION) ?: return null
            val sizes = maxMap.getOutputSizes(ImageFormat.JPEG) ?: return null
            val max = sizes.maxByOrNull { it.width * it.height } ?: return null
            mapOf("width" to max.width, "height" to max.height, "cameraId" to cameraId)
        } catch (_: Exception) { null }
    }

    private fun getBackCameraId(manager: CameraManager): String? {
        for (id in manager.cameraIdList) {
            val chars = manager.getCameraCharacteristics(id)
            val facing = chars.get(CameraCharacteristics.LENS_FACING)
            if (facing == CameraCharacteristics.LENS_FACING_BACK) return id
        }
        return manager.cameraIdList.firstOrNull()
    }

    private fun takeUltraHighResPhoto(path: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.error("UNSUPPORTED", "Requires API 31+", null)
            return
        }
        if (!isUltraHighResSupported()) {
            result.error("UNSUPPORTED", "ULTRA_HIGH_RESOLUTION_SENSOR not supported", null)
            return
        }
        startBackgroundThread()
        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = getBackCameraId(manager)
        if (cameraId == null) {
            stopBackgroundThread()
            result.error("NO_CAMERA", "No back camera", null)
            return
        }
        try {
            val chars = manager.getCameraCharacteristics(cameraId)
            val maxMap = chars.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP_MAXIMUM_RESOLUTION)
            val jpegSizes = maxMap?.getOutputSizes(ImageFormat.JPEG)
            val maxSize = jpegSizes?.maxByOrNull { it.width * it.height }
            if (maxSize == null) {
                stopBackgroundThread()
                result.error("NO_SIZE", "No max JPEG size", null)
                return
            }
            val reader = ImageReader.newInstance(maxSize.width, maxSize.height, ImageFormat.JPEG, 2)
            val file = File(path)
            file.parentFile?.mkdirs()

            val openSemaphore = Semaphore(0)
            var cameraDevice: CameraDevice? = null
            var openError: String? = null

            manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(camera: CameraDevice) {
                    cameraDevice = camera
                    openSemaphore.release()
                }
                override fun onDisconnected(camera: CameraDevice) {
                    camera.close()
                    openError = "Disconnected"
                    openSemaphore.release()
                }
                override fun onError(camera: CameraDevice, error: Int) {
                    camera.close()
                    openError = "Error $error"
                    openSemaphore.release()
                }
            }, backgroundHandler)

            if (!openSemaphore.tryAcquire(5, TimeUnit.SECONDS)) {
                reader.close()
                stopBackgroundThread()
                result.error("TIMEOUT", "Camera open timeout", null)
                return
            }
            if (openError != null || cameraDevice == null) {
                reader.close()
                stopBackgroundThread()
                result.error("OPEN_FAILED", openError, null)
                return
            }

            val device = cameraDevice!!

            // Capture session with max res surface
            val captureSemaphore = Semaphore(0)
            var session: CameraCaptureSession? = null
            var sessionError: String? = null

            device.createCaptureSession(
                listOf(reader.surface),
                object : CameraCaptureSession.StateCallback() {
                    override fun onConfigured(s: CameraCaptureSession) {
                        session = s
                        captureSemaphore.release()
                    }
                    override fun onConfigureFailed(s: CameraCaptureSession) {
                        sessionError = "Configure failed"
                        captureSemaphore.release()
                    }
                },
                backgroundHandler
            )

            if (!captureSemaphore.tryAcquire(5, TimeUnit.SECONDS) || session == null) {
                reader.close()
                device.close()
                stopBackgroundThread()
                result.error("SESSION_FAILED", sessionError, null)
                return
            }

            val captureBuilder = device.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE)
            captureBuilder.addTarget(reader.surface)
            captureBuilder.set(CaptureRequest.JPEG_QUALITY, 100.toByte())
            captureBuilder.set(CaptureRequest.SENSOR_PIXEL_MODE, CameraMetadata.SENSOR_PIXEL_MODE_MAXIMUM_RESOLUTION)
            // Auto everything
            captureBuilder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)

            val captureDone = Semaphore(0)
            var captureError: String? = null

            reader.setOnImageAvailableListener({ r ->
                var image: android.media.Image? = null
                try {
                    image = r.acquireNextImage()
                    val buffer: ByteBuffer = image.planes[0].buffer
                    val bytes = ByteArray(buffer.remaining())
                    buffer.get(bytes)
                    FileOutputStream(file).use { it.write(bytes) }
                } catch (e: Exception) {
                    captureError = e.message
                } finally {
                    image?.close()
                    captureDone.release()
                }
            }, backgroundHandler)

            session!!.capture(captureBuilder.build(), object : CameraCaptureSession.CaptureCallback() {
                override fun onCaptureCompleted(session: CameraCaptureSession, request: CaptureRequest, result: android.hardware.camera2.TotalCaptureResult) {
                    // done via ImageReader
                }
            }, backgroundHandler)

            if (!captureDone.tryAcquire(8, TimeUnit.SECONDS)) {
                captureError = captureError ?: "Capture timeout"
            }

            // Cleanup
            try { session?.close() } catch (_: Exception) {}
            try { device.close() } catch (_: Exception) {}
            reader.close()
            stopBackgroundThread()

            if (captureError != null) {
                result.error("CAPTURE_FAILED", captureError, null)
                return
            }
            if (!file.exists() || file.length() == 0L) {
                result.error("NO_FILE", "File not created", null)
                return
            }
            result.success(mapOf(
                "path" to file.absolutePath,
                "width" to maxSize.width,
                "height" to maxSize.height
            ))

        } catch (e: Exception) {
            try { stopBackgroundThread() } catch (_: Exception) {}
            result.error("EXCEPTION", e.message, null)
        }
    }
}
