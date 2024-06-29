import 'package:epubx/epubx.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'dart:typed_data';

class Blip {
  final String text;
  Blip(this.text);
}

Future<List<Blip>> extractBlipsFromEpub(Uint8List epubBytes) async {
  EpubBook epubBook = await EpubReader.readBook(epubBytes);
  List<Blip> blips = [];

  for (var chapter in epubBook.Chapters!) {
    blips.addAll(await _extractBlipsFromChapter(chapter));
  }

  return _mergeShortBlips(blips);
}

Future<List<Blip>> _extractBlipsFromChapter(EpubChapter chapter) async {
  List<Blip> blips = [];

  if (chapter.Title != null) {
    blips.add(Blip(chapter.Title!));
  }
  if (chapter.HtmlContent != null) {
    String textContent = _parseHtmlToText(chapter.HtmlContent!);
    blips.addAll(_generateBlips(textContent));
  }
  for (var subChapter in chapter.SubChapters!) {
    blips.addAll(await _extractBlipsFromChapter(subChapter));
  }

  return blips;
}

String _parseHtmlToText(String htmlContent) {
  html_dom.Document document = html_parser.parse(htmlContent);
  return _extractTextFromElement(document.body);
}

String _extractTextFromElement(html_dom.Element? element) {
  if (element == null) return '';

  List<String> textParts = [];
  for (var node in element.nodes) {
    if (node is html_dom.Element) {
      textParts.add(_extractTextFromElement(node));
    } else if (node is html_dom.Text) {
      textParts.add(node.text.trim());
    }
  }

  return textParts.join('\n');
}

List<Blip> _generateBlips(String textContent) {
  List<Blip> blips = [];
  RegExp regex = RegExp(r'([^\n.!?]*[.!?])', multiLine: true);
  Iterable<Match> matches = regex.allMatches(textContent);

  for (var match in matches) {
    String blipText = match.group(0)!.trim();
    if (blipText.isNotEmpty) {
      blips.addAll(_splitBlipIntelligently(blipText));
    }
  }

  return blips;
}

List<Blip> _splitBlipIntelligently(String blipText) {
  List<Blip> blips = [];
  List<String> words = blipText.split(RegExp(r'\s+'));

  if (words.length <= 30) {
    blips.add(Blip(blipText));
  } else {
    StringBuffer buffer = StringBuffer();
    int wordCount = 0;

    for (String word in words) {
      buffer.write('$word ');
      wordCount++;

      if (wordCount >= 30 &&
          (word.endsWith(',') || word.endsWith(';') || word.endsWith('.'))) {
        blips.add(Blip(buffer.toString().trim()));
        buffer.clear();
        wordCount = 0;
      }
    }

    if (buffer.isNotEmpty) {
      blips.add(Blip(buffer.toString().trim()));
    }
  }

  return blips;
}

List<Blip> _mergeShortBlips(List<Blip> blips) {
  List<Blip> mergedBlips = [];
  StringBuffer buffer = StringBuffer();

  for (Blip blip in blips) {
    if (blip.text.trim().isEmpty) {
      continue;
    }

    int wordCount = buffer.toString().split(RegExp(r'\s+')).length +
        blip.text.split(RegExp(r'\s+')).length;
    if (wordCount < 10) {
      buffer.write('${buffer.isEmpty ? '' : ' '}${blip.text}');
    } else {
      if (buffer.isNotEmpty) {
        mergedBlips.add(Blip(buffer.toString().trim()));
        buffer.clear();
      }
      buffer.write(blip.text);
    }

    if (buffer.toString().split(RegExp(r'\s+')).length >= 30) {
      mergedBlips.add(Blip(buffer.toString().trim()));
      buffer.clear();
    }
  }

  if (buffer.isNotEmpty) {
    mergedBlips.add(Blip(buffer.toString().trim()));
  }

  return mergedBlips;
}
