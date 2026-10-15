abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message (${code ?? "NO_CODE"})';
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class RuleFailure extends Failure {
  const RuleFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// 서버 소스가 아직 없는 기능. mock 모드로 실행하거나 서버 연결 후 다시 시도한다.
class NotImplementedFailure extends Failure {
  const NotImplementedFailure(super.message, {super.code = 'NOT_IMPLEMENTED'});
}
