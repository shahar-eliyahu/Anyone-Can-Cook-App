import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe.dart';

part 'recipe_analysis.freezed.dart';
part 'recipe_analysis.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum SourceType { text, image, url, sample }

@JsonEnum(fieldRename: FieldRename.snake)
enum GapCategory { safety, outcome, equipment, preference, minor }

@JsonEnum(fieldRename: FieldRename.snake)
enum GapResolution { context, reference, estimate, question, unresolved }

@JsonEnum(fieldRename: FieldRename.snake)
enum QuestionKind { choice, number, text }

@JsonEnum(fieldRename: FieldRename.snake)
enum ReferenceKind { foodSafetyReference, recipeSource }

@freezed
abstract class RecipeSourceInfo with _$RecipeSourceInfo {
  const factory RecipeSourceInfo({
    required SourceType type,
    String? url,
    String? siteName,
    String? title,
    String? retrievedAt,
  }) = _RecipeSourceInfo;

  factory RecipeSourceInfo.fromJson(Map<String, dynamic> json) =>
      _$RecipeSourceInfoFromJson(json);
}

@freezed
abstract class ReferenceSource with _$ReferenceSource {
  const factory ReferenceSource({
    required String id,
    required String title,
    String? url,
    required ReferenceKind kind,
  }) = _ReferenceSource;

  factory ReferenceSource.fromJson(Map<String, dynamic> json) =>
      _$ReferenceSourceFromJson(json);
}

@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required String textHe,
    required String whyHe,
    required QuestionKind kind,
    @Default([]) List<String> options,
    String? unitHe,
    required GapCategory category,
    @Default(false) bool required,
    @Default([]) List<String> affects,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

@freezed
abstract class Answer with _$Answer {
  const factory Answer({
    required String questionId,
    String? value,
    @Default(false) bool unknown,
  }) = _Answer;

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
}

@freezed
abstract class Gap with _$Gap {
  const factory Gap({
    required String id,
    required String field,
    required GapCategory category,
    required GapResolution resolution,
    String? questionId,
    String? noteHe,
  }) = _Gap;

  factory Gap.fromJson(Map<String, dynamic> json) => _$GapFromJson(json);
}

/// Result of analyzing an imported recipe (mirrors backend `RecipeAnalysis`).
@freezed
abstract class RecipeAnalysis with _$RecipeAnalysis {
  const factory RecipeAnalysis({
    @Default(1) int schemaVersion,
    required bool isRecipe,
    String? notRecipeReasonHe,
    required RecipeSourceInfo source,
    @Default('') String sourceText,
    Recipe? recipe,
    @Default([]) List<Question> questions,
    @Default([]) List<Answer> answers,
    @Default([]) List<Gap> gaps,
    @Default([]) List<ReferenceSource> sources,
    @Default([]) List<String> assumptionsHe,
  }) = _RecipeAnalysis;

  factory RecipeAnalysis.fromJson(Map<String, dynamic> json) =>
      _$RecipeAnalysisFromJson(json);
}
