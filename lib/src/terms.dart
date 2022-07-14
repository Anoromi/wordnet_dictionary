
import 'package:wordnet_dictionary/src/dictionary_data.dart';

class FullTerm {
  final String term;
  final List<UnwrappedData> data;
  FullTerm(this.term, this.data);
}

class PartialTerm {
  final String term;
  final List<Reference> references;

  PartialTerm(this.term, this.references);

  PartialTerm combine(PartialTerm other) {
    assert(term == other.term);
    return PartialTerm(
        term, [for (var v in references) v, for (var v in other.references) v]);
  }

  @override
  String toString() {
    return "PartialTerm { $term, $references }";
  }
}