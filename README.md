<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# wordnet_dictionary

**Author: Andrii Zahorulko**

A dictionary built on wordnet database.

```dart
var repository = await Repository.fromPath("path_to_wordnet_data");

List<PartialTerm> suggestions = await repository.findTerms("a", 10).simple().worker; // finds 10 terms (or less) that start with a

// PartialTerm holds the name of a term, and references to part of speech and index in the database.
// Useful to get suggestions for the user.

FullTerm = await repository.unwrapTerm(terms[0]); // full term holds names of word collections that it references (synonyms, antonyms, etc)
```

Data needed for the database is located in directory **./data**.

## Links

[WordNet](https://wordnet.princeton.edu/)
