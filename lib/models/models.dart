import '../core/rbac.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: _parseRole(json['role'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'is_active': isActive,
      };
}

UserRole _parseRole(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'kasir':
      return UserRole.kasir;
    case 'staff_produksi':
    case 'staffProduksi':
      return UserRole.staffProduksi;
    default:
      return UserRole.kasir;
  }
}

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  final String token;
  final String refreshToken;
  final User user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    this.orderCount = 0,
  });

  final int id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final int orderCount;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      orderCount: json['order_count'] as int? ?? 0,
    );
  }
}

enum OrderStatus {
  draft,
  confirmed,
  inProduction,
  ready,
  delivered,
  cancelled,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.draft:
        return 'Draft';
      case OrderStatus.confirmed:
        return 'Dikonfirmasi';
      case OrderStatus.inProduction:
        return 'Produksi';
      case OrderStatus.ready:
        return 'Siap';
      case OrderStatus.delivered:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

class OrderItem {
  const OrderItem({
    required this.recipeId,
    required this.recipeName,
    required this.portions,
    required this.price,
  });

  final int recipeId;
  final String recipeName;
  final int portions;
  final double price;

  double get subtotal => portions * price;
}

class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.notes = '',
    this.paymentStatus = 'pending',
  });

  final int id;
  final String orderNumber;
  final int customerId;
  final String customerName;
  final OrderStatus status;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String notes;
  final String paymentStatus;
}

class RecipeCategory {
  const RecipeCategory({required this.id, required this.name, this.description = ''});

  final int id;
  final String name;
  final String description;
}

class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.servings,
    this.description = '',
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final double price;
  final int servings;
  final String description;
}

class RecipeIngredientLine {
  const RecipeIngredientLine({
    required this.ingredientId,
    required this.ingredientName,
    required this.unit,
    required this.quantity,
  });

  final int ingredientId;
  final String ingredientName;
  final String unit;
  final double quantity;
}

class RecipeStepLine {
  const RecipeStepLine({required this.stepNumber, required this.instruction});

  final int stepNumber;
  final String instruction;
}

class RecipeDetail {
  const RecipeDetail({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.servings,
    this.description = '',
    this.ingredients = const [],
    this.steps = const [],
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final double price;
  final int servings;
  final String description;
  final List<RecipeIngredientLine> ingredients;
  final List<RecipeStepLine> steps;

  Recipe toRecipe() => Recipe(
        id: id,
        name: name,
        categoryId: categoryId,
        categoryName: categoryName,
        price: price,
        servings: servings,
        description: description,
      );

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      servings: json['servings'] as int? ?? 1,
      description: json['description'] as String? ?? '',
      ingredients: (json['ingredients'] as List? ?? [])
          .map((e) => RecipeIngredientLine(
                ingredientId: e['ingredient_id'] as int,
                ingredientName: e['ingredient_name'] as String? ?? '',
                unit: e['unit'] as String? ?? '',
                quantity: (e['quantity'] as num).toDouble(),
              ))
          .toList(),
      steps: (json['steps'] as List? ?? [])
          .map((e) => RecipeStepLine(
                stepNumber: e['step_number'] as int,
                instruction: e['instruction'] as String,
              ))
          .toList(),
    );
  }
}

class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.minStock,
    this.price = 0,
  });

  final int id;
  final String name;
  final String unit;
  final double stock;
  final double minStock;
  final double price;

  bool get isLowStock => stock <= minStock;
}

class ProductionSchedule {
  const ProductionSchedule({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.recipeName,
    required this.portions,
    required this.scheduledDate,
    required this.status,
    this.assignedTo = '',
  });

  final int id;
  final int orderId;
  final String orderNumber;
  final String recipeName;
  final int portions;
  final DateTime scheduledDate;
  final String status;
  final String assignedTo;
}

class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.amount,
    required this.method,
    required this.status,
    required this.paidAt,
  });

  final int id;
  final int orderId;
  final String orderNumber;
  final String customerName;
  final double amount;
  final String method;
  final String status;
  final DateTime paidAt;
}

class DashboardStats {
  const DashboardStats({
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.lowStockCount = 0,
    this.todayProduction = 0,
    this.activeOrders = 0,
    this.pendingPayments = 0,
    this.todayOrders = 0,
    this.processingOrders = 0,
    this.revenueChart = const [],
  });

  final int totalOrders;
  final double totalRevenue;
  final int lowStockCount;
  final int todayProduction;
  final int activeOrders;
  final int pendingPayments;
  final int todayOrders;
  final int processingOrders;
  final List<double> revenueChart;
}

class ReportSummary {
  const ReportSummary({
    required this.title,
    required this.period,
    required this.rows,
    this.total = 0,
  });

  final String title;
  final String period;
  final List<Map<String, dynamic>> rows;
  final double total;
}
