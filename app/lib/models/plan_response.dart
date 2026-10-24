import 'package:freezed_annotation/freezed_annotation.dart';

import 'cooking_plan.dart';
import 'recipe_analysis.dart';

part 'plan_response.freezed.dart';
part 'plan_response.g.dart';

/// Response of POST /v1/recipes/plan (mirrors backend `PlanResponse`).
@freezed
abstract class PlanResponse with _$PlanResponse {
  const factory PlanResponse({
    required CookingPlan plan,
    @Default([]) List<String> warningsHe,
    @Default([]) List<String> limitationsHe,
    @Default([]) List<ReferenceSource> sources,
  }) = _PlanResponse;

  factory PlanResponse.fromJson(Map<String, dynamic> json) =>
      _$PlanResponseFromJson(json);
}
