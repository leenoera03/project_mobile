import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/navigation_item.dart'; // Import navigation_item
import 'profile_page.dart';
import 'search_page.dart';
import 'about_page.dart';
import 'login_page.dart'; // Import login page untuk logout

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

  // Colors
  static const Color primaryGreen = Color(0xFFC7DB9C);
  static const Color accentYellow = Color(0xFFFFF0BD);
  static const Color lightCoral = Color(0xFFFDAB9E);
  static const Color darkGreen = Color(0xFF7BA05B);
  static const Color darkPink = Color(0xFFE50046); // Tambahan untuk logout button

  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Load user info
    _checkPermissions();

    // Initialize pages
    _pages = [
      _buildHomePage(), // Home page content (location services)
      ProfilePage(),
      SearchPage(),
      AboutPage(),
    ];
  }

  @override
  void dispose() {
    locationController.dispose();
    mapController?.dispose();
    super.dispose();
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
          currentAddress = "Izin lokasi ditolak permanen. Silakan aktifkan di pengaturan.";
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
          title: Text('Layanan Lokasi Tidak Aktif'),
          content: Text('Silakan aktifkan layanan lokasi di pengaturan perangkat Anda.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Buka Pengaturan'),
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
          title: Text('Izin Lokasi Diperlukan'),
          content: Text('Aplikasi memerlukan izin lokasi untuk menampilkan lokasi Anda. Silakan aktifkan di pengaturan aplikasi.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Buka Pengaturan'),
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
          currentAddress = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}";
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
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
        markers.removeWhere((marker) => marker.markerId.value == 'search_location');
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
          markers.removeWhere((marker) => marker.markerId.value == 'search_location');
          markers.add(
            Marker(
              markerId: MarkerId('search_location'),
              position: LatLng(locations[0].latitude, locations[0].longitude),
              infoWindow: InfoWindow(
                title: 'Lokasi Pencarian',
                snippet: query,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
          selectedAddress = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}";
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
            target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
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
          Text(text),
        ],
      ),
    );
  }

  // Method untuk membangun halaman home (konten layanan lokasi)
  Widget _buildHomePage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryGreen.withOpacity(0.1),
            accentYellow.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Welcome Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: darkGreen,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text(
                  'Selamat datang, ${username ?? 'User'}!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
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
                    color: darkGreen,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama tempat atau alamat...',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: darkGreen),
                    suffixIcon: locationController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: darkGreen),
                      onPressed: () {
                        locationController.clear();
                        _searchLocation('');
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
                  onChanged: _searchLocation,
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Current Location Card
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [primaryGreen.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: lightCoral, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Lokasi Saat Ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        Spacer(),
                        if (!hasLocationPermission)
                          IconButton(
                            icon: Icon(Icons.refresh, color: darkGreen),
                            onPressed: _checkPermissions,
                            tooltip: 'Periksa izin lokasi',
                          ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (isLoading && currentPosition == null)
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: darkGreen,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Mendapatkan lokasi...'),
                        ],
                      )
                    else ...[
                      Text(
                        currentAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (currentPosition != null) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.my_location, size: 16, color: darkGreen),
                            SizedBox(width: 4),
                            Text(
                              'Lat: ${currentPosition!.latitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.my_location, size: 16, color: darkGreen),
                            SizedBox(width: 4),
                            Text(
                              'Long: ${currentPosition!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
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

          // Google Maps
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Card(
                elevation: 4,
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
                      print('Map tapped at: ${position.latitude}, ${position.longitude}');
                    },
                  ),
                ),
              ),
            ),
          ),

          // Selected Location Details
          if (selectedLocation != null)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [lightCoral.withOpacity(0.1), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.place, color: lightCoral, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Lokasi Pencarian',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        selectedAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.my_location, size: 16, color: darkGreen),
                          SizedBox(width: 4),
                          Text(
                            'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.my_location, size: 16, color: darkGreen),
                          SizedBox(width: 4),
                          Text(
                            'Long: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: Text(
          'Layanan Lokasi',
          style: TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: darkGreen),
            onPressed: _getCurrentLocation,
            tooltip: 'Dapatkan lokasi saat ini',
          ),
          // Tombol logout menggunakan PopupMenuButton
          Container(
            margin: EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.more_vert, color: darkGreen),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (String result) {
                if (result == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'logout',
                  child: _buildMenuRow(Icons.logout, 'Logout', darkPink),
                ),
              ],
            ),
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
          backgroundColor: Colors.white,
          selectedItemColor: darkGreen,
          unselectedItemColor: Colors.grey,
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