import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with TickerProviderStateMixin {
  // Theme colors
  static const Color primaryNavy = Color(0xFF001F3F);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF666666);
  static const Color secretGold = Color(0xFFFFD700);
  static const Color envelopeRed = Color(0xFFE74C3C);
  static const Color envelopeBlue = Color(0xFF3498DB);
  static const Color envelopePurple = Color(0xFF9B59B6);

  List<bool> _openedEnvelopes = List.filled(6, false);
  late AnimationController _floatingController;
  late AnimationController _sparkleController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _sparkleAnimation;

  final List<Map<String, dynamic>> _secretMessages = [
    {
      'title': 'Resep Coding',
      'message': 'Seperti masak nasi goreng,\nCoding juga perlu sabar meneng.\nError itu bumbu kehidupan,\nBiar app jadi lebih nikmat dimakan! 😄',
      'color': envelopeRed,
      'icon': Icons.restaurant_menu,
    },
    {
      'title': 'Flutter Recipe',
      'message': 'Widget itu seperti bumbu dapur,\nDicampur jadi UI yang makmur.\nStateful StateLess jangan bingung,\nYang penting app-nya jalan lancar terus! 🚀',
      'color': envelopeBlue,
      'icon': Icons.flutter_dash,
    },
    {
      'title': 'Debug Wisdom',
      'message': 'Bug adalah guru terbaik kita,\nMengajarkan sabar dan teliti.\nSeperti cari garam yang jatuh,\nHarus telaten sampai ketemu! 🔍',
      'color': envelopePurple,
      'icon': Icons.bug_report,
    },
    {
      'title': 'Mata Kuliah TPM',
      'message': 'Teknologi Pemrograman Mobile,\nBuat hidup jadi lebih mudah dan agile.\nDari Hello World sampai Play Store,\nTerima kasih sudah ajarin explore! 🙏',
      'color': secretGold,
      'icon': Icons.school,
    },
    {
      'title': 'Life Lesson',
      'message': 'Seperti resep nenek yang turun temurun,\nIlmu coding juga harus dibagi terus.\nShare knowledge, help each other,\nBiar komunitas developer makin power! 💪',
      'color': Color(0xFF27AE60),
      'icon': Icons.lightbulb,
    },
    {
      'title': 'Pesan Terakhir',
      'message': 'Dari awal semester sampai UAS,\nCoding Flutter memang kadang bikin panas.\nTapi percayalah journey ini indah,\nSemoga ilmunya berkah dan bermanfaat! ✨',
      'color': Color(0xFFE67E22),
      'icon': Icons.star,
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _openEnvelope(int index) {
    if (!_openedEnvelopes[index]) {
      setState(() {
        _openedEnvelopes[index] = true;
      });

      _sparkleController.reset();
      _sparkleController.forward();

      HapticFeedback.mediumImpact();

      // Show celebration snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📬 Pesan rahasia terbuka!'),
          backgroundColor: _secretMessages[index]['color'],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNavy, primaryNavy.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      // Animated Recipe Book Icon
                      AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: secretGold,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: secretGold.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.menu_book,
                                size: 50,
                                color: primaryNavy,
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20),
                      Text(
                        'Secret Recipe Messages',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: pureWhite,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kesan & Pesan untuk TPM',
                        style: TextStyle(
                          fontSize: 16,
                          color: pureWhite.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: pureWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '📧 Tap envelope untuk membuka pesan rahasia!',
                          style: TextStyle(
                            fontSize: 12,
                            color: pureWhite,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Progress Indicator
                    Container(
                      margin: EdgeInsets.only(bottom: 20),
                      padding: EdgeInsets.all(16),
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
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mail, color: primaryNavy),
                              SizedBox(width: 8),
                              Text(
                                'Progress Membuka Pesan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryNavy,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _openedEnvelopes.where((opened) => opened).length / 6,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(secretGold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_openedEnvelopes.where((opened) => opened).length}/6 pesan terbuka',
                            style: TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Envelope Grid - Fixed to prevent overflow
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9, // Adjusted from 0.85 to 0.9 for better space
                      ),
                      itemCount: _secretMessages.length,
                      itemBuilder: (context, index) {
                        return _buildEnvelopeCard(index);
                      },
                    ),

                    SizedBox(height: 20),

                    // Special Thank You Card
                    if (_openedEnvelopes.every((opened) => opened))
                      AnimatedBuilder(
                        animation: _sparkleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.9 + (_sparkleAnimation.value * 0.1),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [secretGold, Color(0xFFFFE55C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: secretGold.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Text(
                                      '🎉 SEMUA PESAN TERBUKA! 🎉',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryNavy,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Terima kasih telah mengajarkan mata kuliah TPM yang sangat kompleks ini, Semoga ilmu diberikan bermanfaat untuk kedepannya. ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: primaryNavy,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    SizedBox(height: 20),

                    // Footer
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryNavy,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [

                          SizedBox(height: 4),
                          Text(
                            'Teknologi dan Pemrograman Mobile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: secretGold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '2025 • Resep Edition',
                            style: TextStyle(
                              fontSize: 12,
                              color: pureWhite.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnvelopeCard(int index) {
    bool isOpened = _openedEnvelopes[index];
    Map<String, dynamic> message = _secretMessages[index];

    return GestureDetector(
      onTap: () => _openEnvelope(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isOpened ? pureWhite : message['color'],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isOpened
                  ? Colors.black.withOpacity(0.1)
                  : message['color'].withOpacity(0.3),
              blurRadius: isOpened ? 10 : 15,
              offset: Offset(0, isOpened ? 5 : 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12), // Reduced from 16 to 12
          child: isOpened ? _buildOpenedMessage(index) : _buildClosedEnvelope(index),
        ),
      ),
    );
  }

  Widget _buildClosedEnvelope(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.mail,
          size: 36, // Reduced from 40 to 36
          color: pureWhite,
        ),
        SizedBox(height: 10), // Reduced from 12 to 10
        Text(
          'Pesan ${index + 1}',
          style: TextStyle(
            fontSize: 15, // Reduced from 16 to 15
            fontWeight: FontWeight.bold,
            color: pureWhite,
          ),
        ),
        SizedBox(height: 6), // Reduced from 8 to 6
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Reduced padding
          decoration: BoxDecoration(
            color: pureWhite.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Tap untuk buka',
            style: TextStyle(
              fontSize: 11, // Reduced from 12 to 11
              color: pureWhite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpenedMessage(int index) {
    Map<String, dynamic> message = _secretMessages[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(4), // Reduced from 6 to 4
              decoration: BoxDecoration(
                color: message['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                message['icon'],
                color: message['color'],
                size: 18, // Reduced from 20 to 18
              ),
            ),
            SizedBox(width: 6), // Reduced from 8 to 6
            Expanded(
              child: Text(
                message['title'],
                style: TextStyle(
                  fontSize: 13, // Reduced from 14 to 13
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
                maxLines: 2, // Limit title to 2 lines
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 8), // Reduced from 12 to 8
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              message['message'],
              style: TextStyle(
                fontSize: 11, // Reduced from 12 to 11
                color: darkGrey,
                height: 1.3, // Reduced from 1.4 to 1.3
              ),
            ),
          ),
        ),
      ],
    );
  }
}