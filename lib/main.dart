flutter create --platforms=windows,linux,macos library_manager
cd library_manager
name: library_manager
description: إدارة مكتبتي - نظام إدارة مكتبة ومخزن ومبيعات
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # قاعدة البيانات
  drift: ^2.20.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0

  # إدارة الحالة
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # الأمان
  password_guard: ^1.0.0
  flutter_secure_storage: ^9.2.2

  # التصدير
  flutter_pdf_invoice_widgets: ^1.0.1
  syncfusion_flutter_xlsio: ^26.2.7
  printing: ^5.13.2

  # أدوات
  intl: ^0.19.0
  uuid: ^4.4.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.20.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.2

flutter:
  uses-material-design: true
  assets:
    - assets/fonts/Cairo-Regular.ttf
    - assets/fonts/Cairo-Bold.ttf
    lib/
├── main.dart
├── core/
│   ├── app_theme.dart
│   ├── rtl_wrapper.dart
│   └── permissions.dart
├── data/
│   ├── database/
│   │   ├── app_database.dart
│   │   ├── app_database.g.dart   (مُولَّد)
│   │   └── tables/
│   │       ├── users.dart
│   │       ├── products.dart
│   │       ├── stock_movements.dart
│   │       ├── sales.dart
│   │       ├── expenses.dart
│   │       └── audit_logs.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── inventory_repository.dart
│       ├── sales_repository.dart
│       └── reports_repository.dart
├── features/
│   ├── auth/login_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── products/products_screen.dart
│   ├── warehouse/warehouse_screen.dart
│   ├── pos/pos_screen.dart
│   ├── sales_history/sales_history_screen.dart
│   ├── profits/profits_screen.dart
│   ├── reports/reports_screen.dart
│   └── settings/settings_screen.dart
└── providers/
    ├── auth_provider.dart
    ├── database_provider.dart
    └── dashboard_provider.dart
    import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text().withDefault(const Constant('employee'))(); // admin / employee
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get imagePath => text().nullable()();

  // الكميات
  IntColumn get quantityInShop => integer().withDefault(const Constant(0))();
  IntColumn get quantityInWarehouse => integer().withDefault(const Constant(0))();
  IntColumn get minShopQuantity => integer().withDefault(const Constant(5))();
  IntColumn get minWarehouseQuantity => integer().withDefault(const Constant(10))();

  // الأسعار
  RealColumn get purchasePrice => real()(); // سعر الشراء/الجملة (للمدير فقط في الواجهة)
  RealColumn get sellingPrice => real()();

  DateTimeColumn get lastSupplyDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
class PurchaseBatches extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantityReceived => integer()();
  IntColumn get quantityRemaining => integer()();
  RealColumn get unitCost => real()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get note => text().nullable()();
}
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get type => text()(); // supply / transfer_to_shop / sale / return / adjustment
  IntColumn get quantity => integer()(); // موجب للدخول، سالب للخروج
  TextColumn get location => text()(); // warehouse / shop
  IntColumn get referenceId => integer().nullable()(); // invoiceId أو batchId
  TextColumn get reason => text().nullable()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get invoiceNumber => text().unique()();
  IntColumn get userId => integer().references(Users, #id)();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get totalCost => real()();
  RealColumn get totalProfit => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('cash'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isVoided => boolean().withDefault(const Constant(false))();
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  RealColumn get unitSellingPrice => real()(); // سعر البيع وقت البيع
  RealColumn get unitCost => real()(); // تكلفة الشراء وقت البيع (FIFO)
  RealColumn get total => real()();
  RealColumn get profit => real()();
}
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  IntColumn get userId => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().references(Users, #id)();
  TextColumn get action => text()();
  TextColumn get entity => text()();
  IntColumn get entityId => integer().nullable()();
  TextColumn get details => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/users.dart';
import 'tables/products.dart';
import 'tables/stock_movements.dart';
import 'tables/sales.dart';
import 'tables/expenses.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Products,
    PurchaseBatches,
    StockMovements,
    Invoices,
    InvoiceItems,
    Expenses,
    AuditLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'library_manager.sqlite'));
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        // WAL لتحسين الأداء ومنع تعارض القراءة والكتابة
        db.execute('pragma journal_mode = WAL;');
        db.execute('pragma foreign_keys = ON;');
      },
    );
  });
}
dart run build_runner build --delete-conflicting-outputs
import 'package:password_guard/password_guard.dart';

Future<void> createInitialAdmin(String username, String password) async {
  final result = await PasswordGuard.hash(password: password);
  await db.into(db.users).insert(
        UsersCompanion.insert(
          username: username,
          passwordHash: result.hash, // يُخزَّن الهاش فقط
          role: const Value('admin'),
        ),
      );
}
enum Permission {
  viewPurchasePrices,
  viewProfits,
  editProducts,
  deleteProducts,
  manageUsers,
  voidInvoice,
  viewReports,
  exportData,
}

class AuthService {
  final AppDatabase db;
  User? currentUser;

  bool can(Permission permission) {
    if (currentUser == null) return false;
    if (currentUser!.role == 'admin') return true;
    // صلاحيات الموظف الافتراضية
    switch (permission) {
      case Permission.viewPurchasePrices:
      case Permission.viewProfits:
      case Permission.editProducts:
      case Permission.deleteProducts:
      case Permission.manageUsers:
      case Permission.voidInvoice:
        return false;
      case Permission.viewReports:
        return false;
      case Permission.exportData:
        return false;
      default:
        return false;
    }
  }
}
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class SalesRepository {
  final AppDatabase db;
  final AuthService auth;
  final _uuid = const Uuid();

  SalesRepository(this.db, this.auth);

  Future<Invoice> createSale({
    required List<SaleLine> lines,
    double discount = 0,
    String paymentMethod = 'cash',
  }) async {
    // 1. التحقق من الصلاحية
    if (auth.currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولًا');
    }

    // 2. التحقق من توفر الكميات
    for (final line in lines) {
      final product = await (db.select(db.products)
            ..where((p) => p.id.equals(line.productId)))
          .getSingle();
      if (product.quantityInShop < line.quantity) {
        throw Exception(
            'الكمية المطلوبة من "${product.name}" غير متوفرة. المتاح: ${product.quantityInShop}');
      }
    }

    // 3. تنفيذ المعاملة
    return db.transaction(() async {
      double subtotal = 0;
      double totalCost = 0;

      final invoiceCompanion = InvoicesCompanion.insert(
        invoiceNumber: _generateInvoiceNumber(),
        userId: auth.currentUser!.id,
        subtotal: const Value(0),
        discount: Value(discount),
        total: const Value(0),
        totalCost: const Value(0),
        totalProfit: const Value(0),
        paymentMethod: Value(paymentMethod),
      );

      final invoiceId = await db.into(db.invoices).insert(invoiceCompanion);

      for (final line in lines) {
        final product = await (db.select(db.products)
              ..where((p) => p.id.equals(line.productId)))
            .getSingle();

        // خصم الكمية من المكتبة
        await (db.update(db.products)
              ..where((p) => p.id.equals(line.productId)))
            .write(ProductsCompanion(
          quantityInShop: Value(product.quantityInShop - line.quantity),
        ));

        // حساب تكلفة البيع بطريقة FIFO
        final cost = await _consumeFifoCost(line.productId, line.quantity);

        final lineTotal = line.quantity * line.unitSellingPrice;
        final lineProfit = lineTotal - cost;
        subtotal += lineTotal;
        totalCost += cost;

        // حفظ تفاصيل الفاتورة مع سعر البيع والتكلفة وقت البيع
        await db.into(db.invoiceItems).insert(InvoiceItemsCompanion.insert(
              invoiceId: invoiceId,
              productId: line.productId,
              quantity: line.quantity,
              unitSellingPrice: line.unitSellingPrice,
              unitCost: cost / line.quantity,
              total: lineTotal,
              profit: lineProfit,
            ));

        // تسجيل حركة المخزون
        await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
              productId: line.productId,
              type: 'sale',
              quantity: -line.quantity,
              location: 'shop',
              referenceId: Value(invoiceId),
              userId: auth.currentUser!.id,
            ));
      }

      final total = subtotal - discount;
      final totalProfit = subtotal - totalCost - discount;

      // تحديث الفاتورة بالإجماليات
      await (db.update(db.invoices)..where((i) => i.id.equals(invoiceId))).write(
        InvoicesCompanion(
          subtotal: Value(subtotal),
          total: Value(total),
          totalCost: Value(totalCost),
          totalProfit: Value(totalProfit),
        ),
      );

      // تسجيل العملية في سجل التعديلات
      await db.into(db.auditLogs).insert(AuditLogsCompanion.insert(
            userId: auth.currentUser!.id,
            action: 'create_sale',
            entity: 'invoice',
            entityId: Value(invoiceId),
            details: 'تم إنشاء فاتورة بقيمة $total جنيه',
          ));

      return (db.select(db.invoices)..where((i) => i.id.equals(invoiceId)))
          .getSingle();
    });
  }

  /// استهلاك دفعات FIFO وإرجاع التكلفة الفعلية للكمية المباعة
  Future<double> _consumeFifoCost(int productId, int quantity) async {
    final batches = await (db.select(db.purchaseBatches)
          ..where((b) =>
              b.productId.equals(productId) & b.quantityRemaining.isBiggerThanValue(0))
          ..orderBy([(b) => OrderingTerm(expression: b.receivedAt)]))
        .get();

    int remaining = quantity;
    double totalCost = 0;

    for (final batch in batches) {
      if (remaining <= 0) break;
      final take = remaining < batch.quantityRemaining
          ? remaining
          : batch.quantityRemaining;
      totalCost += take * batch.unitCost;
      remaining -= take;

      await (db.update(db.purchaseBatches)
            ..where((b) => b.id.equals(batch.id)))
          .write(PurchaseBatchesCompanion(
        quantityRemaining: Value(batch.quantityRemaining - take),
      ));
    }

    if (remaining > 0) {
      throw Exception('لا توجد دفعات شراء كافية لهذا الصنف');
    }

    return totalCost;
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 6)}';
  }
}

class SaleLine {
  final int productId;
  final int quantity;
  final double unitSellingPrice;
  SaleLine(this.productId, this.quantity, this.unitSellingPrice);
}
Future<DailyProfit> getDailyProfit(DateTime day) async {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));

  final invoices = await (db.select(db.invoices)
        ..where((i) =>
            i.createdAt.isBiggerOrEqualValue(start) &
            i.createdAt.isSmallerThanValue(end) &
            i.isVoided.equals(false)))
      .get();

  final totalSales = invoices.fold<double>(0, (s, i) => s + i.total);
  final totalCost = invoices.fold<double>(0, (s, i) => s + i.totalCost);
  final totalProfit = invoices.fold<double>(0, (s, i) => s + i.totalProfit);

  final expenses = await (db.select(db.expenses)
        ..where((e) =>
            e.createdAt.isBiggerOrEqualValue(start) &
            e.createdAt.isSmallerThanValue(end)))
      .get();
  final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);

  return DailyProfit(
    totalSales: totalSales,
    totalCost: totalCost,
    grossProfit: totalProfit,
    totalExpenses: totalExpenses,
    netProfit: totalProfit - totalExpenses,
    profitMargin: totalSales > 0 ? (totalProfit / totalSales) * 100 : 0,
    markupOnCost: totalCost > 0 ? (totalProfit / totalCost) * 100 : 0,
  );
}
Future<void> transferToShop(int productId, int quantity) async {
  if (!auth.can(Permission.editProducts)) {
    throw Exception('غير مصرح');
  }

  await db.transaction(() async {
    final product = await (db.select(db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingle();

    if (product.quantityInWarehouse < quantity) {
      throw Exception('الكمية في المخزن غير كافية');
    }

    await (db.update(db.products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        quantityInWarehouse: Value(product.quantityInWarehouse - quantity),
        quantityInShop: Value(product.quantityInShop + quantity),
      ),
    );

    // سجل حركتين منفصلتين لتتبع دقيق
    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          productId: productId,
          type: 'transfer_out',
          quantity: -quantity,
          location: 'warehouse',
          userId: auth.currentUser!.id,
        ));

    await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
          productId: productId,
          type: 'transfer_in',
          quantity: quantity,
          location: 'shop',
          userId: auth.currentUser!.id,
        ));
  });
}
import 'package:flutter/material.dart';

class RtlWrapper extends StatelessWidget {
  final Widget child;
  const RtlWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/rtl_wrapper.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: LibraryApp()));
}

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة مكتبتي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        fontFamily: 'Cairo',
        textDirection: TextDirection.rtl,
      ),
      builder: (context, child) => RtlWrapper(child: child!),
      home: const LoginScreen(),
    );
  }
}
import 'package:flutter_pdf_invoice_widgets/flutter_pdf_invoice_widgets.dart';

Future<List<int>> generateInvoicePdf(Invoice invoice, List<InvoiceItem> items) async {
  final document = InvoiceDocument(
    type: InvoiceDocumentType.receipt,
    company: CompanyInfo(name: 'مكتبتي', city: 'القاهرة', country: 'مصر'),
    customer: CustomerInfo(name: 'عميل نقدي'),
    info: InvoiceInfo(
      invoiceNumber: invoice.invoiceNumber,
      invoiceDate: invoice.createdAt,
      currency: 'EGP',
      currencySymbol: 'ج.م',
    ),
    items: items.map((i) => InvoiceItem(
      description: 'صنف رقم ${i.productId}',
      quantity: i.quantity,
      unit: 'قطعة',
      unitPrice: i.unitSellingPrice,
    )).toList(),
  );

  final template = InvoiceTemplateRegistry().create(document);
  final bytes = await template.generate();
  return bytes;
}
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

Future<List<int>> exportSalesToExcel(List<Invoice> invoices) async {
  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'المبيعات';

  // العناوين
  sheet.getRangeByName('A1').setText('رقم الفاتورة');
  sheet.getRangeByName('B1').setText('التاريخ');
  sheet.getRangeByName('C1').setText('الإجمالي');
  sheet.getRangeByName('D1').setText('الربح');

  for (var i = 0; i < invoices.length; i++) {
    final row = i + 2;
    sheet.getRangeByIndex(row, 1).setText(invoices[i].invoiceNumber);
    sheet.getRangeByIndex(row, 2).setText(invoices[i].createdAt.toString());
    sheet.getRangeByIndex(row, 3).setNumber(invoices[i].total);
    sheet.getRangeByIndex(row, 4).setNumber(invoices[i].totalProfit);
  }

  final bytes = workbook.saveSync();
  workbook.dispose();
  return bytes;
}
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final today = await getDailyProfit(now);
  final month = await getMonthlyProfit(now.year, now.month);

  final lowStock = await (db.select(db.products)
        ..where((p) =>
            p.quantityInShop.isSmallerOrEqual(p.minShopQuantity) &
            p.quantityInShop.isBiggerThanValue(0)))
      .get();

  final outOfStock = await (db.select(db.products)
        ..where((p) => p.quantityInShop.equals(0)))
      .get();

  return DashboardData(
    todaySales: today.totalSales,
    todayProfit: today.grossProfit,
    monthSales: month.totalSales,
    monthProfit: month.grossProfit,
    lowStockCount: lowStock.length,
    outOfStockCount: outOfStock.length,
    totalProducts: await db.products.count().getSingle(),
  );
});