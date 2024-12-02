import 'package:getapps/app/app.dart';

class MockPackageService implements PackageService {
  @override
  AsyncResult<AppEntity, AppException> installApp(AppEntity app) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Success(app);
  }

  @override
  AsyncResult<AppEntity, AppException> addInfo(AppEntity app) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Success(app);
  }

  @override
  AsyncResult<Unit, AppException> openApp(AppEntity app) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Success.unit();
  }

  @override
  AsyncResult<AppEntity, AppException> uninstallApp(AppEntity app) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Success(app);
  }

  @override
  AsyncResult<List<AppEntity>, AppException> addInfos(List<AppEntity> apps) async {
    return Success(apps);
  }

  @override
  AsyncResult<Unit, AppException> checkInstallPermission() async {
    return Success.unit();
  }
}
