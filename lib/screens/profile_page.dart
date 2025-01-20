import 'package:flutter/material.dart';
import '../services/floating_window_service.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const platform = MethodChannel('com.example.lingxi/floating_window');
  
  @override
  void initState() {
    super.initState();
    _checkFloatingWindowStatus();
    
    // 注册方法通道处理器
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onFloatingWindowClosed') {
        setState(() {
          FloatingWindowService.isShowing = false;
        });
      }
    });
  }

  Future<void> _checkFloatingWindowStatus() async {
    final status = await FloatingWindowService.checkFloatingWindowStatus();
    if (mounted) {
      setState(() {
        FloatingWindowService.isShowing = status;
      });
    }
  }

  @override
  void dispose() {
    platform.setMethodCallHandler(null); // 清理方法通道处理器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('我的'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.purple, Colors.blue],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '点击登录',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildMenuItem('我的收藏', Icons.favorite),
              _buildMenuItem('历史记录', Icons.history),
              _buildMenuItem('我的关注', Icons.people),
              _buildFloatingWindowSwitch(),
              _buildMenuItem('设置', Icons.settings),
              _buildMenuItem('帮助与反馈', Icons.help),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _buildFloatingWindowSwitch() {
    return ValueListenableBuilder<bool>(
      valueListenable: FloatingWindowService.isShowingNotifier,
      builder: (context, isShowing, child) {
        return ListTile(
          leading: Icon(Icons.launch),
          title: Text('悬浮窗'),
          subtitle: Text('快速访问AI聊天助手'),
          trailing: Switch(
            value: isShowing,
            onChanged: (value) async {
              if (value) {
                await FloatingWindowService.requestPermission();
                await FloatingWindowService.show();
              } else {
                await FloatingWindowService.hide();
              }
            },
          ),
        );
      },
    );
  }
} 