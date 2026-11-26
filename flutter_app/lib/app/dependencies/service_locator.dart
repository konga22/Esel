import '../../features/publishing/data/publishing_remote_source.dart';
import '../../features/media/presentation/controllers/media_upload_controller.dart';
import '../../features/media/data/media_remote_source.dart';
import '../../features/today/data/sources/today_remote_source.dart';
import '../../features/issue/data/sources/issue_remote_source.dart';
import '../../features/records/data/sources/records_source.dart';
import '../../features/records/data/sources/records_remote_source.dart';
import 'package:flutter/foundation.dart';
import '../../features/challenges/data/challenge_source.dart';
import '../../features/collections/data/collection_source.dart';
import '../../core/config/app_config.dart';
import '../../features/drafts/data/local_library.dart';
import '../../core/network/http_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/storage/secure_session_storage.dart';
import '../../core/time/service_clock.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/sources/auth_mock_source.dart';
import '../../features/auth/data/sources/auth_remote_source.dart';
import '../../features/auth/data/sources/mock_account_store.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/feed/data/sources/feed_mock_source.dart';
import '../../features/feed/data/sources/feed_remote_source.dart';
import '../../features/feed/presentation/controllers/feed_controller.dart';
import '../../features/friends/data/friends_source.dart';
import '../../features/friends/presentation/controllers/friends_controller.dart';
import '../../features/moderation/data/blocks_source.dart';
import '../../features/moderation/data/reports_source.dart';
import '../../features/moderation/presentation/controllers/blocks_controller.dart';
import '../../features/magazine/data/sources/magazine_mock_source.dart';
import '../../features/magazine/data/sources/magazine_remote_source.dart';
import '../../features/magazine/presentation/controllers/magazine_controller.dart';
import '../../features/magazine/presentation/controllers/scraps_controller.dart';
import '../../features/magazine/data/sources/scraps_remote_source.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/settings/data/notification_settings_source.dart';
import '../../features/settings/data/profile_remote_source.dart';
import '../../features/settings/presentation/controllers/profile_bio_controller.dart';
import '../../features/reactions/presentation/controllers/reactions_controller.dart';
import '../../features/records/presentation/controllers/records_controller.dart';
import '../../features/stand/data/sources/stand_mock_source.dart';
import '../../features/stand/data/sources/stand_remote_source.dart';
import '../../features/stand/presentation/controllers/stand_controller.dart';
import '../../features/today/presentation/controllers/today_controller.dart';
import '../../features/twin/presentation/controllers/twin_controller.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AppConfig config;
  late final ChallengeSource challengeSource;
  late final CollectionSource collectionSource;
  late final ServiceClock clock;
  LocalLibrary? localLibrary;
  late final SessionStorage storage;
  late final AppHttpClient httpClient;
  late final MediaRemoteSource mediaSource;
  late final MediaUploadController mediaUploads;

  late final AuthRepository authRepository;
  late final AuthController authController;
  late final TodayController todayController;
  late final OnboardingController onboardingController;
  late final ReactionsController reactionsController;
  late final FeedController feedController;
  late final StandController standController;
  late final MagazineController magazineController;

  /// 알림 설정(DEV-19). 서버 모드는 GET·PUT /me/notifications, mock 모드는 앱 메모리.
  late final NotificationSettingsSource notificationSettingsSource;

  /// 서버 모드의 한 줄 소개 저장(PATCH /me/profile). mock 모드는 소개 칸을 잠가 두므로 null.
  late final ProfileBioController? profileBioController;

  /// 서버 모드 저장함(GET /me/scraps). mock 모드는 기기 보관 저장함을 쓰므로 null.
  late final ScrapsController? scrapsController;
  late final RecordsController recordsController;
  late final RecordsSource recordsSource;

  /// 차단하기·풀기·차단 목록(DEV-20). 바뀌면 홈·팔레트를 다시 읽는다.
  late final BlocksController blocksController;

  /// 표지 신고 보내기(DEV-20). 처리 기준은 미정이라 서버는 접수만 저장한다.
  late final ReportsSource reportsSource;
  late final FriendsController friendsController;
  late final TwinController twinController;

  /// [accountVault]는 시연 계정을 두는 곳이다. 기본은 기기 보안 저장소, 웹은 메모리.
  void initialize({
    AppConfig? customConfig,
    ServiceClock? serviceClock,
    MockAccountVault? accountVault,
    AppHttpClient? client,
    SessionStorage? sessionStorage,
  }) {
    config = customConfig ?? AppConfig.current;
    clock = serviceClock ?? const SystemServiceClock();
    storage =
        sessionStorage ??
        (config.isMock
            ? InMemorySessionStorage()
            : const SecureSessionStorage());
    httpClient = client ?? StandardHttpClient(config: config, storage: storage);

    final mockSource = AuthMockSource(
      accounts: MockAccountStore(
        accountVault ??
            (kIsWeb
                ? InMemoryMockAccountVault()
                : const SecureMockAccountVault()),
      ),
    );
    final remoteSource = AuthRemoteSource(httpClient);

    authRepository = AuthRepositoryImpl(
      config: config,
      storage: storage,
      mockSource: mockSource,
      remoteSource: remoteSource,
    );

    authController = AuthController(authRepository);
    mediaSource = MediaRemoteSource(httpClient);
    mediaUploads = MediaUploadController(mediaSource);
    authController.addListener(
      () => mediaSource.bindOwner(authController.currentSession?.userId),
    );
    todayController = TodayController(
      clock: clock,
      publishRemote: config.isMock
          ? null
          : PublishingRemoteSource(
              httpClient,
              mediaUploads,
              readPhoto: (path) async {
                final library = localLibrary;
                if (library == null) {
                  throw const FormatException('기기 보관함을 먼저 열어 주세요.');
                }
                return library.readPhotoBytes(path);
              },
            ).publish,
      remote: config.isMock ? null : TodayRemoteSource(httpClient),
      remoteMagazine: config.isMock ? null : MagazineRemoteSource(httpClient),
    );
    onboardingController = OnboardingController(
      checkMasthead: authController.isMastheadAvailable,
    );
    reactionsController = ReactionsController(
      remote: config.isMock ? null : IssueRemoteSource(httpClient),
      remoteMagazine: config.isMock ? null : MagazineRemoteSource(httpClient),
    );
    // 피드·팔레트·스케치북도 ESEL_API_MODE 하나로 mock과 서버 소스를 바꾼다(DEV-03).
    // 서버 소스는 아직 미구현이라 부르면 "아직 연결하지 않았어요"로 끝난다.
    LocalLibrary? library() => localLibrary;
    challengeSource = config.isMock
        ? LocalChallengeSource(library)
        : RemoteChallengeSource();
    collectionSource = config.isMock
        ? LocalCollectionSource(library)
        : RemoteCollectionSource();
    feedController = FeedController(
      config.isMock
          ? FeedMockSource()
          : FeedRemoteSource(
              httpClient,
              currentSession: () => authController.currentSession,
            ),
    );
    standController = StandController(
      config.isMock
          ? StandMockSource(library: library)
          : StandRemoteSource(
              httpClient,
              currentSession: () => authController.currentSession,
            ),
    );
    magazineController = MagazineController(
      config.isMock
          ? MagazineMockSource(library: library)
          : MagazineRemoteSource(httpClient),
    );
    // 서버는 차단한 사람의 캔버스를 응답에서 뺀다. 차단·풀기 뒤에 다시 읽어 그 결과를 받는다.
    blocksController = BlocksController(
      config.isMock ? BlocksMemorySource() : BlocksRemoteSource(httpClient),
      onChanged: () {
        feedController.load();
        standController.load();
      },
    );
    reportsSource = config.isMock
        ? ReportsMemorySource()
        : ReportsRemoteSource(httpClient);
    scrapsController = config.isMock
        ? null
        : ScrapsController(ScrapsRemoteSource(httpClient));
    notificationSettingsSource = config.isMock
        ? NotificationSettingsMemorySource()
        : NotificationSettingsRemoteSource(httpClient);
    profileBioController = config.isMock
        ? null
        : ProfileBioController(ProfileRemoteSource(httpClient));
    recordsController = RecordsController();
    recordsSource = config.isMock
        ? LocalRecordsSource(
            library,
            () => authController.currentSession?.userId,
            clock,
          )
        : RecordsRemoteSource(httpClient);
    // 친구(DEV-16): mock은 예시 친구, 서버는 GET·POST /friends….
    friendsController = FriendsController(
      config.isMock ? FriendsMockSource() : FriendsRemoteSource(httpClient),
    );
    twinController = TwinController();
  }
}
