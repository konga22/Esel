import '../dependencies/service_locator.dart';
import '../../features/drafts/data/local_library.dart';

class AppBootstrap {
  static Future<void> setup({LocalLibrary? localLibrary}) async {
    ServiceLocator().initialize();
    if (ServiceLocator().config.isMock) {
      ServiceLocator().localLibrary = localLibrary ?? await LocalLibrary.open();
      ServiceLocator().magazineController.localLibrary =
          ServiceLocator().localLibrary;
    }
    await ServiceLocator().authController.restoreSession();
  }
}
