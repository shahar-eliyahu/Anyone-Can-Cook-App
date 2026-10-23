import 'package:json_annotation/json_annotation.dart';

/// Where a value came from. AI estimates ([inferred]) are always labeled as such.
@JsonEnum(fieldRename: FieldRename.snake)
enum Provenance {
  original,
  inferred,
  answered,
  user;

  bool get isEstimate => this == Provenance.inferred;
}
