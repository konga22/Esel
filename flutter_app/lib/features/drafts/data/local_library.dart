import '../../garments/domain/garment.dart';
import 'dart:convert';
import '../../challenges/domain/challenge.dart';
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
    photoPath.startsWith('assets/')
    ? AssetImage(photoPath)
    : photoPath.startsWith(memoryPhotoPrefix)
    ? MemoryImage(LocalLibrary._memoryPhotos[photoPath] ?? Uint8List(0))
    : FileImage(File(photoPath));

class LocalLibrary extends ChangeNotifier {
  /// null이면 저장하지 않는 메모리 보관함이다(웹은 기기 파일을 쓸 수 없다).
  final Directory? directory;
  LocalLibrary(Directory this.directory);
  LocalLibrary.inMemory() : directory = null;
  LocalLibrary.unavailable() : directory = null {
    loadError = '기기 보관함을 열지 못했어요. 기존 자료는 보존되어 있어요. 앱을 다시 시작해 주세요.';
  }
  String? loadError;
  bool get available => loadError == null;
  Future<void> loadForStartup() async {
    try {
      await load();
      loadError = null;
    } catch (_) {
      _drafts.clear();
      _publicationLedger.clear();
      _reactionRecords.clear();
      _featureRecords.clear();
      _personalRecords.clear();
      loadError = '기기 보관함을 읽지 못했어요. 기존 파일은 보존되어 있어요. 다시 읽기를 시도해 주세요.';
    }
    notifyListeners();
  }

  void _ensureAvailable() {
    if (loadError != null) throw FormatException(loadError!);
  }

  static final Map<String, Uint8List> _memoryPhotos = {};

  bool get persistent => directory != null;

  /// 서버 모드(기기 보관함 화면)의 저장 폴더. 이전부터 쓰던 이름이다.
  static const String serverFolder = 'esel-local';

  /// 시연(mock) 모드의 저장 폴더. 서버 모드와 같은 library.json을 쓰지 않는다.
  static const String mockFolder = 'esel-mock';

  /// [mock]이면 시연 모드 보관함을 연다. 웹은 늘 메모리.
  static Future<LocalLibrary> open({bool mock = false, Directory? root}) async {
    if (kIsWeb) return LocalLibrary.inMemory();
    final base = root ?? await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${base.path}/${mock ? mockFolder : serverFolder}',
    );
    if (mock && !await directory.exists()) {
      await _moveMockRecords(
        from: Directory('${base.path}/$serverFolder'),
        to: directory,
      );
    }
    final library = LocalLibrary(directory);
    await library.loadForStartup();
    return library;
  }

  /// 예전에는 두 모드가 esel-local 하나를 같이 썼다. 시연 폴더를 처음 만들 때, 시연
  /// 계정(mock_…)의 초안·호와 그 사진만 복사해 온다. 원래 폴더는 건드리지 않는다.
  static Future<void> _moveMockRecords({
    required Directory from,
    required Directory to,
  }) async {
    final index = File('${from.path}/library.json');
    if (!await index.exists()) return;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(await index.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (data['version'] != 1) return;
    await to.create(recursive: true);
    final moved = <Map<String, dynamic>>[];
    for (final item in (data['drafts'] as List? ?? const [])) {
      final draft = Map<String, dynamic>.from(item as Map);
      if (!(draft['ownerId'] as String? ?? '').startsWith('mock_')) continue;
      final photo = File(draft['photoPath'] as String? ?? '');
      if (await photo.exists() &&
          photo.absolute.path.startsWith(from.absolute.path)) {
        final copy = File('${to.path}/${photo.uri.pathSegments.last}');
        await photo.copy(copy.path);
        draft['photoPath'] = copy.path;
      }
      moved.add(draft);
    }
    final metadata = {
      for (final key in [
        'publicationLedger',
        'reactionRecords',
        'featureRecords',
        'personalRecords',
      ])
        key: {
          for (final entry in (data[key] as Map? ?? {}).entries)
            if ((entry.key as String).startsWith('mock_'))
              entry.key: entry.value,
        },
    };
    await File('${to.path}/library.json').writeAsString(
      jsonEncode({...data, ...metadata, 'drafts': moved}),
      flush: true,
    );
  }

  final List<CoverDraft> _drafts = [];
  final Map<String, Map<String, int>> _publicationLedger = {};
  final Map<String, Map<String, dynamic>> _reactionRecords = {};
  final Map<String, Map<String, dynamic>> _featureRecords = {};
  final Map<String, Map<String, dynamic>> _personalRecords = {};
  Map<String, dynamic> reactionsFor(String owner) => Map<String, dynamic>.from(
    jsonDecode(jsonEncode(_reactionRecords[owner] ?? {})) as Map,
  );
  Map<String, dynamic> featuresFor(String owner) => Map<String, dynamic>.from(
    jsonDecode(jsonEncode(_featureRecords[owner] ?? {})) as Map,
  );

  /// 본인의 기록에서 같은 옷 ID를 재사용한다. 다른 계정의 옷은 섞지 않는다.
  List<Garment> garmentsFor(String owner) => {
    for (final entry
        in ((_personalRecords[owner]?['garments'] as Map?) ?? {}).entries)
      entry.key as String: Garment.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      ),
    for (final draft in _drafts.where((d) => d.ownerId == owner))
      for (final garment in draft.garments) garment.id: garment,
  }.values.map((g) => g.at(null, null).forColor(false)).toList();

  Map<String, String> restoredColorsFor(String owner) =>
      Map<String, String>.from(
        _personalRecords[owner]?['restored'] as Map? ?? {},
      );
  Future<void> restoreColor(String owner, ServiceDate day, String color) =>
      _change(() {
        if (owner.isEmpty) throw const FormatException('로그인이 필요해요.');
        final data = Map<String, dynamic>.from(_personalRecords[owner] ?? {});
        final restored = restoredColorsFor(owner);
        if (restored.containsKey(day.key) || hasPublishedOn(owner, day)) {
          throw const FormatException('이미 기록한 날짜예요.');
        }
        if (restored.keys
                .where((v) => v.startsWith(day.key.substring(0, 7)))
                .length >=
            2) {
          throw const FormatException('이달의 복원 기회를 모두 사용했어요.');
        }
        restored[day.key] = color;
        data['restored'] = restored;
        _personalRecords[owner] = data;
      });
  void _rememberGarments(CoverDraft draft) {
    if (draft.ownerId.isEmpty) return;
    final data = Map<String, dynamic>.from(
      _personalRecords[draft.ownerId] ?? {},
    );
    data['garments'] = {
      ...?(data['garments'] as Map?),
      for (final item in draft.garments) item.id: item.toJson(),
    };
    _personalRecords[draft.ownerId] = data;
  }

  Future<void> saveReactions(String owner, Map<String, dynamic> data) {
    if (owner.isEmpty) throw const FormatException('로그인이 필요해요.');
    final copy = Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);
    return _change(() => _reactionRecords[owner] = copy);
  }

  Future<void> selectFeature(
    String owner,
    String period,
    String issueId,
    String? reason,
  ) => _change(() {
    if (owner.isEmpty) throw const FormatException('로그인이 필요해요.');
    if (reason != null &&
        !_drafts.any((d) => d.id == issueId && d.issueNumber > 0)) {
      throw const FormatException('표지를 찾을 수 없어요. 다시 불러와 주세요.');
    }
    final records = featuresFor(owner);
    final selections = List<dynamic>.of(records[period] as List? ?? []);
    selections.removeWhere((entry) => (entry as Map)['issueId'] == issueId);
    if (reason != null) selections.add({'issueId': issueId, 'reason': reason});
    records[period] = selections;
    _featureRecords[owner] = records;
  });
  bool hasPublishedOn(String owner, ServiceDate day) =>
      _publicationLedger[owner]?.containsKey(day.key) == true ||
      issuesFor(owner).any((d) => d.publishedOn == day.key);
  int publicationCount(String owner) => [
    ...?_publicationLedger[owner]?.values,
    ...issuesFor(owner).map((d) => d.issueNumber),
  ].fold<int>(0, (a, b) => a > b ? a : b);
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
    _publicationLedger.clear();
    for (final entry in (data['publicationLedger'] as Map? ?? {}).entries) {
      _publicationLedger[entry.key as String] = {
        for (final item in (entry.value as Map).entries)
          item.key as String: (item.value as num).toInt(),
      };
    }
    // 이전 저장본도 올리기 이력을 지우지 않고 이어받는다.
    for (final issue in _drafts.where(
      (d) => d.issueNumber > 0 && d.publishedOn != null,
    )) {
      final ledger = _publicationLedger.putIfAbsent(issue.ownerId, () => {});
      final previous = ledger[issue.publishedOn!] ?? 0;
      if (issue.issueNumber > previous) {
        ledger[issue.publishedOn!] = issue.issueNumber;
      }
    }
    _personalRecords.clear();
    for (final entry in (data['personalRecords'] as Map? ?? {}).entries) {
      _personalRecords[entry.key as String] = Map<String, dynamic>.from(
        entry.value as Map,
      );
    }
    _reactionRecords.clear();
    _featureRecords.clear();
    for (final entry in (data['reactionRecords'] as Map? ?? {}).entries) {
      _reactionRecords[entry.key as String] = Map<String, dynamic>.from(
        entry.value as Map,
      );
    }
    for (final entry in (data['featureRecords'] as Map? ?? {}).entries) {
      _featureRecords[entry.key as String] = Map<String, dynamic>.from(
        entry.value as Map,
      );
    }
  }

  Future<void> _persist() async {
    _ensureAvailable();
    final directory = this.directory;
    if (directory == null) return;
    final data = jsonEncode({
      'version': 1,
      'drafts': _drafts.map((d) => d.toJson()).toList(),
      'publicationLedger': _publicationLedger,
      'reactionRecords': _reactionRecords,
      'featureRecords': _featureRecords,
      'personalRecords': _personalRecords,
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
      _ensureAvailable();
      final oldDrafts = List<CoverDraft>.of(_drafts);
      final oldLedger = {
        for (final e in _publicationLedger.entries)
          e.key: Map<String, int>.of(e.value),
      };
      final oldReactions = Map<String, Map<String, dynamic>>.of(
        _reactionRecords,
      );
      final oldPersonal = Map<String, Map<String, dynamic>>.from(
        jsonDecode(jsonEncode(_personalRecords)) as Map,
      );
      final oldFeatures = Map<String, Map<String, dynamic>>.of(_featureRecords);
      final oldSettings = [
        reduceMotion,
        reduceTransparency,
        largeText,
        gridView,
      ];
      try {
        change();
        await _persist();
      } catch (_) {
        _drafts
          ..clear()
          ..addAll(oldDrafts);
        reduceMotion = oldSettings[0];
        reduceTransparency = oldSettings[1];
        largeText = oldSettings[2];
        gridView = oldSettings[3];
        _publicationLedger
          ..clear()
          ..addAll(oldLedger);
        _reactionRecords
          ..clear()
          ..addAll(oldReactions);
        _personalRecords
          ..clear()
          ..addAll(oldPersonal);
        _featureRecords
          ..clear()
          ..addAll(oldFeatures);
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
      _rememberGarments(draft);
    });
  }

  /// 초안 하나를 지운다. 그 초안만 쓰던 사진 파일도 지운다.
  Future<void> delete(String id) async {
    final removed = _drafts.where((d) => d.id == id).toList();
    await _change(() {
      _drafts.removeWhere((d) => d.id == id);
      for (var i = 0; i < _drafts.length; i++) {
        if (_drafts[i].previousIssueId == id) {
          _drafts[i] = _drafts[i].copyWith(clearChallenge: true);
        }
      }
    });
    await _deletePhotos(removed.map((d) => d.photoPath));
  }

  /// 계정 탈퇴: 그 사람의 초안·올린 호·사진 파일, 그리고 내보낸 표지 이미지(exports/)와
  /// 어느 초안도 쓰지 않는 사진(첫 캔버스·편집하다 그만둔 사진)까지 지운다. 사진첩 원본은 그대로다.
  Future<void> deleteOwnerData(String ownerId) async {
    final removed = _drafts.where((d) => d.ownerId == ownerId).toList();
    final removedIds = removed.map((d) => d.id).toSet();
    await _change(() {
      _drafts.removeWhere((d) => d.ownerId == ownerId);
      _publicationLedger.remove(ownerId);
      _reactionRecords.remove(ownerId);
      _featureRecords.remove(ownerId);
      _personalRecords.remove(ownerId);
      for (var i = 0; i < _drafts.length; i++) {
        if (removedIds.contains(_drafts[i].previousIssueId)) {
          _drafts[i] = _drafts[i].copyWith(clearChallenge: true);
        }
      }
    });
    await _deletePhotos(removed.map((d) => d.photoPath));
    final directory = this.directory;
    if (directory == null) {
      final used = _drafts.map((d) => d.photoPath).toSet();
      _memoryPhotos.removeWhere((key, _) => !used.contains(key));
      return;
    }
    final exports = Directory('${directory.path}/exports');
    if (await exports.exists()) await exports.delete(recursive: true);
    final used = _drafts
        .map((d) => File(d.photoPath).absolute.path.replaceAll('\\', '/'))
        .toSet();
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.endsWith('.png') &&
          !used.contains(entity.absolute.path.replaceAll('\\', '/'))) {
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
      if (file.parent.absolute.path.replaceAll('\\', '/') !=
          directory.absolute.path.replaceAll('\\', '/')) {
        continue;
      }
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
      _rememberGarments(draft);
      final existing = issuesFor(ownerId);
      final stored = _drafts.where((d) => d.id == draft.id).firstOrNull;
      if (stored != null &&
          (stored.issueNumber > 0 ||
              (stored.ownerId.isNotEmpty && stored.ownerId != ownerId))) {
        throw const FormatException('이미 올렸거나 다른 계정의 표지는 올릴 수 없어요.');
      }
      if (!PublishRule.canPublishToday(
        hasPublishedToday: hasPublishedOn(ownerId, on),
      )) {
        throw const FormatException('오늘은 이미 한 호를 올렸어요.');
      }
      if (draft.challengeId != null) {
        final challenge = StyleChallenge.resolve(draft.challengeId);
        if (challenge == null) {
          throw const FormatException('주제를 찾지 못했어요. 참여를 해제하고 다시 골라 주세요.');
        }
        challenge.validate(
          today: on,
          ownerId: ownerId,
          issue: draft,
          publications: existing,
          previousId: draft.previousIssueId,
        );
      }
      issue = draft.copyWith(
        ownerId: ownerId,
        issueNumber: PublishRule.nextIssueNumber(
          [
            publicationCount(ownerId),
            ...existing.map((d) => d.issueNumber),
          ].reduce((a, b) => a > b ? a : b),
        ),
        publishedOn: day,
        updatedAt: date,
      );
      _drafts.removeWhere((d) => d.id == draft.id);
      _drafts.insert(0, issue);
      _publicationLedger.putIfAbsent(ownerId, () => {})[day] =
          issue.issueNumber;
    });
    return issue;
  }

  /// Attach today's existing publication without publishing a second issue.
  Future<void> attachChallenge(
    String issueId,
    String ownerId,
    StyleChallenge challenge,
    ServiceDate today, {
    String? previousId,
  }) => _change(() {
    final index = _drafts.indexWhere(
      (d) => d.id == issueId && d.ownerId == ownerId && d.issueNumber > 0,
    );
    if (index < 0) throw const FormatException('내 올린 표지를 찾지 못했어요.');
    final issue = _drafts[index];
    challenge.validate(
      today: today,
      ownerId: ownerId,
      issue: issue,
      publications: issuesFor(ownerId),
      previousId: previousId,
    );
    if (issue.challengeId != null &&
        (issue.challengeId != challenge.id ||
            issue.previousIssueId != previousId)) {
      throw const FormatException('이미 다른 참여가 연결돼 있어요. 내 참여에서 해제한 뒤 다시 골라 주세요.');
    }
    _drafts[index] = issue.copyWith(
      challengeId: challenge.id,
      previousIssueId: previousId,
    );
  });

  Future<void> detachChallenge(String issueId, String ownerId) => _change(() {
    final index = _drafts.indexWhere(
      (d) => d.id == issueId && d.ownerId == ownerId,
    );
    if (index < 0) throw const FormatException('내 표지를 찾지 못했어요.');
    _drafts[index] = _drafts[index].copyWith(clearChallenge: true);
  });

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

  Future<bool> photoExists(String path) async =>
      path.startsWith(memoryPhotoPrefix)
      ? _memoryPhotos.containsKey(path)
      : File(path).exists();

  Future<String> importPhoto(String path) async {
    _ensureAvailable();
    final source = File(path);
    if (await source.length() > maxPhotoBytes) {
      throw const FormatException('사진은 15MB 이하로 골라 주세요.');
    }
    return importPhotoBytes(await source.readAsBytes());
  }

  /// 웹은 고른 사진을 파일 경로가 아니라 바이트로만 받을 수 있다.
  Future<String> importPhotoBytes(Uint8List source) async {
    _ensureAvailable();
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
