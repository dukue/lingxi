import 'package:flutter/material.dart';

class MessageCenter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('消息中心'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person),
            ),
            title: Text('用户 ${index + 1}'),
            subtitle: Text('最新消息内容...'),
            trailing: Text('12:30'),
          );
        },
      ),
    );
  }
} 