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
import '../../features/friends/presentation/controllers/friends_controller.dart';
import '../../features/magazine/data/sources/magazine_mock_source.dart';
import '../../features/magazine/data/sources/magazine_remote_source.dart';
import '../../features/magazine/presentation/controllers/magazine_controller.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
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

  late final AuthRepository authRepository;
  late final AuthController authController;
  late final TodayController todayController;
  late final OnboardingController onboardingController;
  late final ReactionsController reactionsController;
  late final FeedController feedController;
  late final StandController standController;
  late final MagazineController magazineController;
  late final RecordsController recordsController;
  late final RecordsSource recordsSource;
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
    todayController = TodayController(
      clock: clock,
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
      config.isMock ? FeedMockSource() : FeedRemoteSource(httpClient),
    );
    standController = StandController(
      config.isMock
          ? StandMockSource(library: library)
          : StandRemoteSource(httpClient),
    );
    magazineController = MagazineController(
      config.isMock
          ? MagazineMockSource(library: library)
          : MagazineRemoteSource(httpClient),
    );
    recordsController = RecordsController();
    recordsSource = config.isMock
        ? LocalRecordsSource(
            library,
            () => authController.currentSession?.userId,
            clock,
          )
        : RecordsRemoteSource(httpClient);
    friendsController = FriendsController();
    twinController = TwinController();
  }
}
