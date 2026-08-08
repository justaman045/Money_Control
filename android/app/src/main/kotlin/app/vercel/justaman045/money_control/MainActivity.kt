package app.vercel.justaman045.money_control

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import kotlin.concurrent.thread

class MainActivity : FlutterFragmentActivity() {
    private val UPI_CHANNEL = "money_control/upi"
    private val UPI_REQUEST_CODE = 1001
    private val UPI_RESULT_TIMEOUT_MS = 60_000L

    private var pendingResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Survives config-change recreation: the FlutterEngine is reused across
    // rotations, so a half-finished UPI flow's Result can be handed to the
    // recreated activity instead of being dropped (which would hang the Dart
    // Future until its own timeout).
    private var pendingResultStatic: MethodChannel.Result? = null

    private val upiTimeoutRunnable = Runnable {
        val result = pendingResult ?: return@Runnable
        pendingResult = null
        result.error("TIMEOUT", "UPI app did not respond", null)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Predictive back: required for Android 13+ system back gestures to
        // drive Flutter's own back handling. Accessed reflectively because the
        // method is API 33+ and not always on the compile classpath.
        try {
            val m = Activity::class.java.getMethod(
                "enableOnBackInvokedCallback", Boolean::class.javaPrimitiveType
            )
            m.invoke(this, true)
        } catch (_: Exception) {
            // Pre-API 33: nothing to enable.
        }
        super.onCreate(savedInstanceState)
        pendingResultStatic?.let { resumed ->
            pendingResultStatic = null
            pendingResult = resumed
            mainHandler.postDelayed(upiTimeoutRunnable, UPI_RESULT_TIMEOUT_MS)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPI_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInstallerPackageName") {
                    thread {
                        val installer = try {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                packageManager.getInstallSourceInfo(packageName).installingPackageName
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getInstallerPackageName(packageName)
                            }
                        } catch (e: Exception) { null }
                        runOnUiThread { result.success(installer) }
                    }
                } else if (call.method == "installedUpiApps") {
                    thread {
                        val apps = try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("upi://pay"))
                            packageManager.queryIntentActivities(intent, 0)
                                .map { ri ->
                                    val label = try {
                                        ri.loadLabel(packageManager).toString()
                                    } catch (e: Exception) {
                                        ri.activityInfo.packageName
                                    }
                                    mapOf("package" to ri.activityInfo.packageName, "label" to label)
                                }
                        } catch (e: Exception) {
                            emptyList<Map<String, String>>()
                        }
                        runOnUiThread { result.success(apps) }
                    }
                } else if (call.method == "pay") {
                    if (pendingResult != null) {
                        result.error("BUSY", "A UPI payment is already in progress", null)
                        return@setMethodCallHandler
                    }

                    val packageName = call.argument<String>("packageName")
                    val amount     = call.argument<String>("amount") ?: ""
                    val payeeName  = call.argument<String>("payeeName") ?: ""
                    val payeeVpa   = call.argument<String>("payeeVpa") ?: ""
                    val note       = call.argument<String>("note") ?: ""

                    if (payeeVpa.isEmpty()) {
                        result.error("MISSING_VPA", "payeeVpa (pa) is required for UPI payments", null)
                        return@setMethodCallHandler
                    }
                    // Amount must be a valid non-negative decimal with at most 2 fraction digits.
                    if (!amount.matches(Regex("""\d+(\.\d{1,2})?"""))) {
                        result.error("INVALID_AMOUNT", "Invalid UPI amount: $amount", null)
                        return@setMethodCallHandler
                    }

                    val uri = Uri.parse(
                        "upi://pay?pa=${Uri.encode(payeeVpa)}" +
                            "&pn=${Uri.encode(payeeName)}" +
                            "&am=$amount" +
                            "&cu=INR" +
                            "&tn=${Uri.encode(note)}" +
                            "&tr=${UUID.randomUUID()}"
                    )
                    val intent = Intent(Intent.ACTION_VIEW, uri)
                    if (!packageName.isNullOrEmpty()) intent.setPackage(packageName)

                    pendingResult = result
                    mainHandler.postDelayed(upiTimeoutRunnable, UPI_RESULT_TIMEOUT_MS)
                    try {
                        startActivityForResult(intent, UPI_REQUEST_CODE)
                    } catch (e: ActivityNotFoundException) {
                        pendingResult = null
                        mainHandler.removeCallbacks(upiTimeoutRunnable)
                        result.error("APP_NOT_FOUND", "No UPI app found", null)
                    } catch (e: Exception) {
                        pendingResult = null
                        mainHandler.removeCallbacks(upiTimeoutRunnable)
                        result.error("UPI_FAILED", "Could not launch UPI app: ${e.message}", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != UPI_REQUEST_CODE) return
        mainHandler.removeCallbacks(upiTimeoutRunnable)
        val result = pendingResult ?: return
        pendingResult = null

        val response = data?.getStringExtra("response")
            ?: data?.dataString
            ?: ""

        when (resultCode) {
            Activity.RESULT_OK -> {
                // App confirmed success even if it returned no response payload —
                // never report that as a silent cancellation.
                result.success(if (response.isEmpty()) "Status=SUCCESS" else response)
            }
            Activity.RESULT_CANCELED -> result.success("")
            else -> result.success("Status=FAILED&responseCode=$resultCode")
        }
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(upiTimeoutRunnable)
        if (isFinishing) {
            // Real teardown: cancel so the Dart-side Future doesn't hang.
            try {
                pendingResult?.error("CANCELLED", "Payment cancelled (activity destroyed)", null)
            } catch (_: Exception) {
                // Flutter engine may already be torn down.
            }
            pendingResult = null
        } else {
            // Config-change recreation (rotation, resize): keep the payment
            // alive and hand the result to the recreated activity.
            pendingResultStatic = pendingResult
            pendingResult = null
        }
        super.onDestroy()
    }
}
