import '../../core/config/app_config.dart';
import '../../features/drafts/data/local_library.dart';
import '../../core/network/http_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/storage/secure_session_storage.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/sources/auth_mock_source.dart';
import '../../features/auth/data/sources/auth_remote_source.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/feed/presentation/controllers/feed_controller.dart';
import '../../features/friends/presentation/controllers/friends_controller.dart';
import '../../features/magazine/presentation/controllers/magazine_controller.dart';
import '../../features/onboarding/presentation/controllers/onboarding_controller.dart';
import '../../features/publishing/presentation/controllers/publishing_controller.dart';
import '../../features/reactions/presentation/controllers/reactions_controller.dart';
import '../../features/records/presentation/controllers/records_controller.dart';
import '../../features/stand/presentation/controllers/stand_controller.dart';
import '../../features/twin/presentation/controllers/twin_controller.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final AppConfig config;
  LocalLibrary? localLibrary;
  late final SessionStorage storage;
  late final AppHttpClient httpClient;

  late final AuthRepository authRepository;
  late final AuthController authController;
  late final OnboardingController onboardingController;
  late final PublishingController publishingController;
  late final ReactionsController reactionsController;
  late final FeedController feedController;
  late final StandController standController;
  late final MagazineController magazineController;
  late final RecordsController recordsController;
  late final FriendsController friendsController;
  late final TwinController twinController;

  void initialize({AppConfig? customConfig}) {
    config = customConfig ?? AppConfig.current;
    storage = config.isMock
        ? InMemorySessionStorage()
        : const SecureSessionStorage();
    httpClient = StandardHttpClient(config: config, storage: storage);

    final mockSource = AuthMockSource();
    final remoteSource = AuthRemoteSource(httpClient);

    authRepository = AuthRepositoryImpl(
      config: config,
      storage: storage,
      mockSource: mockSource,
      remoteSource: remoteSource,
    );

    authController = AuthController(authRepository);
    onboardingController = OnboardingController();
    publishingController = PublishingController();
    reactionsController = ReactionsController();
    feedController = FeedController();
    standController = StandController();
    magazineController = MagazineController();
    recordsController = RecordsController();
    friendsController = FriendsController();
    twinController = TwinController();
  }
}
