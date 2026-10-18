import '../../core/network/http_client.dart';
import '../../core/storage/session_storage.dart';
import '../../core/time/service_clock.dart';
import '../dependencies/service_locator.dart';
import '../../features/auth/data/sources/mock_account_store.dart';
import '../../features/drafts/data/local_library.dart';

class AppBootstrap {
  static Future<void> setup({
    LocalLibrary? localLibrary,
    ServiceClock? clock,
    MockAccountVault? accountVault,
    AppHttpClient? httpClient,
    SessionStorage? sessionStorage,
  }) async {
    ServiceLocator().initialize(
      serviceClock: clock,
      accountVault: accountVault,
      client: httpClient,
      sessionStorage: sessionStorage,
    );
    try {
      ServiceLocator().localLibrary =
          localLibrary ??
          await LocalLibrary.open(mock: ServiceLocator().config.isMock);
    } catch (_) {
      ServiceLocator().localLibrary = LocalLibrary.unavailable();
    }
    ServiceLocator().todayController.library = ServiceLocator().localLibrary;
    await ServiceLocator().authController.restoreSession();
  }
}
