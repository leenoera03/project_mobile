class Recipe {
  List<Recipes> recipes;
  int total;
  int skip;
  int limit;

  Recipe({
    required this.recipes,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipes: (json['recipes'] as List)
          .map((v) => Recipes.fromJson(v))
          .toList(),
      total: json['total'],
      skip: json['skip'],
      limit: json['limit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipes': recipes.map((v) => v.toJson()).toList(),
      'total': total,
      'skip': skip,
      'limit': limit,
    };
  }
}

class Recipes {
  int id;
  String name;
  List<String> ingredients;
  List<String> instructions;
  int prepTimeMinutes;
  int cookTimeMinutes;
  int servings;
  String difficulty;
  String cuisine;
  int caloriesPerServing;
  List<String> tags;
  int userId;
  String image;
  double rating;
  int reviewCount;
  List<String> mealType;
  double? standardPrice;  // Added standard_price field
  String? currency;       // Added currency field

  Recipes({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.cuisine,
    required this.caloriesPerServing,
    required this.tags,
    required this.userId,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.mealType,
    this.standardPrice,     // Optional parameter
    this.currency,          // Optional parameter
  });

  factory Recipes.fromJson(Map<String, dynamic> json) {
    return Recipes(
      id: json['id'],
      name: json['name'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      prepTimeMinutes: json['prepTimeMinutes'],
      cookTimeMinutes: json['cookTimeMinutes'],
      servings: json['servings'],
      difficulty: json['difficulty'],
      cuisine: json['cuisine'],
      caloriesPerServing: json['caloriesPerServing'],
      tags: List<String>.from(json['tags']),
      userId: json['userId'],
      image: json['image'],
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'],
      mealType: List<String>.from(json['mealType']),
      standardPrice: json['standard_price'] != null
          ? (json['standard_price'] as num).toDouble()
          : null,
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'difficulty': difficulty,
      'cuisine': cuisine,
      'caloriesPerServing': caloriesPerServing,
      'tags': tags,
      'userId': userId,
      'image': image,
      'rating': rating,
      'reviewCount': reviewCount,
      'mealType': mealType,
      'standard_price': standardPrice,
      'currency': currency,
    };
  }

  // Helper method to get formatted price
  String getFormattedPrice() {
    if (standardPrice == null) return 'Price not available';

    if (currency == 'USD') {
      return '\$${standardPrice!.toStringAsFixed(2)}';
    } else if (currency == 'IDR') {
      return 'Rp ${standardPrice!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.'
      )}';
    } else {
      return '${standardPrice!.toStringAsFixed(2)} ${currency ?? ''}';
    }
  }
}