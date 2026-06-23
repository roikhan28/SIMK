import '../core/rbac.dart';
import '../models/models.dart';

class MockData {
  static final users = [
    const User(id: 1, name: 'Administrator', email: 'admin@simk.id', role: UserRole.admin),
    const User(id: 2, name: 'Budi Santoso', email: 'kasir@simk.id', role: UserRole.kasir),
    const User(id: 3, name: 'Siti Aminah', email: 'produksi@simk.id', role: UserRole.staffProduksi),
    const User(id: 4, name: 'Rina Wijaya', email: 'rina@simk.id', role: UserRole.kasir),
  ];

  static final customers = [
    const Customer(id: 1, name: 'PT Maju Jaya', phone: '081234567890', email: 'info@majujaya.com', address: 'Jl. Sudirman No. 10', orderCount: 12),
    const Customer(id: 2, name: 'Ibu Dewi', phone: '081298765432', address: 'Perumahan Green Valley Blok A5', orderCount: 5),
    const Customer(id: 3, name: 'Kantor BPKAD', phone: '0274123456', email: 'bpkad@go.id', address: 'Jl. Pemuda No. 1', orderCount: 8),
    const Customer(id: 4, name: 'Pak Hartono', phone: '085612345678', address: 'Jl. Merdeka No. 25', orderCount: 3),
  ];

  static final categories = [
    const RecipeCategory(id: 1, name: 'Menu Utama', description: 'Hidangan utama katering'),
    const RecipeCategory(id: 2, name: 'Snack', description: 'Camilan dan kue'),
    const RecipeCategory(id: 3, name: 'Minuman', description: 'Minuman segar'),
  ];

  static final recipes = [
    const Recipe(id: 1, name: 'Nasi Box Ayam Bakar', categoryId: 1, categoryName: 'Menu Utama', price: 35000, servings: 1),
    const Recipe(id: 2, name: 'Nasi Box Ikan Goreng', categoryId: 1, categoryName: 'Menu Utama', price: 38000, servings: 1),
    const Recipe(id: 3, name: 'Prasmanan Nasi Kuning', categoryId: 1, categoryName: 'Menu Utama', price: 45000, servings: 1),
    const Recipe(id: 4, name: 'Kue Tart Coklat', categoryId: 2, categoryName: 'Snack', price: 250000, servings: 20),
    const Recipe(id: 5, name: 'Es Teh Manis', categoryId: 3, categoryName: 'Minuman', price: 5000, servings: 1),
  ];

  static final ingredients = [
    const Ingredient(id: 1, name: 'Beras', unit: 'kg', stock: 50, minStock: 20, price: 12000),
    const Ingredient(id: 2, name: 'Ayam Potong', unit: 'kg', stock: 15, minStock: 10, price: 35000),
    const Ingredient(id: 3, name: 'Ikan Kakap', unit: 'kg', stock: 8, minStock: 10, price: 55000),
    const Ingredient(id: 4, name: 'Minyak Goreng', unit: 'liter', stock: 25, minStock: 10, price: 18000),
    const Ingredient(id: 5, name: 'Gula Pasir', unit: 'kg', stock: 5, minStock: 8, price: 14000),
    const Ingredient(id: 6, name: 'Telur', unit: 'kg', stock: 12, minStock: 5, price: 28000),
  ];

  static final orders = [
    Order(
      id: 1,
      orderNumber: 'ORD-20240610-001',
      customerId: 1,
      customerName: 'PT Maju Jaya',
      status: OrderStatus.inProduction,
      items: const [
        OrderItem(recipeId: 1, recipeName: 'Nasi Box Ayam Bakar', portions: 50, price: 35000),
        OrderItem(recipeId: 5, recipeName: 'Es Teh Manis', portions: 50, price: 5000),
      ],
      totalAmount: 2000000,
      orderDate: DateTime(2024, 6, 10, 8, 30),
      paymentStatus: 'paid',
    ),
    Order(
      id: 2,
      orderNumber: 'ORD-20240610-002',
      customerId: 2,
      customerName: 'Ibu Dewi',
      status: OrderStatus.confirmed,
      items: const [
        OrderItem(recipeId: 4, recipeName: 'Kue Tart Coklat', portions: 2, price: 250000),
      ],
      totalAmount: 500000,
      orderDate: DateTime(2024, 6, 10, 10, 15),
      paymentStatus: 'pending',
    ),
    Order(
      id: 3,
      orderNumber: 'ORD-20240609-003',
      customerId: 3,
      customerName: 'Kantor BPKAD',
      status: OrderStatus.ready,
      items: const [
        OrderItem(recipeId: 3, recipeName: 'Prasmanan Nasi Kuning', portions: 100, price: 45000),
      ],
      totalAmount: 4500000,
      orderDate: DateTime(2024, 6, 9, 14, 0),
      paymentStatus: 'paid',
    ),
  ];

  static final productions = [
    ProductionSchedule(
      id: 1,
      orderId: 1,
      orderNumber: 'ORD-20240610-001',
      recipeName: 'Nasi Box Ayam Bakar',
      portions: 50,
      scheduledDate: DateTime(2024, 6, 10, 6, 0),
      status: 'in_progress',
      assignedTo: 'Siti Aminah',
    ),
    ProductionSchedule(
      id: 2,
      orderId: 2,
      orderNumber: 'ORD-20240610-002',
      recipeName: 'Kue Tart Coklat',
      portions: 2,
      scheduledDate: DateTime(2024, 6, 10, 7, 0),
      status: 'scheduled',
      assignedTo: 'Siti Aminah',
    ),
    ProductionSchedule(
      id: 3,
      orderId: 3,
      orderNumber: 'ORD-20240609-003',
      recipeName: 'Prasmanan Nasi Kuning',
      portions: 100,
      scheduledDate: DateTime(2024, 6, 9, 5, 0),
      status: 'completed',
      assignedTo: 'Siti Aminah',
    ),
  ];

  static final payments = [
    Payment(
      id: 1,
      orderId: 1,
      orderNumber: 'ORD-20240610-001',
      customerName: 'PT Maju Jaya',
      amount: 2000000,
      method: 'Transfer Bank',
      status: 'confirmed',
      paidAt: DateTime(2024, 6, 10, 9, 0),
    ),
    Payment(
      id: 2,
      orderId: 3,
      orderNumber: 'ORD-20240609-003',
      customerName: 'Kantor BPKAD',
      amount: 4500000,
      method: 'Transfer Bank',
      status: 'confirmed',
      paidAt: DateTime(2024, 6, 9, 15, 30),
    ),
  ];

  static DashboardStats adminDashboard() => const DashboardStats(
        totalOrders: 156,
        totalRevenue: 48500000,
        lowStockCount: 2,
        todayProduction: 3,
        revenueChart: [12, 18, 15, 22, 28, 25, 32],
      );

  static DashboardStats kasirDashboard() => const DashboardStats(
        activeOrders: 5,
        pendingPayments: 2,
        todayOrders: 8,
      );

  static DashboardStats produksiDashboard() => const DashboardStats(
        todayProduction: 3,
        processingOrders: 2,
      );

  static AuthResponse? login(String email, String password) {
    const credentials = {
      'admin@simk.id': 'admin123',
      'kasir@simk.id': 'kasir123',
      'produksi@simk.id': 'produksi123',
    };

    if (credentials[email] != password) return null;

    final user = users.firstWhere((u) => u.email == email);
    return AuthResponse(
      token: 'mock_jwt_token_${user.id}',
      refreshToken: 'mock_refresh_token_${user.id}',
      user: user,
    );
  }
}
