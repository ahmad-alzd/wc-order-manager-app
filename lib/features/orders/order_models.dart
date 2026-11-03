/// Plain data models mirroring the JSON shapes produced by the
/// plugin's `WCOM_Order_Formatter` (see wc-order-manager-plugin's
/// includes/class-wcom-order-formatter.php).

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  return fallback;
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return fallback;
}

String _asString(dynamic value, [String fallback = '']) {
  if (value is String) return value;
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// One row in the orders list (GET /orders).
class OrderSummary {
  OrderSummary({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.currency,
    required this.total,
    required this.totalFormatted,
    required this.dateCreated,
    required this.customerName,
    required this.paymentMethodTitle,
    required this.itemCount,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: _asInt(json['id']),
      number: _asString(json['number']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      currency: _asString(json['currency']),
      total: _asDouble(json['total']),
      totalFormatted: _asString(json['total_formatted']),
      dateCreated: _asDateTime(json['date_created']),
      customerName: _asString(json['customer_name']),
      paymentMethodTitle: _asString(json['payment_method_title']),
      itemCount: _asInt(json['item_count']),
    );
  }

  final int id;
  final String number;
  final String status;
  final String statusLabel;
  final String currency;
  final double total;
  final String totalFormatted;
  final DateTime? dateCreated;
  final String customerName;
  final String paymentMethodTitle;
  final int itemCount;
}

/// A page of results from GET /orders.
class OrdersPage {
  OrdersPage({
    required this.orders,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<OrderSummary> orders;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;
}

/// A billing or shipping address, as returned in order detail.
class OrderAddress {
  OrderAddress({
    required this.name,
    required this.company,
    required this.address,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    this.phone,
    this.email,
  });

  factory OrderAddress.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const {};
    return OrderAddress(
      name: _asString(data['name']),
      company: _asString(data['company']),
      address: _asString(data['address']),
      city: _asString(data['city']),
      state: _asString(data['state']),
      postcode: _asString(data['postcode']),
      country: _asString(data['country']),
      phone: data['phone'] as String?,
      email: data['email'] as String?,
    );
  }

  final String name;
  final String company;
  final String address;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String? phone;
  final String? email;

  /// A single-line summary for display, skipping empty parts.
  String get singleLine {
    return [address, city, state, postcode, country]
        .where((part) => part.trim().isNotEmpty)
        .join('، ');
  }

  bool get isEmpty => name.isEmpty && address.isEmpty && city.isEmpty;
}

/// One product line within an order.
class OrderLineItem {
  OrderLineItem({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.total,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      name: _asString(json['name']),
      sku: _asString(json['sku']),
      quantity: _asInt(json['quantity']),
      total: _asDouble(json['total']),
    );
  }

  final String name;
  final String sku;
  final int quantity;
  final double total;
}

/// Full detail view (GET /orders/{id}).
class OrderDetail {
  OrderDetail({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.currency,
    required this.total,
    required this.totalFormatted,
    required this.dateCreated,
    required this.customerName,
    required this.paymentMethodTitle,
    required this.itemCount,
    required this.customerNote,
    required this.billing,
    required this.shipping,
    required this.lineItems,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: _asInt(json['id']),
      number: _asString(json['number']),
      status: _asString(json['status']),
      statusLabel: _asString(json['status_label']),
      currency: _asString(json['currency']),
      total: _asDouble(json['total']),
      totalFormatted: _asString(json['total_formatted']),
      dateCreated: _asDateTime(json['date_created']),
      customerName: _asString(json['customer_name']),
      paymentMethodTitle: _asString(json['payment_method_title']),
      itemCount: _asInt(json['item_count']),
      customerNote: _asString(json['customer_note']),
      billing: OrderAddress.fromJson(json['billing'] as Map<String, dynamic>?),
      shipping: OrderAddress.fromJson(json['shipping'] as Map<String, dynamic>?),
      lineItems: (json['line_items'] as List<dynamic>? ?? [])
          .map((item) => OrderLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String number;
  final String status;
  final String statusLabel;
  final String currency;
  final double total;
  final String totalFormatted;
  final DateTime? dateCreated;
  final String customerName;
  final String paymentMethodTitle;
  final int itemCount;
  final String customerNote;
  final OrderAddress billing;
  final OrderAddress shipping;
  final List<OrderLineItem> lineItems;

  /// Returns a copy with just the status fields replaced — used after
  /// a successful status change, without re-fetching the whole order.
  OrderDetail copyWithStatus({required String status, required String statusLabel}) {
    return OrderDetail(
      id: id,
      number: number,
      status: status,
      statusLabel: statusLabel,
      currency: currency,
      total: total,
      totalFormatted: totalFormatted,
      dateCreated: dateCreated,
      customerName: customerName,
      paymentMethodTitle: paymentMethodTitle,
      itemCount: itemCount,
      customerNote: customerNote,
      billing: billing,
      shipping: shipping,
      lineItems: lineItems,
    );
  }
}

/// One entry from GET /order-statuses, used to populate filter chips
/// and the status-change picker.
class OrderStatusOption {
  OrderStatusOption({required this.status, required this.label});

  factory OrderStatusOption.fromJson(Map<String, dynamic> json) {
    return OrderStatusOption(
      status: _asString(json['status']),
      label: _asString(json['label']),
    );
  }

  final String status;
  final String label;
}
