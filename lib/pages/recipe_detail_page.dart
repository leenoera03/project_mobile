import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipes recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  String selectedCurrency = 'USD';
  bool isLoadingRates = true;
  String? errorMessage;

  // Default/fallback exchange rates
  Map<String, Map<String, dynamic>> currencies = {
    'USD': {'rate': 1.0, 'symbol': '\$', 'name': 'US Dollar'},
    'IDR': {'rate': 15300.0, 'symbol': 'Rp', 'name': 'Indonesian Rupiah'},
    'EUR': {'rate': 0.85, 'symbol': '€', 'name': 'Euro'},
    'GBP': {'rate': 0.73, 'symbol': '£', 'name': 'British Pound'},
    'JPY': {'rate': 110.0, 'symbol': '¥', 'name': 'Japanese Yen'},
    'KRW': {'rate': 1200.0, 'symbol': '₩', 'name': 'South Korean Won'},
    'SAR': {'rate': 3.75, 'symbol': 'ر.س', 'name': 'Saudi Arabian Riyal'},
  };

  @override
  void initState() {
    super.initState();
    _fetchExchangeRates();
  }

  // Fetch exchange rates from API
  Future<void> _fetchExchangeRates() async {
    try {
      setState(() {
        isLoadingRates = true;
        errorMessage = null;
      });

      // Option 1: ExchangeRate-API (Free tier: 1500 requests/month)
      const String apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

      // Option 2: Fixer.io (Requires API key)
      // const String apiKey = 'YOUR_API_KEY';
      // const String apiUrl = 'http://data.fixer.io/api/latest?access_key=$apiKey&base=USD';

      // Option 3: CurrencyAPI (Free tier available)
      // const String apiKey = 'YOUR_API_KEY';
      // const String apiUrl = 'https://api.currencyapi.com/v3/latest?apikey=$apiKey&base_currency=USD';

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse response for ExchangeRate-API
        if (data['rates'] != null) {
          _updateCurrencyRates(data['rates']);
        }
      } else {
        throw Exception('Failed to load exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat kurs terkini. Menggunakan kurs default.';
      });
      print('Error fetching exchange rates: $e');
    } finally {
      setState(() {
        isLoadingRates = false;
      });
    }
  }

  void _updateCurrencyRates(Map<String, dynamic> rates) {
    setState(() {
      // Update rates while keeping symbols and names
      currencies.forEach((key, value) {
        if (rates[key] != null) {
          currencies[key]!['rate'] = rates[key].toDouble();
        }
      });
    });
  }

  Future<void> _refreshRates() async {
    await _fetchExchangeRates();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kurs mata uang telah diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(widget.recipe.name + " recipe")}');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  String _getConvertedPrice() {
    if (widget.recipe.standardPrice == null) return 'N/A';

    double usdPrice = widget.recipe.standardPrice!;
    double convertedPrice = usdPrice * currencies[selectedCurrency]!['rate'];
    String symbol = currencies[selectedCurrency]!['symbol'];

    if (selectedCurrency == 'IDR' || selectedCurrency == 'KRW') {
      return '$symbol${convertedPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},'
      )}';
    } else if (selectedCurrency == 'JPY') {
      return '$symbol${convertedPrice.toStringAsFixed(0)}';
    } else {
      return '$symbol${convertedPrice.toStringAsFixed(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.recipe.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.restaurant,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.launch),
                onPressed: _launchURL,
                tooltip: 'Cari resep di Google',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Card with Currency Converter - FIXED VERSION
                  if (widget.recipe.standardPrice != null) ...[
                    Card(
                      elevation: 4,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row with title and price
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title section
                                Row(
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Estimasi Harga',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 12),
                                // Price section - Flexible to handle overflow
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isLoadingRates) ...[
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Text(
                                              _getConvertedPrice(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18, // Reduced from 20
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.right,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Currency selector and refresh button
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedCurrency,
                                        dropdownColor: Colors.green.shade700,
                                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                        style: TextStyle(color: Colors.white, fontSize: 14),
                                        isExpanded: true, // Added to prevent overflow
                                        items: currencies.entries.map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  entry.value['symbol'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    '${entry.key} - ${entry.value['name']}',
                                                    style: TextStyle(color: Colors.white),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              selectedCurrency = newValue;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  onPressed: isLoadingRates ? null : _refreshRates,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: 'Refresh kurs',
                                ),
                              ],
                            ),

                            // Original price display
                            if (selectedCurrency != 'USD') ...[
                              SizedBox(height: 8),
                              Text(
                                'Harga asli: ${widget.recipe.getFormattedPrice()}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            // Error message display
                            if (errorMessage != null) ...[
                              SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.access_time,
                          title: 'Total Waktu',
                          value: '${widget.recipe.prepTimeMinutes + widget.recipe.cookTimeMinutes} menit',
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.people,
                          title: 'Porsi',
                          value: '${widget.recipe.servings} orang',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.local_fire_department,
                          title: 'Kalori',
                          value: '${widget.recipe.caloriesPerServing} kcal',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Cuisine and Difficulty
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.recipe.cuisine),
                        backgroundColor: Colors.blue.shade50,
                        avatar: Icon(Icons.public, size: 18),
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text(widget.recipe.difficulty),
                        backgroundColor: _getDifficultyColor(widget.recipe.difficulty),
                        avatar: Icon(Icons.bar_chart, size: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Tags
                  if (widget.recipe.tags.isNotEmpty) ...[
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.recipe.tags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey.shade200,
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Meal Type
                  if (widget.recipe.mealType.isNotEmpty) ...[
                    Text(
                      'Jenis Makanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.recipe.mealType.map((type) {
                        return Chip(
                          label: Text(type),
                          backgroundColor: Colors.purple.shade100,
                          avatar: Icon(Icons.restaurant_menu, size: 18),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                  ],

                  // Ingredients
                  Text(
                    'Bahan-bahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: widget.recipe.ingredients.asMap().entries.map((entry) {
                          int index = entry.key;
                          String ingredient = entry.value;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ingredient,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Instructions
                  Text(
                    'Cara Memasak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: widget.recipe.instructions.asMap().entries.map((entry) {
                          int index = entry.key;
                          String instruction = entry.value;
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    instruction,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}