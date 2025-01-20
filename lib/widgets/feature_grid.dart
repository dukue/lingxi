import 'package:flutter/material.dart';

class FeatureGrid extends StatelessWidget {
  final List<FeatureItem> features = [
    FeatureItem('聊天技巧', 'assets/icons/chat_tips.png', Colors.pink[100]!),
    FeatureItem('土味情话', 'assets/icons/love_words.png', Colors.blue[100]!),
    FeatureItem('表情文案', 'assets/icons/emoji.png', Colors.purple[100]!),
    FeatureItem('画风诗', 'assets/icons/poetry.png', Colors.green[100]!),
    FeatureItem('撩人文案', 'assets/icons/flirt.png', Colors.orange[100]!),
    FeatureItem('情人小记', 'assets/icons/love_notes.png', Colors.red[100]!),
    FeatureItem('表情包', 'assets/icons/stickers.png', Colors.yellow[100]!),
    FeatureItem('情诗湾', 'assets/icons/love_poetry.png', Colors.teal[100]!),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return _buildFeatureItem(features[index]);
      },
    );
  }

  Widget _buildFeatureItem(FeatureItem item) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(item.iconPath),
        ),
        SizedBox(height: 4),
        Text(
          item.title,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class FeatureItem {
  final String title;
  final String iconPath;
  final Color color;

  FeatureItem(this.title, this.iconPath, this.color);
} 