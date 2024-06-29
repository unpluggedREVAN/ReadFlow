import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_content_screen.dart';
import 'epub_processor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        backgroundColor: const Color(0xFFFF8161), // Cambiado a #FF8161
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
              List<ChapterBlips> chapters = await extractBlipsFromEpub(bytes);
              String filePath = file.path!;
              Provider.of<BookProvider>(context, listen: false)
                  .addBook(file.name, chapters, filePath);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Only EPUB files are allowed')),
              );
            }
          }
        },
        tooltip: 'Add Book',
        backgroundColor: const Color(0xFFFF8161), // Cambiado a #FF8161
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

    if (books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Tu biblioteca está vacía por ahora, para cargar libros presiona el botón "+".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

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
        return Card(
          elevation: 5,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookContentScreen(
                        bookTitle: books[index].title,
                        chapters: books[index].chapters,
                        initialBlipIndex:
                            bookProvider.getProgress(books[index].title),
                      ),
                    ),
                  );
                },
                child: Center(
                  child: Text(
                    books[index].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    bookProvider.removeBook(books[index].title);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Book {
  final String title;
  final List<ChapterBlips> chapters;
  final String filePath;

  Book(this.title, this.chapters, this.filePath);
}

class BookProvider extends ChangeNotifier {
  final List<Book> _books = [];
  final Map<String, int> _bookProgress = {};

  List<Book> get books => _books;

  BookProvider() {
    _loadBooks();
  }

  void addBook(
      String title, List<ChapterBlips> chapters, String filePath) async {
    if (!_books.any((b) => b.title == title)) {
      _books.add(Book(title, chapters, filePath));
      await _saveBooks();
      notifyListeners();
    } else {
      print('Book already exists.');
    }
  }

  void removeBook(String title) async {
    _books.removeWhere((book) => book.title == title);
    _bookProgress.remove(title);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('filePath_$title');
    await prefs.remove('progress_$title');
    await _saveBooks();
    notifyListeners();
  }

  int getProgress(String title) {
    return _bookProgress[title] ?? 0;
  }

  void updateProgress(String title, int progress) async {
    _bookProgress[title] = progress;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('progress_$title', progress);
  }

  Future<void> _loadBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookTitles = prefs.getStringList('book_titles') ?? [];
    for (String title in bookTitles) {
      String? filePath = prefs.getString('filePath_$title');
      if (filePath != null) {
        File epubFile = File(filePath);
        Uint8List bytes = await epubFile.readAsBytes();
        List<ChapterBlips> chapters = await extractBlipsFromEpub(bytes);
        _books.add(Book(title, chapters, filePath));
        _bookProgress[title] = prefs.getInt('progress_$title') ?? 0;
      }
    }
    notifyListeners();
  }

  Future<void> _saveBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> bookTitles = _books.map((b) => b.title).toList();
    await prefs.setStringList('book_titles', bookTitles);
    for (Book book in _books) {
      await prefs.setString('filePath_${book.title}', book.filePath);
    }
  }
}
