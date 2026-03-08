import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/category.dart';
import '../models/service_item.dart';
import '../models/project.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scope_it.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE projects ADD COLUMN configJson TEXT');
    }
    if (oldVersion < 4) {
      await db.execute(
          'ALTER TABLE projects ADD COLUMN iconCode INTEGER');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        colorValue INTEGER NOT NULL DEFAULT 444898812
      )
    ''');

    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        basePrice REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'hora',
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        clientName TEXT NOT NULL,
        description TEXT,
        totalEstimate REAL NOT NULL,
        multiplierUsed REAL NOT NULL DEFAULT 1.0,
        status INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        configJson TEXT,
        iconCode INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE project_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER NOT NULL,
        serviceId INTEGER NOT NULL,
        serviceName TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        quantity REAL NOT NULL,
        unitPrice REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'hora',
        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    // Seed default categories
    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    final categories = [
      {'name': 'Frontend', 'description': 'Desarrollo de interfaces', 'colorValue': 0xFF1B9CFC},
      {'name': 'Backend', 'description': 'Servidor y APIs', 'colorValue': 0xFF4CAF50},
      {'name': 'UX/UI', 'description': 'Diseño de experiencia', 'colorValue': 0xFFFF9800},
      {'name': 'DevOps', 'description': 'Infraestructura y despliegue', 'colorValue': 0xFF9C27B0},
    ];

    final services = [
      {'catIdx': 0, 'name': 'Pantallas móviles', 'basePrice': 150.0, 'unit': 'pantalla'},
      {'catIdx': 0, 'name': 'Integración de API', 'basePrice': 80.0, 'unit': 'endpoint'},
      {'catIdx': 1, 'name': 'Endpoint REST', 'basePrice': 60.0, 'unit': 'endpoint'},
      {'catIdx': 1, 'name': 'Base de datos', 'basePrice': 200.0, 'unit': 'módulo'},
      {'catIdx': 2, 'name': 'Wireframes', 'basePrice': 50.0, 'unit': 'pantalla'},
      {'catIdx': 2, 'name': 'Prototipo interactivo', 'basePrice': 300.0, 'unit': 'flujo'},
      {'catIdx': 3, 'name': 'Configuración CI/CD', 'basePrice': 400.0, 'unit': 'pipeline'},
      {'catIdx': 3, 'name': 'Contenedores Docker', 'basePrice': 150.0, 'unit': 'servicio'},
    ];

    final catIds = <int>[];
    for (final cat in categories) {
      final id = await db.insert('categories', {
        'name': cat['name'],
        'description': cat['description'],
        'colorValue': cat['colorValue'],
      });
      catIds.add(id);
    }

    for (final svc in services) {
      final catIdx = svc['catIdx'] as int;
      await db.insert('services', {
        'categoryId': catIds[catIdx],
        'name': svc['name'],
        'basePrice': svc['basePrice'],
        'unit': svc['unit'],
      });
    }
  }

  // ── SETTINGS ──────────────────────────────────────────────────────
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── CATEGORIES ────────────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── SERVICES ──────────────────────────────────────────────────────
  Future<List<ServiceItem>> getServices({int? categoryId}) async {
    final db = await database;
    final maps = categoryId != null
        ? await db.query('services',
            where: 'categoryId = ?', whereArgs: [categoryId], orderBy: 'name ASC')
        : await db.query('services', orderBy: 'name ASC');
    return maps.map(ServiceItem.fromMap).toList();
  }

  Future<int> insertService(ServiceItem service) async {
    final db = await database;
    return db.insert('services', service.toMap());
  }

  Future<int> updateService(ServiceItem service) async {
    final db = await database;
    return db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return db.delete('services', where: 'id = ?', whereArgs: [id]);
  }

  // ── PROJECTS ──────────────────────────────────────────────────────
  Future<List<Project>> getProjects() async {
    final db = await database;
    final maps = await db.query('projects', orderBy: 'createdAt DESC');
    final projects = maps.map(Project.fromMap).toList();

    for (int i = 0; i < projects.length; i++) {
      final lines = await getProjectLines(projects[i].id!);
      projects[i] = projects[i].copyWith(lines: lines);
    }
    return projects;
  }

  Future<Project?> getProject(int id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final project = Project.fromMap(maps.first);
    final lines = await getProjectLines(id);
    return project.copyWith(lines: lines);
  }

  Future<int> insertProject(Project project) async {
    final db = await database;
    final projectId = await db.insert('projects', project.toMap());

    for (final line in project.lines) {
      await db.insert('project_lines', line.toMap()..['projectId'] = projectId);
    }
    return projectId;
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    // Replace project lines
    await db.delete('project_lines',
        where: 'projectId = ?', whereArgs: [project.id]);
    for (final line in project.lines) {
      await db.insert(
          'project_lines', line.toMap()..['projectId'] = project.id);
    }
  }

  Future<int> updateProjectStatus(int id, ProjectStatus status) async {
    final db = await database;
    return db.update(
      'projects',
      {'status': status.index},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ProjectLine>> getProjectLines(int projectId) async {
    final db = await database;
    final maps = await db.query(
      'project_lines',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return maps.map(ProjectLine.fromMap).toList();
  }
}
