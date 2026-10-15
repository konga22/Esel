import 'package:flutter/widgets.dart';
import '../../drafts/data/local_library.dart';

/// 호의 사진: 예시 인물은 앱 에셋, 내가 발행한 호는 기기 보관함(웹은 메모리)의 사진.
ImageProvider issuePhotoProvider(String photo) =>
    photo.startsWith('assets/') ? AssetImage(photo) : localPhotoProvider(photo);
