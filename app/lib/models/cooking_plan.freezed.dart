// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cooking_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanTimer {

 String get id; String get labelHe; int get seconds; Provenance get provenance; String? get noteHe;
/// Create a copy of PlanTimer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTimerCopyWith<PlanTimer> get copyWith => _$PlanTimerCopyWithImpl<PlanTimer>(this as PlanTimer, _$identity);

  /// Serializes this PlanTimer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanTimer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTimer&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.labelHe, _this.labelHe) || other.labelHe == _this.labelHe)&&(identical(other.seconds, _this.seconds) || other.seconds == _this.seconds)&&(identical(other.provenance, _this.provenance) || other.provenance == _this.provenance)&&(identical(other.noteHe, _this.noteHe) || other.noteHe == _this.noteHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanTimer;
  return Object.hash(runtimeType,_this.id,_this.labelHe,_this.seconds,_this.provenance,_this.noteHe);
}

@override
String toString() {
  final _this = this as PlanTimer;
  return 'PlanTimer(id: ${_this.id}, labelHe: ${_this.labelHe}, seconds: ${_this.seconds}, provenance: ${_this.provenance}, noteHe: ${_this.noteHe})';
}


}

/// @nodoc
abstract mixin class $PlanTimerCopyWith<$Res>  {
  factory $PlanTimerCopyWith(PlanTimer value, $Res Function(PlanTimer) _then) = _$PlanTimerCopyWithImpl;
@useResult
$Res call({
 String id, String labelHe, int seconds, Provenance provenance, String? noteHe
});




}
/// @nodoc
class _$PlanTimerCopyWithImpl<$Res>
    implements $PlanTimerCopyWith<$Res> {
  _$PlanTimerCopyWithImpl(this._self, this._then);

  final PlanTimer _self;
  final $Res Function(PlanTimer) _then;

/// Create a copy of PlanTimer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? labelHe = null,Object? seconds = null,Object? provenance = null,Object? noteHe = freezed,}) {
  return _then(PlanTimer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,labelHe: null == labelHe ? _self.labelHe : labelHe // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,noteHe: freezed == noteHe ? _self.noteHe : noteHe // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanTimer].
extension PlanTimerPatterns on PlanTimer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanTimer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanTimer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanTimer value)  $default,){
final _that = this;
switch (_that) {
case _PlanTimer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanTimer value)?  $default,){
final _that = this;
switch (_that) {
case _PlanTimer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String labelHe,  int seconds,  Provenance provenance,  String? noteHe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanTimer() when $default != null:
return $default(_that.id,_that.labelHe,_that.seconds,_that.provenance,_that.noteHe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String labelHe,  int seconds,  Provenance provenance,  String? noteHe)  $default,) {final _that = this;
switch (_that) {
case _PlanTimer():
return $default(_that.id,_that.labelHe,_that.seconds,_that.provenance,_that.noteHe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String labelHe,  int seconds,  Provenance provenance,  String? noteHe)?  $default,) {final _that = this;
switch (_that) {
case _PlanTimer() when $default != null:
return $default(_that.id,_that.labelHe,_that.seconds,_that.provenance,_that.noteHe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanTimer implements PlanTimer {
  const _PlanTimer({required this.id, required this.labelHe, required this.seconds, required this.provenance, this.noteHe});
  factory _PlanTimer.fromJson(Map<String, dynamic> json) => _$PlanTimerFromJson(json);

@override final  String id;
@override final  String labelHe;
@override final  int seconds;
@override final  Provenance provenance;
@override final  String? noteHe;

/// Create a copy of PlanTimer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanTimerCopyWith<_PlanTimer> get copyWith => __$PlanTimerCopyWithImpl<_PlanTimer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanTimerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanTimer&&(identical(other.id, id) || other.id == id)&&(identical(other.labelHe, labelHe) || other.labelHe == labelHe)&&(identical(other.seconds, seconds) || other.seconds == seconds)&&(identical(other.provenance, provenance) || other.provenance == provenance)&&(identical(other.noteHe, noteHe) || other.noteHe == noteHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,labelHe,seconds,provenance,noteHe);
}

@override
String toString() {
    return 'PlanTimer(id: $id, labelHe: $labelHe, seconds: $seconds, provenance: $provenance, noteHe: $noteHe)';
}


}

/// @nodoc
abstract mixin class _$PlanTimerCopyWith<$Res> implements $PlanTimerCopyWith<$Res> {
  factory _$PlanTimerCopyWith(_PlanTimer value, $Res Function(_PlanTimer) _then) = __$PlanTimerCopyWithImpl;
@override @useResult
$Res call({
 String id, String labelHe, int seconds, Provenance provenance, String? noteHe
});




}
/// @nodoc
class __$PlanTimerCopyWithImpl<$Res>
    implements _$PlanTimerCopyWith<$Res> {
  __$PlanTimerCopyWithImpl(this._self, this._then);

  final _PlanTimer _self;
  final $Res Function(_PlanTimer) _then;

/// Create a copy of PlanTimer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? labelHe = null,Object? seconds = null,Object? provenance = null,Object? noteHe = freezed,}) {
  return _then(_PlanTimer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,labelHe: null == labelHe ? _self.labelHe : labelHe // ignore: cast_nullable_to_non_nullable
as String,seconds: null == seconds ? _self.seconds : seconds // ignore: cast_nullable_to_non_nullable
as int,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,noteHe: freezed == noteHe ? _self.noteHe : noteHe // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$StepAction {

 String get id; ActionType get type; String get labelHe; String? get startsTimer; bool get completesStep; ConfirmPolicy get confirmPolicy;
/// Create a copy of StepAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepActionCopyWith<StepAction> get copyWith => _$StepActionCopyWithImpl<StepAction>(this as StepAction, _$identity);

  /// Serializes this StepAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StepAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepAction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.labelHe, _this.labelHe) || other.labelHe == _this.labelHe)&&(identical(other.startsTimer, _this.startsTimer) || other.startsTimer == _this.startsTimer)&&(identical(other.completesStep, _this.completesStep) || other.completesStep == _this.completesStep)&&(identical(other.confirmPolicy, _this.confirmPolicy) || other.confirmPolicy == _this.confirmPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StepAction;
  return Object.hash(runtimeType,_this.id,_this.type,_this.labelHe,_this.startsTimer,_this.completesStep,_this.confirmPolicy);
}

@override
String toString() {
  final _this = this as StepAction;
  return 'StepAction(id: ${_this.id}, type: ${_this.type}, labelHe: ${_this.labelHe}, startsTimer: ${_this.startsTimer}, completesStep: ${_this.completesStep}, confirmPolicy: ${_this.confirmPolicy})';
}


}

/// @nodoc
abstract mixin class $StepActionCopyWith<$Res>  {
  factory $StepActionCopyWith(StepAction value, $Res Function(StepAction) _then) = _$StepActionCopyWithImpl;
@useResult
$Res call({
 String id, ActionType type, String labelHe, String? startsTimer, bool completesStep, ConfirmPolicy confirmPolicy
});




}
/// @nodoc
class _$StepActionCopyWithImpl<$Res>
    implements $StepActionCopyWith<$Res> {
  _$StepActionCopyWithImpl(this._self, this._then);

  final StepAction _self;
  final $Res Function(StepAction) _then;

/// Create a copy of StepAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? labelHe = null,Object? startsTimer = freezed,Object? completesStep = null,Object? confirmPolicy = null,}) {
  return _then(StepAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ActionType,labelHe: null == labelHe ? _self.labelHe : labelHe // ignore: cast_nullable_to_non_nullable
as String,startsTimer: freezed == startsTimer ? _self.startsTimer : startsTimer // ignore: cast_nullable_to_non_nullable
as String?,completesStep: null == completesStep ? _self.completesStep : completesStep // ignore: cast_nullable_to_non_nullable
as bool,confirmPolicy: null == confirmPolicy ? _self.confirmPolicy : confirmPolicy // ignore: cast_nullable_to_non_nullable
as ConfirmPolicy,
  ));
}

}


/// Adds pattern-matching-related methods to [StepAction].
extension StepActionPatterns on StepAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StepAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StepAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StepAction value)  $default,){
final _that = this;
switch (_that) {
case _StepAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StepAction value)?  $default,){
final _that = this;
switch (_that) {
case _StepAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ActionType type,  String labelHe,  String? startsTimer,  bool completesStep,  ConfirmPolicy confirmPolicy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StepAction() when $default != null:
return $default(_that.id,_that.type,_that.labelHe,_that.startsTimer,_that.completesStep,_that.confirmPolicy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ActionType type,  String labelHe,  String? startsTimer,  bool completesStep,  ConfirmPolicy confirmPolicy)  $default,) {final _that = this;
switch (_that) {
case _StepAction():
return $default(_that.id,_that.type,_that.labelHe,_that.startsTimer,_that.completesStep,_that.confirmPolicy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ActionType type,  String labelHe,  String? startsTimer,  bool completesStep,  ConfirmPolicy confirmPolicy)?  $default,) {final _that = this;
switch (_that) {
case _StepAction() when $default != null:
return $default(_that.id,_that.type,_that.labelHe,_that.startsTimer,_that.completesStep,_that.confirmPolicy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StepAction implements StepAction {
  const _StepAction({required this.id, required this.type, required this.labelHe, this.startsTimer, this.completesStep = false, this.confirmPolicy = ConfirmPolicy.autoOk});
  factory _StepAction.fromJson(Map<String, dynamic> json) => _$StepActionFromJson(json);

@override final  String id;
@override final  ActionType type;
@override final  String labelHe;
@override final  String? startsTimer;
@override@JsonKey() final  bool completesStep;
@override@JsonKey() final  ConfirmPolicy confirmPolicy;

/// Create a copy of StepAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StepActionCopyWith<_StepAction> get copyWith => __$StepActionCopyWithImpl<_StepAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StepActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StepAction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.labelHe, labelHe) || other.labelHe == labelHe)&&(identical(other.startsTimer, startsTimer) || other.startsTimer == startsTimer)&&(identical(other.completesStep, completesStep) || other.completesStep == completesStep)&&(identical(other.confirmPolicy, confirmPolicy) || other.confirmPolicy == confirmPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,labelHe,startsTimer,completesStep,confirmPolicy);
}

@override
String toString() {
    return 'StepAction(id: $id, type: $type, labelHe: $labelHe, startsTimer: $startsTimer, completesStep: $completesStep, confirmPolicy: $confirmPolicy)';
}


}

/// @nodoc
abstract mixin class _$StepActionCopyWith<$Res> implements $StepActionCopyWith<$Res> {
  factory _$StepActionCopyWith(_StepAction value, $Res Function(_StepAction) _then) = __$StepActionCopyWithImpl;
@override @useResult
$Res call({
 String id, ActionType type, String labelHe, String? startsTimer, bool completesStep, ConfirmPolicy confirmPolicy
});




}
/// @nodoc
class __$StepActionCopyWithImpl<$Res>
    implements _$StepActionCopyWith<$Res> {
  __$StepActionCopyWithImpl(this._self, this._then);

  final _StepAction _self;
  final $Res Function(_StepAction) _then;

/// Create a copy of StepAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? labelHe = null,Object? startsTimer = freezed,Object? completesStep = null,Object? confirmPolicy = null,}) {
  return _then(_StepAction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ActionType,labelHe: null == labelHe ? _self.labelHe : labelHe // ignore: cast_nullable_to_non_nullable
as String,startsTimer: freezed == startsTimer ? _self.startsTimer : startsTimer // ignore: cast_nullable_to_non_nullable
as String?,completesStep: null == completesStep ? _self.completesStep : completesStep // ignore: cast_nullable_to_non_nullable
as bool,confirmPolicy: null == confirmPolicy ? _self.confirmPolicy : confirmPolicy // ignore: cast_nullable_to_non_nullable
as ConfirmPolicy,
  ));
}


}


/// @nodoc
mixin _$Temperature {

 int get value; TemperatureUnit get unit; Provenance get provenance;
/// Create a copy of Temperature
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemperatureCopyWith<Temperature> get copyWith => _$TemperatureCopyWithImpl<Temperature>(this as Temperature, _$identity);

  /// Serializes this Temperature to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Temperature;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Temperature&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unit, _this.unit) || other.unit == _this.unit)&&(identical(other.provenance, _this.provenance) || other.provenance == _this.provenance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Temperature;
  return Object.hash(runtimeType,_this.value,_this.unit,_this.provenance);
}

@override
String toString() {
  final _this = this as Temperature;
  return 'Temperature(value: ${_this.value}, unit: ${_this.unit}, provenance: ${_this.provenance})';
}


}

/// @nodoc
abstract mixin class $TemperatureCopyWith<$Res>  {
  factory $TemperatureCopyWith(Temperature value, $Res Function(Temperature) _then) = _$TemperatureCopyWithImpl;
@useResult
$Res call({
 int value, TemperatureUnit unit, Provenance provenance
});




}
/// @nodoc
class _$TemperatureCopyWithImpl<$Res>
    implements $TemperatureCopyWith<$Res> {
  _$TemperatureCopyWithImpl(this._self, this._then);

  final Temperature _self;
  final $Res Function(Temperature) _then;

/// Create a copy of Temperature
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? unit = null,Object? provenance = null,}) {
  return _then(Temperature(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as TemperatureUnit,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,
  ));
}

}


/// Adds pattern-matching-related methods to [Temperature].
extension TemperaturePatterns on Temperature {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Temperature value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Temperature() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Temperature value)  $default,){
final _that = this;
switch (_that) {
case _Temperature():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Temperature value)?  $default,){
final _that = this;
switch (_that) {
case _Temperature() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value,  TemperatureUnit unit,  Provenance provenance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Temperature() when $default != null:
return $default(_that.value,_that.unit,_that.provenance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value,  TemperatureUnit unit,  Provenance provenance)  $default,) {final _that = this;
switch (_that) {
case _Temperature():
return $default(_that.value,_that.unit,_that.provenance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value,  TemperatureUnit unit,  Provenance provenance)?  $default,) {final _that = this;
switch (_that) {
case _Temperature() when $default != null:
return $default(_that.value,_that.unit,_that.provenance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Temperature implements Temperature {
  const _Temperature({required this.value, this.unit = TemperatureUnit.celsius, required this.provenance});
  factory _Temperature.fromJson(Map<String, dynamic> json) => _$TemperatureFromJson(json);

@override final  int value;
@override@JsonKey() final  TemperatureUnit unit;
@override final  Provenance provenance;

/// Create a copy of Temperature
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemperatureCopyWith<_Temperature> get copyWith => __$TemperatureCopyWithImpl<_Temperature>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemperatureToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Temperature&&(identical(other.value, value) || other.value == value)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.provenance, provenance) || other.provenance == provenance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,unit,provenance);
}

@override
String toString() {
    return 'Temperature(value: $value, unit: $unit, provenance: $provenance)';
}


}

/// @nodoc
abstract mixin class _$TemperatureCopyWith<$Res> implements $TemperatureCopyWith<$Res> {
  factory _$TemperatureCopyWith(_Temperature value, $Res Function(_Temperature) _then) = __$TemperatureCopyWithImpl;
@override @useResult
$Res call({
 int value, TemperatureUnit unit, Provenance provenance
});




}
/// @nodoc
class __$TemperatureCopyWithImpl<$Res>
    implements _$TemperatureCopyWith<$Res> {
  __$TemperatureCopyWithImpl(this._self, this._then);

  final _Temperature _self;
  final $Res Function(_Temperature) _then;

/// Create a copy of Temperature
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? unit = null,Object? provenance = null,}) {
  return _then(_Temperature(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as TemperatureUnit,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,
  ));
}


}


/// @nodoc
mixin _$Minutes {

 int get value; Provenance get provenance; String? get noteHe;
/// Create a copy of Minutes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MinutesCopyWith<Minutes> get copyWith => _$MinutesCopyWithImpl<Minutes>(this as Minutes, _$identity);

  /// Serializes this Minutes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Minutes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Minutes&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.provenance, _this.provenance) || other.provenance == _this.provenance)&&(identical(other.noteHe, _this.noteHe) || other.noteHe == _this.noteHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Minutes;
  return Object.hash(runtimeType,_this.value,_this.provenance,_this.noteHe);
}

@override
String toString() {
  final _this = this as Minutes;
  return 'Minutes(value: ${_this.value}, provenance: ${_this.provenance}, noteHe: ${_this.noteHe})';
}


}

/// @nodoc
abstract mixin class $MinutesCopyWith<$Res>  {
  factory $MinutesCopyWith(Minutes value, $Res Function(Minutes) _then) = _$MinutesCopyWithImpl;
@useResult
$Res call({
 int value, Provenance provenance, String? noteHe
});




}
/// @nodoc
class _$MinutesCopyWithImpl<$Res>
    implements $MinutesCopyWith<$Res> {
  _$MinutesCopyWithImpl(this._self, this._then);

  final Minutes _self;
  final $Res Function(Minutes) _then;

/// Create a copy of Minutes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? provenance = null,Object? noteHe = freezed,}) {
  return _then(Minutes(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,noteHe: freezed == noteHe ? _self.noteHe : noteHe // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Minutes].
extension MinutesPatterns on Minutes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Minutes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Minutes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Minutes value)  $default,){
final _that = this;
switch (_that) {
case _Minutes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Minutes value)?  $default,){
final _that = this;
switch (_that) {
case _Minutes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value,  Provenance provenance,  String? noteHe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Minutes() when $default != null:
return $default(_that.value,_that.provenance,_that.noteHe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value,  Provenance provenance,  String? noteHe)  $default,) {final _that = this;
switch (_that) {
case _Minutes():
return $default(_that.value,_that.provenance,_that.noteHe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value,  Provenance provenance,  String? noteHe)?  $default,) {final _that = this;
switch (_that) {
case _Minutes() when $default != null:
return $default(_that.value,_that.provenance,_that.noteHe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Minutes implements Minutes {
  const _Minutes({required this.value, required this.provenance, this.noteHe});
  factory _Minutes.fromJson(Map<String, dynamic> json) => _$MinutesFromJson(json);

@override final  int value;
@override final  Provenance provenance;
@override final  String? noteHe;

/// Create a copy of Minutes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MinutesCopyWith<_Minutes> get copyWith => __$MinutesCopyWithImpl<_Minutes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MinutesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Minutes&&(identical(other.value, value) || other.value == value)&&(identical(other.provenance, provenance) || other.provenance == provenance)&&(identical(other.noteHe, noteHe) || other.noteHe == noteHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,value,provenance,noteHe);
}

@override
String toString() {
    return 'Minutes(value: $value, provenance: $provenance, noteHe: $noteHe)';
}


}

/// @nodoc
abstract mixin class _$MinutesCopyWith<$Res> implements $MinutesCopyWith<$Res> {
  factory _$MinutesCopyWith(_Minutes value, $Res Function(_Minutes) _then) = __$MinutesCopyWithImpl;
@override @useResult
$Res call({
 int value, Provenance provenance, String? noteHe
});




}
/// @nodoc
class __$MinutesCopyWithImpl<$Res>
    implements _$MinutesCopyWith<$Res> {
  __$MinutesCopyWithImpl(this._self, this._then);

  final _Minutes _self;
  final $Res Function(_Minutes) _then;

/// Create a copy of Minutes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? provenance = null,Object? noteHe = freezed,}) {
  return _then(_Minutes(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,noteHe: freezed == noteHe ? _self.noteHe : noteHe // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PlanStep {

 String get id; String get title; String get instructionHe; List<String> get sourceRefs; List<String> get ingredientIds; List<String> get equipmentIds; List<String> get dependsOn; StepKind get kind; bool get parallelOk; List<StepAction> get actions; List<PlanTimer> get timers; Temperature? get temperature; String? get donenessCueHe; List<String> get warningsHe;
/// Create a copy of PlanStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanStepCopyWith<PlanStep> get copyWith => _$PlanStepCopyWithImpl<PlanStep>(this as PlanStep, _$identity);

  /// Serializes this PlanStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanStep;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanStep&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.instructionHe, _this.instructionHe) || other.instructionHe == _this.instructionHe)&&const DeepCollectionEquality().equals(other.sourceRefs, _this.sourceRefs)&&const DeepCollectionEquality().equals(other.ingredientIds, _this.ingredientIds)&&const DeepCollectionEquality().equals(other.equipmentIds, _this.equipmentIds)&&const DeepCollectionEquality().equals(other.dependsOn, _this.dependsOn)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.parallelOk, _this.parallelOk) || other.parallelOk == _this.parallelOk)&&const DeepCollectionEquality().equals(other.actions, _this.actions)&&const DeepCollectionEquality().equals(other.timers, _this.timers)&&(identical(other.temperature, _this.temperature) || other.temperature == _this.temperature)&&(identical(other.donenessCueHe, _this.donenessCueHe) || other.donenessCueHe == _this.donenessCueHe)&&const DeepCollectionEquality().equals(other.warningsHe, _this.warningsHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanStep;
  return Object.hash(runtimeType,_this.id,_this.title,_this.instructionHe,const DeepCollectionEquality().hash(_this.sourceRefs),const DeepCollectionEquality().hash(_this.ingredientIds),const DeepCollectionEquality().hash(_this.equipmentIds),const DeepCollectionEquality().hash(_this.dependsOn),_this.kind,_this.parallelOk,const DeepCollectionEquality().hash(_this.actions),const DeepCollectionEquality().hash(_this.timers),_this.temperature,_this.donenessCueHe,const DeepCollectionEquality().hash(_this.warningsHe));
}

@override
String toString() {
  final _this = this as PlanStep;
  return 'PlanStep(id: ${_this.id}, title: ${_this.title}, instructionHe: ${_this.instructionHe}, sourceRefs: ${_this.sourceRefs}, ingredientIds: ${_this.ingredientIds}, equipmentIds: ${_this.equipmentIds}, dependsOn: ${_this.dependsOn}, kind: ${_this.kind}, parallelOk: ${_this.parallelOk}, actions: ${_this.actions}, timers: ${_this.timers}, temperature: ${_this.temperature}, donenessCueHe: ${_this.donenessCueHe}, warningsHe: ${_this.warningsHe})';
}


}

/// @nodoc
abstract mixin class $PlanStepCopyWith<$Res>  {
  factory $PlanStepCopyWith(PlanStep value, $Res Function(PlanStep) _then) = _$PlanStepCopyWithImpl;
@useResult
$Res call({
 String id, String title, String instructionHe, List<String> sourceRefs, List<String> ingredientIds, List<String> equipmentIds, List<String> dependsOn, StepKind kind, bool parallelOk, List<StepAction> actions, List<PlanTimer> timers, Temperature? temperature, String? donenessCueHe, List<String> warningsHe
});


$TemperatureCopyWith<$Res>? get temperature;

}
/// @nodoc
class _$PlanStepCopyWithImpl<$Res>
    implements $PlanStepCopyWith<$Res> {
  _$PlanStepCopyWithImpl(this._self, this._then);

  final PlanStep _self;
  final $Res Function(PlanStep) _then;

/// Create a copy of PlanStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? instructionHe = null,Object? sourceRefs = null,Object? ingredientIds = null,Object? equipmentIds = null,Object? dependsOn = null,Object? kind = null,Object? parallelOk = null,Object? actions = null,Object? timers = null,Object? temperature = freezed,Object? donenessCueHe = freezed,Object? warningsHe = null,}) {
  return _then(PlanStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructionHe: null == instructionHe ? _self.instructionHe : instructionHe // ignore: cast_nullable_to_non_nullable
as String,sourceRefs: null == sourceRefs ? _self.sourceRefs : sourceRefs // ignore: cast_nullable_to_non_nullable
as List<String>,ingredientIds: null == ingredientIds ? _self.ingredientIds : ingredientIds // ignore: cast_nullable_to_non_nullable
as List<String>,equipmentIds: null == equipmentIds ? _self.equipmentIds : equipmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,dependsOn: null == dependsOn ? _self.dependsOn : dependsOn // ignore: cast_nullable_to_non_nullable
as List<String>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as StepKind,parallelOk: null == parallelOk ? _self.parallelOk : parallelOk // ignore: cast_nullable_to_non_nullable
as bool,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<StepAction>,timers: null == timers ? _self.timers : timers // ignore: cast_nullable_to_non_nullable
as List<PlanTimer>,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as Temperature?,donenessCueHe: freezed == donenessCueHe ? _self.donenessCueHe : donenessCueHe // ignore: cast_nullable_to_non_nullable
as String?,warningsHe: null == warningsHe ? _self.warningsHe : warningsHe // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of PlanStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TemperatureCopyWith<$Res>? get temperature {
    if (_self.temperature == null) {
    return null;
  }

  return $TemperatureCopyWith<$Res>(_self.temperature!, (value) {
    return _then(_self.copyWith(temperature: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlanStep].
extension PlanStepPatterns on PlanStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanStep value)  $default,){
final _that = this;
switch (_that) {
case _PlanStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanStep value)?  $default,){
final _that = this;
switch (_that) {
case _PlanStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String instructionHe,  List<String> sourceRefs,  List<String> ingredientIds,  List<String> equipmentIds,  List<String> dependsOn,  StepKind kind,  bool parallelOk,  List<StepAction> actions,  List<PlanTimer> timers,  Temperature? temperature,  String? donenessCueHe,  List<String> warningsHe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanStep() when $default != null:
return $default(_that.id,_that.title,_that.instructionHe,_that.sourceRefs,_that.ingredientIds,_that.equipmentIds,_that.dependsOn,_that.kind,_that.parallelOk,_that.actions,_that.timers,_that.temperature,_that.donenessCueHe,_that.warningsHe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String instructionHe,  List<String> sourceRefs,  List<String> ingredientIds,  List<String> equipmentIds,  List<String> dependsOn,  StepKind kind,  bool parallelOk,  List<StepAction> actions,  List<PlanTimer> timers,  Temperature? temperature,  String? donenessCueHe,  List<String> warningsHe)  $default,) {final _that = this;
switch (_that) {
case _PlanStep():
return $default(_that.id,_that.title,_that.instructionHe,_that.sourceRefs,_that.ingredientIds,_that.equipmentIds,_that.dependsOn,_that.kind,_that.parallelOk,_that.actions,_that.timers,_that.temperature,_that.donenessCueHe,_that.warningsHe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String instructionHe,  List<String> sourceRefs,  List<String> ingredientIds,  List<String> equipmentIds,  List<String> dependsOn,  StepKind kind,  bool parallelOk,  List<StepAction> actions,  List<PlanTimer> timers,  Temperature? temperature,  String? donenessCueHe,  List<String> warningsHe)?  $default,) {final _that = this;
switch (_that) {
case _PlanStep() when $default != null:
return $default(_that.id,_that.title,_that.instructionHe,_that.sourceRefs,_that.ingredientIds,_that.equipmentIds,_that.dependsOn,_that.kind,_that.parallelOk,_that.actions,_that.timers,_that.temperature,_that.donenessCueHe,_that.warningsHe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanStep extends PlanStep {
  const _PlanStep({required this.id, required this.title, required this.instructionHe,  List<String> sourceRefs = const [],  List<String> ingredientIds = const [],  List<String> equipmentIds = const [],  List<String> dependsOn = const [], this.kind = StepKind.active, this.parallelOk = false, required  List<StepAction> actions,  List<PlanTimer> timers = const [], this.temperature, this.donenessCueHe,  List<String> warningsHe = const []}): _sourceRefs = sourceRefs,_ingredientIds = ingredientIds,_equipmentIds = equipmentIds,_dependsOn = dependsOn,_actions = actions,_timers = timers,_warningsHe = warningsHe,super._();
  factory _PlanStep.fromJson(Map<String, dynamic> json) => _$PlanStepFromJson(json);

@override final  String id;
@override final  String title;
@override final  String instructionHe;
 final  List<String> _sourceRefs;
@override@JsonKey() List<String> get sourceRefs {
  if (_sourceRefs is EqualUnmodifiableListView) return _sourceRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceRefs);
}

 final  List<String> _ingredientIds;
@override@JsonKey() List<String> get ingredientIds {
  if (_ingredientIds is EqualUnmodifiableListView) return _ingredientIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ingredientIds);
}

 final  List<String> _equipmentIds;
@override@JsonKey() List<String> get equipmentIds {
  if (_equipmentIds is EqualUnmodifiableListView) return _equipmentIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_equipmentIds);
}

 final  List<String> _dependsOn;
@override@JsonKey() List<String> get dependsOn {
  if (_dependsOn is EqualUnmodifiableListView) return _dependsOn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dependsOn);
}

@override@JsonKey() final  StepKind kind;
@override@JsonKey() final  bool parallelOk;
 final  List<StepAction> _actions;
@override List<StepAction> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}

 final  List<PlanTimer> _timers;
@override@JsonKey() List<PlanTimer> get timers {
  if (_timers is EqualUnmodifiableListView) return _timers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timers);
}

@override final  Temperature? temperature;
@override final  String? donenessCueHe;
 final  List<String> _warningsHe;
@override@JsonKey() List<String> get warningsHe {
  if (_warningsHe is EqualUnmodifiableListView) return _warningsHe;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warningsHe);
}


/// Create a copy of PlanStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanStepCopyWith<_PlanStep> get copyWith => __$PlanStepCopyWithImpl<_PlanStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanStepToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanStep&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.instructionHe, instructionHe) || other.instructionHe == instructionHe)&&const DeepCollectionEquality().equals(other.sourceRefs, _sourceRefs)&&const DeepCollectionEquality().equals(other.ingredientIds, _ingredientIds)&&const DeepCollectionEquality().equals(other.equipmentIds, _equipmentIds)&&const DeepCollectionEquality().equals(other.dependsOn, _dependsOn)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.parallelOk, parallelOk) || other.parallelOk == parallelOk)&&const DeepCollectionEquality().equals(other.actions, _actions)&&const DeepCollectionEquality().equals(other.timers, _timers)&&(identical(other.temperature, temperature) || other.temperature == temperature)&&(identical(other.donenessCueHe, donenessCueHe) || other.donenessCueHe == donenessCueHe)&&const DeepCollectionEquality().equals(other.warningsHe, _warningsHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,instructionHe,const DeepCollectionEquality().hash(_sourceRefs),const DeepCollectionEquality().hash(_ingredientIds),const DeepCollectionEquality().hash(_equipmentIds),const DeepCollectionEquality().hash(_dependsOn),kind,parallelOk,const DeepCollectionEquality().hash(_actions),const DeepCollectionEquality().hash(_timers),temperature,donenessCueHe,const DeepCollectionEquality().hash(_warningsHe));
}

@override
String toString() {
    return 'PlanStep(id: $id, title: $title, instructionHe: $instructionHe, sourceRefs: $sourceRefs, ingredientIds: $ingredientIds, equipmentIds: $equipmentIds, dependsOn: $dependsOn, kind: $kind, parallelOk: $parallelOk, actions: $actions, timers: $timers, temperature: $temperature, donenessCueHe: $donenessCueHe, warningsHe: $warningsHe)';
}


}

/// @nodoc
abstract mixin class _$PlanStepCopyWith<$Res> implements $PlanStepCopyWith<$Res> {
  factory _$PlanStepCopyWith(_PlanStep value, $Res Function(_PlanStep) _then) = __$PlanStepCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String instructionHe, List<String> sourceRefs, List<String> ingredientIds, List<String> equipmentIds, List<String> dependsOn, StepKind kind, bool parallelOk, List<StepAction> actions, List<PlanTimer> timers, Temperature? temperature, String? donenessCueHe, List<String> warningsHe
});


@override $TemperatureCopyWith<$Res>? get temperature;

}
/// @nodoc
class __$PlanStepCopyWithImpl<$Res>
    implements _$PlanStepCopyWith<$Res> {
  __$PlanStepCopyWithImpl(this._self, this._then);

  final _PlanStep _self;
  final $Res Function(_PlanStep) _then;

/// Create a copy of PlanStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? instructionHe = null,Object? sourceRefs = null,Object? ingredientIds = null,Object? equipmentIds = null,Object? dependsOn = null,Object? kind = null,Object? parallelOk = null,Object? actions = null,Object? timers = null,Object? temperature = freezed,Object? donenessCueHe = freezed,Object? warningsHe = null,}) {
  return _then(_PlanStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,instructionHe: null == instructionHe ? _self.instructionHe : instructionHe // ignore: cast_nullable_to_non_nullable
as String,sourceRefs: null == sourceRefs ? _self._sourceRefs : sourceRefs // ignore: cast_nullable_to_non_nullable
as List<String>,ingredientIds: null == ingredientIds ? _self._ingredientIds : ingredientIds // ignore: cast_nullable_to_non_nullable
as List<String>,equipmentIds: null == equipmentIds ? _self._equipmentIds : equipmentIds // ignore: cast_nullable_to_non_nullable
as List<String>,dependsOn: null == dependsOn ? _self._dependsOn : dependsOn // ignore: cast_nullable_to_non_nullable
as List<String>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as StepKind,parallelOk: null == parallelOk ? _self.parallelOk : parallelOk // ignore: cast_nullable_to_non_nullable
as bool,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<StepAction>,timers: null == timers ? _self._timers : timers // ignore: cast_nullable_to_non_nullable
as List<PlanTimer>,temperature: freezed == temperature ? _self.temperature : temperature // ignore: cast_nullable_to_non_nullable
as Temperature?,donenessCueHe: freezed == donenessCueHe ? _self.donenessCueHe : donenessCueHe // ignore: cast_nullable_to_non_nullable
as String?,warningsHe: null == warningsHe ? _self._warningsHe : warningsHe // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of PlanStep
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TemperatureCopyWith<$Res>? get temperature {
    if (_self.temperature == null) {
    return null;
  }

  return $TemperatureCopyWith<$Res>(_self.temperature!, (value) {
    return _then(_self.copyWith(temperature: value));
  });
}
}


/// @nodoc
mixin _$PrepSurface {

 String? get withStep; bool get atStart;
/// Create a copy of PrepSurface
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrepSurfaceCopyWith<PrepSurface> get copyWith => _$PrepSurfaceCopyWithImpl<PrepSurface>(this as PrepSurface, _$identity);

  /// Serializes this PrepSurface to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PrepSurface;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrepSurface&&(identical(other.withStep, _this.withStep) || other.withStep == _this.withStep)&&(identical(other.atStart, _this.atStart) || other.atStart == _this.atStart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PrepSurface;
  return Object.hash(runtimeType,_this.withStep,_this.atStart);
}

@override
String toString() {
  final _this = this as PrepSurface;
  return 'PrepSurface(withStep: ${_this.withStep}, atStart: ${_this.atStart})';
}


}

/// @nodoc
abstract mixin class $PrepSurfaceCopyWith<$Res>  {
  factory $PrepSurfaceCopyWith(PrepSurface value, $Res Function(PrepSurface) _then) = _$PrepSurfaceCopyWithImpl;
@useResult
$Res call({
 String? withStep, bool atStart
});




}
/// @nodoc
class _$PrepSurfaceCopyWithImpl<$Res>
    implements $PrepSurfaceCopyWith<$Res> {
  _$PrepSurfaceCopyWithImpl(this._self, this._then);

  final PrepSurface _self;
  final $Res Function(PrepSurface) _then;

/// Create a copy of PrepSurface
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? withStep = freezed,Object? atStart = null,}) {
  return _then(PrepSurface(
withStep: freezed == withStep ? _self.withStep : withStep // ignore: cast_nullable_to_non_nullable
as String?,atStart: null == atStart ? _self.atStart : atStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PrepSurface].
extension PrepSurfacePatterns on PrepSurface {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrepSurface value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrepSurface() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrepSurface value)  $default,){
final _that = this;
switch (_that) {
case _PrepSurface():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrepSurface value)?  $default,){
final _that = this;
switch (_that) {
case _PrepSurface() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? withStep,  bool atStart)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrepSurface() when $default != null:
return $default(_that.withStep,_that.atStart);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? withStep,  bool atStart)  $default,) {final _that = this;
switch (_that) {
case _PrepSurface():
return $default(_that.withStep,_that.atStart);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? withStep,  bool atStart)?  $default,) {final _that = this;
switch (_that) {
case _PrepSurface() when $default != null:
return $default(_that.withStep,_that.atStart);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrepSurface implements PrepSurface {
  const _PrepSurface({this.withStep, this.atStart = false});
  factory _PrepSurface.fromJson(Map<String, dynamic> json) => _$PrepSurfaceFromJson(json);

@override final  String? withStep;
@override@JsonKey() final  bool atStart;

/// Create a copy of PrepSurface
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrepSurfaceCopyWith<_PrepSurface> get copyWith => __$PrepSurfaceCopyWithImpl<_PrepSurface>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrepSurfaceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrepSurface&&(identical(other.withStep, withStep) || other.withStep == withStep)&&(identical(other.atStart, atStart) || other.atStart == atStart));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,withStep,atStart);
}

@override
String toString() {
    return 'PrepSurface(withStep: $withStep, atStart: $atStart)';
}


}

/// @nodoc
abstract mixin class _$PrepSurfaceCopyWith<$Res> implements $PrepSurfaceCopyWith<$Res> {
  factory _$PrepSurfaceCopyWith(_PrepSurface value, $Res Function(_PrepSurface) _then) = __$PrepSurfaceCopyWithImpl;
@override @useResult
$Res call({
 String? withStep, bool atStart
});




}
/// @nodoc
class __$PrepSurfaceCopyWithImpl<$Res>
    implements _$PrepSurfaceCopyWith<$Res> {
  __$PrepSurfaceCopyWithImpl(this._self, this._then);

  final _PrepSurface _self;
  final $Res Function(_PrepSurface) _then;

/// Create a copy of PrepSurface
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? withStep = freezed,Object? atStart = null,}) {
  return _then(_PrepSurface(
withStep: freezed == withStep ? _self.withStep : withStep // ignore: cast_nullable_to_non_nullable
as String?,atStart: null == atStart ? _self.atStart : atStart // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PrepTask {

 String get id; PrepKind get kind; String get textHe; String? get neededByStep; Minutes? get leadMinutes; PrepSurface get surface; PlanTimer? get timer; ConfirmPolicy get confirmPolicy;
/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrepTaskCopyWith<PrepTask> get copyWith => _$PrepTaskCopyWithImpl<PrepTask>(this as PrepTask, _$identity);

  /// Serializes this PrepTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PrepTask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrepTask&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.textHe, _this.textHe) || other.textHe == _this.textHe)&&(identical(other.neededByStep, _this.neededByStep) || other.neededByStep == _this.neededByStep)&&(identical(other.leadMinutes, _this.leadMinutes) || other.leadMinutes == _this.leadMinutes)&&(identical(other.surface, _this.surface) || other.surface == _this.surface)&&(identical(other.timer, _this.timer) || other.timer == _this.timer)&&(identical(other.confirmPolicy, _this.confirmPolicy) || other.confirmPolicy == _this.confirmPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PrepTask;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.textHe,_this.neededByStep,_this.leadMinutes,_this.surface,_this.timer,_this.confirmPolicy);
}

@override
String toString() {
  final _this = this as PrepTask;
  return 'PrepTask(id: ${_this.id}, kind: ${_this.kind}, textHe: ${_this.textHe}, neededByStep: ${_this.neededByStep}, leadMinutes: ${_this.leadMinutes}, surface: ${_this.surface}, timer: ${_this.timer}, confirmPolicy: ${_this.confirmPolicy})';
}


}

/// @nodoc
abstract mixin class $PrepTaskCopyWith<$Res>  {
  factory $PrepTaskCopyWith(PrepTask value, $Res Function(PrepTask) _then) = _$PrepTaskCopyWithImpl;
@useResult
$Res call({
 String id, PrepKind kind, String textHe, String? neededByStep, Minutes? leadMinutes, PrepSurface surface, PlanTimer? timer, ConfirmPolicy confirmPolicy
});


$MinutesCopyWith<$Res>? get leadMinutes;$PrepSurfaceCopyWith<$Res> get surface;$PlanTimerCopyWith<$Res>? get timer;

}
/// @nodoc
class _$PrepTaskCopyWithImpl<$Res>
    implements $PrepTaskCopyWith<$Res> {
  _$PrepTaskCopyWithImpl(this._self, this._then);

  final PrepTask _self;
  final $Res Function(PrepTask) _then;

/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? textHe = null,Object? neededByStep = freezed,Object? leadMinutes = freezed,Object? surface = null,Object? timer = freezed,Object? confirmPolicy = null,}) {
  return _then(PrepTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PrepKind,textHe: null == textHe ? _self.textHe : textHe // ignore: cast_nullable_to_non_nullable
as String,neededByStep: freezed == neededByStep ? _self.neededByStep : neededByStep // ignore: cast_nullable_to_non_nullable
as String?,leadMinutes: freezed == leadMinutes ? _self.leadMinutes : leadMinutes // ignore: cast_nullable_to_non_nullable
as Minutes?,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as PrepSurface,timer: freezed == timer ? _self.timer : timer // ignore: cast_nullable_to_non_nullable
as PlanTimer?,confirmPolicy: null == confirmPolicy ? _self.confirmPolicy : confirmPolicy // ignore: cast_nullable_to_non_nullable
as ConfirmPolicy,
  ));
}
/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MinutesCopyWith<$Res>? get leadMinutes {
    if (_self.leadMinutes == null) {
    return null;
  }

  return $MinutesCopyWith<$Res>(_self.leadMinutes!, (value) {
    return _then(_self.copyWith(leadMinutes: value));
  });
}/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrepSurfaceCopyWith<$Res> get surface {
  
  return $PrepSurfaceCopyWith<$Res>(_self.surface, (value) {
    return _then(_self.copyWith(surface: value));
  });
}/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanTimerCopyWith<$Res>? get timer {
    if (_self.timer == null) {
    return null;
  }

  return $PlanTimerCopyWith<$Res>(_self.timer!, (value) {
    return _then(_self.copyWith(timer: value));
  });
}
}


/// Adds pattern-matching-related methods to [PrepTask].
extension PrepTaskPatterns on PrepTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrepTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrepTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrepTask value)  $default,){
final _that = this;
switch (_that) {
case _PrepTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrepTask value)?  $default,){
final _that = this;
switch (_that) {
case _PrepTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  PrepKind kind,  String textHe,  String? neededByStep,  Minutes? leadMinutes,  PrepSurface surface,  PlanTimer? timer,  ConfirmPolicy confirmPolicy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrepTask() when $default != null:
return $default(_that.id,_that.kind,_that.textHe,_that.neededByStep,_that.leadMinutes,_that.surface,_that.timer,_that.confirmPolicy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  PrepKind kind,  String textHe,  String? neededByStep,  Minutes? leadMinutes,  PrepSurface surface,  PlanTimer? timer,  ConfirmPolicy confirmPolicy)  $default,) {final _that = this;
switch (_that) {
case _PrepTask():
return $default(_that.id,_that.kind,_that.textHe,_that.neededByStep,_that.leadMinutes,_that.surface,_that.timer,_that.confirmPolicy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  PrepKind kind,  String textHe,  String? neededByStep,  Minutes? leadMinutes,  PrepSurface surface,  PlanTimer? timer,  ConfirmPolicy confirmPolicy)?  $default,) {final _that = this;
switch (_that) {
case _PrepTask() when $default != null:
return $default(_that.id,_that.kind,_that.textHe,_that.neededByStep,_that.leadMinutes,_that.surface,_that.timer,_that.confirmPolicy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrepTask implements PrepTask {
  const _PrepTask({required this.id, required this.kind, required this.textHe, this.neededByStep, this.leadMinutes, this.surface = const PrepSurface(atStart: true), this.timer, this.confirmPolicy = ConfirmPolicy.autoOk});
  factory _PrepTask.fromJson(Map<String, dynamic> json) => _$PrepTaskFromJson(json);

@override final  String id;
@override final  PrepKind kind;
@override final  String textHe;
@override final  String? neededByStep;
@override final  Minutes? leadMinutes;
@override@JsonKey() final  PrepSurface surface;
@override final  PlanTimer? timer;
@override@JsonKey() final  ConfirmPolicy confirmPolicy;

/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrepTaskCopyWith<_PrepTask> get copyWith => __$PrepTaskCopyWithImpl<_PrepTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrepTaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrepTask&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.textHe, textHe) || other.textHe == textHe)&&(identical(other.neededByStep, neededByStep) || other.neededByStep == neededByStep)&&(identical(other.leadMinutes, leadMinutes) || other.leadMinutes == leadMinutes)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.timer, timer) || other.timer == timer)&&(identical(other.confirmPolicy, confirmPolicy) || other.confirmPolicy == confirmPolicy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,textHe,neededByStep,leadMinutes,surface,timer,confirmPolicy);
}

@override
String toString() {
    return 'PrepTask(id: $id, kind: $kind, textHe: $textHe, neededByStep: $neededByStep, leadMinutes: $leadMinutes, surface: $surface, timer: $timer, confirmPolicy: $confirmPolicy)';
}


}

/// @nodoc
abstract mixin class _$PrepTaskCopyWith<$Res> implements $PrepTaskCopyWith<$Res> {
  factory _$PrepTaskCopyWith(_PrepTask value, $Res Function(_PrepTask) _then) = __$PrepTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, PrepKind kind, String textHe, String? neededByStep, Minutes? leadMinutes, PrepSurface surface, PlanTimer? timer, ConfirmPolicy confirmPolicy
});


@override $MinutesCopyWith<$Res>? get leadMinutes;@override $PrepSurfaceCopyWith<$Res> get surface;@override $PlanTimerCopyWith<$Res>? get timer;

}
/// @nodoc
class __$PrepTaskCopyWithImpl<$Res>
    implements _$PrepTaskCopyWith<$Res> {
  __$PrepTaskCopyWithImpl(this._self, this._then);

  final _PrepTask _self;
  final $Res Function(_PrepTask) _then;

/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? textHe = null,Object? neededByStep = freezed,Object? leadMinutes = freezed,Object? surface = null,Object? timer = freezed,Object? confirmPolicy = null,}) {
  return _then(_PrepTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PrepKind,textHe: null == textHe ? _self.textHe : textHe // ignore: cast_nullable_to_non_nullable
as String,neededByStep: freezed == neededByStep ? _self.neededByStep : neededByStep // ignore: cast_nullable_to_non_nullable
as String?,leadMinutes: freezed == leadMinutes ? _self.leadMinutes : leadMinutes // ignore: cast_nullable_to_non_nullable
as Minutes?,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as PrepSurface,timer: freezed == timer ? _self.timer : timer // ignore: cast_nullable_to_non_nullable
as PlanTimer?,confirmPolicy: null == confirmPolicy ? _self.confirmPolicy : confirmPolicy // ignore: cast_nullable_to_non_nullable
as ConfirmPolicy,
  ));
}

/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MinutesCopyWith<$Res>? get leadMinutes {
    if (_self.leadMinutes == null) {
    return null;
  }

  return $MinutesCopyWith<$Res>(_self.leadMinutes!, (value) {
    return _then(_self.copyWith(leadMinutes: value));
  });
}/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrepSurfaceCopyWith<$Res> get surface {
  
  return $PrepSurfaceCopyWith<$Res>(_self.surface, (value) {
    return _then(_self.copyWith(surface: value));
  });
}/// Create a copy of PrepTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanTimerCopyWith<$Res>? get timer {
    if (_self.timer == null) {
    return null;
  }

  return $PlanTimerCopyWith<$Res>(_self.timer!, (value) {
    return _then(_self.copyWith(timer: value));
  });
}
}


/// @nodoc
mixin _$CookingPlan {

 int get schemaVersion; List<PlanStep> get steps; List<PrepTask> get prepTasks;
/// Create a copy of CookingPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CookingPlanCopyWith<CookingPlan> get copyWith => _$CookingPlanCopyWithImpl<CookingPlan>(this as CookingPlan, _$identity);

  /// Serializes this CookingPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CookingPlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CookingPlan&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&const DeepCollectionEquality().equals(other.steps, _this.steps)&&const DeepCollectionEquality().equals(other.prepTasks, _this.prepTasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CookingPlan;
  return Object.hash(runtimeType,_this.schemaVersion,const DeepCollectionEquality().hash(_this.steps),const DeepCollectionEquality().hash(_this.prepTasks));
}

@override
String toString() {
  final _this = this as CookingPlan;
  return 'CookingPlan(schemaVersion: ${_this.schemaVersion}, steps: ${_this.steps}, prepTasks: ${_this.prepTasks})';
}


}

/// @nodoc
abstract mixin class $CookingPlanCopyWith<$Res>  {
  factory $CookingPlanCopyWith(CookingPlan value, $Res Function(CookingPlan) _then) = _$CookingPlanCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, List<PlanStep> steps, List<PrepTask> prepTasks
});




}
/// @nodoc
class _$CookingPlanCopyWithImpl<$Res>
    implements $CookingPlanCopyWith<$Res> {
  _$CookingPlanCopyWithImpl(this._self, this._then);

  final CookingPlan _self;
  final $Res Function(CookingPlan) _then;

/// Create a copy of CookingPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? steps = null,Object? prepTasks = null,}) {
  return _then(CookingPlan(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<PlanStep>,prepTasks: null == prepTasks ? _self.prepTasks : prepTasks // ignore: cast_nullable_to_non_nullable
as List<PrepTask>,
  ));
}

}


/// Adds pattern-matching-related methods to [CookingPlan].
extension CookingPlanPatterns on CookingPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CookingPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CookingPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CookingPlan value)  $default,){
final _that = this;
switch (_that) {
case _CookingPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CookingPlan value)?  $default,){
final _that = this;
switch (_that) {
case _CookingPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  List<PlanStep> steps,  List<PrepTask> prepTasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CookingPlan() when $default != null:
return $default(_that.schemaVersion,_that.steps,_that.prepTasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  List<PlanStep> steps,  List<PrepTask> prepTasks)  $default,) {final _that = this;
switch (_that) {
case _CookingPlan():
return $default(_that.schemaVersion,_that.steps,_that.prepTasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  List<PlanStep> steps,  List<PrepTask> prepTasks)?  $default,) {final _that = this;
switch (_that) {
case _CookingPlan() when $default != null:
return $default(_that.schemaVersion,_that.steps,_that.prepTasks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CookingPlan extends CookingPlan {
  const _CookingPlan({this.schemaVersion = 1, required  List<PlanStep> steps,  List<PrepTask> prepTasks = const []}): _steps = steps,_prepTasks = prepTasks,super._();
  factory _CookingPlan.fromJson(Map<String, dynamic> json) => _$CookingPlanFromJson(json);

@override@JsonKey() final  int schemaVersion;
 final  List<PlanStep> _steps;
@override List<PlanStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

 final  List<PrepTask> _prepTasks;
@override@JsonKey() List<PrepTask> get prepTasks {
  if (_prepTasks is EqualUnmodifiableListView) return _prepTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prepTasks);
}


/// Create a copy of CookingPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CookingPlanCopyWith<_CookingPlan> get copyWith => __$CookingPlanCopyWithImpl<_CookingPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CookingPlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CookingPlan&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other.steps, _steps)&&const DeepCollectionEquality().equals(other.prepTasks, _prepTasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(_steps),const DeepCollectionEquality().hash(_prepTasks));
}

@override
String toString() {
    return 'CookingPlan(schemaVersion: $schemaVersion, steps: $steps, prepTasks: $prepTasks)';
}


}

/// @nodoc
abstract mixin class _$CookingPlanCopyWith<$Res> implements $CookingPlanCopyWith<$Res> {
  factory _$CookingPlanCopyWith(_CookingPlan value, $Res Function(_CookingPlan) _then) = __$CookingPlanCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, List<PlanStep> steps, List<PrepTask> prepTasks
});




}
/// @nodoc
class __$CookingPlanCopyWithImpl<$Res>
    implements _$CookingPlanCopyWith<$Res> {
  __$CookingPlanCopyWithImpl(this._self, this._then);

  final _CookingPlan _self;
  final $Res Function(_CookingPlan) _then;

/// Create a copy of CookingPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? steps = null,Object? prepTasks = null,}) {
  return _then(_CookingPlan(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<PlanStep>,prepTasks: null == prepTasks ? _self._prepTasks : prepTasks // ignore: cast_nullable_to_non_nullable
as List<PrepTask>,
  ));
}


}

// dart format on
