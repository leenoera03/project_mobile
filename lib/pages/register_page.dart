import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Color palette - White & Navy theme (sama dengan login page)
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF666666);
  static const Color darkPink = Color(0xFFE91E63);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  _register() async {
    // Debug print để melihat apakah fungsi dipanggil
    print('Register function called');

    if (_formKey.currentState!.validate()) {
      print('Form is valid');

      setState(() {
        _isLoading = true;
      });

      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      // Debug print
      print('Username: $username, Password: $password');

      try {
        // HAPUS baris ini - tidak perlu inisialisasi manual
        // await _databaseHelper.initializeDatabase();

        // Langsung panggil registerUser
        bool success = await _databaseHelper.registerUser(username, password, 'user');
        print('Registration result: $success');

        if (success) {
          // Registration successful
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registrasi berhasil! Silakan login.'),
              backgroundColor: primaryNavy,
              duration: Duration(seconds: 3),
            ),
          );

          // Clear form
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();

          // Navigate back to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          // Registration failed (username exists)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username sudah digunakan! Pilih username lain.'),
              backgroundColor: Colors.red[600],
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error during registration: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat registrasi: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      print('Form is not valid');
      // Tampilkan pesan jika form tidak valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon periksa kembali data yang dimasukkan'),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 2),
        ),
      );
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
                                child: Icon(
                                  Icons.person_add,
                                  size: 60,
                                  color: pureWhite,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: primaryNavy,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Buat akun untuk melihat resep',
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Username tidak boleh kosong';
                            }
                            if (value.trim().length < 3) {
                              return 'Username minimal 3 karakter';
                            }
                            if (value.contains(' ')) {
                              return 'Username tidak boleh mengandung spasi';
                            }
                            // Tambahan validasi untuk karakter khusus
                            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                              return 'Username hanya boleh mengandung huruf, angka, dan underscore';
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
                            if (value == null || value.trim().isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.trim().length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      // Confirm Password field
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
                          controller: _confirmPasswordController,
                          style: TextStyle(color: primaryNavy),
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
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
                              child: Icon(Icons.lock_outline, color: primaryNavy),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (value.trim() != _passwordController.text.trim()) {
                              return 'Password tidak sama';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 32),
                      // Register button
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
                          onPressed: _isLoading ? null : () {
                            print('Register button pressed');
                            _register();
                          },
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
                                'DAFTAR',
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
                      // Login link text
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              'Login di sini',
                              style: TextStyle(
                                color: primaryNavy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                                    'Syarat',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoRow('Username', 'Minimal 3 karakter, tanpa spasi'),
                              SizedBox(height: 8),
                              _buildInfoRow('Password', 'Minimal 6 karakter'),
                              SizedBox(height: 8),
                              _buildInfoRow('Akses', 'Setelah daftar, Anda bisa langsung login'),
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

  Widget _buildInfoRow(String label, String description) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryNavy,
              ),
            ),
          ),
          Text(' : ', style: TextStyle(color: primaryNavy)),
          Expanded(
            child: Text(
              description,
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