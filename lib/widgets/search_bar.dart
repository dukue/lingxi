import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search, color: Colors.grey),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '女生怎"脱单"交友公园',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
} 