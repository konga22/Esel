import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/time/service_date.dart';
import '../../publishing/domain/rules/publish_rule.dart';
import '../domain/cover_draft.dart';

/// 메모리에만 둔 사진(웹 시연)의 photoPath 접두사.
const String memoryPhotoPrefix = 'memory:';

/// photoPath가 기기 파일이든 메모리 사진이든 같은 방식으로 그린다.
ImageProvider localPhotoProvider(String photoPath) =>
    photoPath.startsWith(memoryPhotoPrefix)
    ? MemoryImage(LocalLibrary._memoryPhotos[photoPath] ?? Uint8List(0))
    : FileImage(File(photoPath));

class LocalLibrary extends ChangeNotifier {
  /// null이면 저장하지 않는 메모리 보관함이다(웹은 기기 파일을 쓸 수 없다).
  final Directory? directory;
  LocalLibrary(Directory this.directory);
  LocalLibrary.inMemory() : directory = null;

  static final Map<String, Uint8List> _memoryPhotos = {};

  bool get persistent => directory != null;

  static Future<LocalLibrary> open() async {
    if (kIsWeb) return LocalLibrary.inMemory();
    final root = await getApplicationDocumentsDirectory();
    final library = LocalLibrary(Directory('${root.path}/esel-local'));
    await library.load();
    return library;
  }

  final List<CoverDraft> _drafts = [];
  List<CoverDraft> get drafts => List.unmodifiable(_drafts);
  bool reduceMotion = false, reduceTransparency = false, largeText = false;
  bool gridView = true;
  String? recoveryNotice;
  bool _recovered = false;
  Future<void> _queue = Future.value();
  File get _index => File('${directory!.path}/library.json');
  File get _backup => File('${directory!.path}/library.backup.json');
  Future<void> load() async {
    final directory = this.directory;
    if (directory == null) return;
    await directory.create(recursive: true);
    if (!await _index.exists() && !await _backup.exists()) return;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(await _index.readAsString()) as Map<String, dynamic>;
      _restore(data);
    } catch (_) {
      if (!await _backup.exists()) rethrow;
      data = jsonDecode(await _backup.readAsString()) as Map<String, dynamic>;
      _restore(data);
      recoveryNotice = '이전 저장 기록에서 초안을 복구했어요.';
      _recovered = true;
    }
  }

  void _restore(Map<String, dynamic> data) {
    if (data['version'] != 1) {
      throw const FormatException('Unknown local library version');
    }
    final parsed = (data['drafts'] as List)
        .map((e) => CoverDraft.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _drafts
      ..clear()
      ..addAll(parsed);
    reduceMotion = data['reduceMotion'] == true;
    reduceTransparency = data['reduceTransparency'] == true;
    largeText = data['largeText'] == true;
    gridView = data['gridView'] != false;
  }

  Future<void> _persist() async {
    final directory = this.directory;
    if (directory == null) return;
    final data = jsonEncode({
      'version': 1,
      'drafts': _drafts.map((d) => d.toJson()).toList(),
      'reduceMotion': reduceMotion,
      'reduceTransparency': reduceTransparency,
      'largeText': largeText,
      'gridView': gridView,
    });
    final next = File('${directory.path}/library.next.json');
    await next.writeAsString(data, flush: true);
    if (!_recovered && await _index.exists()) await _index.copy(_backup.path);
    await next.rename(_index.path);
    _recovered = false;
  }

  Future<void> _change(void Function() change) {
    final result = _queue.then((_) async {
      final oldDrafts = List<CoverDraft>.of(_drafts);
      final oldSettings = [
        reduceMotion,
        reduceTransparency,
        largeText,
        gridView,
      ];
      change();
      try {
        await _persist();
      } catch (_) {
        _drafts
          ..clear()
          ..addAll(oldDrafts);
        reduceMotion = oldSettings[0];
        reduceTransparency = oldSettings[1];
        largeText = oldSettings[2];
        gridView = oldSettings[3];
        rethrow;
      }
      notifyListeners();
    });
    _queue = result.catchError((Object _) {});
    return result;
  }

  Future<void> save(CoverDraft draft) {
    final error = draft.validationError;
    if (error != null) {
      throw FormatException(error);
    }
    return _change(() {
      _drafts.removeWhere((d) => d.id == draft.id);
      _drafts.insert(0, draft.copyWith(updatedAt: DateTime.now()));
    });
  }

  /// 초안 하나를 지운다. 그 초안만 쓰던 사진 파일도 지운다.
  Future<void> delete(String id) async {
    final removed = _drafts.where((d) => d.id == id).toList();
    await _change(() => _drafts.removeWhere((d) => d.id == id));
    await _deletePhotos(removed.map((d) => d.photoPath));
  }

  /// 계정 탈퇴: 그 사람의 초안·발행한 호·사진 파일, 그리고 내보낸 표지 이미지(exports/)와
  /// 어느 초안도 쓰지 않는 사진(창간·편집하다 그만둔 사진)까지 지운다. 사진첩 원본은 그대로다.
  Future<void> deleteOwnerData(String ownerId) async {
    final removed = _drafts.where((d) => d.ownerId == ownerId).toList();
    await _change(() => _drafts.removeWhere((d) => d.ownerId == ownerId));
    await _deletePhotos(removed.map((d) => d.photoPath));
    final directory = this.directory;
    if (directory == null) {
      final used = _drafts.map((d) => d.photoPath).toSet();
      _memoryPhotos.removeWhere((key, _) => !used.contains(key));
      return;
    }
    final exports = Directory('${directory.path}/exports');
    if (await exports.exists()) await exports.delete(recursive: true);
    final used = _drafts.map((d) => File(d.photoPath).absolute.path).toSet();
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.endsWith('.png') &&
          !used.contains(entity.absolute.path)) {
        await entity.delete();
      }
    }
  }

  /// 보관함이 만든 사진만 지운다. 다른 초안이 아직 쓰는 사진은 남긴다.
  Future<void> _deletePhotos(Iterable<String> paths) async {
    final stillUsed = _drafts.map((d) => d.photoPath).toSet();
    final directory = this.directory;
    for (final path in paths) {
      if (path.isEmpty || stillUsed.contains(path)) continue;
      if (path.startsWith(memoryPhotoPrefix)) {
        _memoryPhotos.remove(path);
        continue;
      }
      if (directory == null) continue;
      final file = File(path);
      if (!file.absolute.path.startsWith(directory.absolute.path)) continue;
      if (await file.exists()) await file.delete();
    }
  }

  List<CoverDraft> issuesFor(String ownerId) =>
      _drafts.where((d) => d.ownerId == ownerId && d.issueNumber > 0).toList()
        ..sort((a, b) => b.issueNumber.compareTo(a.issueNumber));

  /// [on]은 서비스 날짜(Asia/Seoul)다. 기기 현지 날짜로 하루를 나누지 않는다(P04).
  Future<CoverDraft> publish(
    CoverDraft draft,
    String ownerId, {
    required ServiceDate on,
    DateTime? at,
  }) async {
    final error = draft.validationError;
    if (error != null) throw FormatException(error);
    if (ownerId.isEmpty) throw const FormatException('로그인이 필요해요.');
    final date = at ?? DateTime.now();
    final day = on.key;
    late CoverDraft issue;
    await _change(() {
      final existing = issuesFor(ownerId);
      if (!PublishRule.canPublishToday(
        hasPublishedToday: existing.any((d) => d.publishedOn == day),
      )) {
        throw const FormatException('오늘은 이미 한 호를 발행했어요.');
      }
      issue = draft.copyWith(
        ownerId: ownerId,
        issueNumber: PublishRule.nextIssueNumber(existing.length),
        publishedOn: day,
        updatedAt: date,
      );
      _drafts.removeWhere((d) => d.id == draft.id);
      _drafts.insert(0, issue);
    });
    return issue;
  }

  Future<void> settings({
    bool? motion,
    bool? transparency,
    bool? text,
    bool? grid,
  }) => _change(() {
    reduceMotion = motion ?? reduceMotion;
    reduceTransparency = transparency ?? reduceTransparency;
    largeText = text ?? largeText;
    gridView = grid ?? gridView;
  });
  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
  static const int maxPhotoBytes = 15 * 1024 * 1024;

  Future<String> importPhoto(String path) async {
    final source = File(path);
    if (await source.length() > maxPhotoBytes) {
      throw const FormatException('사진은 15MB 이하로 골라 주세요.');
    }
    return importPhotoBytes(await source.readAsBytes());
  }

  /// 웹은 고른 사진을 파일 경로가 아니라 바이트로만 받을 수 있다.
  Future<String> importPhotoBytes(Uint8List source) async {
    if (source.length > maxPhotoBytes) {
      throw const FormatException('사진은 15MB 이하로 골라 주세요.');
    }
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(
        source,
        targetWidth: 1800,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final bytes = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      if (bytes == null) throw const FormatException('사진을 읽지 못했어요.');
      final png = bytes.buffer.asUint8List();
      final directory = this.directory;
      if (directory == null) {
        final key = '$memoryPhotoPrefix${newId()}';
        _memoryPhotos[key] = png;
        return key;
      }
      final file = File('${directory.path}/${newId()}.png');
      await file.writeAsBytes(png, flush: true);
      return file.path;
    } catch (error) {
      if (error is FileSystemException) rethrow;
      throw const FormatException('열 수 없는 사진이에요. JPEG·PNG·HEIC 사진을 다시 골라 주세요.');
    } finally {
      codec?.dispose();
    }
  }
}
