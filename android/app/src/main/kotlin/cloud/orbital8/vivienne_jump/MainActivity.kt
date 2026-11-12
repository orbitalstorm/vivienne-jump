package cloud.orbital8.vivienne_jump

import android.content.Context
import android.content.pm.ActivityInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), SensorEventListener {
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null
    private var smoothedTiltX: Float = 0.0f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "cloud.orbital8.vivienne_jump/tilt"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                registerAccelerometer()
            }

            override fun onCancel(arguments: Any?) {
                unregisterAccelerometer()
                eventSink = null
            }
        })
    }

    private fun registerAccelerometer() {
        val mgr = sensorManager ?: return
        val sensor = accelerometer ?: return
        mgr.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    private fun unregisterAccelerometer() {
        sensorManager?.unregisterListener(this)
    }

    override fun onResume() {
        super.onResume()
        if (eventSink != null) {
            registerAccelerometer()
        }
    }

    override fun onPause() {
        super.onPause()
        unregisterAccelerometer()
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_ACCELEROMETER) return
        val ax = event.values[0]
        val ay = event.values[1]
        val az = event.values[2]
        // In Android Portrait mode: tilting the phone right produces negative ax (-g_x).
        val targetTiltX = (-ax / 5.8f).coerceIn(-1.4f, 1.4f)
        smoothedTiltX += (targetTiltX - smoothedTiltX) * 0.28f
        eventSink?.success(doubleArrayOf(
            smoothedTiltX.toDouble(),
            ax.toDouble(),
            ay.toDouble(),
            az.toDouble()
        ))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
