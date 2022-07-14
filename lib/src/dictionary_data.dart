
import 'package:wordnet_dictionary/src/types.dart';

class Reference {
  final int index;
  final WordType type;

  Reference(this.index, this.type);

  @override
  String toString() {
    return "Reference { $index, $type }";
  }
}

class Relation {
  final PartialUnwrappedData relation;
  final RelationType relationType;
  final WordType wordType;

  Relation(this.relation, this.wordType, this.relationType);

  @override
  String toString() {
    return "Relation { $relation $relationType $wordType }";
  }
}




class PartialUnwrappedData {
  final List<String> words;
  final int index;

  PartialUnwrappedData(this.words, this.index);

  @override
  String toString() {
    return "PartialUnwrappedData { $words $index }";
  }
}

class UnwrappedData {
  final List<String> words;
  final List<Relation> relations;
  final String definition;
  final List<UseCase> useCases;
  final WordType wType;
  UnwrappedData(
      this.words, this.relations, this.definition, this.useCases, this.wType);

  @override
  String toString() {
    return "UnwrappedData { $words $relations $definition $useCases }";
  }
}


class UseCase {
  final int id;
  final int wordInd;

  UseCase(this.id, this.wordInd);
}