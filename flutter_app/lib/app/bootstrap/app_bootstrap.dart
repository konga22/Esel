import '../../core/time/service_clock.dart';
import '../dependencies/service_locator.dart';
import '../../features/auth/data/sources/mock_account_store.dart';
import '../../features/drafts/data/local_library.dart';

class AppBootstrap {
  static Future<void> setup({
    LocalLibrary? localLibrary,
    ServiceClock? clock,
    MockAccountVault? accountVault,
  }) async {
    ServiceLocator().initialize(
      serviceClock: clock,
      accountVault: accountVault,
    );
    if (ServiceLocator().config.isMock) {
      ServiceLocator().localLibrary = localLibrary ?? await LocalLibrary.open();
      ServiceLocator().todayController.library = ServiceLocator().localLibrary;
    }
    await ServiceLocator().authController.restoreSession();
  }
}
