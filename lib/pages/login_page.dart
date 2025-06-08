import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../models/user.dart';
import 'admin_page.dart';
import 'user_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Color palette - White & Navy theme
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    _checkDatabaseIntegrity();
  }

  // Cek database dan print info untuk debugging
  _checkDatabaseIntegrity() async {
    try {
      bool isDbOk = await _databaseHelper.checkDatabaseIntegrity();
      print('Database integrity check: $isDbOk');

      // Print semua user untuk debugging
      await _databaseHelper.printAllUsers();

      // Test login admin
      User? testAdmin = await _databaseHelper.loginUser('admin', 'admin');
      print('Test admin login: ${testAdmin != null ? 'SUCCESS' : 'FAILED'}');
      if (testAdmin != null) {
        print('Admin user type: ${testAdmin.userType}');
      }
    } catch (e) {
      print('Error checking database: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      // Debug print
      print('Attempting login with username: $username, password: $password');

      try {
        // Simulasi delay login
        await Future.delayed(Duration(seconds: 1));

        User? user = await _databaseHelper.loginUser(username, password);

        // Debug print
        print('Login result: ${user != null ? 'Success' : 'Failed'}');
        if (user != null) {
          print('User type: ${user.userType}');
        }

        if (user != null) {
          // Login berhasil
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', user.username);
          await prefs.setString('userType', user.userType);

          print('Navigating to: ${user.userType == 'admin' ? 'AdminPage' : 'UserPage'}');

          if (user.userType == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserPage()),
            );
          }
        } else {
          // Login gagal - tambahkan debug info
          print('Login failed - checking all users in database');
          List<User> allUsers = await _databaseHelper.getAllUsers();
          print('Total users in database: ${allUsers.length}');
          for (User u in allUsers) {
            print('User: ${u.username}, Type: ${u.userType}');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username atau password salah!'),
              backgroundColor: primaryNavy,
            ),
          );
        }
      } catch (e) {
        print('Login error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat login: $e'),
            backgroundColor: primaryNavy,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background
      body: Container(
        decoration: BoxDecoration(
          color: pureWhite,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top - 48.0,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Column(
                          children: [
                            // Logo container with navy background
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: primaryNavy,
                                borderRadius: BorderRadius.circular(60),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                  child: Image.asset(
                                    'assets/cooking2.png',
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.restaurant_menu,
                                        size: 60,
                                        color: pureWhite,
                                      ); // Fallback with white icon
                                    },
                                  )
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Find your Recipe',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: primaryNavy,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Temukan resep disini',
                              style: TextStyle(
                                fontSize: 16,
                                color: darkGrey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                      // Username field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _usernameController,
                          style: TextStyle(color: primaryNavy),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: lightGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: lightGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: primaryNavy, width: 2),
                            ),
                            filled: true,
                            fillColor: lightGrey,
                            prefixIcon: Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryNavy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.person, color: primaryNavy),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      // Password field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: primaryNavy),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: lightGrey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: lightGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: primaryNavy, width: 2),
                            ),
                            filled: true,
                            fillColor: lightGrey,
                            prefixIcon: Container(
                              margin: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryNavy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.lock, color: primaryNavy),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 32),
                      // Login button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: primaryNavy.withOpacity(0.3),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: pureWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(
                            color: pureWhite,
                            strokeWidth: 2,
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 8),
                              Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Register button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: primaryNavy, width: 2),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: primaryNavy,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'DAFTAR AKUN BARU',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Debug button - hapus setelah testing
                      Container(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              List<User> users = await _databaseHelper.getAllUsers();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: pureWhite,
                                  title: Text('Database Users', style: TextStyle(color: primaryNavy)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: users.map((user) =>
                                        Text('${user.username} - ${user.userType}',
                                            style: TextStyle(color: primaryNavy))
                                    ).toList(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK', style: TextStyle(color: primaryNavy)),
                                    ),
                                  ],
                                ),
                              );
                            } catch (e) {
                              print('Error: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightGrey,
                            foregroundColor: primaryNavy,
                          ),
                          child: Text('Database Users'),
                        ),
                      ),
                      SizedBox(height: 32),
                      // Info card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: lightGrey,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryNavy.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: primaryNavy,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Clue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoRow('Admin', 'username: admin', 'password: admin'),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: pureWhite,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      child: Text(
                                        'User',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: primaryNavy,
                                        ),
                                      ),
                                    ),
                                    Text(' : ', style: TextStyle(color: primaryNavy)),
                                    Expanded(
                                      child: Text(
                                        'Daftar akun baru atau gunakan akun yang sudah ada',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String role, String username, String password) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            child: Text(
              role,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryNavy,
              ),
            ),
          ),
          Text(' : ', style: TextStyle(color: primaryNavy)),
          Expanded(
            child: Text(
              '$username, $password',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}