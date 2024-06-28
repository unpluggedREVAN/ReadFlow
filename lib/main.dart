import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'book_content_screen.dart';
import 'epub_processor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookProvider()),
      ],
      child: MaterialApp(
        title: 'ReadFlow',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlipFlow Library'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const BookLibraryScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['epub'],
          );
          if (result != null && result.files.single.path != null) {
            final file = result.files.single;
            if (file.extension == 'epub') {
              File epubFile = File(file.path!);
              Uint8List bytes = await epubFile.readAsBytes();
              List<Blip> blips = await extractBlipsFromEpub(bytes);
              Provider.of<BookProvider>(context, listen: false)
                  .addBook(file.name, blips);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Only EPUB files are allowed')),
              );
            }
          }
        },
        tooltip: 'Add Book',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class BookLibraryScreen extends StatelessWidget {
  const BookLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    final List<Book> books = bookProvider.books;

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookContentScreen(
                  bookTitle: books[index].title,
                  blips: books[index].blips,
                ),
              ),
            );
          },
          child: Card(
            elevation: 5,
            child: Center(
              child: Text(
                books[index].title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Book {
  final String title;
  final List<Blip> blips;

  Book(this.title, this.blips);
}

class BookProvider extends ChangeNotifier {
  final List<Book> _books = [];

  List<Book> get books => _books;

  void addBook(String title, List<Blip> blips) {
    if (!_books.any((b) => b.title == title)) {
      _books.add(Book(title, blips));
      notifyListeners();
    } else {
      print('Book already exists.');
    }
  }
}
