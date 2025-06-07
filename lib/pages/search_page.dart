import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Recipes> allRecipes = [];
  List<Recipes> searchResults = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true; // Changed to true initially
  bool hasSearched = false;

  // Colors dari UserPage
  static const Color primaryGreen = Color(0xFFC7DB9C);
  static const Color accentYellow = Color(0xFFFFF0BD);
  static const Color lightCoral = Color(0xFFFDAB9E);
  static const Color darkGreen = Color(0xFF7BA05B);

  @override
  void initState() {
    super.initState();
    _loadAllRecipes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  _loadAllRecipes() async {
    try {
      List<Recipes> recipes = await RecipeService.getAllRecipes();
      setState(() {
        allRecipes = recipes;
        searchResults = recipes; // Show all recipes initially
        isLoading = false;
        hasSearched = true; // Set to true so it shows the recipe list
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  _performSearch(String query) {
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    // Simulate search delay
    Future.delayed(Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          searchResults = allRecipes; // Show all recipes when search is empty
          isLoading = false;
        });
        return;
      }

      List<Recipes> results = allRecipes.where((recipe) {
        return recipe.name.toLowerCase().contains(query.toLowerCase()) ||
            recipe.cuisine.toLowerCase().contains(query.toLowerCase()) ||
            recipe.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
      }).toList();

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryGreen.withOpacity(0.2),
              accentYellow.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Cari Resep',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Search Bar
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari resep, masakan, atau tag...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(Icons.search, color: darkGreen),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: darkGreen),
                          onPressed: () {
                            searchController.clear();
                            _performSearch('');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryGreen),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: darkGreen, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: _performSearch,
                    ),
                  ],
                ),
              ),

              // Search Results
              Expanded(
                child: _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: darkGreen,
            ),
            SizedBox(height: 16),
            Text(
              'Memuat resep...',
              style: TextStyle(
                fontSize: 16,
                color: darkGreen,
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty && searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: lightCoral,
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada resep ditemukan',
              style: TextStyle(
                fontSize: 18,
                color: darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coba kata kunci yang berbeda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty && allRecipes.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: darkGreen.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada resep tersedia',
              style: TextStyle(
                fontSize: 18,
                color: darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Show result count
        if (searchController.text.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ditemukan ${searchResults.length} resep',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final recipe = searchResults[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      recipe.image,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.restaurant, color: darkGreen),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    recipe.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.cuisine),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: accentYellow, size: 16),
                          SizedBox(width: 4),
                          Text('${recipe.rating.toStringAsFixed(1)}'),
                          SizedBox(width: 16),
                          Icon(Icons.access_time, color: Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text('${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min'),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailPage(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}