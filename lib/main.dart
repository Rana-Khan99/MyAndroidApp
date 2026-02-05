import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:matchreport_v3/pages/match_book/models/post_model.dart';

// 🧩 MatchBook Module Screens
import 'pages/match_book/screens/match_book_screen.dart';
import 'pages/match_book/screens/new_post_screen.dart';
import 'pages/match_book/screens/post_detail_screen.dart';
import 'pages/match_book/screens/chat_screen.dart';
import 'pages/match_book/screens/chat_detail_screen.dart';
import 'pages/match_book/screens/friend_requests_screen.dart';
import 'pages/match_book/screens/friends_list_screen.dart';
import 'pages/match_book/screens/friends_screen.dart';
import 'pages/match_book/screens/friends_list_screen.dart';
import 'pages/match_book/screens/home_feed_screen.dart';
import 'pages/match_book/screens/profile_screen.dart';

// 🧮 Other Pages
import 'pages/meal_calculation/meal_calculation.dart';
import 'pages/rice_calculation/rice_calculation.dart';
import 'pages/khala_calculation/khala_calculation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Mr. R-Group",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),

      // 🏠 Home Screen
      home: const HomeScreen(),

      // 🧭 Dynamic Route Management
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/newPost':
            return MaterialPageRoute(
              builder: (_) => const NewPostScreen(),
            );
          case '/postDetail':
            final post = settings.arguments;
            if (post is! Post) {
              debugPrint("⚠️ Invalid post argument passed to /postDetail");
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(
                    child: Text(
                      "Invalid post data",
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post),
            );


          case '/chat':
            final args = settings.arguments as Map<String, dynamic>?;
            final friendId = args?['friendId'] ?? '';
            final friendName = args?['friendName'] ?? 'Unknown';
            return MaterialPageRoute(
              builder: (_) => ChatScreen(
                friendId: friendId,
                friendName: friendName,
              ),
            );

          case '/friendRequests':
            return MaterialPageRoute(
              builder: (_) => FriendRequestsScreen(),
            );

          case '/friendsList':
            return MaterialPageRoute(
              builder: (_) => FriendsScreen(),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text(
                    "404 — Page not found",
                    style: TextStyle(fontSize: 18, color: Colors.redAccent),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MatchBookScreen(),
    MealCalculationScreen(),
    RiceCalculationPage(),
    KhalaBillPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: "Match Book",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: "Meal Calc",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rice_bowl_outlined),
            activeIcon: Icon(Icons.rice_bowl),
            label: "Rice Calc",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: "Khala/Gura Bill",
          ),
        ],
      ),
    );
  }
}
