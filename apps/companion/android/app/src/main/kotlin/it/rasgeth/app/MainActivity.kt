package it.rasgeth.app

import android.Manifest
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiInfo
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PatternMatcher
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The first start from the app (G40.8): Rasgeth OS's temporary network, Rasgeth-Setup-XXXX,
 * joined with WifiNetworkSpecifier (Android 10+). The system shows its own sheet with the
 * networks that match the prefix; the person picks one. The network has no internet and is
 * bound to this app only (bindProcessToNetwork): the phone's own connection stays the default
 * for everything else, and the app's sockets (Dart's included) go to Rasgeth. Leaving releases
 * the request and the binding.
 *
 * Permissions: NEARBY_WIFI_DEVICES on Android 13+ (neverForLocation), the fine location before
 * (the system asks it for a network request). A refusal is "denied": the app offers joining by
 * hand, never a silent retry.
 */
class MainActivity : FlutterActivity() {
    private val main = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null
    private var pendingJoin: (() -> Unit)? = null
    private var pendingDenied: (() -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "join" -> {
                    val prefix = call.argument<String>("prefix") ?: PREFIX
                    val passphrase = call.argument<String>("passphrase") ?: ""
                    val ssid = call.argument<String>("ssid")
                    join(prefix, passphrase, ssid, result)
                }
                "leave" -> {
                    leave()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        // G42.9: the phone's time zone by its IANA name, for the automations' recipes.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "rgcompanion/timezone").setMethodCallHandler { call, result ->
            if (call.method == "zone") result.success(java.util.TimeZone.getDefault().id) else result.notImplemented()
        }
    }

    private fun answer(result: MethodChannel.Result, state: String, ssid: String? = null, message: String? = null) {
        main.post { result.success(mapOf("state" to state, "ssid" to ssid, "message" to message)) }
    }

    private fun neededPermission(): String =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) Manifest.permission.NEARBY_WIFI_DEVICES
        else Manifest.permission.ACCESS_FINE_LOCATION

    private fun join(prefix: String, passphrase: String, ssid: String?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            answer(result, "unsupported", message = "android_9")
            return
        }
        // Only the temporary network's own names: nothing else is ever asked for.
        if (prefix != PREFIX || (ssid != null && !SSID.matches(ssid))) {
            answer(result, "failed", message = "bad_name")
            return
        }
        val perm = neededPermission()
        if (checkSelfPermission(perm) != PackageManager.PERMISSION_GRANTED) {
            pendingJoin = { request(prefix, passphrase, ssid, result) }
            pendingDenied = { answer(result, "denied", message = perm) }
            requestPermissions(arrayOf(perm), PERMISSION_REQUEST)
            return
        }
        request(prefix, passphrase, ssid, result)
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray) {
        super.onRequestPermissionsResult(code, permissions, grants)
        if (code != PERMISSION_REQUEST) return
        val go = pendingJoin
        val no = pendingDenied
        pendingJoin = null
        pendingDenied = null
        if (grants.isNotEmpty() && grants.all { it == PackageManager.PERMISSION_GRANTED }) go?.invoke() else no?.invoke()
    }

    private fun request(prefix: String, passphrase: String, ssid: String?, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return
        leave()
        val spec = WifiNetworkSpecifier.Builder().apply {
            if (ssid != null) setSsid(ssid) else setSsidPattern(PatternMatcher(prefix, PatternMatcher.PATTERN_PREFIX))
            if (passphrase.isNotEmpty()) setWpa2Passphrase(passphrase)
        }.build()
        val req = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(spec)
            .build()
        val cm = getSystemService(ConnectivityManager::class.java)
        var answered = false
        val cb = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                cm.bindProcessToNetwork(network)
                if (answered) return
                answered = true
                answer(result, "joined", ssid = ssidOf(cm, network) ?: ssid)
            }

            override fun onUnavailable() {
                if (answered) return
                answered = true
                callback = null
                // The person closed the sheet, or no matching network came in time.
                answer(result, "cancelled")
            }

            override fun onLost(network: Network) {
                cm.bindProcessToNetwork(null)
            }
        }
        callback = cb
        try {
            cm.requestNetwork(req, cb, JOIN_TIMEOUT_MS)
        } catch (e: SecurityException) {
            callback = null
            answer(result, "denied", message = e.message)
        } catch (e: RuntimeException) {
            callback = null
            answer(result, "failed", message = e.message)
        }
    }

    /** The network's name, when the system tells it (it may be hidden without the location). */
    private fun ssidOf(cm: ConnectivityManager, network: Network): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
        val info = cm.getNetworkCapabilities(network)?.transportInfo as? WifiInfo ?: return null
        val s = info.ssid?.trim('"') ?: return null
        return if (SSID.matches(s)) s else null
    }

    private fun leave() {
        val cm = getSystemService(ConnectivityManager::class.java)
        cm.bindProcessToNetwork(null)
        callback?.let {
            try {
                cm.unregisterNetworkCallback(it)
            } catch (_: IllegalArgumentException) {
                // Already released by the system.
            }
        }
        callback = null
    }

    override fun onDestroy() {
        leave()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "rgcompanion/setup_wifi"
        private const val PREFIX = "Rasgeth-Setup-"
        private val SSID = Regex("^Rasgeth-Setup-[A-Za-z0-9]{1,16}$")
        private const val PERMISSION_REQUEST = 4080
        private const val JOIN_TIMEOUT_MS = 120_000
    }
}
