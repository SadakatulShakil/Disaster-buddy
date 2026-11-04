import 'dart:async';

import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';

import '../utils/app_logger.dart';
import '../../presentation/widgets/update_ready_dialog.dart';

/// Checks the Play Store for a newer version of the app and drives Google's
/// in-app update flow. Android-only — a silent no-op on every other
/// platform, since Play Core has no equivalent there.
///
/// Policy: an update flagged with a high priority in the Play Console
/// (`inAppUpdatePriority` on the release) is force-installed via the
/// blocking "immediate" flow. Anything lower downloads quietly in the
/// background via the "flexible" flow, then prompts the player to restart
/// once it's ready — never interrupts whatever they're doing mid-download.
/// Registered as a permanent singleton in `InitialBinding`, same as
/// `SoundService`/`NarrationService`.
class AppUpdateService {
  /// Play Console in-app update priority (0-5) at/above which an update is
  /// forced immediately instead of offered as a flexible background update.
  static const int _criticalUpdatePriority = 4;

  StreamSubscription<InstallStatus>? _installSub;

  Future<void> checkForUpdate() async {
    if (!GetPlatform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      final isCritical = info.updatePriority >= _criticalUpdatePriority;

      if (isCritical && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        _listenForFlexibleDownload();
      } else if (info.immediateUpdateAllowed) {
        // Neither critical nor flexible-eligible, but immediate is all
        // Play will offer (e.g. the store's own staleness threshold) —
        // take it rather than leave the user stuck on an old version.
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e, stackTrace) {
      // Never let a flaky Play Services call affect app startup.
      AppLogger.error('In-app update check failed', error: e, stackTrace: stackTrace);
    }
  }

  void _listenForFlexibleDownload() {
    _installSub?.cancel();
    _installSub = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) {
        _installSub?.cancel();
        _installSub = null;
        showUpdateReadyDialog();
      }
    });
  }
}
