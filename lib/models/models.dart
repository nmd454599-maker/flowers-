import 'user_role.dart';
export 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? storeId;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.storeId,
  });
}

enum StoreApprovalStatus { pending, approved, rejected, suspended }

enum ProductApprovalStatus { draft, pending, approved, rejected, hidden }

enum SettlementStatus { draft, underReview, approved, paid, rejected }

enum PaymentMethod { cash, card, wallet }

enum PaymentStatus { pending, authorized, paid, failed, cancelled, refunded }

enum RefundStatus { requested, underReview, approved, completed, rejected }

enum RefundLiability { platform, store }

class AdminStoreRecord {
  final String id;
  final String name;
  final String city;
  final String ownerName;
  final String ownerPhone;
  final StoreApprovalStatus status;
  final bool documentsComplete;
  final DateTime? createdAt;

  const AdminStoreRecord({
    required this.id,
    required this.name,
    required this.city,
    required this.ownerName,
    required this.ownerPhone,
    required this.status,
    required this.documentsComplete,
    this.createdAt,
  });
}

class AdminUserRecord {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;

  const AdminUserRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.active,
    this.createdAt,
  });
}

class AdminProductRecord {
  final String id;
  final String storeId;
  final String name;
  final String category;
  final int price;
  final int stock;
  final String? imageUrl;
  final bool active;
  final ProductApprovalStatus status;
  final String? rejectionReason;
  final DateTime? createdAt;

  const AdminProductRecord({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.active,
    required this.status,
    this.imageUrl,
    this.rejectionReason,
    this.createdAt,
  });
}

class AdminOrderRecord {
  final String id;
  final String customerId;
  final List<String> storeIds;
  final int itemCount;
  final int total;
  final String address;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime? createdAt;

  const AdminOrderRecord({
    required this.id,
    required this.customerId,
    required this.storeIds,
    required this.itemCount,
    required this.total,
    required this.address,
    required this.status,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
    this.createdAt,
  });
}

class PaymentTransaction {
  final String id;
  final String orderId;
  final String customerId;
  final int amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String provider;
  final String? providerPaymentId;
  final DateTime? createdAt;

  const PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.method,
    required this.status,
    required this.provider,
    this.providerPaymentId,
    this.createdAt,
  });
}

class RefundRequest {
  final String id;
  final String orderId;
  final String customerId;
  final int amount;
  final String reason;
  final RefundLiability liability;
  final RefundStatus status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const RefundRequest({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.reason,
    required this.liability,
    required this.status,
    this.note,
    this.createdAt,
    this.completedAt,
  });

  RefundRequest copyWith(
          {RefundStatus? status, String? note, DateTime? completedAt}) =>
      RefundRequest(
        id: id,
        orderId: orderId,
        customerId: customerId,
        amount: amount,
        reason: reason,
        liability: liability,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );
}

class AdminAuditRecord {
  final String id;
  final String actorId;
  final String action;
  final String targetId;
  final Map<String, Object?> details;
  final DateTime? createdAt;

  const AdminAuditRecord({
    required this.id,
    required this.actorId,
    required this.action,
    required this.targetId,
    required this.details,
    this.createdAt,
  });
}

class StoreSettlement {
  final String id;
  final String storeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int grossSales;
  final int commission;
  final int refunds;
  final int adjustments;
  final int netAmount;
  final SettlementStatus status;
  final String? transferReference;
  final DateTime? createdAt;
  final DateTime? paidAt;

  const StoreSettlement({
    required this.id,
    required this.storeId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossSales,
    required this.commission,
    required this.refunds,
    required this.adjustments,
    required this.netAmount,
    required this.status,
    this.transferReference,
    this.createdAt,
    this.paidAt,
  });

  StoreSettlement copyWith({
    String? id,
    SettlementStatus? status,
    String? transferReference,
    DateTime? paidAt,
  }) =>
      StoreSettlement(
        id: id ?? this.id,
        storeId: storeId,
        periodStart: periodStart,
        periodEnd: periodEnd,
        grossSales: grossSales,
        commission: commission,
        refunds: refunds,
        adjustments: adjustments,
        netAmount: netAmount,
        status: status ?? this.status,
        transferReference: transferReference ?? this.transferReference,
        createdAt: createdAt,
        paidAt: paidAt ?? this.paidAt,
      );
}

class AdminRecord {
  final String id;
  final String scope;
  final Map<String, Object?> data;

  const AdminRecord({
    required this.id,
    required this.scope,
    required this.data,
  });
}

class Product {
  final String id;
  final String storeId;
  final String name;
  final String category;
  final int price;
  final String emoji;
  final double rating;
  final String description;
  final String? imageUrl;
  final List<String> imageUrls;

  List<String> get photos => List.unmodifiable({
        if (imageUrl != null && imageUrl!.trim().isNotEmpty) imageUrl!,
        ...imageUrls.where((url) => url.trim().isNotEmpty),
      });

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.price,
    required this.emoji,
    required this.rating,
    required this.description,
    this.imageUrl,
    this.imageUrls = const [],
  });
}

class Store {
  final String id;
  final String name;
  final String city;
  final double rating;
  final String emoji;
  final int minOrder;
  final int deliveryMinutes;

  const Store({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.emoji,
    required this.minOrder,
    required this.deliveryMinutes,
  });
}

enum OrderStatus { newOrder, preparing, delivering, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.newOrder => 'طلب جديد',
        OrderStatus.preparing => 'قيد التجهيز',
        OrderStatus.delivering => 'في الطريق',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.cancelled => 'ملغى',
      };
}

class OrderItem {
  final Product product;
  final int qty;

  const OrderItem(this.product, this.qty);

  int get total => product.price * qty;
}

class AppOrder {
  final String? couponId;
  final int discount;
  final int walletUsed;
  String id;
  final List<OrderItem> items;
  final int deliveryFee;
  final String address;
  OrderStatus status;
  final PaymentMethod paymentMethod;
  PaymentStatus paymentStatus;

  AppOrder({
    this.couponId,
    this.discount = 0,
    this.walletUsed = 0,
    required this.id,
    required this.items,
    required this.deliveryFee,
    required this.address,
    this.status = OrderStatus.newOrder,
    this.paymentMethod = PaymentMethod.cash,
    this.paymentStatus = PaymentStatus.pending,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get total => subtotal + deliveryFee - discount;
  int get cashDue => total - walletUsed;
}

class Address {
  final String id;
  final String title;
  final String city;
  final String details;

  const Address({
    required this.id,
    required this.title,
    required this.city,
    required this.details,
  });
}

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime createdAt;
  final bool fromMe;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
    required this.fromMe,
  });
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });
}
