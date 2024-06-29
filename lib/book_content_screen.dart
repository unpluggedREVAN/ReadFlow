import 'package:flutter/material.dart';
import 'epub_processor.dart';

class BookContentScreen extends StatefulWidget {
  final String bookTitle;
  final List<Blip> blips;

  const BookContentScreen(
      {Key? key, required this.bookTitle, required this.blips})
      : super(key: key);

  @override
  _BookContentScreenState createState() => _BookContentScreenState();
}

class _BookContentScreenState extends State<BookContentScreen> {
  PageController _pageController = PageController(viewportFraction: 0.4);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              itemCount: widget.blips.length,
              itemBuilder: (context, index) {
                return _buildBlipCard(widget.blips[index], index);
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
                const Text(
                  'Capítulo 1', // Placeholder for dynamic chapter functionality
                  style: TextStyle(
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
