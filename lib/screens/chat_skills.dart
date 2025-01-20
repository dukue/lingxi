import 'package:flutter/material.dart';

class ChatSkills extends StatelessWidget {
  final List<SkillItem> skills = [
    SkillItem(
      title: "帮我回复",
      usageCount: "22000人使用",
      iconPath: "assets/icons/ai_reply.png",
      color: Colors.blue[100]!,
      isSpecial: true,
      description: "让AI为你生成回复",
    ),
    SkillItem(
      title: "帮我润色",
      usageCount: "15000人使用",
      iconPath: "assets/icons/ai_reply.png",
      color: Colors.green[100]!,
      isSpecial: true,
      description: "让回复更加得体",
    ),
    SkillItem(
      title: "开场话题",
      usageCount: "22000人使用",
      iconPath: "assets/icons/chat_start.png",
      color: Colors.orange[100]!,
    ),
    SkillItem(
      title: "邀约技巧",
      usageCount: "15000人使用",
      iconPath: "assets/icons/date_skill.png",
      color: Colors.purple[100]!,
    ),
    SkillItem(
      title: "如何表白",
      usageCount: "12000人使用",
      iconPath: "assets/icons/confess.png",
      color: Colors.pink[100]!,
    ),
    SkillItem(
      title: "定制情话",
      usageCount: "10000人使用",
      iconPath: "assets/icons/love_words.png",
      color: Colors.blue[100]!,
    ),
    SkillItem(
      title: "可爱早安",
      usageCount: "22000人使用",
      iconPath: "assets/icons/morning.png",
      color: Colors.yellow[100]!,
    ),
    SkillItem(
      title: "撩人开场",
      usageCount: "17000人使用",
      iconPath: "assets/icons/flirt.png",
      color: Colors.red[100]!,
    ),
    SkillItem(
      title: "自我介绍",
      usageCount: "12000人使用",
      iconPath: "assets/icons/intro.png",
      color: Colors.teal[100]!,
    ),
    SkillItem(
      title: "暧昧话题",
      usageCount: "10000人使用",
      iconPath: "assets/icons/romantic.png",
      color: Colors.purple[100]!,
    ),
    SkillItem(
      title: "话题探讨",
      usageCount: "10000人使用",
      iconPath: "assets/icons/discuss.png",
      color: Colors.green[100]!,
    ),
    SkillItem(
      title: "分享新事",
      usageCount: "9500人使用",
      iconPath: "assets/icons/share.png",
      color: Colors.orange[100]!,
    ),
    SkillItem(
      title: "心动对象",
      usageCount: "6874人使用",
      iconPath: "assets/icons/crush.png",
      color: Colors.pink[100]!,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('聊天话术'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "一键生成，把握那个心仪的TA",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = skills[index];
                  return _buildSkillCard(item);
                },
                childCount: skills.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(SkillItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          if (item.isSpecial)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Image.asset(
              item.iconPath,
              width: 40,
              height: 40,
              color: item.color,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  item.description ?? item.usageCount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkillItem {
  final String title;
  final String usageCount;
  final String iconPath;
  final Color color;
  final bool isSpecial;
  final String? description;

  SkillItem({
    required this.title,
    required this.usageCount,
    required this.iconPath,
    required this.color,
    this.isSpecial = false,
    this.description,
  });
} 