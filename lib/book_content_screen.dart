import 'package:flutter/material.dart';
import 'epub_processor.dart';

class BookContentScreen extends StatelessWidget {
  final String bookTitle;
  final List<Blip> blips;

  const BookContentScreen(
      {Key? key, required this.bookTitle, required this.blips})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: blips.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              blips[index].text,
              style: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
