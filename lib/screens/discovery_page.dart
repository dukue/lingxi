import 'package:flutter/material.dart';

class DiscoveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('发现'),
      ),
      body: ListView(
        children: [
          _buildSection('热门话题', Icons.trending_up),
          _buildSection('情感故事', Icons.favorite),
          _buildSection('交友广场', Icons.people),
          _buildSection('恋爱技巧', Icons.lightbulb),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('内容 ${index + 1}')),
                );
              },
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
} 