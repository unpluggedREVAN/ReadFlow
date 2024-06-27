import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'dart:typed_data';

class BookContentScreen extends StatelessWidget {
  final String bookTitle;
  final Uint8List bookBytes;

  const BookContentScreen(
      {Key? key, required this.bookTitle, required this.bookBytes})
      : super(key: key);

  Future<String> _extractTextFromEpub(Uint8List epubBytes) async {
    EpubBook epubBook = await EpubReader.readBook(epubBytes);
    StringBuffer buffer = StringBuffer();

    for (var chapter in epubBook.Chapters!) {
      buffer.writeln(chapter.Title);
      buffer.writeln(await _extractChapterText(chapter));
    }

    return buffer.toString();
  }

  Future<String> _extractChapterText(EpubChapter chapter) async {
    StringBuffer buffer = StringBuffer();

    buffer.writeln(chapter.HtmlContent);
    for (var subChapter in chapter.SubChapters!) {
      buffer.writeln(await _extractChapterText(subChapter));
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bookTitle),
      ),
      body: FutureBuilder<String>(
        future: _extractTextFromEpub(bookBytes),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading book content'));
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(snapshot.data ?? 'No content available'),
            );
          }
        },
      ),
    );
  }
}
