/// Stable collection names shared by repositories and live customer screens.
/// Renaming a value requires a separate, reviewed backend migration.
abstract final class FirestoreCollections {
  static const users = 'users';
  static const stores = 'stores';
  static const products = 'products';
  static const orders = 'orders';
  static const messages = 'messages';
  static const auditLogs = 'auditLogs';
  static const settlements = 'settlements';
  static const paymentTransactions = 'paymentTransactions';
  static const refundRequests = 'refundRequests';
  static const adminData = 'adminData';
  static const records = 'records';
}
