/// A cancelled session must not publish results or start follow-up requests.
class StaleOperation implements Exception {
  const StaleOperation();
  @override
  String toString() => 'انتهت الجلسة أو تغيّر الحساب';
}

class OperationToken {
  final bool Function() _isCurrent;
  OperationToken(this._isCurrent);
  bool get isCurrent => _isCurrent();
  void check() {
    if (!isCurrent) throw const StaleOperation();
  }

  Future<T> wait<T>(Future<T> future) async {
    final result = await future;
    check();
    return result;
  }
}

typedef OperationRunner = Future<void> Function(
    Future<void> Function(OperationToken token) operation);
