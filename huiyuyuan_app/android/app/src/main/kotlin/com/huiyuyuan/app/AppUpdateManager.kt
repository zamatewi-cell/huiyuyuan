package com.huiyuyuan.app

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import java.io.File
import java.security.MessageDigest

class AppUpdateManager(
    private val context: Context,
    private val activityProvider: () -> MainActivity?,
) {
    companion object {
        const val channelName = "com.huiyuyuan.app/app_update"

        private const val prefsName = "app_update_download"
        private const val apkMimeType = "application/vnd.android.package-archive"

        private const val keyDownloadId = "download_id"
        private const val keyFileName = "file_name"
        private const val keyVersion = "version"
        private const val keyBuildNumber = "build_number"
        private const val keyUrl = "url"
        private const val keyUrls = "urls"
        private const val keyUrlIndex = "url_index"
        private const val keyMimeType = "mime_type"
        private const val keyExpectedSha256 = "expected_sha256"
        private const val keyExpectedSizeBytes = "expected_size_bytes"
        private const val keyFailureMessage = "failure_message"
    }

    private data class DownloadRequest(
        val urls: List<String>,
        val fileName: String,
        val version: String,
        val buildNumber: Int,
        val title: String,
        val description: String,
        val mimeType: String,
        val expectedSha256: String,
        val expectedSizeBytes: Long,
    )

    private val downloadManager: DownloadManager by lazy {
        context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    }

    private val prefs by lazy {
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
    }

    fun handle(call: MethodCall): Map<String, Any?> {
        return when (call.method) {
            "enqueueUpdateDownload" -> enqueueUpdateDownload(call)
            "getUpdateDownloadState" -> getUpdateDownloadState(call)
            "resumeDownloadedUpdateInstall" -> resumeDownloadedUpdateInstall(call)
            "clearUpdateDownloadState" -> {
                pruneInstalledState(call.argument<Int>("currentBuildNumber") ?: 0)
                removeTrackedDownloadIfNeeded()
                idleState()
            }

            else -> idleState(message = "not_implemented")
        }
    }

    private fun enqueueUpdateDownload(call: MethodCall): Map<String, Any?> {
        val request = requestFromCall(call) ?: return failedState("missing_download_url")
        if (request.urls.isEmpty()) {
            return failedState("missing_download_url")
        }

        val existingState = currentDownloadState(currentBuildNumber = 0)
        if (existingState["buildNumber"] == request.buildNumber &&
            existingState["status"] in setOf("queued", "running", "paused", "successful")
        ) {
            return existingState
        }

        return startDownload(
            downloadInfo = request,
            urlIndex = 0,
            retryMessage = null,
        )
    }

    private fun startDownload(
        downloadInfo: DownloadRequest,
        urlIndex: Int,
        retryMessage: String?,
    ): Map<String, Any?> {
        val url = downloadInfo.urls.getOrNull(urlIndex)?.trim().orEmpty()
        if (url.isEmpty()) {
            return failedState("missing_download_url")
        }

        removeTrackedDownloadIfNeeded()
        val destinationDir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: return failedState("downloads_dir_unavailable")
        val destinationFile = File(destinationDir, downloadInfo.fileName)
        if (destinationFile.exists()) {
            destinationFile.delete()
        }

        val downloadRequest = DownloadManager.Request(Uri.parse(url)).apply {
            setTitle(downloadInfo.title)
            setDescription(downloadInfo.description)
            setMimeType(downloadInfo.mimeType)
            setNotificationVisibility(
                DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED,
            )
            setAllowedOverMetered(true)
            setAllowedOverRoaming(false)
            addRequestHeader("Accept", "${downloadInfo.mimeType},*/*")
            setDestinationInExternalFilesDir(
                context,
                Environment.DIRECTORY_DOWNLOADS,
                downloadInfo.fileName,
            )
        }

        val downloadId = try {
            downloadManager.enqueue(downloadRequest)
        } catch (error: Exception) {
            return retryNextSourceIfAvailable(
                downloadInfo,
                urlIndex,
                error.message ?: "enqueue_failed",
            )
                ?: failedState(error.message ?: "enqueue_failed")
        }

        prefs.edit()
            .putLong(keyDownloadId, downloadId)
            .putString(keyFileName, downloadInfo.fileName)
            .putString(keyVersion, downloadInfo.version)
            .putInt(keyBuildNumber, downloadInfo.buildNumber)
            .putString(keyUrl, url)
            .putString(keyUrls, downloadInfo.urls.joinToString("\n"))
            .putInt(keyUrlIndex, urlIndex)
            .putString(keyMimeType, downloadInfo.mimeType)
            .putString(keyExpectedSha256, downloadInfo.expectedSha256)
            .putLong(keyExpectedSizeBytes, downloadInfo.expectedSizeBytes)
            .remove(keyFailureMessage)
            .apply()

        return annotateState(
            currentDownloadState(currentBuildNumber = 0),
            retryMessage,
        )
    }

    private fun getUpdateDownloadState(call: MethodCall): Map<String, Any?> {
        val currentBuildNumber = call.argument<Int>("currentBuildNumber") ?: 0
        return currentDownloadState(currentBuildNumber)
    }

    @Suppress("DEPRECATION")
    private fun resumeDownloadedUpdateInstall(call: MethodCall): Map<String, Any?> {
        val currentBuildNumber = call.argument<Int>("currentBuildNumber") ?: 0
        val state = currentDownloadState(currentBuildNumber)
        if (state["status"] != "successful") {
            return state
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !context.packageManager.canRequestPackageInstalls()
        ) {
            val settingsIntent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}"),
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startIntent(settingsIntent)
            return mutableState("permission_required", message = "install_permission_required")
        }

        val apkFile = trackedApkFile() ?: return failedState("downloaded_apk_missing")
        if (!apkFile.exists()) {
            clearStoredDownloadState()
            return failedState("downloaded_apk_missing")
        }

        val apkUri = try {
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                apkFile,
            )
        } catch (error: IllegalArgumentException) {
            return failedState(error.message ?: "file_provider_failed")
        }

        val installIntent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            data = apkUri
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_RETURN_RESULT, false)
        }

        return if (startIntent(installIntent)) {
            mutableState("installing")
        } else {
            failedState("installer_unavailable")
        }
    }

    private fun currentDownloadState(currentBuildNumber: Int): Map<String, Any?> {
        pruneInstalledState(currentBuildNumber)

        val downloadId = prefs.getLong(keyDownloadId, -1L)
        if (downloadId <= 0L) {
            val failureMessage = prefs.getString(keyFailureMessage, "").orEmpty().trim()
            if (failureMessage.isNotEmpty()) {
                return failedState(failureMessage)
            }
            return idleState()
        }

        val query = DownloadManager.Query().setFilterById(downloadId)
        val cursor = downloadManager.query(query) ?: return missingState()
        cursor.use {
            if (!it.moveToFirst()) {
                val retryState = retryNextSourceIfAvailable(
                    storedDownloadRequest(),
                    prefs.getInt(keyUrlIndex, 0),
                    "download_record_missing",
                )
                if (retryState != null) {
                    return retryState
                }
                return markTerminalFailure("download_record_missing")
            }

            val status = it.getInt(it.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val downloadedBytes = it.getLong(
                it.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR),
            )
            val totalBytes = it.getLong(
                it.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES),
            )
            val reason = it.getInt(it.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
            val progress = if (totalBytes > 0L) {
                ((downloadedBytes * 100L) / totalBytes).toInt().coerceIn(0, 100)
            } else {
                0
            }

            if (status == DownloadManager.STATUS_FAILED) {
                val failureMessage = "download_failed_$reason"
                val retryState = retryNextSourceIfAvailable(
                    storedDownloadRequest(),
                    prefs.getInt(keyUrlIndex, 0),
                    failureMessage,
                )
                if (retryState != null) {
                    return retryState
                }
                return markTerminalFailure(failureMessage)
            }

            if (status == DownloadManager.STATUS_SUCCESSFUL) {
                val verificationFailure = verifyTrackedDownload()
                if (verificationFailure != null) {
                    val retryState = retryNextSourceIfAvailable(
                        storedDownloadRequest(),
                        prefs.getInt(keyUrlIndex, 0),
                        verificationFailure,
                    )
                    if (retryState != null) {
                        return retryState
                    }
                    return markTerminalFailure(verificationFailure)
                }
            }

            return mutableState(
                status = when (status) {
                    DownloadManager.STATUS_PENDING -> "queued"
                    DownloadManager.STATUS_RUNNING -> "running"
                    DownloadManager.STATUS_PAUSED -> "paused"
                    DownloadManager.STATUS_SUCCESSFUL -> "successful"
                    else -> "idle"
                },
                downloadId = downloadId,
                progress = progress,
                downloadedBytes = downloadedBytes,
                totalBytes = totalBytes,
                buildNumber = prefs.getInt(keyBuildNumber, 0),
                version = prefs.getString(keyVersion, "").orEmpty(),
            )
        }
    }

    private fun pruneInstalledState(currentBuildNumber: Int) {
        val trackedBuildNumber = prefs.getInt(keyBuildNumber, 0)
        if (trackedBuildNumber > 0 && currentBuildNumber >= trackedBuildNumber) {
            removeTrackedDownloadIfNeeded()
        }
    }

    private fun removeTrackedDownloadIfNeeded() {
        val downloadId = prefs.getLong(keyDownloadId, -1L)
        if (downloadId > 0L) {
            runCatching { downloadManager.remove(downloadId) }
        }
        trackedApkFile()?.let { file ->
            if (file.exists()) {
                file.delete()
            }
        }
        clearStoredDownloadState()
    }

    private fun trackedApkFile(): File? {
        val fileName = prefs.getString(keyFileName, "").orEmpty()
        if (fileName.isBlank()) {
            return null
        }
        val baseDir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: return null
        return File(baseDir, fileName)
    }

    private fun clearStoredDownloadState() {
        prefs.edit()
            .remove(keyDownloadId)
            .remove(keyFileName)
            .remove(keyVersion)
            .remove(keyBuildNumber)
            .remove(keyUrl)
            .remove(keyUrls)
            .remove(keyUrlIndex)
            .remove(keyMimeType)
            .remove(keyExpectedSha256)
            .remove(keyExpectedSizeBytes)
            .remove(keyFailureMessage)
            .apply()
    }

    private fun requestFromCall(call: MethodCall): DownloadRequest? {
        val rawUrls = call.argument<List<Any?>>("urls") ?: emptyList()
        val parsedUrls = rawUrls
            .mapNotNull { it?.toString()?.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
            .toMutableList()
        val fallbackUrl = call.argument<String>("url")?.trim().orEmpty()
        if (fallbackUrl.isNotEmpty() && fallbackUrl !in parsedUrls) {
            parsedUrls.add(fallbackUrl)
        }

        if (parsedUrls.isEmpty()) {
            return null
        }

        val version = call.argument<String>("version")?.trim().orEmpty()
        val buildNumber = call.argument<Int>("buildNumber") ?: 0
        return DownloadRequest(
            urls = parsedUrls,
            fileName = call.argument<String>("fileName")?.trim().takeUnless {
                it.isNullOrEmpty()
            } ?: "huiyuyuan-update.apk",
            version = version,
            buildNumber = buildNumber,
            title = call.argument<String>("title")?.trim().takeUnless {
                it.isNullOrEmpty()
            } ?: "HuiYuYuan Update",
            description = call.argument<String>("description")?.trim().takeUnless {
                it.isNullOrEmpty()
            } ?: "Downloading update package",
            mimeType = call.argument<String>("mimeType")?.trim().takeUnless {
                it.isNullOrEmpty()
            } ?: apkMimeType,
            expectedSha256 = call.argument<String>("sha256")?.trim()?.lowercase().orEmpty(),
            expectedSizeBytes = parseLong(call.argument<Any?>("expectedSizeBytes")) ?: 0L,
        )
    }

    private fun storedDownloadRequest(): DownloadRequest? {
        val urls = prefs.getString(keyUrls, "").orEmpty()
            .split('\n')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
        if (urls.isEmpty()) {
            return null
        }

        val version = prefs.getString(keyVersion, "").orEmpty()
        return DownloadRequest(
            urls = urls,
            fileName = prefs.getString(keyFileName, "").orEmpty().ifBlank {
                "huiyuyuan-update.apk"
            },
            version = version,
            buildNumber = prefs.getInt(keyBuildNumber, 0),
            title = "HuiYuYuan Update",
            description = if (version.isNotBlank()) {
                "Downloading version $version"
            } else {
                "Downloading update package"
            },
            mimeType = prefs.getString(keyMimeType, apkMimeType).orEmpty().ifBlank {
                apkMimeType
            },
            expectedSha256 = prefs.getString(keyExpectedSha256, "").orEmpty().trim().lowercase(),
            expectedSizeBytes = prefs.getLong(keyExpectedSizeBytes, 0L),
        )
    }

    private fun retryNextSourceIfAvailable(
        request: DownloadRequest?,
        currentUrlIndex: Int,
        failureMessage: String,
    ): Map<String, Any?>? {
        val retryRequest = request ?: return null
        val nextUrlIndex = currentUrlIndex + 1
        if (nextUrlIndex >= retryRequest.urls.size) {
            return null
        }
        return startDownload(
            downloadInfo = retryRequest,
            urlIndex = nextUrlIndex,
            retryMessage = "retrying_alternate_url:$failureMessage",
        )
    }

    private fun verifyTrackedDownload(): String? {
        val apkFile = trackedApkFile() ?: return "downloaded_apk_missing"
        if (!apkFile.exists()) {
            return "downloaded_apk_missing"
        }

        val expectedSizeBytes = prefs.getLong(keyExpectedSizeBytes, 0L)
        if (expectedSizeBytes > 0L && apkFile.length() != expectedSizeBytes) {
            return "download_size_mismatch"
        }

        val expectedSha256 = prefs.getString(keyExpectedSha256, "").orEmpty().trim().lowercase()
        if (expectedSha256.isBlank()) {
            return null
        }

        val actualSha256 = calculateSha256(apkFile)
        return if (actualSha256 == expectedSha256) {
            null
        } else {
            "download_checksum_mismatch"
        }
    }

    private fun calculateSha256(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(1024 * 1024)
            while (true) {
                val read = input.read(buffer)
                if (read <= 0) {
                    break
                }
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { byte -> "%02x".format(byte) }
    }

    private fun markTerminalFailure(message: String): Map<String, Any?> {
        removeTrackedDownloadIfNeeded()
        prefs.edit()
            .putString(keyFailureMessage, message)
            .apply()
        return failedState(message)
    }

    private fun parseLong(value: Any?): Long? {
        return when (value) {
            null -> null
            is Int -> value.toLong()
            is Long -> value
            is Number -> value.toLong()
            else -> value.toString().trim().takeIf { it.isNotEmpty() }?.toLongOrNull()
        }
    }

    private fun annotateState(
        state: Map<String, Any?>,
        message: String?,
    ): Map<String, Any?> {
        if (message.isNullOrBlank()) {
            return state
        }
        return HashMap(state).apply {
            put("message", message)
        }
    }

    private fun startIntent(intent: Intent): Boolean {
        val activity = activityProvider()
        return try {
            val launchContext = activity ?: context
            launchContext.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun mutableState(
        status: String,
        downloadId: Long? = prefs.getLong(keyDownloadId, -1L).takeIf { it > 0L },
        progress: Int = 0,
        downloadedBytes: Long = 0L,
        totalBytes: Long = 0L,
        buildNumber: Int = prefs.getInt(keyBuildNumber, 0),
        version: String = prefs.getString(keyVersion, "").orEmpty(),
        message: String? = null,
    ): Map<String, Any?> {
        return hashMapOf(
            "status" to status,
            "downloadId" to downloadId,
            "progress" to progress,
            "downloadedBytes" to downloadedBytes,
            "totalBytes" to totalBytes,
            "buildNumber" to buildNumber,
            "version" to version,
            "message" to message,
        )
    }

    private fun idleState(message: String? = null): Map<String, Any?> =
        mutableState(status = "idle", downloadId = null, buildNumber = 0, version = "", message = message)

    private fun missingState(): Map<String, Any?> = mutableState(
        status = "failed",
        message = "download_record_missing",
    )

    private fun failedState(message: String): Map<String, Any?> =
        mutableState(status = "failed", message = message)
}
