import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class RecipeService {
  static const String baseUrl = 'https://fdsikdmxqjsydykeeraq.supabase.co/rest/v1/recipes';
  static const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkc2lrZG14cWpzeWR5a2VlcmFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwNzU3OTIsImV4cCI6MjA2NDY1MTc5Mn0.3alid8z6u5CL3GKw_z6tHdEnUm-RBbgmLXazQ84kV6A';

  // Headers untuk Supabase
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Prefer': 'return=representation',
  };

  // Get all recipes
  static Future<List<Recipes>> getAllRecipes() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Recipes.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get single recipe by ID
  static Future<Recipes> getRecipeById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?id=eq.$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        if (jsonList.isNotEmpty) {
          return Recipes.fromJson(jsonList[0]);
        } else {
          throw Exception('Recipe not found');
        }
      } else {
        throw Exception('Failed to load recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Add new recipe
  static Future<Recipes> addRecipe(Recipes recipe) async {
    try {
      // Remove id from JSON if it exists (Supabase will auto-generate)
      Map<String, dynamic> recipeJson = recipe.toJson();
      recipeJson.remove('id');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(recipeJson),
      );

      if (response.statusCode == 201) {
        List<dynamic> jsonList = json.decode(response.body);
        return Recipes.fromJson(jsonList[0]);
      } else {
        throw Exception('Failed to add recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update recipe
  static Future<Recipes> updateRecipe(int id, Recipes recipe) async {
    try {
      // Remove id from JSON untuk update
      Map<String, dynamic> recipeJson = recipe.toJson();
      recipeJson.remove('id');

      final response = await http.patch(
        Uri.parse('$baseUrl?id=eq.$id'),
        headers: headers,
        body: json.encode(recipeJson),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        if (jsonList.isNotEmpty) {
          return Recipes.fromJson(jsonList[0]);
        } else {
          throw Exception('Recipe not found after update');
        }
      } else {
        throw Exception('Failed to update recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Delete recipe - FIXED VERSION
  static Future<bool> deleteRecipe(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl?id=eq.$id'),
        headers: headers,
      );

      // Supabase bisa mengembalikan 200 atau 204 untuk delete yang berhasil
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Search recipes by name (bonus feature)
  static Future<List<Recipes>> searchRecipes(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?name=ilike.*$query*'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Recipes.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}