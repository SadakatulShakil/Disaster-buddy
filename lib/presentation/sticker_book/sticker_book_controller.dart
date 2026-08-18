import 'package:get/get.dart';

import '../../core/error/result.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/collectible_sticker.dart';
import '../../domain/usecases/get_earned_collection.dart';

/// Load state for [StickerBookController], observed by the sticker book page.
enum StickerBookViewStatus { loading, data, error }

/// Loads the child's full sticker collection via the same
/// [GetEarnedCollection] source Tuku's Den uses — every badge the app can
/// award, whether from a hazard module, a cross-cutting activity, or a
/// streak milestone — keeping only the ones actually earned so far.
class StickerBookController extends GetxController {
  StickerBookController({required GetEarnedCollection getEarnedCollection})
      : _getEarnedCollection = getEarnedCollection;

  final GetEarnedCollection _getEarnedCollection;

  final Rx<StickerBookViewStatus> status = StickerBookViewStatus.loading.obs;
  final RxList<CollectibleSticker> earnedStickers = <CollectibleSticker>[].obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Loads earned badges. Exposed publicly so the UI can retry after an
  /// error.
  Future<void> load() async {
    status.value = StickerBookViewStatus.loading;
    final result = await _getEarnedCollection();
    if (result case Failure<List<CollectibleSticker>>(failure: final failure)) {
      AppLogger.error('StickerBookController failed to load collection: ${failure.message}');
      errorMessage.value = failure.message;
      status.value = StickerBookViewStatus.error;
      return;
    }

    final collection = (result as Success<List<CollectibleSticker>>).value;
    earnedStickers.value = collection.where((sticker) => sticker.earned).toList();
    status.value = StickerBookViewStatus.data;
  }
}
