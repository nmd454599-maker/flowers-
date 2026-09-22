/// Contract for the production backend integration.
/// Replace the local AppState operations with a concrete Firebase/REST implementation.
abstract class BackendContract {
  Future<void> requestOtp(String phone);
  Future<String> verifyOtp(String phone, String code);
  Future<List<Map<String, dynamic>>> fetchStores({required String city});
  Future<List<Map<String, dynamic>>> fetchProducts(
      {String? storeId, String? category});
  Future<String> createOrder(Map<String, dynamic> order);
  Future<void> sendChatMessage(String conversationId, String text);
}
