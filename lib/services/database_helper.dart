import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // HAPUS method initializeDatabase() - tidak diperlukan
  // Getter database sudah otomatis menginisialisasi

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'recipe_app.db');
      print('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onOpen: (db) {
          print('Database opened successfully');
        },
      );
    } catch (e) {
      print('Error opening database: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    try {
      print('Creating tables...');

      // Tabel users
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          userType TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      print('Users table created successfully');

      // Insert default admin user
      String hashedPassword = _hashPassword('admin');
      await db.insert('users', {
        'username': 'admin',
        'password': hashedPassword,
        'userType': 'admin',
        'createdAt': DateTime.now().toIso8601String(),
      });

      print('Default admin user created');
    } catch (e) {
      print('Error creating tables: $e');
      rethrow;
    }
  }

  String _hashPassword(String password) {
    try {
      var bytes = utf8.encode(password);
      var digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      print('Error hashing password: $e');
      rethrow;
    }
  }

  // User Operations
  Future<User?> loginUser(String username, String password) async {
    try {
      final db = await database;
      String hashedPassword = _hashPassword(password);

      print('Attempting login for username: $username');

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, hashedPassword],
      );

      if (maps.isNotEmpty) {
        print('Login successful for username: $username');
        return User.fromMap(maps.first);
      }

      print('Login failed - user not found or incorrect password');
      return null;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  Future<bool> registerUser(String username, String password, String userType) async {
    try {
      print('Starting registration for username: $username');

      final db = await database;

      // Check if username already exists
      final List<Map<String, dynamic>> existingUsers = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (existingUsers.isNotEmpty) {
        print('Registration failed - username already exists: $username');
        return false; // Username already exists
      }

      // Create new user
      String hashedPassword = _hashPassword(password);
      print('Password hashed successfully');

      Map<String, dynamic> userData = {
        'username': username,
        'password': hashedPassword,
        'userType': userType,
        'createdAt': DateTime.now().toIso8601String(),
      };

      print('User data prepared: $userData');

      int result = await db.insert('users', userData);
      print('Insert result: $result');

      if (result > 0) {
        print('Registration successful for username: $username');
        return true;
      } else {
        print('Registration failed - insert returned 0');
        return false;
      }
    } catch (e) {
      print('Error during registration: $e');
      return false;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by username: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('users');

      return List.generate(maps.length, (i) {
        return User.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  Future<bool> updateUserPassword(String username, String newPassword) async {
    try {
      final db = await database;
      String hashedPassword = _hashPassword(newPassword);

      int result = await db.update(
        'users',
        {'password': hashedPassword},
        where: 'username = ?',
        whereArgs: [username],
      );
      return result > 0;
    } catch (e) {
      print('Error updating user password: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String username) async {
    try {
      final db = await database;

      // Don't allow deleting admin
      if (username == 'admin') {
        print('Cannot delete admin user');
        return false;
      }

      int result = await db.delete(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      return result > 0;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Method untuk debugging - melihat semua user
  Future<void> printAllUsers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('users');

      print('=== All Users in Database ===');
      for (var user in maps) {
        print('ID: ${user['id']}, Username: ${user['username']}, UserType: ${user['userType']}, CreatedAt: ${user['createdAt']}');
      }
      print('=============================');
    } catch (e) {
      print('Error printing all users: $e');
    }
  }

  // Method untuk cek apakah database dan tabel ada
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final db = await database;

      // Cek apakah tabel users ada
      final List<Map<String, dynamic>> tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'"
      );

      if (tables.isEmpty) {
        print('Users table does not exist');
        return false;
      }

      print('Database integrity check passed');
      return true;
    } catch (e) {
      print('Error checking database integrity: $e');
      return false;
    }
  }

  Future<void> closeDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
        print('Database closed successfully');
      }
    } catch (e) {
      print('Error closing database: $e');
    }
  }
}