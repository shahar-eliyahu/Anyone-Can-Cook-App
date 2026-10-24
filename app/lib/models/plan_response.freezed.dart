// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanResponse {

 CookingPlan get plan; List<String> get warningsHe; List<String> get limitationsHe; List<ReferenceSource> get sources;
/// Create a copy of PlanResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanResponseCopyWith<PlanResponse> get copyWith => _$PlanResponseCopyWithImpl<PlanResponse>(this as PlanResponse, _$identity);

  /// Serializes this PlanResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanResponse&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&const DeepCollectionEquality().equals(other.warningsHe, _this.warningsHe)&&const DeepCollectionEquality().equals(other.limitationsHe, _this.limitationsHe)&&const DeepCollectionEquality().equals(other.sources, _this.sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanResponse;
  return Object.hash(runtimeType,_this.plan,const DeepCollectionEquality().hash(_this.warningsHe),const DeepCollectionEquality().hash(_this.limitationsHe),const DeepCollectionEquality().hash(_this.sources));
}

@override
String toString() {
  final _this = this as PlanResponse;
  return 'PlanResponse(plan: ${_this.plan}, warningsHe: ${_this.warningsHe}, limitationsHe: ${_this.limitationsHe}, sources: ${_this.sources})';
}


}

/// @nodoc
abstract mixin class $PlanResponseCopyWith<$Res>  {
  factory $PlanResponseCopyWith(PlanResponse value, $Res Function(PlanResponse) _then) = _$PlanResponseCopyWithImpl;
@useResult
$Res call({
 CookingPlan plan, List<String> warningsHe, List<String> limitationsHe, List<ReferenceSource> sources
});


$CookingPlanCopyWith<$Res> get plan;

}
/// @nodoc
class _$PlanResponseCopyWithImpl<$Res>
    implements $PlanResponseCopyWith<$Res> {
  _$PlanResponseCopyWithImpl(this._self, this._then);

  final PlanResponse _self;
  final $Res Function(PlanResponse) _then;

/// Create a copy of PlanResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? warningsHe = null,Object? limitationsHe = null,Object? sources = null,}) {
  return _then(PlanResponse(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as CookingPlan,warningsHe: null == warningsHe ? _self.warningsHe : warningsHe // ignore: cast_nullable_to_non_nullable
as List<String>,limitationsHe: null == limitationsHe ? _self.limitationsHe : limitationsHe // ignore: cast_nullable_to_non_nullable
as List<String>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<ReferenceSource>,
  ));
}
/// Create a copy of PlanResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CookingPlanCopyWith<$Res> get plan {
  
  return $CookingPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanResponse].
extension PlanResponsePatterns on PlanResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanResponse value)  $default,){
final _that = this;
switch (_that) {
case _PlanResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PlanResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CookingPlan plan,  List<String> warningsHe,  List<String> limitationsHe,  List<ReferenceSource> sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanResponse() when $default != null:
return $default(_that.plan,_that.warningsHe,_that.limitationsHe,_that.sources);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CookingPlan plan,  List<String> warningsHe,  List<String> limitationsHe,  List<ReferenceSource> sources)  $default,) {final _that = this;
switch (_that) {
case _PlanResponse():
return $default(_that.plan,_that.warningsHe,_that.limitationsHe,_that.sources);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CookingPlan plan,  List<String> warningsHe,  List<String> limitationsHe,  List<ReferenceSource> sources)?  $default,) {final _that = this;
switch (_that) {
case _PlanResponse() when $default != null:
return $default(_that.plan,_that.warningsHe,_that.limitationsHe,_that.sources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanResponse implements PlanResponse {
  const _PlanResponse({required this.plan,  List<String> warningsHe = const [],  List<String> limitationsHe = const [],  List<ReferenceSource> sources = const []}): _warningsHe = warningsHe,_limitationsHe = limitationsHe,_sources = sources;
  factory _PlanResponse.fromJson(Map<String, dynamic> json) => _$PlanResponseFromJson(json);

@override final  CookingPlan plan;
 final  List<String> _warningsHe;
@override@JsonKey() List<String> get warningsHe {
  if (_warningsHe is EqualUnmodifiableListView) return _warningsHe;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warningsHe);
}

 final  List<String> _limitationsHe;
@override@JsonKey() List<String> get limitationsHe {
  if (_limitationsHe is EqualUnmodifiableListView) return _limitationsHe;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_limitationsHe);
}

 final  List<ReferenceSource> _sources;
@override@JsonKey() List<ReferenceSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of PlanResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanResponseCopyWith<_PlanResponse> get copyWith => __$PlanResponseCopyWithImpl<_PlanResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanResponse&&(identical(other.plan, plan) || other.plan == plan)&&const DeepCollectionEquality().equals(other.warningsHe, _warningsHe)&&const DeepCollectionEquality().equals(other.limitationsHe, _limitationsHe)&&const DeepCollectionEquality().equals(other.sources, _sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,plan,const DeepCollectionEquality().hash(_warningsHe),const DeepCollectionEquality().hash(_limitationsHe),const DeepCollectionEquality().hash(_sources));
}

@override
String toString() {
    return 'PlanResponse(plan: $plan, warningsHe: $warningsHe, limitationsHe: $limitationsHe, sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$PlanResponseCopyWith<$Res> implements $PlanResponseCopyWith<$Res> {
  factory _$PlanResponseCopyWith(_PlanResponse value, $Res Function(_PlanResponse) _then) = __$PlanResponseCopyWithImpl;
@override @useResult
$Res call({
 CookingPlan plan, List<String> warningsHe, List<String> limitationsHe, List<ReferenceSource> sources
});


@override $CookingPlanCopyWith<$Res> get plan;

}
/// @nodoc
class __$PlanResponseCopyWithImpl<$Res>
    implements _$PlanResponseCopyWith<$Res> {
  __$PlanResponseCopyWithImpl(this._self, this._then);

  final _PlanResponse _self;
  final $Res Function(_PlanResponse) _then;

/// Create a copy of PlanResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? warningsHe = null,Object? limitationsHe = null,Object? sources = null,}) {
  return _then(_PlanResponse(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as CookingPlan,warningsHe: null == warningsHe ? _self._warningsHe : warningsHe // ignore: cast_nullable_to_non_nullable
as List<String>,limitationsHe: null == limitationsHe ? _self._limitationsHe : limitationsHe // ignore: cast_nullable_to_non_nullable
as List<String>,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<ReferenceSource>,
  ));
}

/// Create a copy of PlanResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CookingPlanCopyWith<$Res> get plan {
  
  return $CookingPlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}

// dart format on
