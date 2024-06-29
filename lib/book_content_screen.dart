import 'package:flutter/material.dart';
import 'epub_processor.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class BookContentScreen extends StatefulWidget {
  final String bookTitle;
  final List<ChapterBlips> chapters;
  final int initialBlipIndex;

  const BookContentScreen(
      {Key? key,
      required this.bookTitle,
      required this.chapters,
      required this.initialBlipIndex})
      : super(key: key);

  @override
  _BookContentScreenState createState() => _BookContentScreenState();
}

class _BookContentScreenState extends State<BookContentScreen> {
  late PageController _pageController;
  int _currentBlipIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentBlipIndex = widget.initialBlipIndex;
    _pageController =
        PageController(viewportFraction: 0.4, initialPage: _currentBlipIndex);
    _pageController.addListener(() {
      int newIndex = _pageController.page?.round() ?? 0;
      if (_currentBlipIndex != newIndex) {
        setState(() {
          _currentBlipIndex = newIndex;
        });
        Provider.of<BookProvider>(context, listen: false)
            .updateProgress(widget.bookTitle, _currentBlipIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8161),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _getBlipCount(),
              itemBuilder: (context, index) {
                Blip blip = _getBlipByIndex(index);
                return _buildBlipCard(blip, index);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_upward),
                  onPressed: () {
                    _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward),
                  onPressed: () {
                    _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String currentChapterTitle =
        _getCurrentChapterTitle(widget.chapters, _currentBlipIndex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
      color: const Color(0xFFFF8161),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.bookTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currentChapterTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getBlipCount() {
    return widget.chapters
        .fold(0, (count, chapter) => count + _getBlipCountRecursive(chapter));
  }

  int _getBlipCountRecursive(ChapterBlips chapter) {
    return chapter.blips.length +
        chapter.subChapters.fold(0,
            (count, subChapter) => count + _getBlipCountRecursive(subChapter));
  }

  Blip _getBlipByIndex(int index) {
    for (var chapter in widget.chapters) {
      int chapterBlipCount = _getBlipCountRecursive(chapter);
      if (index < chapterBlipCount) {
        return _getBlipByIndexRecursive(chapter, index);
      }
      index -= chapterBlipCount;
    }
    throw IndexError(index, widget.chapters);
  }

  Blip _getBlipByIndexRecursive(ChapterBlips chapter, int index) {
    if (index < chapter.blips.length) {
      return chapter.blips[index];
    }
    index -= chapter.blips.length;
    for (var subChapter in chapter.subChapters) {
      int subChapterBlipCount = _getBlipCountRecursive(subChapter);
      if (index < subChapterBlipCount) {
        return _getBlipByIndexRecursive(subChapter, index);
      }
      index -= subChapterBlipCount;
    }
    throw IndexError(index, chapter.subChapters);
  }

  String _getCurrentChapterTitle(List<ChapterBlips> chapters, int blipIndex) {
    for (var chapter in chapters) {
      int chapterBlipCount = _getBlipCountRecursive(chapter);
      if (blipIndex < chapterBlipCount) {
        return _getCurrentChapterTitleRecursive(chapter, blipIndex);
      }
      blipIndex -= chapterBlipCount;
    }
    return "Untitled";
  }

  String _getCurrentChapterTitleRecursive(ChapterBlips chapter, int blipIndex) {
    if (blipIndex < chapter.blips.length) {
      return chapter.title;
    }
    blipIndex -= chapter.blips.length;
    for (var subChapter in chapter.subChapters) {
      int subChapterBlipCount = _getBlipCountRecursive(subChapter);
      if (blipIndex < subChapterBlipCount) {
        return _getCurrentChapterTitleRecursive(subChapter, blipIndex);
      }
      blipIndex -= subChapterBlipCount;
    }
    return chapter.title;
  }

  Widget _buildBlipCard(Blip blip, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = (_pageController.page! - index).clamp(-1.0, 1.0);
        }

        double scaleFactor = 1.0 - (value.abs() * 0.3);
        double fontSizeScaleFactor =
            1.0 - (value.abs() * 0.3); // Ajustar la escala de la letra
        Color cardColor = _getCardColor(value);
        Color textColor = _getTextColor(value);

        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(scaleFactor) * 250,
            width: Curves.easeInOut.transform(scaleFactor) * 300,
            child: Opacity(
              opacity: scaleFactor,
              child: Card(
                color: cardColor,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Transform.scale(
                      scale:
                          fontSizeScaleFactor, // Escalar el texto en lugar de cambiar el tamaño de la fuente
                      child: Text(
                        blip.text,
                        style: TextStyle(
                          fontSize: 18, // Mantener el tamaño de la fuente fijo
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCardColor(double value) {
    if (value == 0.0) {
      return Color(0xFF333333);
    } else {
      return Color.lerp(Color(0xFFA5A5A5), Color(0xFF333333), 1 - value.abs())!;
    }
  }

  Color _getTextColor(double value) {
    if (value == 0.0) {
      return Colors.white;
    } else {
      return Color.lerp(Color(0xFF666666), Colors.white, 1 - value.abs())!;
    }
  }
}
