import '../../models/models.dart';

/// Normal fulfilment only. Cancellation requires the backend refund/stock flow.
bool canAdvanceOrder(OrderStatus from, OrderStatus to) =>
    (from == OrderStatus.newOrder && to == OrderStatus.preparing) ||
    (from == OrderStatus.preparing && to == OrderStatus.delivering) ||
    (from == OrderStatus.delivering && to == OrderStatus.delivered);
