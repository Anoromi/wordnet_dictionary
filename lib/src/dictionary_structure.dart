import 'package:wordnet_dictionary/src/terms.dart';
import 'package:wordnet_dictionary/src/types.dart';

import 'dictionary_data.dart';
import 'reader.dart';

WordType wordTypeFromChar(String s) {
  switch (s) {
    case "s":
      return WordType.satellite;
    case "r":
      return WordType.adverb;
    case "n":
      return WordType.noun;
    case "v":
      return WordType.verb;
    case "a":
      return WordType.adjective;
    default:
      throw Exception("Illegal argument $s");
  }
}

class Dictionary {
  final String path;
  final Reader _indexData,
      _indexReference,
      _indexWords,
      _relationData,
      _relationReference;
  final WordType type;
  final int relationSize;
  final int indexSize;

  Dictionary._init(
      this.path,
      this.type,
      this._indexData,
      this._indexReference,
      this._indexWords,
      this._relationData,
      this._relationReference,
      this.indexSize,
      this.relationSize);

  Future<PartialTerm?> nextTerm() async {
    if (await _indexReference.file.length() ==
        await _indexReference.file.position()) {
      return null;
    }
    var wordPosition = await _indexReference.nextInt64();
    var dataPosition = await _indexReference.nextInt64();
    await _indexWords.moveTo(wordPosition);
    await _indexData.moveTo(dataPosition);
    var word =
        await _indexWords.nextString(await _indexWords.nextVariableInt());
    word = word.replaceAll("_", " ");
    var dataLength = await _indexData.nextVariableInt();
    var references = [
      for (var i = 0; i < dataLength; ++i)
        Reference(await _indexData.nextVariableInt(), type)
    ];

    return PartialTerm(word, references);
  }

  Future<PartialTerm?> termAt(int index) async {
    var position = index * 16;
    await _indexReference.moveTo(position);
    return await nextTerm();
  }

  Future<PartialUnwrappedData> partialDataAt(int index) async {
    var position = index * 8;
    await _relationReference.moveTo(position);
    var reference = await _relationReference.nextInt64();
    await _relationData.moveTo(reference);
    var count = await _relationData.nextVariableInt();
    var words = List<String>.empty(growable: true);
    for (var i = 0; i < count; ++i) {
      var len = await _relationData.nextVariableInt();
      words.add(await _relationData.nextString(len));
    }
    return PartialUnwrappedData(words, index);
  }

  Future<PartialTerm?> term(String lowerBound) async {
    var min = 0, max = indexSize - 1;
    PartialTerm? next;
    while (min <= max) {
      var mid = min + (max - min) ~/ 2;
      next = await termAt(mid);
      next!;
      var comp = next.term.compareTo(lowerBound);
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }
    return await termAt(min);
  }

  Future<UnwrappedData> unwrapAt(
      int index,
      Future<PartialUnwrappedData> Function(WordType, int index)
          partialDataAt) async {
    await _relationReference.moveTo(index * 8);
    var position = await _relationReference.nextInt64();
    await _relationData.moveTo(position);
    var words = List<String>.empty(growable: true);
    var count = await _relationData.nextVariableInt();
    for (var i = 0; i < count; ++i) {
      var len = await _relationData.nextVariableInt();
      words.add(await _relationData.nextString(len));
    }

    var useCases = List<UseCase>.empty(growable: true);
    if (type == WordType.verb) {
      count = await _relationData.nextVariableInt();
      for (var i = 0; i < count; ++i) {
        var id = await _relationData.nextVariableInt();
        var wordInd = await _relationData.nextVariableInt();
        useCases.add(UseCase(id, wordInd));
      }
    }

    count = await _relationData.nextVariableInt();
    var definition = await _relationData.nextString(count);

    count = await _relationData.nextVariableInt();
    var relations = List<Relation>.empty(growable: true);
    for (var i = 0; i < count; ++i) {
      var index = await _relationData.nextVariableInt();
      var data = await _relationData.nextU8();
      var wType = WordType.values[data & 0x7];
      var rType = RelationType.values[data >> 3];
      relations
          .add(Relation(await partialDataAt(wType, index), wType, rType));
    }
    return UnwrappedData(words, relations, definition, useCases, type);
  }

  static Future<Dictionary> fromPath(String d, WordType type) async {
    Future<Reader> path(String s) async => await Reader.fromPath("$d/$s");
    var indexData = await path("indexData");
    var indexReference = await path("indexReference");
    var indexWords = await path("indexWords");
    var relationData = await path("relationData");
    var relationReference = await path("relationsReference");
    var indexSize = await indexReference.file.length() ~/ 16;
    var relationSize = await relationReference.file.length() ~/ 8;
    return Dictionary._init(d, type, indexData, indexReference, indexWords,
        relationData, relationReference, indexSize, relationSize);
  }
}
