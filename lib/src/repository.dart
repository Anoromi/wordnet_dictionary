import 'package:worker_configuration/worker_configuration.dart';
import 'package:wordnet_dictionary/dictionary.dart';
import 'package:wordnet_dictionary/src/dictionary_data.dart';
import 'package:wordnet_dictionary/src/terms.dart';
import 'package:wordnet_dictionary/src/types.dart';

class Repository {
  Dictionary noun, verb, adjective, adverb;

  Repository._(this.noun, this.verb, this.adjective, this.adverb);

  Dictionary operator [](WordType s) {
    switch (s) {
      case WordType.noun:
        return noun;
      case WordType.verb:
        return verb;
      case WordType.adjective:
        return adjective;
      case WordType.satellite:
        return adjective;
      case WordType.adverb:
        return adverb;
    }
  }

  Future<UnwrappedData> dataAt(WordType type, int index) async {
    var dict = this[type];
    return dict.unwrapAt(index, (p0, index) => this[type].partialDataAt(index));
  }

  Future<UnwrappedData> dataAtReference(Reference r) async =>
      dataAt(r.type, r.index);

  Future<FullTerm> unwrapTerm(PartialTerm term) async {
    var references = [for (var v in term.references) await dataAtReference(v)];
    return FullTerm(term.term, references);
  }

  OperationBd<List<PartialTerm>> findTerms(String lowerBound, int count) =>
      OperationBd<List<PartialTerm>>((context) async {
        String higherBound;
        {
          var v = lowerBound.codeUnitAt(lowerBound.length - 1);
          higherBound = lowerBound.substring(0, lowerBound.length - 1) +
              String.fromCharCode(v + 1);
        }
        PartialTerm? testSet(PartialTerm? term) {
          if (term == null || term.term.compareTo(higherBound) > 0) return null;
          return term;
        }

        var m = [
          Pair(noun, testSet(await noun.term(lowerBound))),
          Pair(verb, testSet(await verb.term(lowerBound))),
          Pair(adjective, testSet(await adjective.term(lowerBound))),
          Pair(adverb, testSet(await adverb.term(lowerBound))),
        ];
        context.check();

        var value = List<PartialTerm>.empty(growable: true);

        for (var i = 0; i < count; i++) {
          context.check();

          int min = -1;
          for (var i = 0; i < m.length; i++) {
            var item = m[i];

            if ((min == -1 && item.b != null) ||
                (item.b != null &&
                    item.b!.term.compareTo(m[min].b!.term) < 0)) {
              min = i;
            }
          }
          if (min == -1) break;
          var term = m[min].b!;
          m[min] = Pair(m[min].a, testSet(await m[min].a.nextTerm()));
          for (var i = 0; i < m.length; i++) {
            context.check();
            if (m[i].b != null && term.term == m[i].b!.term) {
              term = term.combine(m[i].b!);
              m[i] = Pair(m[i].a, testSet(await m[i].a.nextTerm()));
            }
          }
          value.add(term);
        }
        return value;
      });

  static Future<Repository> fromPath(String path) async {
    Future<Dictionary> getDictionary(String name, WordType type) async =>
        Dictionary.fromPath("$path/$name", type);

    var noun = await getDictionary("noun", WordType.noun);
    var verb = await getDictionary("verb", WordType.verb);
    var adjective = await getDictionary("adjective", WordType.adjective);
    var adverb = await getDictionary("adverb", WordType.adverb);

    return Repository._(noun, verb, adjective, adverb);
  }
}
