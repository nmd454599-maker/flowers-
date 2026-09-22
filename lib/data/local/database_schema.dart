import 'package:sqflite/sqflite.dart';

/// Versioned, additive schema. Existing account identifiers are never rewritten.
class DatabaseSchema {
  static const version = 8;
  static Future<void> create(Database database) async {
    await database.execute('''CREATE TABLE users(
          id TEXT PRIMARY KEY, name TEXT NOT NULL, phone TEXT UNIQUE NOT NULL,
          role TEXT NOT NULL, account_type TEXT NOT NULL DEFAULT 'customer',
          points INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)''');
    await database.execute('''CREATE TABLE stores(
          id TEXT PRIMARY KEY, name TEXT NOT NULL, city TEXT NOT NULL,
          rating REAL NOT NULL, emoji TEXT NOT NULL, min_order INTEGER NOT NULL,
          delivery_minutes INTEGER NOT NULL, latitude REAL, longitude REAL)''');
    await database.execute('''CREATE TABLE products(
          id TEXT PRIMARY KEY, store_id TEXT NOT NULL, name TEXT NOT NULL,
          category TEXT NOT NULL, price INTEGER NOT NULL, emoji TEXT NOT NULL,
          rating REAL NOT NULL, description TEXT NOT NULL, image_url TEXT, image_urls TEXT,
          FOREIGN KEY(store_id) REFERENCES stores(id))''');
    await database.execute('''CREATE TABLE favorites(
          user_id TEXT NOT NULL, product_id TEXT NOT NULL,
          PRIMARY KEY(user_id, product_id))''');
    await database.execute('''CREATE TABLE orders(
          id TEXT PRIMARY KEY, user_id TEXT, address TEXT NOT NULL,
          delivery_fee INTEGER NOT NULL, status TEXT NOT NULL,
          created_at TEXT NOT NULL)''');
    await database.execute('''CREATE TABLE order_items(
          order_id TEXT NOT NULL, product_id TEXT NOT NULL, quantity INTEGER NOT NULL,
          unit_price INTEGER NOT NULL, PRIMARY KEY(order_id, product_id))''');
    await database.execute('''CREATE TABLE conversations(
          id TEXT PRIMARY KEY, user_id TEXT, store_id TEXT NOT NULL,
          updated_at TEXT NOT NULL)''');
    await database.execute('''CREATE TABLE messages(
          id TEXT PRIMARY KEY, conversation_id TEXT NOT NULL, sender_id TEXT,
          body TEXT NOT NULL, from_customer INTEGER NOT NULL, created_at TEXT NOT NULL)''');
    await database.execute('''CREATE TABLE coupons(
          id TEXT PRIMARY KEY, code TEXT UNIQUE NOT NULL, discount INTEGER NOT NULL,
          expires_at TEXT, active INTEGER NOT NULL DEFAULT 1)''');

    await _createAccountTables(database);
    await _createMerchantTables(database);
    await _createLocalRecordsTable(database);
    await _upgradeTo6(database);
    await _upgradeTo8(database);
  }

  static Future<void> upgrade(
      Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 8 && newVersion >= 8) await _upgradeTo8(database);
    if (oldVersion < 2) await _createAccountTables(database);
    if (oldVersion < 3) await _createMerchantTables(database);
    if (oldVersion < 4) await _createLocalRecordsTable(database);
    if (oldVersion < 5) {
      await database.execute('ALTER TABLE products ADD COLUMN image_url TEXT');
    }
    if (oldVersion < 6) await _upgradeTo6(database);
    if (oldVersion < 7 && newVersion >= 7) {
      await database.execute('ALTER TABLE products ADD COLUMN image_urls TEXT');
    }
  }

  static Future<void> _upgradeTo8(Database database) async {
    await database.execute('ALTER TABLE orders ADD COLUMN coupon_id TEXT');
    await database.execute(
        'ALTER TABLE orders ADD COLUMN discount INTEGER NOT NULL DEFAULT 0');
    await database.execute(
        'ALTER TABLE orders ADD COLUMN wallet_used INTEGER NOT NULL DEFAULT 0');
    await database.execute(
        'ALTER TABLE orders ADD COLUMN rewards_granted INTEGER NOT NULL DEFAULT 0');
  }

  static Future<void> _createAccountTables(Database database) async {
    await database.execute('''CREATE TABLE IF NOT EXISTS user_profiles(
      user_id TEXT PRIMARY KEY, email TEXT, birth_date TEXT, gender TEXT,
      avatar_path TEXT, membership_level TEXT DEFAULT 'gold', points INTEGER DEFAULT 78,
      language TEXT DEFAULT 'ar', currency TEXT DEFAULT 'IQD', preferences TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS saved_recipients(
      id TEXT PRIMARY KEY, user_id TEXT, name TEXT NOT NULL, phone TEXT,
      address TEXT, occasion TEXT, preferences TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS occasions(
      id TEXT PRIMARY KEY, user_id TEXT, recipient_id TEXT, title TEXT NOT NULL,
      event_date TEXT NOT NULL, repeat_yearly INTEGER DEFAULT 1, reminder_days INTEGER DEFAULT 7)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS wallet_transactions(
      id TEXT PRIMARY KEY, user_id TEXT, amount INTEGER NOT NULL, type TEXT NOT NULL,
      description TEXT, created_at TEXT NOT NULL)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS user_devices(
      id TEXT PRIMARY KEY, user_id TEXT, device_name TEXT, last_active TEXT,
      is_current INTEGER DEFAULT 0)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS reviews(
      id TEXT PRIMARY KEY, user_id TEXT, order_id TEXT, store_id TEXT,
      rating INTEGER NOT NULL, comment TEXT, created_at TEXT NOT NULL)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS referrals(
      id TEXT PRIMARY KEY, user_id TEXT, referral_code TEXT UNIQUE,
      invited_count INTEGER DEFAULT 0, earned_points INTEGER DEFAULT 0)''');
  }

  static Future<void> _createMerchantTables(Database database) async {
    await database.execute('''CREATE TABLE IF NOT EXISTS store_profiles(
      store_id TEXT PRIMARY KEY, legal_name TEXT, business_type TEXT,
      owner_name TEXT, email TEXT, tax_number TEXT, bank_iban TEXT,
      verification_status TEXT DEFAULT 'draft', accepting_orders INTEGER DEFAULT 1)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_documents(
      id TEXT PRIMARY KEY, store_id TEXT, document_type TEXT, file_path TEXT,
      status TEXT DEFAULT 'pending', expires_at TEXT, rejection_reason TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_branches(
      id TEXT PRIMARY KEY, store_id TEXT, name TEXT, manager_name TEXT,
      phone TEXT, address TEXT, latitude REAL, longitude REAL,
      working_hours TEXT, temporarily_closed INTEGER DEFAULT 0)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_service_zones(
      id TEXT PRIMARY KEY, branch_id TEXT, zone_name TEXT, radius_km REAL,
      delivery_fee INTEGER, minimum_order INTEGER, hourly_capacity INTEGER,
      pickup_enabled INTEGER DEFAULT 1)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_staff(
      id TEXT PRIMARY KEY, store_id TEXT, branch_id TEXT, name TEXT, phone TEXT,
      role TEXT, permissions TEXT, active INTEGER DEFAULT 1)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_product_options(
      id TEXT PRIMARY KEY, product_id TEXT, option_group TEXT, option_name TEXT,
      price_delta INTEGER DEFAULT 0, stock INTEGER DEFAULT 0, active INTEGER DEFAULT 1)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_bundles(
      id TEXT PRIMARY KEY, store_id TEXT, name TEXT, product_ids TEXT,
      base_price INTEGER, customization TEXT, active INTEGER DEFAULT 1)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS inventory_items(
      id TEXT PRIMARY KEY, branch_id TEXT, name TEXT, sku TEXT, unit TEXT,
      quantity REAL DEFAULT 0, reserved REAL DEFAULT 0, reorder_level REAL DEFAULT 0,
      expiry_date TEXT, supplier_id TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS inventory_movements(
      id TEXT PRIMARY KEY, inventory_id TEXT, movement_type TEXT, quantity REAL,
      reason TEXT, employee_id TEXT, created_at TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS suppliers(
      id TEXT PRIMARY KEY, store_id TEXT, name TEXT, phone TEXT, address TEXT,
      payment_terms TEXT, rating REAL DEFAULT 0)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS purchase_orders(
      id TEXT PRIMARY KEY, supplier_id TEXT, branch_id TEXT, items_json TEXT,
      total INTEGER, status TEXT, expected_at TEXT, received_at TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS delivery_jobs(
      id TEXT PRIMARY KEY, order_id TEXT, courier_id TEXT, status TEXT,
      pickup_otp TEXT, delivery_otp TEXT, proof_path TEXT, temperature_note TEXT,
      accepted_at TEXT, picked_up_at TEXT, delivered_at TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_capacity_slots(
      id TEXT PRIMARY KEY, branch_id TEXT, slot_start TEXT, max_orders INTEGER,
      reserved_orders INTEGER DEFAULT 0, closed INTEGER DEFAULT 0)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_settlements(
      id TEXT PRIMARY KEY, store_id TEXT, period_start TEXT, period_end TEXT,
      gross INTEGER, commission INTEGER, refunds INTEGER, net INTEGER,
      status TEXT, transferred_at TEXT)''');
    await database.execute('''CREATE TABLE IF NOT EXISTS store_audit_logs(
      id TEXT PRIMARY KEY, store_id TEXT, employee_id TEXT, action TEXT,
      entity_type TEXT, entity_id TEXT, payload TEXT, created_at TEXT)''');
  }

  static Future<void> _createLocalRecordsTable(Database database) async {
    await database.execute('''CREATE TABLE IF NOT EXISTS local_records(
      id TEXT PRIMARY KEY, scope TEXT NOT NULL, payload TEXT NOT NULL,
      created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
  }

  static const version6Statements = <String>[
    'ALTER TABLE users ADD COLUMN store_id TEXT',
    'ALTER TABLE users ADD COLUMN active INTEGER NOT NULL DEFAULT 1',
    "CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)",
    "CREATE INDEX IF NOT EXISTS idx_stores_city ON stores(city)",
    "CREATE INDEX IF NOT EXISTS idx_products_store ON products(store_id)",
    "CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)",
    "CREATE INDEX IF NOT EXISTS idx_orders_user_created ON orders(user_id, created_at)",
    "CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id)",
    "CREATE INDEX IF NOT EXISTS idx_conversations_user ON conversations(user_id)",
    "CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON messages(conversation_id, created_at)",
    "CREATE INDEX IF NOT EXISTS idx_recipients_user ON saved_recipients(user_id)",
    "CREATE INDEX IF NOT EXISTS idx_wallet_user_created ON wallet_transactions(user_id, created_at)",
    "CREATE INDEX IF NOT EXISTS idx_delivery_courier_status ON delivery_jobs(courier_id, status)",
    "CREATE INDEX IF NOT EXISTS idx_local_records_scope_updated ON local_records(scope, updated_at)",
  ];
  static Future<void> _upgradeTo6(Database database) async {
    for (final sql in version6Statements) {
      await database.execute(sql);
    }
  }
}
