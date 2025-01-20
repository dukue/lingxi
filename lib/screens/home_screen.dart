import 'package:flutter/material.dart';
import '../services/clipboard_service.dart';
import '../services/floating_window_service.dart';
import '../widgets/feature_grid.dart';
import '../widgets/search_bar.dart';
import 'chat_skills.dart';
import 'ai_chat.dart';
import 'discovery_page.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    HomeContent(),
    ChatSkills(),
    AIChat(),
    DiscoveryPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '话术',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'AI帮回',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 搜索栏
          CustomSearchBar(),
          
          // 顶部功能区
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeatureItem('追爱智选', 'assets/icons/smart_choice.png', Colors.blue[100]!),
                _buildFeatureItem('AI帮回复', 'assets/icons/ai_reply.png', Colors.pink[100]!),
                _buildFeatureItem('AI一键识图', 'assets/icons/ai_image.png', Colors.orange[100]!),
                _buildFeatureItem('恋爱导师', 'assets/icons/love_coach.png', Colors.green[100]!),
              ],
            ),
          ),
          
          // 功能网格
          Expanded(
            child: FeatureGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String iconPath, Color bgColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 32, height: 32),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
} 