class User {
  final int? id;
  final String username;
  final String password;
  final String userType;
  final String? createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.userType,
    this.createdAt,
  });

  // Convert User object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'userType': userType,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  // Create User object from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      userType: map['userType'],
      createdAt: map['createdAt'],
    );
  }

  // Create User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      userType: json['userType'],
      createdAt: json['createdAt'],
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'userType': userType,
      'createdAt': createdAt,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, userType: $userType, createdAt: $createdAt}';
  }

  // Copy with method for immutable updates
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? userType,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}