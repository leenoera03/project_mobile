import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../models/navigation_item.dart'; // Import navigation_item
import 'profile_page.dart';
import 'search_page.dart';
import 'about_page.dart';
import 'login_page.dart'; // Import login page untuk logout
import '../models/recipe.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_page.dart';

class UserPage extends StatefulWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  TextEditingController locationController = TextEditingController();
  bool isLoading = false;
  bool hasLocationPermission = false;
  String? username; // Tambahan untuk menyimpan username

  // Current location data
  Position? currentPosition;
  String currentAddress = "Lokasi belum ditentukan";
  String currentCity = "";
  String currentCountry = "";

  // Time detection variables
  Timer? _timeTimer;
  DateTime currentTime = DateTime.now();
  String timeOfDay = "";
  String timeGreeting = "";
  IconData timeIcon = Icons.access_time;
  Color timeColor = Colors.blue;

  // Search results
  List<Location> searchResults = [];
  Location? selectedLocation;
  String selectedAddress = "";

  // Navigation
  int _currentIndex = 0;
  late List<Widget> _pages;

  // Google Maps
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(-7.7956, 110.3695), // Default to Yogyakarta
    zoom: 11.0,
  );

  List<Recipes> allRecipes = [];
  List<Recipes> recommendedRecipes = [];
  bool isLoadingRecommendations = false;

  // Colors - Navy & White theme to match LoginPage
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF666666);
  static const Color accentBlue = Color(0xFF0074D9);
  static const Color lightNavy = Color(0xFF2C5282);

  @override
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkPermissions();
    _startTimeUpdates();
    _updateTimeInfo();
    _loadAllRecipes(); // TAMBAHKAN BARIS INI

    _pages = [
      _buildHomePage(),
      ProfilePage(),
      SearchPage(),
      AboutPage(),
    ];
  }


  @override
  void dispose() {
    locationController.dispose();
    mapController?.dispose();
    _timeTimer?.cancel(); // Cancel timer
    super.dispose();
  }

  // Start periodic time updates
  void _startTimeUpdates() {
    _timeTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateTimeInfo();
    });
  }

  // Update time information
  void _updateTimeInfo() {
    setState(() {
      currentTime = DateTime.now();
      int hour = currentTime.hour;

      if (hour >= 5 && hour < 12) {
        timeOfDay = "Pagi";
        timeGreeting = "Selamat Pagi";
        timeIcon = Icons.wb_sunny;
        timeColor = Colors.orange;
      } else if (hour >= 12 && hour < 18) {
        timeOfDay = "Siang";
        timeGreeting = "Selamat Siang";
        timeIcon = Icons.wb_sunny_outlined;
        timeColor = Colors.amber;
      } else if (hour >= 18 && hour < 21) {
        timeOfDay = "Sore";
        timeGreeting = "Selamat Sore";
        timeIcon = Icons.wb_twilight;
        timeColor = Colors.deepOrange;
      } else {
        timeOfDay = "Malam";
        timeGreeting = "Selamat Malam";
        timeIcon = Icons.nightlight;
        timeColor = Colors.indigo;
      }
    });

    if (allRecipes.isNotEmpty) {
      _filterRecommendationsByTime();
    }
  }

  // Format time string
  String _formatTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Format date string
  String _formatDate(DateTime date) {
    List<String> days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    String dayName = days[date.weekday % 7];
    String monthName = months[date.month - 1];

    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  // Fungsi untuk load user info
  _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });
  }

  // Fungsi logout
  _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _checkPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          currentAddress = "Layanan lokasi tidak aktif";
        });
        // Show dialog to enable location services
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            currentAddress = "Izin lokasi ditolak";
            hasLocationPermission = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          currentAddress =
          "Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan.";
          hasLocationPermission = false;
        });
        _showPermissionDialog();
        return;
      }

      setState(() {
        hasLocationPermission = true;
      });

      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        currentAddress = "Error checking permissions: $e";
        hasLocationPermission = false;
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: pureWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Layanan Lokasi Tidak Aktif',
            style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Silakan aktifkan layanan lokasi di pengaturan perangkat Anda.',
            style: TextStyle(color: darkGrey),
          ),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: primaryNavy)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                  'Buka Pengaturan', style: TextStyle(color: primaryNavy)),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: pureWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Izin Lokasi Diperlukan',
            style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Aplikasi memerlukan izin lokasi untuk menampilkan lokasi Anda. Silakan aktifkan di pengaturan aplikasi.',
            style: TextStyle(color: darkGrey),
          ),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: primaryNavy)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                  'Buka Pengaturan', style: TextStyle(color: primaryNavy)),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!hasLocationPermission) return;

    setState(() {
      isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          currentPosition = position;
          currentAddress =
          "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place
              .locality ?? ''}";
          currentCity = place.locality ?? "";
          currentCountry = place.country ?? "";

          // Update camera position and marker
          initialCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          );

          // Add marker for current location
          markers.add(
            Marker(
              markerId: MarkerId('current_location'),
              position: LatLng(position.latitude, position.longitude),
              infoWindow: InfoWindow(
                title: 'Lokasi Saat Ini',
                snippet: currentAddress,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          );
        });

        // Move camera to current location if map is ready
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 15.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        currentAddress = "Gagal mendapatkan lokasi: ${e.toString()}";
      });
      print("Error getting location: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        selectedLocation = null;
        selectedAddress = "";
        // Remove search marker
        markers.removeWhere((marker) =>
        marker.markerId.value == 'search_location');
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);

      setState(() {
        searchResults = locations;
        if (locations.isNotEmpty) {
          selectedLocation = locations[0];
          _getAddressFromLocation(locations[0]);

          // Add marker for searched location
          markers.removeWhere((marker) =>
          marker.markerId.value == 'search_location');
          markers.add(
            Marker(
              markerId: MarkerId('search_location'),
              position: LatLng(locations[0].latitude, locations[0].longitude),
              infoWindow: InfoWindow(
                title: 'Lokasi Pencarian',
                snippet: query,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          );

          // Move camera to searched location
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(locations[0].latitude, locations[0].longitude),
                  zoom: 15.0,
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      setState(() {
        searchResults = [];
        selectedLocation = null;
        selectedAddress = "Lokasi tidak ditemukan: ${e.toString()}";
      });
      print("Error searching location: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getAddressFromLocation(Location location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          selectedAddress =
          "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place
              .locality ?? ''}, ${place.country ?? ''}";
        });
      }
    } catch (e) {
      setState(() {
        selectedAddress = "Detail alamat tidak tersedia: ${e.toString()}";
      });
    }
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // If we have current position, move camera there
    if (currentPosition != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
                currentPosition!.latitude, currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _loadAllRecipes() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    try {
      // Debug: Print untuk melihat apakah method dipanggil
      print('Loading recipes from API...');

      List<Recipes> recipes = await RecipeService.getAllRecipes();

      // Debug: Print jumlah resep yang didapat
      print('Loaded ${recipes.length} recipes');

      setState(() {
        allRecipes = recipes;
      });

      _filterRecommendationsByTime();
    } catch (e) {
      // Tampilkan error yang lebih jelas
      print('Error loading recipes: $e');

      setState(() {
        allRecipes = []; // Reset ke empty list
        recommendedRecipes = [];
      });

      // Opsional: Tampilkan snackbar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat rekomendasi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingRecommendations = false;
      });
    }
  }

// Filter recommendations based on current time
  void _filterRecommendationsByTime() {
    if (allRecipes.isEmpty) {
      setState(() {
        recommendedRecipes = [];
      });
      return;
    }

    String currentMealType = _getCurrentMealType();
    print('Current meal type: $currentMealType'); // Debug

    // Coba filter berdasarkan meal type
    List<Recipes> filtered = allRecipes.where((recipe) {
      // Debug: Print meal types dari setiap recipe
      print('Recipe: ${recipe.name}, Meal Types: ${recipe.mealType}');

      return recipe.mealType.any((mealType) =>
          mealType.toLowerCase().contains(currentMealType.toLowerCase()));
    }).toList();

    print('Filtered recipes: ${filtered.length}'); // Debug

    // Jika tidak ada yang cocok dengan meal type, ambil resep random
    if (filtered.isEmpty) {
      print('No recipes match meal type, showing random recipes');
      filtered = List.from(allRecipes)..shuffle();
    }

    // Ambil maksimal 5 rekomendasi
    setState(() {
      recommendedRecipes = filtered.take(5).toList();
    });

    print('Final recommendations: ${recommendedRecipes.length}'); // Debug
  }


// Get current meal type based on time
  String _getCurrentMealType() {
    int hour = DateTime
        .now()
        .hour;

    if (hour >= 5 && hour < 12) {
      return "Breakfast";
    } else if (hour >= 12 && hour < 18) {
      return "Lunch";
    } else {
      return "Dinner";
    }
  }

  Widget _buildRecommendationsSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: timeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.restaurant_menu, color: timeColor, size: 24),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi ${_getCurrentMealType()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  Text(
                    'Cocok untuk waktu $timeOfDay',
                    style: TextStyle(
                      fontSize: 12,
                      color: timeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),

          if (isLoadingRecommendations)
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryNavy),
                    SizedBox(height: 12),
                    Text('Memuat rekomendasi...',
                        style: TextStyle(color: darkGrey)),
                  ],
                ),
              ),
            )
          else if (allRecipes.isEmpty) // Tambahkan kondisi untuk error state
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 40),
                    SizedBox(height: 8),
                    Text('Gagal memuat data',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    TextButton(
                      onPressed: _loadAllRecipes,
                      child: Text('Coba Lagi', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            )
          else if (recommendedRecipes.isEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu,
                          color: primaryNavy.withOpacity(0.5), size: 40),
                      SizedBox(height: 8),
                      Text('Belum ada rekomendasi tersedia',
                          style: TextStyle(color: darkGrey)),
                      SizedBox(height: 4),
                      TextButton(
                        onPressed: _loadAllRecipes,
                        child: Text('Muat Ulang', style: TextStyle(color: primaryNavy)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recommendedRecipes[index];
                    return Container(
                      width: 160,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: pureWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecipeDetailPage(recipe: recipe),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                recipe.image,
                                width: double.infinity,
                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: primaryNavy.withOpacity(0.1),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: primaryNavy,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: primaryNavy.withOpacity(0.1),
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                    ),
                                    child: Icon(Icons.restaurant,
                                        color: primaryNavy, size: 40),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      recipe.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryNavy,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      recipe.cuisine,
                                      style: TextStyle(
                                        color: darkGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Spacer(),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            color: timeColor, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                                          style: TextStyle(
                                            color: timeColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  // Widget helper untuk menu row
  Widget _buildMenuRow(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Text(text, style: TextStyle(color: primaryNavy)),
        ],
      ),
    );
  }

  // Method untuk membangun halaman home (konten layanan lokasi) - FIXED VERSION
  Widget _buildHomePage() {
    return SingleChildScrollView( // 1. Bungkus dengan SingleChildScrollView
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
        ),
        child: Column(
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [lightGrey.withOpacity(0.3), pureWhite],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: primaryNavy,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: primaryNavy.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Icon(Icons.person, color: pureWhite),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded( // 2. Tambahkan Expanded widget
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${timeGreeting}, ${username ?? 'Foodie'}!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryNavy,
                          ),
                          overflow: TextOverflow
                              .ellipsis, // Tambahkan overflow handling
                        ),
                        Text(
                          'Waktu ${timeOfDay}',
                          style: TextStyle(
                            fontSize: 14,
                            color: timeColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Location Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cari Lokasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  SizedBox(height: 8),
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
                      controller: locationController,
                      style: TextStyle(color: primaryNavy),
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama tempat atau alamat...',
                        hintStyle: TextStyle(color: darkGrey),
                        prefixIcon: Container(
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryNavy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.search, color: primaryNavy),
                        ),
                        suffixIcon: locationController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: primaryNavy),
                          onPressed: () {
                            locationController.clear();
                            _searchLocation('');
                          },
                        )
                            : null,
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
                      ),
                      onChanged: _searchLocation,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Time Detection Card (Previously Current Location Card)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: pureWhite,
                    border: Border.all(color: lightGrey, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: timeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(timeIcon, color: timeColor, size: 24),
                          ),
                          SizedBox(width: 8),
                          Expanded( // Tambahkan Expanded untuk menghindari overflow
                            child: Text(
                              'Waktu & Lokasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryNavy,
                              ),
                            ),
                          ),
                          if (!hasLocationPermission)
                            Container(
                              decoration: BoxDecoration(
                                color: primaryNavy.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.refresh, color: primaryNavy),
                                onPressed: _checkPermissions,
                                tooltip: 'Periksa izin lokasi',
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Time Information
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: timeColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: timeColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, color: timeColor, size: 20),
                            SizedBox(width: 8),
                            Expanded( // Tambahkan Expanded untuk text yang panjang
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatTime(currentTime)} - $timeOfDay',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: timeColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDate(currentTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkGrey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12),

                      // Location Information
                      if (isLoading && currentPosition == null)
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primaryNavy,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mendapatkan lokasi...',
                                style: TextStyle(color: darkGrey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        ...[
                          Row(
                            children: [
                              Icon(Icons.location_on, color: primaryNavy,
                                  size: 16),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  currentAddress,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: darkGrey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2, // Batasi maksimal 2 baris
                                ),
                              ),
                            ],
                          ),
                          if (currentPosition != null) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.my_location, size: 14,
                                    color: primaryNavy),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Lat: ${currentPosition!.latitude
                                        .toStringAsFixed(
                                        6)} | Long: ${currentPosition!.longitude
                                        .toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: darkGrey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                    ],
                  ),
                ),
              ),
            ),

            // Google Maps - 3. Berikan tinggi tetap untuk GoogleMap
            Container(
              height: 300,
              // Ganti Expanded dengan Container dengan tinggi tetap
              margin: EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: initialCameraPosition,
                    markers: markers,
                    myLocationEnabled: hasLocationPermission,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                    compassEnabled: true,
                    onTap: (LatLng position) {
                      // Optional: Handle map tap
                      print('Map tapped at: ${position.latitude}, ${position
                          .longitude}');
                    },
                  ),
                ),
              ),
            ),

            _buildRecommendationsSection(),

            // Selected Location Details
            if (selectedLocation != null)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: pureWhite,
                      border: Border.all(color: lightGrey, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                  Icons.place, color: accentBlue, size: 24),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lokasi Pencarian',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          selectedAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: darkGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3, // Batasi maksimal 3 baris
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.my_location, size: 16,
                                color: primaryNavy),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Lat: ${selectedLocation!.latitude
                                    .toStringAsFixed(
                                    6)} | Long: ${selectedLocation!.longitude
                                    .toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: darkGrey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Tambahkan padding bottom untuk space dengan bottom navigation
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

// 4. Update body di build method - Tambahkan SafeArea
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: pureWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        title: Text(
          'Location Check',
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.my_location, color: primaryNavy),
              onPressed: _getCurrentLocation,
              tooltip: 'Dapatkan lokasi saat ini',
            ),
          ),
          // Tombol logout menggunakan PopupMenuButton
          Container(
            margin: EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.more_vert, color: primaryNavy),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: pureWhite,
              onSelected: (String result) {
                if (result == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'logout',
                  child: _buildMenuRow(Icons.logout, 'Logout', primaryNavy),
                ),
              ],
            ),
          ),
        ],
      ) : null,
      body: SafeArea( // Tambahkan SafeArea untuk menghindari collision dengan system UI
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: pureWhite,
          selectedItemColor: primaryNavy,
          unselectedItemColor: darkGrey,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
          ),
          currentIndex: _currentIndex,
          onTap: _onNavigationTapped,
          items: navigationItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}