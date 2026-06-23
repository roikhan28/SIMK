import '../config/api_config.dart';
import '../core/rbac.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'mock_data.dart';

class DataService {
  DataService(this._api);

  final ApiClient _api;

  final Map<UserRole, DashboardStats> _dashboardCache = {};
  List<User>? _usersCache;
  List<Customer>? _customersCache;
  List<Order>? _ordersCache;
  List<Recipe>? _recipesCache;
  List<RecipeCategory>? _categoriesCache;
  List<Ingredient>? _ingredientsCache;
  List<ProductionSchedule>? _productionsCache;
  List<Payment>? _paymentsCache;

  void clearCache() {
    _dashboardCache.clear();
    _usersCache = null;
    _customersCache = null;
    _ordersCache = null;
    _recipesCache = null;
    _categoriesCache = null;
    _ingredientsCache = null;
    _productionsCache = null;
    _paymentsCache = null;
  }

  Future<AuthResponse> login(String email, String password) async {
    if (ApiConfig.useMockData) {
      final result = MockData.login(email, password);
      if (result == null) throw ApiException('Email atau password salah');
      return result;
    }

    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<DashboardStats> getDashboard(UserRole role, {bool force = false}) async {
    if (!force && _dashboardCache.containsKey(role)) {
      return _dashboardCache[role]!;
    }

    if (ApiConfig.useMockData) {
      final stats = switch (role) {
        UserRole.admin => MockData.adminDashboard(),
        UserRole.kasir => MockData.kasirDashboard(),
        UserRole.staffProduksi => MockData.produksiDashboard(),
      };
      _dashboardCache[role] = stats;
      return stats;
    }

    final data = await _api.get('/dashboard');
    final stats = DashboardStats(
      totalOrders: data['total_orders'] as int? ?? 0,
      totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0,
      lowStockCount: data['low_stock_count'] as int? ?? 0,
      todayProduction: data['today_production'] as int? ?? 0,
      activeOrders: data['active_orders'] as int? ?? 0,
      pendingPayments: data['pending_payments'] as int? ?? 0,
      todayOrders: data['today_orders'] as int? ?? 0,
      processingOrders: data['processing_orders'] as int? ?? 0,
      revenueChart: (data['revenue_chart'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
    _dashboardCache[role] = stats;
    return stats;
  }

  Future<List<User>> getUsers({bool force = false}) async {
    if (!force && _usersCache != null) return _usersCache!;
    if (ApiConfig.useMockData) {
      _usersCache = MockData.users;
      return _usersCache!;
    }
    final data = await _api.get('/users');
    _usersCache = (data['data'] as List).map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
    return _usersCache!;
  }

  Future<User> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (ApiConfig.useMockData) {
      final user = User(
        id: (_usersCache?.length ?? 0) + 1,
        name: name,
        email: email,
        role: role,
      );
      _usersCache ??= [];
      _usersCache!.add(user);
      return user;
    }

    final data = await _api.post('/users', body: {
      'name': name,
      'email': email,
      'password': password,
      'role': _roleToApi(role),
    });
    final user = User.fromJson(data['data'] as Map<String, dynamic>);
    _usersCache ??= [];
    _usersCache!.add(user);
    return user;
  }

  Future<User> updateUser(
    int id, {
    required String name,
    required String email,
    required UserRole role,
    required bool isActive,
    String? password,
  }) async {
    if (ApiConfig.useMockData) {
      final index = _usersCache?.indexWhere((u) => u.id == id) ?? -1;
      if (index < 0) throw ApiException('Pengguna tidak ditemukan');
      final updated = User(
        id: id,
        name: name,
        email: email,
        role: role,
        isActive: isActive,
      );
      _usersCache![index] = updated;
      return updated;
    }

    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'role': _roleToApi(role),
      'is_active': isActive,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final data = await _api.put('/users/$id', body: body);
    final user = User.fromJson(data['data'] as Map<String, dynamic>);

    if (_usersCache != null) {
      final index = _usersCache!.indexWhere((u) => u.id == id);
      if (index >= 0) _usersCache![index] = user;
    }
    return user;
  }

  String _roleToApi(UserRole role) => switch (role) {
        UserRole.admin => 'admin',
        UserRole.kasir => 'kasir',
        UserRole.staffProduksi => 'staff_produksi',
      };

  Future<List<Customer>> getCustomers({bool force = false}) async {
    if (!force && _customersCache != null) return _customersCache!;
    if (ApiConfig.useMockData) {
      _customersCache = MockData.customers;
      return _customersCache!;
    }
    final data = await _api.get('/customers');
    _customersCache = (data['data'] as List).map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
    return _customersCache!;
  }

  Future<Customer> createCustomer({
    required String name,
    required String phone,
    String email = '',
    String address = '',
  }) async {
    if (ApiConfig.useMockData) {
      final customer = Customer(
        id: (_customersCache?.length ?? 0) + 1,
        name: name,
        phone: phone,
        email: email,
        address: address,
      );
      _customersCache ??= [];
      _customersCache!.add(customer);
      return customer;
    }

    final data = await _api.post('/customers', body: {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    });
    final customer = Customer.fromJson(data['data'] as Map<String, dynamic>);
    _customersCache ??= [];
    _customersCache!.add(customer);
    return customer;
  }

  Future<Customer> updateCustomer(
    int id, {
    required String name,
    required String phone,
    String email = '',
    String address = '',
  }) async {
    if (ApiConfig.useMockData) {
      final index = _customersCache?.indexWhere((c) => c.id == id) ?? -1;
      if (index < 0) throw ApiException('Pelanggan tidak ditemukan');
      final current = _customersCache![index];
      final updated = Customer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        orderCount: current.orderCount,
      );
      _customersCache![index] = updated;
      return updated;
    }

    final data = await _api.put('/customers/$id', body: {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    });
    final customer = Customer.fromJson(data['data'] as Map<String, dynamic>);

    if (_customersCache != null) {
      final index = _customersCache!.indexWhere((c) => c.id == id);
      if (index >= 0) _customersCache![index] = customer;
    }
    return customer;
  }

  Future<List<Order>> getOrders({bool force = false}) async {
    if (!force && _ordersCache != null) return _ordersCache!;
    if (ApiConfig.useMockData) {
      _ordersCache = MockData.orders;
      return _ordersCache!;
    }
    final data = await _api.get('/orders');
    _ordersCache = (data['data'] as List)
        .map((e) => _parseOrder(e as Map<String, dynamic>))
        .toList();
    return _ordersCache!;
  }

  Future<Order> createOrder({
    required int customerId,
    required List<Map<String, dynamic>> items,
    String notes = '',
  }) async {
    if (ApiConfig.useMockData) {
      final customer = _customersCache?.firstWhere(
        (c) => c.id == customerId,
        orElse: () => const Customer(id: 0, name: 'Pelanggan', phone: ''),
      );
      final orderItems = items.map((item) {
        final recipe = _recipesCache?.firstWhere((r) => r.id == item['recipe_id']);
        return OrderItem(
          recipeId: item['recipe_id'] as int,
          recipeName: recipe?.name ?? 'Menu',
          portions: item['portions'] as int,
          price: recipe?.price ?? 0,
        );
      }).toList();
      final total = orderItems.fold<double>(0, (sum, i) => sum + i.subtotal);
      final order = Order(
        id: (_ordersCache?.length ?? 0) + 1,
        orderNumber: 'ORD-MOCK-${DateTime.now().millisecondsSinceEpoch}',
        customerId: customerId,
        customerName: customer?.name ?? '',
        status: OrderStatus.confirmed,
        items: orderItems,
        totalAmount: total,
        orderDate: DateTime.now(),
        notes: notes,
      );
      _ordersCache ??= [];
      _ordersCache!.insert(0, order);
      return order;
    }

    final data = await _api.post('/orders', body: {
      'customer_id': customerId,
      'items': items,
      'notes': notes,
    });
    final order = _parseOrder(data['data'] as Map<String, dynamic>);
    _ordersCache ??= [];
    _ordersCache!.insert(0, order);
    _invalidateOperationalCaches();
    return order;
  }

  Future<List<RecipeCategory>> getRecipeCategories({bool force = false}) async {
    if (!force && _categoriesCache != null) return _categoriesCache!;
    if (ApiConfig.useMockData) {
      _categoriesCache = MockData.categories;
      return _categoriesCache!;
    }
    final data = await _api.get('/recipe-categories');
    _categoriesCache = (data['data'] as List)
        .map((e) => RecipeCategory(id: e['id'], name: e['name'], description: e['description'] ?? ''))
        .toList();
    return _categoriesCache!;
  }

  Future<RecipeCategory> createRecipeCategory({
    required String name,
    String description = '',
  }) async {
    if (ApiConfig.useMockData) {
      final category = RecipeCategory(
        id: (_categoriesCache?.length ?? 0) + 1,
        name: name,
        description: description,
      );
      _categoriesCache ??= [];
      _categoriesCache!.add(category);
      return category;
    }

    final data = await _api.post('/recipe-categories', body: {
      'name': name,
      'description': description,
    });
    final category = RecipeCategory(
      id: data['data']['id'],
      name: data['data']['name'],
      description: data['data']['description'] ?? '',
    );
    _categoriesCache ??= [];
    _categoriesCache!.add(category);
    return category;
  }

  Future<RecipeCategory> updateRecipeCategory(
    int id, {
    required String name,
    String description = '',
  }) async {
    if (ApiConfig.useMockData) {
      final index = _categoriesCache?.indexWhere((c) => c.id == id) ?? -1;
      if (index < 0) throw ApiException('Kategori tidak ditemukan');
      final updated = RecipeCategory(id: id, name: name, description: description);
      _categoriesCache![index] = updated;
      return updated;
    }

    final data = await _api.put('/recipe-categories/$id', body: {
      'name': name,
      'description': description,
    });
    final category = RecipeCategory(
      id: data['data']['id'],
      name: data['data']['name'],
      description: data['data']['description'] ?? '',
    );

    if (_categoriesCache != null) {
      final index = _categoriesCache!.indexWhere((c) => c.id == id);
      if (index >= 0) _categoriesCache![index] = category;
    }
    return category;
  }

  Future<List<Recipe>> getRecipes({bool force = false}) async {
    if (!force && _recipesCache != null) return _recipesCache!;
    if (ApiConfig.useMockData) {
      _recipesCache = MockData.recipes;
      return _recipesCache!;
    }
    final data = await _api.get('/recipes');
    _recipesCache = (data['data'] as List).map((e) => _parseRecipe(e as Map<String, dynamic>)).toList();
    return _recipesCache!;
  }

  Future<RecipeDetail> getRecipeDetail(int id) async {
    if (ApiConfig.useMockData) {
      final recipe = _recipesCache?.firstWhere((r) => r.id == id);
      if (recipe == null) throw ApiException('Resep tidak ditemukan');
      return RecipeDetail(
        id: recipe.id,
        name: recipe.name,
        categoryId: recipe.categoryId,
        categoryName: recipe.categoryName,
        price: recipe.price,
        servings: recipe.servings,
        description: recipe.description,
      );
    }

    final data = await _api.get('/recipes/$id');
    return RecipeDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Recipe> createRecipe({
    required String name,
    required int categoryId,
    required double price,
    required int servings,
    String description = '',
    List<Map<String, dynamic>> ingredients = const [],
    List<String> steps = const [],
  }) async {
    if (ApiConfig.useMockData) {
      final categoryName = _categoriesCache
              ?.firstWhere((c) => c.id == categoryId, orElse: () => const RecipeCategory(id: 0, name: ''))
              .name ??
          '';
      final recipe = Recipe(
        id: (_recipesCache?.length ?? 0) + 1,
        name: name,
        categoryId: categoryId,
        categoryName: categoryName,
        price: price,
        servings: servings,
        description: description,
      );
      _recipesCache ??= [];
      _recipesCache!.add(recipe);
      return recipe;
    }

    final data = await _api.post('/recipes', body: {
      'name': name,
      'category_id': categoryId,
      'price': price,
      'servings': servings,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
    });
    final recipe = _parseRecipe(data['data'] as Map<String, dynamic>);
    _recipesCache ??= [];
    _recipesCache!.add(recipe);
    return recipe;
  }

  Future<Recipe> updateRecipe(
    int id, {
    required String name,
    required int categoryId,
    required double price,
    required int servings,
    String description = '',
    List<Map<String, dynamic>> ingredients = const [],
    List<String> steps = const [],
  }) async {
    if (ApiConfig.useMockData) {
      final index = _recipesCache?.indexWhere((r) => r.id == id) ?? -1;
      if (index < 0) throw ApiException('Resep tidak ditemukan');
      final categoryName = _categoriesCache
              ?.firstWhere((c) => c.id == categoryId, orElse: () => const RecipeCategory(id: 0, name: ''))
              .name ??
          '';
      final updated = Recipe(
        id: id,
        name: name,
        categoryId: categoryId,
        categoryName: categoryName,
        price: price,
        servings: servings,
        description: description,
      );
      _recipesCache![index] = updated;
      return updated;
    }

    final data = await _api.put('/recipes/$id', body: {
      'name': name,
      'category_id': categoryId,
      'price': price,
      'servings': servings,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
    });
    final recipe = _parseRecipe(data['data'] as Map<String, dynamic>);

    if (_recipesCache != null) {
      final index = _recipesCache!.indexWhere((r) => r.id == id);
      if (index >= 0) _recipesCache![index] = recipe;
    }
    return recipe;
  }

  Recipe _parseRecipe(Map<String, dynamic> e) {
    return Recipe(
      id: e['id'],
      name: e['name'],
      categoryId: e['category_id'],
      categoryName: e['category_name'] ?? '',
      price: (e['price'] as num).toDouble(),
      servings: e['servings'] ?? 1,
      description: e['description'] ?? '',
    );
  }

  Future<List<Ingredient>> getIngredients({bool force = false}) async {
    if (!force && _ingredientsCache != null) return _ingredientsCache!;
    if (ApiConfig.useMockData) {
      _ingredientsCache = MockData.ingredients;
      return _ingredientsCache!;
    }
    final data = await _api.get('/ingredients');
    _ingredientsCache = (data['data'] as List).map((e) {
      return Ingredient(
        id: e['id'],
        name: e['name'],
        unit: e['unit'],
        stock: (e['stock'] as num).toDouble(),
        minStock: (e['min_stock'] as num).toDouble(),
        price: (e['price'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
    return _ingredientsCache!;
  }

  Future<Ingredient> restockIngredient(int id, double quantity, {String? notes}) async {
    if (ApiConfig.useMockData) {
      final index = _ingredientsCache?.indexWhere((i) => i.id == id) ?? -1;
      if (index < 0) throw ApiException('Bahan tidak ditemukan');
      final current = _ingredientsCache![index];
      final updated = Ingredient(
        id: current.id,
        name: current.name,
        unit: current.unit,
        stock: current.stock + quantity,
        minStock: current.minStock,
        price: current.price,
      );
      _ingredientsCache![index] = updated;
      return updated;
    }

    final data = await _api.post('/ingredients/$id/restock', body: {
      'quantity': quantity,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final e = data['data'] as Map<String, dynamic>;
    final updated = Ingredient(
      id: e['id'],
      name: e['name'],
      unit: e['unit'],
      stock: (e['stock'] as num).toDouble(),
      minStock: (e['min_stock'] as num).toDouble(),
      price: (e['price'] as num?)?.toDouble() ?? 0,
    );

    if (_ingredientsCache != null) {
      final index = _ingredientsCache!.indexWhere((i) => i.id == id);
      if (index >= 0) _ingredientsCache![index] = updated;
    }
    return updated;
  }

  Future<List<ProductionSchedule>> getProductions({bool force = false}) async {
    if (!force && _productionsCache != null) return _productionsCache!;
    if (ApiConfig.useMockData) {
      _productionsCache = MockData.productions;
      return _productionsCache!;
    }
    final data = await _api.get('/production');
    _productionsCache = (data['data'] as List).map((e) {
      return ProductionSchedule(
        id: e['id'],
        orderId: e['order_id'],
        orderNumber: e['order_number'],
        recipeName: e['recipe_name'],
        portions: e['portions'],
        scheduledDate: DateTime.parse(e['scheduled_date']),
        status: e['status'],
        assignedTo: e['assigned_to'] ?? '',
      );
    }).toList();
    return _productionsCache!;
  }

  Future<ProductionSchedule> updateProductionStatus(int id, String status) async {
    if (ApiConfig.useMockData) {
      final index = _productionsCache?.indexWhere((s) => s.id == id) ?? -1;
      if (index < 0) throw ApiException('Jadwal produksi tidak ditemukan');
      final current = _productionsCache![index];
      final updated = ProductionSchedule(
        id: current.id,
        orderId: current.orderId,
        orderNumber: current.orderNumber,
        recipeName: current.recipeName,
        portions: current.portions,
        scheduledDate: current.scheduledDate,
        status: status,
        assignedTo: current.assignedTo,
      );
      _productionsCache![index] = updated;
      return updated;
    }

    final data = await _api.put('/production/$id', body: {'status': status});
    final e = data['data'] as Map<String, dynamic>;
    final updated = ProductionSchedule(
      id: e['id'],
      orderId: e['order_id'],
      orderNumber: e['order_number'],
      recipeName: e['recipe_name'],
      portions: e['portions'],
      scheduledDate: DateTime.parse(e['scheduled_date']),
      status: e['status'],
      assignedTo: e['assigned_to'] ?? '',
    );

    if (_productionsCache != null) {
      final index = _productionsCache!.indexWhere((s) => s.id == id);
      if (index >= 0) _productionsCache![index] = updated;
    }
    _ordersCache = null;
    _dashboardCache.clear();
    return updated;
  }

  Future<List<Payment>> getPayments({bool force = false}) async {
    if (!force && _paymentsCache != null) return _paymentsCache!;
    if (ApiConfig.useMockData) {
      _paymentsCache = MockData.payments;
      return _paymentsCache!;
    }
    final data = await _api.get('/payments');
    _paymentsCache = (data['data'] as List).map((e) {
      return Payment(
        id: e['id'],
        orderId: e['order_id'],
        orderNumber: e['order_number'],
        customerName: e['customer_name'],
        amount: (e['amount'] as num).toDouble(),
        method: e['method'],
        status: e['status'],
        paidAt: DateTime.parse(e['paid_at']),
      );
    }).toList();
    return _paymentsCache!;
  }

  Future<Payment> createPayment({
    required int orderId,
    required String method,
    double? amount,
  }) async {
    if (ApiConfig.useMockData) {
      final order = _ordersCache?.firstWhere((o) => o.id == orderId);
      final payment = Payment(
        id: (_paymentsCache?.length ?? 0) + 1,
        orderId: orderId,
        orderNumber: order?.orderNumber ?? '',
        customerName: order?.customerName ?? '',
        amount: amount ?? order?.totalAmount ?? 0,
        method: method,
        status: 'confirmed',
        paidAt: DateTime.now(),
      );
      _paymentsCache ??= [];
      _paymentsCache!.insert(0, payment);
      return payment;
    }

    final body = <String, dynamic>{
      'order_id': orderId,
      'method': method,
    };
    if (amount != null) body['amount'] = amount;

    final data = await _api.post('/payments', body: body);
    final e = data['data'] as Map<String, dynamic>;
    final payment = Payment(
      id: e['id'],
      orderId: e['order_id'],
      orderNumber: e['order_number'],
      customerName: e['customer_name'],
      amount: (e['amount'] as num).toDouble(),
      method: e['method'],
      status: e['status'],
      paidAt: DateTime.parse(e['paid_at']),
    );

    _paymentsCache ??= [];
    _paymentsCache!.insert(0, payment);
    _ordersCache = null;
    _dashboardCache.clear();
    return payment;
  }

  void _invalidateOperationalCaches() {
    _ordersCache = null;
    _productionsCache = null;
    _paymentsCache = null;
    _ingredientsCache = null;
    _dashboardCache.clear();
  }

  Future<ReportSummary> getReport(String type, String period) async {
    if (ApiConfig.useMockData) {
      return _mockReport(type, period);
    }
    final data = await _api.get('/reports/$type', query: {'period': period});
    return ReportSummary(
      title: data['title'] as String,
      period: period,
      rows: (data['rows'] as List).cast<Map<String, dynamic>>(),
      total: (data['total'] as num?)?.toDouble() ?? 0,
    );
  }

  Order _parseOrder(Map<String, dynamic> e) {
    return Order(
      id: e['id'],
      orderNumber: e['order_number'],
      customerId: e['customer_id'],
      customerName: e['customer_name'],
      status: OrderStatus.values.firstWhere(
        (s) => s.name == e['status'],
        orElse: () => OrderStatus.draft,
      ),
      items: (e['items'] as List).map((i) {
        return OrderItem(
          recipeId: i['recipe_id'],
          recipeName: i['recipe_name'],
          portions: i['portions'],
          price: (i['price'] as num).toDouble(),
        );
      }).toList(),
      totalAmount: (e['total_amount'] as num).toDouble(),
      orderDate: DateTime.parse(e['order_date']),
      notes: e['notes'] ?? '',
      paymentStatus: e['payment_status'] ?? 'pending',
    );
  }

  ReportSummary _mockReport(String type, String period) {
    switch (type) {
      case 'sales':
        return ReportSummary(
          title: 'Laporan Penjualan',
          period: period,
          total: 48500000,
          rows: [
            {'menu': 'Nasi Box Ayam Bakar', 'qty': 320, 'revenue': 11200000},
            {'menu': 'Prasmanan Nasi Kuning', 'qty': 180, 'revenue': 8100000},
            {'menu': 'Kue Tart Coklat', 'qty': 45, 'revenue': 11250000},
          ],
        );
      case 'orders':
        return ReportSummary(
          title: 'Laporan Pesanan',
          period: period,
          total: 156,
          rows: [
            {'status': 'Selesai', 'count': 120},
            {'status': 'Produksi', 'count': 18},
            {'status': 'Dikonfirmasi', 'count': 12},
            {'status': 'Dibatalkan', 'count': 6},
          ],
        );
      case 'inventory':
        return ReportSummary(
          title: 'Laporan Inventori',
          period: period,
          rows: MockData.ingredients
              .map((i) => {'bahan': i.name, 'stok': i.stock, 'unit': i.unit, 'status': i.isLowStock ? 'Rendah' : 'Aman'})
              .toList(),
        );
      case 'ingredients':
        return ReportSummary(
          title: 'Laporan Penggunaan Bahan',
          period: period,
          total: 12500000,
          rows: [
            {'bahan': 'Beras', 'used': 120, 'unit': 'kg', 'cost': 1440000},
            {'bahan': 'Ayam Potong', 'used': 85, 'unit': 'kg', 'cost': 2975000},
            {'bahan': 'Minyak Goreng', 'used': 40, 'unit': 'liter', 'cost': 720000},
          ],
        );
      default:
        return ReportSummary(
          title: 'Analisis Pendapatan',
          period: period,
          total: 48500000,
          rows: [
            {'bulan': 'Jan', 'pendapatan': 32000000},
            {'bulan': 'Feb', 'pendapatan': 38000000},
            {'bulan': 'Mar', 'pendapatan': 42000000},
            {'bulan': 'Apr', 'pendapatan': 45000000},
            {'bulan': 'Mei', 'pendapatan': 48500000},
          ],
        );
    }
  }
}
