import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RecipeFormPage extends StatefulWidget {
  final Recipes? recipe; // null untuk add, ada value untuk edit

  const RecipeFormPage({Key? key, this.recipe}) : super(key: key);

  @override
  _RecipeFormPageState createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _imageController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _tagsController = TextEditingController();
  final _mealTypeController = TextEditingController();
  final _standardPriceController = TextEditingController();

  String _selectedDifficulty = 'Easy';
  String _selectedCurrency = 'IDR';
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'GBP', 'SGD'];
  bool _isLoading = false;

  // Color palette - White & Navy theme (matching login page)
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final recipe = widget.recipe!;
    _nameController.text = recipe.name;
    _cuisineController.text = recipe.cuisine;
    _imageController.text = recipe.image;
    _prepTimeController.text = recipe.prepTimeMinutes.toString();
    _cookTimeController.text = recipe.cookTimeMinutes.toString();
    _servingsController.text = recipe.servings.toString();
    _caloriesController.text = recipe.caloriesPerServing.toString();
    _selectedDifficulty = recipe.difficulty;

    // Set standard price and currency
    if (recipe.standardPrice != null) {
      _standardPriceController.text = recipe.standardPrice.toString();
    }
    if (recipe.currency != null && _currencies.contains(recipe.currency)) {
      _selectedCurrency = recipe.currency!;
    }

    // Join arrays with newlines for editing
    _ingredientsController.text = recipe.ingredients.join('\n');
    _instructionsController.text = recipe.instructions.join('\n');
    _tagsController.text = recipe.tags.join(', ');
    _mealTypeController.text = recipe.mealType.join(', ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _imageController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _tagsController.dispose();
    _mealTypeController.dispose();
    _standardPriceController.dispose();
    super.dispose();
  }

  _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare data
        final ingredients = _ingredientsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final instructions = _instructionsController.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final tags = _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final mealType = _mealTypeController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // Parse standard price
        double? standardPrice;
        if (_standardPriceController.text.isNotEmpty) {
          standardPrice = double.tryParse(_standardPriceController.text);
        }

        final recipe = Recipes(
          id: widget.recipe?.id ?? 0, // Supabase akan auto-generate ID untuk create
          name: _nameController.text.trim(),
          ingredients: ingredients,
          instructions: instructions,
          prepTimeMinutes: int.parse(_prepTimeController.text),
          cookTimeMinutes: int.parse(_cookTimeController.text),
          servings: int.parse(_servingsController.text),
          difficulty: _selectedDifficulty,
          cuisine: _cuisineController.text.trim(),
          caloriesPerServing: int.parse(_caloriesController.text),
          tags: tags,
          userId: widget.recipe?.userId ?? 1, // Default user ID
          image: _imageController.text.trim(),
          rating: widget.recipe?.rating ?? 4.0, // Default rating
          reviewCount: widget.recipe?.reviewCount ?? 0,
          mealType: mealType,
          standardPrice: standardPrice,
          currency: _standardPriceController.text.isNotEmpty ? _selectedCurrency : null,
        );

        if (widget.recipe == null) {
          // Add new recipe
          Recipes newRecipe = await RecipeService.addRecipe(recipe);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resep "${newRecipe.name}" berhasil ditambahkan!'),
              backgroundColor: primaryNavy,
              action: SnackBarAction(
                label: 'LIHAT',
                textColor: pureWhite,
                onPressed: () {
                  // Optional: Navigate to detail page
                },
              ),
            ),
          );
        } else {
          // Update existing recipe
          Recipes updatedRecipe = await RecipeService.updateRecipe(widget.recipe!.id, recipe);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resep "${updatedRecipe.name}" berhasil diupdate!'),
              backgroundColor: primaryNavy,
            ),
          );
        }

        Navigator.pop(context, true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Validate URL helper
  bool _isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  // Build styled text field with navy theme
  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: primaryNavy),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: lightGrey,
          prefixIcon: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryNavy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(prefixIcon, color: primaryNavy),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  // Build styled dropdown field
  Widget _buildStyledDropdown<T>({
    required T value,
    required List<T> items,
    required String labelText,
    required IconData prefixIcon,
    required Function(T?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        style: TextStyle(color: primaryNavy),
        decoration: InputDecoration(
          labelText: labelText,
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
            child: Icon(prefixIcon, color: primaryNavy),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        title: Text(
          widget.recipe == null ? 'Tambah Resep' : 'Edit Resep',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: pureWhite,
        elevation: 0,
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: pureWhite,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            Container(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: pureWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: _saveRecipe,
                child: Text(
                  'SIMPAN',
                  style: TextStyle(
                    color: pureWhite,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Basic Info Section
            _buildSectionTitle('Informasi Dasar'),
            _buildStyledTextField(
              controller: _nameController,
              labelText: 'Nama Resep *',
              prefixIcon: Icons.restaurant_menu,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama resep harus diisi';
                }
                if (value.length < 3) {
                  return 'Nama resep minimal 3 karakter';
                }
                return null;
              },
            ),

            _buildStyledTextField(
              controller: _cuisineController,
              labelText: 'Jenis Masakan *',
              prefixIcon: Icons.public,
              hintText: 'Contoh: Indonesian, Italian, Chinese',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jenis masakan harus diisi';
                }
                return null;
              },
            ),

            _buildStyledTextField(
              controller: _imageController,
              labelText: 'URL Gambar *',
              prefixIcon: Icons.image,
              hintText: 'https://example.com/image.jpg',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'URL gambar harus diisi';
                }
                if (!_isValidUrl(value)) {
                  return 'URL tidak valid (harus dimulai dengan http:// atau https://)';
                }
                return null;
              },
            ),

            // Image Preview
            if (_imageController.text.isNotEmpty && _isValidUrl(_imageController.text))
              Container(
                margin: EdgeInsets.only(bottom: 20),
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(color: lightGrey, width: 2),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    _imageController.text,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: lightGrey,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: darkGrey, size: 40),
                              SizedBox(height: 8),
                              Text(
                                'Gambar tidak dapat dimuat',
                                style: TextStyle(color: darkGrey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Difficulty Dropdown
            _buildStyledDropdown<String>(
              value: _selectedDifficulty,
              items: _difficulties,
              labelText: 'Tingkat Kesulitan',
              prefixIcon: Icons.bar_chart,
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
            ),
            SizedBox(height: 8),

            // Time and Serving Section
            _buildSectionTitle('Waktu & Porsi'),
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _prepTimeController,
                    labelText: 'Persiapan (menit) *',
                    prefixIcon: Icons.timer,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harus diisi';
                      }
                      final int? num = int.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Harus angka > 0';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _cookTimeController,
                    labelText: 'Memasak (menit) *',
                    prefixIcon: Icons.access_time,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harus diisi';
                      }
                      final int? num = int.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Harus angka > 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _servingsController,
                    labelText: 'Jumlah Porsi *',
                    prefixIcon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harus diisi';
                      }
                      final int? num = int.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Harus angka > 0';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStyledTextField(
                    controller: _caloriesController,
                    labelText: 'Kalori per Porsi *',
                    prefixIcon: Icons.local_fire_department,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harus diisi';
                      }
                      final int? num = int.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Harus angka > 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Price Section
            _buildSectionTitle('Informasi Harga'),
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                    controller: _standardPriceController,
                    labelText: 'Standar Harga',
                    prefixIcon: Icons.monetization_on,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    hintText: 'Contoh: 25000 atau 5.99',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final double? price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Harga harus berupa angka positif';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStyledDropdown<String>(
                    value: _selectedCurrency,
                    items: _currencies,
                    labelText: 'Mata Uang',
                    prefixIcon: Icons.currency_exchange,
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Price Preview
            if (_standardPriceController.text.isNotEmpty &&
                double.tryParse(_standardPriceController.text) != null)
              Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryNavy.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.preview, color: primaryNavy),
                    SizedBox(width: 12),
                    Text(
                      'Preview Harga: ',
                      style: TextStyle(
                        color: primaryNavy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getFormattedPricePreview(),
                      style: TextStyle(
                        color: primaryNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),

            // Ingredients Section
            _buildSectionTitle('Bahan-bahan'),
            _buildStyledTextField(
              controller: _ingredientsController,
              labelText: 'Bahan-bahan (satu bahan per baris) *',
              prefixIcon: Icons.list,
              hintText: 'Contoh:\n2 cup tepung terigu\n1 sdt garam\n3 butir telur',
              maxLines: 8,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bahan-bahan harus diisi';
                }
                final ingredients = value.split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (ingredients.length < 2) {
                  return 'Minimal 2 bahan diperlukan';
                }
                return null;
              },
            ),
            SizedBox(height: 8),

            // Instructions Section
            _buildSectionTitle('Cara Memasak'),
            _buildStyledTextField(
              controller: _instructionsController,
              labelText: 'Instruksi (satu langkah per baris) *',
              prefixIcon: Icons.format_list_numbered,
              hintText: 'Contoh:\nCampurkan tepung dan garam\nTambahkan telur satu per satu\nAduk hingga rata',
              maxLines: 10,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Instruksi harus diisi';
                }
                final instructions = value.split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (instructions.length < 2) {
                  return 'Minimal 2 langkah diperlukan';
                }
                return null;
              },
            ),
            SizedBox(height: 8),

            // Tags and Meal Type Section
            _buildSectionTitle('Tags & Kategori'),
            _buildStyledTextField(
              controller: _tagsController,
              labelText: 'Tags (pisahkan dengan koma)',
              prefixIcon: Icons.tag,
              hintText: 'Contoh: mudah, cepat, sehat',
            ),

            _buildStyledTextField(
              controller: _mealTypeController,
              labelText: 'Jenis Makanan (pisahkan dengan koma)',
              prefixIcon: Icons.restaurant,
              hintText: 'Contoh: Breakfast, Snack',
            ),
            SizedBox(height: 16),

            // Save Button
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
                onPressed: _isLoading ? null : _saveRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: pureWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: pureWhite,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Menyimpan...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
                    : Text(
                  widget.recipe == null ? 'TAMBAH RESEP' : 'UPDATE RESEP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getFormattedPricePreview() {
    final priceText = _standardPriceController.text;
    final price = double.tryParse(priceText);

    if (price == null) return 'Invalid price';

    if (_selectedCurrency == 'USD') {
      return '\$${price.toStringAsFixed(2)}';
    } else if (_selectedCurrency == 'IDR') {
      return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.'
      )}';
    } else {
      return '${price.toStringAsFixed(2)} $_selectedCurrency';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 20, top: 8),
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}