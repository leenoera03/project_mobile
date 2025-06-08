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
  bool isLoading = true;
  bool hasSearched = false;

  // Navy & White theme colors - matching LoginPage
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF666666);

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
        searchResults = recipes;
        isLoading = false;
        hasSearched = true;
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

    Future.delayed(Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          searchResults = allRecipes;
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
      backgroundColor: pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header with navy background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Cari Resep',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: pureWhite,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Search Bar with white background
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
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(color: primaryNavy),
                        decoration: InputDecoration(
                          hintText: 'Cari resep, masakan, atau tag...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryNavy.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.search, color: primaryNavy),
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                            icon: Icon(Icons.clear, color: primaryNavy),
                            onPressed: () {
                              searchController.clear();
                              _performSearch('');
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: primaryNavy, width: 2),
                          ),
                          filled: true,
                          fillColor: pureWhite,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to show/hide clear button
                          _performSearch(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
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
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryNavy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: CircularProgressIndicator(
                color: primaryNavy,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Memuat resep...',
              style: TextStyle(
                fontSize: 16,
                color: primaryNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (searchResults.isEmpty && searchController.text.isNotEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: lightGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.search_off,
                  size: 60,
                  color: primaryNavy,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Tidak ada resep ditemukan',
                style: TextStyle(
                  fontSize: 20,
                  color: primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Coba kata kunci yang berbeda',
                style: TextStyle(
                  fontSize: 16,
                  color: darkGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (searchResults.isEmpty && allRecipes.isEmpty && !isLoading) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: lightGrey,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: primaryNavy,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Belum ada resep tersedia',
                style: TextStyle(
                  fontSize: 20,
                  color: primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Show result count
        if (searchController.text.isNotEmpty)
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryNavy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Ditemukan ${searchResults.length} resep',
              style: TextStyle(
                fontSize: 16,
                color: primaryNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final recipe = searchResults[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      recipe.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: primaryNavy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: primaryNavy,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                  title: Text(
                    recipe.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        recipe.cuisine,
                        style: TextStyle(
                          color: darkGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          // Price container (replacing rating)
                          if (recipe.standardPrice != null) ...[
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 4),
                                  Text(
                                    recipe.getFormattedPrice(),
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: lightGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, color: darkGrey, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                                  style: TextStyle(
                                    color: darkGrey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
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