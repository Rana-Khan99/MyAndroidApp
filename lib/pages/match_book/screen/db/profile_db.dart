import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ProfileDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'profile.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE profile_images(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  static Future<void> saveImage(String type, String path) async {
    final db = await database;
    await db.delete('profile_images', where: 'type = ?', whereArgs: [type]);
    await db.insert('profile_images', {
      'type': type,
      'imagePath': path,
    });
  }

  static Future<String?> getImage(String type) async {
    final db = await database;
    final res = await db.query(
      'profile_images',
      where: 'type = ?',
      whereArgs: [type],
      limit: 1,
    );
    return res.isNotEmpty ? res.first['imagePath'] as String : null;
  }
}
