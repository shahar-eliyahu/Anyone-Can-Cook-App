import 'package:json_annotation/json_annotation.dart';

/// Where a value came from. AI estimates ([inferred]) are always labeled as
/// such; [reference] values come from the curated, cited food-safety table.
@JsonEnum(fieldRename: FieldRename.snake)
enum Provenance {
  original,
  inferred,
  answered,
  user,
  reference;

  bool get isEstimate => this == Provenance.inferred;
}

/// How sure an estimate is.
@JsonEnum(fieldRename: FieldRename.snake)
enum Confidence { high, medium, low }
