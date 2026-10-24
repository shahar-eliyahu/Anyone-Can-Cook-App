// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecipeSourceInfo {

 SourceType get type; String? get url; String? get siteName; String? get title; String? get retrievedAt;
/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeSourceInfoCopyWith<RecipeSourceInfo> get copyWith => _$RecipeSourceInfoCopyWithImpl<RecipeSourceInfo>(this as RecipeSourceInfo, _$identity);

  /// Serializes this RecipeSourceInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeSourceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeSourceInfo&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.siteName, _this.siteName) || other.siteName == _this.siteName)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.retrievedAt, _this.retrievedAt) || other.retrievedAt == _this.retrievedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeSourceInfo;
  return Object.hash(runtimeType,_this.type,_this.url,_this.siteName,_this.title,_this.retrievedAt);
}

@override
String toString() {
  final _this = this as RecipeSourceInfo;
  return 'RecipeSourceInfo(type: ${_this.type}, url: ${_this.url}, siteName: ${_this.siteName}, title: ${_this.title}, retrievedAt: ${_this.retrievedAt})';
}


}

/// @nodoc
abstract mixin class $RecipeSourceInfoCopyWith<$Res>  {
  factory $RecipeSourceInfoCopyWith(RecipeSourceInfo value, $Res Function(RecipeSourceInfo) _then) = _$RecipeSourceInfoCopyWithImpl;
@useResult
$Res call({
 SourceType type, String? url, String? siteName, String? title, String? retrievedAt
});




}
/// @nodoc
class _$RecipeSourceInfoCopyWithImpl<$Res>
    implements $RecipeSourceInfoCopyWith<$Res> {
  _$RecipeSourceInfoCopyWithImpl(this._self, this._then);

  final RecipeSourceInfo _self;
  final $Res Function(RecipeSourceInfo) _then;

/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? url = freezed,Object? siteName = freezed,Object? title = freezed,Object? retrievedAt = freezed,}) {
  return _then(RecipeSourceInfo(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,siteName: freezed == siteName ? _self.siteName : siteName // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,retrievedAt: freezed == retrievedAt ? _self.retrievedAt : retrievedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RecipeSourceInfo].
extension RecipeSourceInfoPatterns on RecipeSourceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeSourceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeSourceInfo value)  $default,){
final _that = this;
switch (_that) {
case _RecipeSourceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeSourceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SourceType type,  String? url,  String? siteName,  String? title,  String? retrievedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
return $default(_that.type,_that.url,_that.siteName,_that.title,_that.retrievedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SourceType type,  String? url,  String? siteName,  String? title,  String? retrievedAt)  $default,) {final _that = this;
switch (_that) {
case _RecipeSourceInfo():
return $default(_that.type,_that.url,_that.siteName,_that.title,_that.retrievedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SourceType type,  String? url,  String? siteName,  String? title,  String? retrievedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecipeSourceInfo() when $default != null:
return $default(_that.type,_that.url,_that.siteName,_that.title,_that.retrievedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeSourceInfo implements RecipeSourceInfo {
  const _RecipeSourceInfo({required this.type, this.url, this.siteName, this.title, this.retrievedAt});
  factory _RecipeSourceInfo.fromJson(Map<String, dynamic> json) => _$RecipeSourceInfoFromJson(json);

@override final  SourceType type;
@override final  String? url;
@override final  String? siteName;
@override final  String? title;
@override final  String? retrievedAt;

/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeSourceInfoCopyWith<_RecipeSourceInfo> get copyWith => __$RecipeSourceInfoCopyWithImpl<_RecipeSourceInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeSourceInfoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeSourceInfo&&(identical(other.type, type) || other.type == type)&&(identical(other.url, url) || other.url == url)&&(identical(other.siteName, siteName) || other.siteName == siteName)&&(identical(other.title, title) || other.title == title)&&(identical(other.retrievedAt, retrievedAt) || other.retrievedAt == retrievedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,url,siteName,title,retrievedAt);
}

@override
String toString() {
    return 'RecipeSourceInfo(type: $type, url: $url, siteName: $siteName, title: $title, retrievedAt: $retrievedAt)';
}


}

/// @nodoc
abstract mixin class _$RecipeSourceInfoCopyWith<$Res> implements $RecipeSourceInfoCopyWith<$Res> {
  factory _$RecipeSourceInfoCopyWith(_RecipeSourceInfo value, $Res Function(_RecipeSourceInfo) _then) = __$RecipeSourceInfoCopyWithImpl;
@override @useResult
$Res call({
 SourceType type, String? url, String? siteName, String? title, String? retrievedAt
});




}
/// @nodoc
class __$RecipeSourceInfoCopyWithImpl<$Res>
    implements _$RecipeSourceInfoCopyWith<$Res> {
  __$RecipeSourceInfoCopyWithImpl(this._self, this._then);

  final _RecipeSourceInfo _self;
  final $Res Function(_RecipeSourceInfo) _then;

/// Create a copy of RecipeSourceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? url = freezed,Object? siteName = freezed,Object? title = freezed,Object? retrievedAt = freezed,}) {
  return _then(_RecipeSourceInfo(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SourceType,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,siteName: freezed == siteName ? _self.siteName : siteName // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,retrievedAt: freezed == retrievedAt ? _self.retrievedAt : retrievedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ReferenceSource {

 String get id; String get title; String? get url; ReferenceKind get kind;
/// Create a copy of ReferenceSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenceSourceCopyWith<ReferenceSource> get copyWith => _$ReferenceSourceCopyWithImpl<ReferenceSource>(this as ReferenceSource, _$identity);

  /// Serializes this ReferenceSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReferenceSource;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceSource&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReferenceSource;
  return Object.hash(runtimeType,_this.id,_this.title,_this.url,_this.kind);
}

@override
String toString() {
  final _this = this as ReferenceSource;
  return 'ReferenceSource(id: ${_this.id}, title: ${_this.title}, url: ${_this.url}, kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $ReferenceSourceCopyWith<$Res>  {
  factory $ReferenceSourceCopyWith(ReferenceSource value, $Res Function(ReferenceSource) _then) = _$ReferenceSourceCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? url, ReferenceKind kind
});




}
/// @nodoc
class _$ReferenceSourceCopyWithImpl<$Res>
    implements $ReferenceSourceCopyWith<$Res> {
  _$ReferenceSourceCopyWithImpl(this._self, this._then);

  final ReferenceSource _self;
  final $Res Function(ReferenceSource) _then;

/// Create a copy of ReferenceSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? url = freezed,Object? kind = null,}) {
  return _then(ReferenceSource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReferenceKind,
  ));
}

}


/// Adds pattern-matching-related methods to [ReferenceSource].
extension ReferenceSourcePatterns on ReferenceSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReferenceSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReferenceSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReferenceSource value)  $default,){
final _that = this;
switch (_that) {
case _ReferenceSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReferenceSource value)?  $default,){
final _that = this;
switch (_that) {
case _ReferenceSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? url,  ReferenceKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReferenceSource() when $default != null:
return $default(_that.id,_that.title,_that.url,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? url,  ReferenceKind kind)  $default,) {final _that = this;
switch (_that) {
case _ReferenceSource():
return $default(_that.id,_that.title,_that.url,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? url,  ReferenceKind kind)?  $default,) {final _that = this;
switch (_that) {
case _ReferenceSource() when $default != null:
return $default(_that.id,_that.title,_that.url,_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReferenceSource implements ReferenceSource {
  const _ReferenceSource({required this.id, required this.title, this.url, required this.kind});
  factory _ReferenceSource.fromJson(Map<String, dynamic> json) => _$ReferenceSourceFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? url;
@override final  ReferenceKind kind;

/// Create a copy of ReferenceSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferenceSourceCopyWith<_ReferenceSource> get copyWith => __$ReferenceSourceCopyWithImpl<_ReferenceSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferenceSourceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReferenceSource&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.url, url) || other.url == url)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,url,kind);
}

@override
String toString() {
    return 'ReferenceSource(id: $id, title: $title, url: $url, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$ReferenceSourceCopyWith<$Res> implements $ReferenceSourceCopyWith<$Res> {
  factory _$ReferenceSourceCopyWith(_ReferenceSource value, $Res Function(_ReferenceSource) _then) = __$ReferenceSourceCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? url, ReferenceKind kind
});




}
/// @nodoc
class __$ReferenceSourceCopyWithImpl<$Res>
    implements _$ReferenceSourceCopyWith<$Res> {
  __$ReferenceSourceCopyWithImpl(this._self, this._then);

  final _ReferenceSource _self;
  final $Res Function(_ReferenceSource) _then;

/// Create a copy of ReferenceSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? url = freezed,Object? kind = null,}) {
  return _then(_ReferenceSource(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ReferenceKind,
  ));
}


}


/// @nodoc
mixin _$Question {

 String get id; String get textHe; String get whyHe; QuestionKind get kind; List<String> get options; String? get unitHe; GapCategory get category; bool get required; List<String> get affects;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Question;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.textHe, _this.textHe) || other.textHe == _this.textHe)&&(identical(other.whyHe, _this.whyHe) || other.whyHe == _this.whyHe)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.options, _this.options)&&(identical(other.unitHe, _this.unitHe) || other.unitHe == _this.unitHe)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.required, _this.required) || other.required == _this.required)&&const DeepCollectionEquality().equals(other.affects, _this.affects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Question;
  return Object.hash(runtimeType,_this.id,_this.textHe,_this.whyHe,_this.kind,const DeepCollectionEquality().hash(_this.options),_this.unitHe,_this.category,_this.required,const DeepCollectionEquality().hash(_this.affects));
}

@override
String toString() {
  final _this = this as Question;
  return 'Question(id: ${_this.id}, textHe: ${_this.textHe}, whyHe: ${_this.whyHe}, kind: ${_this.kind}, options: ${_this.options}, unitHe: ${_this.unitHe}, category: ${_this.category}, required: ${_this.required}, affects: ${_this.affects})';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 String id, String textHe, String whyHe, QuestionKind kind, List<String> options, String? unitHe, GapCategory category, bool required, List<String> affects
});




}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? textHe = null,Object? whyHe = null,Object? kind = null,Object? options = null,Object? unitHe = freezed,Object? category = null,Object? required = null,Object? affects = null,}) {
  return _then(Question(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textHe: null == textHe ? _self.textHe : textHe // ignore: cast_nullable_to_non_nullable
as String,whyHe: null == whyHe ? _self.whyHe : whyHe // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QuestionKind,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>,unitHe: freezed == unitHe ? _self.unitHe : unitHe // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GapCategory,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,affects: null == affects ? _self.affects : affects // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Question].
extension QuestionPatterns on Question {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Question value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Question value)  $default,){
final _that = this;
switch (_that) {
case _Question():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Question value)?  $default,){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String textHe,  String whyHe,  QuestionKind kind,  List<String> options,  String? unitHe,  GapCategory category,  bool required,  List<String> affects)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.textHe,_that.whyHe,_that.kind,_that.options,_that.unitHe,_that.category,_that.required,_that.affects);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String textHe,  String whyHe,  QuestionKind kind,  List<String> options,  String? unitHe,  GapCategory category,  bool required,  List<String> affects)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.id,_that.textHe,_that.whyHe,_that.kind,_that.options,_that.unitHe,_that.category,_that.required,_that.affects);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String textHe,  String whyHe,  QuestionKind kind,  List<String> options,  String? unitHe,  GapCategory category,  bool required,  List<String> affects)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.textHe,_that.whyHe,_that.kind,_that.options,_that.unitHe,_that.category,_that.required,_that.affects);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question implements Question {
  const _Question({required this.id, required this.textHe, required this.whyHe, required this.kind,  List<String> options = const [], this.unitHe, required this.category, this.required = false,  List<String> affects = const []}): _options = options,_affects = affects;
  factory _Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

@override final  String id;
@override final  String textHe;
@override final  String whyHe;
@override final  QuestionKind kind;
 final  List<String> _options;
@override@JsonKey() List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

@override final  String? unitHe;
@override final  GapCategory category;
@override@JsonKey() final  bool required;
 final  List<String> _affects;
@override@JsonKey() List<String> get affects {
  if (_affects is EqualUnmodifiableListView) return _affects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_affects);
}


/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCopyWith<_Question> get copyWith => __$QuestionCopyWithImpl<_Question>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.id, id) || other.id == id)&&(identical(other.textHe, textHe) || other.textHe == textHe)&&(identical(other.whyHe, whyHe) || other.whyHe == whyHe)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.options, _options)&&(identical(other.unitHe, unitHe) || other.unitHe == unitHe)&&(identical(other.category, category) || other.category == category)&&(identical(other.required, required) || other.required == required)&&const DeepCollectionEquality().equals(other.affects, _affects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,textHe,whyHe,kind,const DeepCollectionEquality().hash(_options),unitHe,category,required,const DeepCollectionEquality().hash(_affects));
}

@override
String toString() {
    return 'Question(id: $id, textHe: $textHe, whyHe: $whyHe, kind: $kind, options: $options, unitHe: $unitHe, category: $category, required: $required, affects: $affects)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String textHe, String whyHe, QuestionKind kind, List<String> options, String? unitHe, GapCategory category, bool required, List<String> affects
});




}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? textHe = null,Object? whyHe = null,Object? kind = null,Object? options = null,Object? unitHe = freezed,Object? category = null,Object? required = null,Object? affects = null,}) {
  return _then(_Question(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,textHe: null == textHe ? _self.textHe : textHe // ignore: cast_nullable_to_non_nullable
as String,whyHe: null == whyHe ? _self.whyHe : whyHe // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as QuestionKind,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,unitHe: freezed == unitHe ? _self.unitHe : unitHe // ignore: cast_nullable_to_non_nullable
as String?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GapCategory,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,affects: null == affects ? _self._affects : affects // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Answer {

 String get questionId; String? get value; bool get unknown;
/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerCopyWith<Answer> get copyWith => _$AnswerCopyWithImpl<Answer>(this as Answer, _$identity);

  /// Serializes this Answer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Answer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Answer&&(identical(other.questionId, _this.questionId) || other.questionId == _this.questionId)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.unknown, _this.unknown) || other.unknown == _this.unknown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Answer;
  return Object.hash(runtimeType,_this.questionId,_this.value,_this.unknown);
}

@override
String toString() {
  final _this = this as Answer;
  return 'Answer(questionId: ${_this.questionId}, value: ${_this.value}, unknown: ${_this.unknown})';
}


}

/// @nodoc
abstract mixin class $AnswerCopyWith<$Res>  {
  factory $AnswerCopyWith(Answer value, $Res Function(Answer) _then) = _$AnswerCopyWithImpl;
@useResult
$Res call({
 String questionId, String? value, bool unknown
});




}
/// @nodoc
class _$AnswerCopyWithImpl<$Res>
    implements $AnswerCopyWith<$Res> {
  _$AnswerCopyWithImpl(this._self, this._then);

  final Answer _self;
  final $Res Function(Answer) _then;

/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? value = freezed,Object? unknown = null,}) {
  return _then(Answer(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,unknown: null == unknown ? _self.unknown : unknown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Answer].
extension AnswerPatterns on Answer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Answer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Answer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Answer value)  $default,){
final _that = this;
switch (_that) {
case _Answer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Answer value)?  $default,){
final _that = this;
switch (_that) {
case _Answer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  String? value,  bool unknown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Answer() when $default != null:
return $default(_that.questionId,_that.value,_that.unknown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  String? value,  bool unknown)  $default,) {final _that = this;
switch (_that) {
case _Answer():
return $default(_that.questionId,_that.value,_that.unknown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  String? value,  bool unknown)?  $default,) {final _that = this;
switch (_that) {
case _Answer() when $default != null:
return $default(_that.questionId,_that.value,_that.unknown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Answer implements Answer {
  const _Answer({required this.questionId, this.value, this.unknown = false});
  factory _Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);

@override final  String questionId;
@override final  String? value;
@override@JsonKey() final  bool unknown;

/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerCopyWith<_Answer> get copyWith => __$AnswerCopyWithImpl<_Answer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswerToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Answer&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.value, value) || other.value == value)&&(identical(other.unknown, unknown) || other.unknown == unknown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,questionId,value,unknown);
}

@override
String toString() {
    return 'Answer(questionId: $questionId, value: $value, unknown: $unknown)';
}


}

/// @nodoc
abstract mixin class _$AnswerCopyWith<$Res> implements $AnswerCopyWith<$Res> {
  factory _$AnswerCopyWith(_Answer value, $Res Function(_Answer) _then) = __$AnswerCopyWithImpl;
@override @useResult
$Res call({
 String questionId, String? value, bool unknown
});




}
/// @nodoc
class __$AnswerCopyWithImpl<$Res>
    implements _$AnswerCopyWith<$Res> {
  __$AnswerCopyWithImpl(this._self, this._then);

  final _Answer _self;
  final $Res Function(_Answer) _then;

/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? value = freezed,Object? unknown = null,}) {
  return _then(_Answer(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,unknown: null == unknown ? _self.unknown : unknown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Gap {

 String get id; String get field; GapCategory get category; GapResolution get resolution; String? get questionId; String? get noteHe;
/// Create a copy of Gap
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GapCopyWith<Gap> get copyWith => _$GapCopyWithImpl<Gap>(this as Gap, _$identity);

  /// Serializes this Gap to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Gap;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gap&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.field, _this.field) || other.field == _this.field)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.resolution, _this.resolution) || other.resolution == _this.resolution)&&(identical(other.questionId, _this.questionId) || other.questionId == _this.questionId)&&(identical(other.noteHe, _this.noteHe) || other.noteHe == _this.noteHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Gap;
  return Object.hash(runtimeType,_this.id,_this.field,_this.category,_this.resolution,_this.questionId,_this.noteHe);
}

@override
String toString() {
  final _this = this as Gap;
  return 'Gap(id: ${_this.id}, field: ${_this.field}, category: ${_this.category}, resolution: ${_this.resolution}, questionId: ${_this.questionId}, noteHe: ${_this.noteHe})';
}


}

/// @nodoc
abstract mixin class $GapCopyWith<$Res>  {
  factory $GapCopyWith(Gap value, $Res Function(Gap) _then) = _$GapCopyWithImpl;
@useResult
$Res call({
 String id, String field, GapCategory category, GapResolution resolution, String? questionId, String? noteHe
});




}
/// @nodoc
class _$GapCopyWithImpl<$Res>
    implements $GapCopyWith<$Res> {
  _$GapCopyWithImpl(this._self, this._then);

  final Gap _self;
  final $Res Function(Gap) _then;

/// Create a copy of Gap
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? field = null,Object? category = null,Object? resolution = null,Object? questionId = freezed,Object? noteHe = freezed,}) {
  return _then(Gap(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GapCategory,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as GapResolution,questionId: freezed == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String?,noteHe: freezed == noteHe ? _self.noteHe : noteHe // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Gap].
extension GapPatterns on Gap {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gap value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gap() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gap value)  $default,){
final _that = this;
switch (_that) {
case _Gap():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gap value)?  $default,){
final _that = this;
switch (_that) {
case _Gap() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String field,  GapCategory category,  GapResolution resolution,  String? questionId,  String? noteHe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gap() when $default != null:
return $default(_that.id,_that.field,_that.category,_that.resolution,_that.questionId,_that.noteHe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String field,  GapCategory category,  GapResolution resolution,  String? questionId,  String? noteHe)  $default,) {final _that = this;
switch (_that) {
case _Gap():
return $default(_that.id,_that.field,_that.category,_that.resolution,_that.questionId,_that.noteHe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String field,  GapCategory category,  GapResolution resolution,  String? questionId,  String? noteHe)?  $default,) {final _that = this;
switch (_that) {
case _Gap() when $default != null:
return $default(_that.id,_that.field,_that.category,_that.resolution,_that.questionId,_that.noteHe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Gap implements Gap {
  const _Gap({required this.id, required this.field, required this.category, required this.resolution, this.questionId, this.noteHe});
  factory _Gap.fromJson(Map<String, dynamic> json) => _$GapFromJson(json);

@override final  String id;
@override final  String field;
@override final  GapCategory category;
@override final  GapResolution resolution;
@override final  String? questionId;
@override final  String? noteHe;

/// Create a copy of Gap
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GapCopyWith<_Gap> get copyWith => __$GapCopyWithImpl<_Gap>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GapToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gap&&(identical(other.id, id) || other.id == id)&&(identical(other.field, field) || other.field == field)&&(identical(other.category, category) || other.category == category)&&(identical(other.resolution, resolution) || other.resolution == resolution)&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.noteHe, noteHe) || other.noteHe == noteHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,field,category,resolution,questionId,noteHe);
}

@override
String toString() {
    return 'Gap(id: $id, field: $field, category: $category, resolution: $resolution, questionId: $questionId, noteHe: $noteHe)';
}


}

/// @nodoc
abstract mixin class _$GapCopyWith<$Res> implements $GapCopyWith<$Res> {
  factory _$GapCopyWith(_Gap value, $Res Function(_Gap) _then) = __$GapCopyWithImpl;
@override @useResult
$Res call({
 String id, String field, GapCategory category, GapResolution resolution, String? questionId, String? noteHe
});




}
/// @nodoc
class __$GapCopyWithImpl<$Res>
    implements _$GapCopyWith<$Res> {
  __$GapCopyWithImpl(this._self, this._then);

  final _Gap _self;
  final $Res Function(_Gap) _then;

/// Create a copy of Gap
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? field = null,Object? category = null,Object? resolution = null,Object? questionId = freezed,Object? noteHe = freezed,}) {
  return _then(_Gap(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as GapCategory,resolution: null == resolution ? _self.resolution : resolution // ignore: cast_nullable_to_non_nullable
as GapResolution,questionId: freezed == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String?,noteHe: freezed == noteHe ? _self.noteHe : noteHe // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RecipeAnalysis {

 int get schemaVersion; bool get isRecipe; String? get notRecipeReasonHe; RecipeSourceInfo get source; String get sourceText; Recipe? get recipe; List<Question> get questions; List<Answer> get answers; List<Gap> get gaps; List<ReferenceSource> get sources; List<String> get assumptionsHe;
/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecipeAnalysisCopyWith<RecipeAnalysis> get copyWith => _$RecipeAnalysisCopyWithImpl<RecipeAnalysis>(this as RecipeAnalysis, _$identity);

  /// Serializes this RecipeAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecipeAnalysis;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecipeAnalysis&&(identical(other.schemaVersion, _this.schemaVersion) || other.schemaVersion == _this.schemaVersion)&&(identical(other.isRecipe, _this.isRecipe) || other.isRecipe == _this.isRecipe)&&(identical(other.notRecipeReasonHe, _this.notRecipeReasonHe) || other.notRecipeReasonHe == _this.notRecipeReasonHe)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.sourceText, _this.sourceText) || other.sourceText == _this.sourceText)&&(identical(other.recipe, _this.recipe) || other.recipe == _this.recipe)&&const DeepCollectionEquality().equals(other.questions, _this.questions)&&const DeepCollectionEquality().equals(other.answers, _this.answers)&&const DeepCollectionEquality().equals(other.gaps, _this.gaps)&&const DeepCollectionEquality().equals(other.sources, _this.sources)&&const DeepCollectionEquality().equals(other.assumptionsHe, _this.assumptionsHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecipeAnalysis;
  return Object.hash(runtimeType,_this.schemaVersion,_this.isRecipe,_this.notRecipeReasonHe,_this.source,_this.sourceText,_this.recipe,const DeepCollectionEquality().hash(_this.questions),const DeepCollectionEquality().hash(_this.answers),const DeepCollectionEquality().hash(_this.gaps),const DeepCollectionEquality().hash(_this.sources),const DeepCollectionEquality().hash(_this.assumptionsHe));
}

@override
String toString() {
  final _this = this as RecipeAnalysis;
  return 'RecipeAnalysis(schemaVersion: ${_this.schemaVersion}, isRecipe: ${_this.isRecipe}, notRecipeReasonHe: ${_this.notRecipeReasonHe}, source: ${_this.source}, sourceText: ${_this.sourceText}, recipe: ${_this.recipe}, questions: ${_this.questions}, answers: ${_this.answers}, gaps: ${_this.gaps}, sources: ${_this.sources}, assumptionsHe: ${_this.assumptionsHe})';
}


}

/// @nodoc
abstract mixin class $RecipeAnalysisCopyWith<$Res>  {
  factory $RecipeAnalysisCopyWith(RecipeAnalysis value, $Res Function(RecipeAnalysis) _then) = _$RecipeAnalysisCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, bool isRecipe, String? notRecipeReasonHe, RecipeSourceInfo source, String sourceText, Recipe? recipe, List<Question> questions, List<Answer> answers, List<Gap> gaps, List<ReferenceSource> sources, List<String> assumptionsHe
});


$RecipeSourceInfoCopyWith<$Res> get source;$RecipeCopyWith<$Res>? get recipe;

}
/// @nodoc
class _$RecipeAnalysisCopyWithImpl<$Res>
    implements $RecipeAnalysisCopyWith<$Res> {
  _$RecipeAnalysisCopyWithImpl(this._self, this._then);

  final RecipeAnalysis _self;
  final $Res Function(RecipeAnalysis) _then;

/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? isRecipe = null,Object? notRecipeReasonHe = freezed,Object? source = null,Object? sourceText = null,Object? recipe = freezed,Object? questions = null,Object? answers = null,Object? gaps = null,Object? sources = null,Object? assumptionsHe = null,}) {
  return _then(RecipeAnalysis(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,isRecipe: null == isRecipe ? _self.isRecipe : isRecipe // ignore: cast_nullable_to_non_nullable
as bool,notRecipeReasonHe: freezed == notRecipeReasonHe ? _self.notRecipeReasonHe : notRecipeReasonHe // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RecipeSourceInfo,sourceText: null == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String,recipe: freezed == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as Recipe?,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<Question>,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<Answer>,gaps: null == gaps ? _self.gaps : gaps // ignore: cast_nullable_to_non_nullable
as List<Gap>,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<ReferenceSource>,assumptionsHe: null == assumptionsHe ? _self.assumptionsHe : assumptionsHe // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeSourceInfoCopyWith<$Res> get source {
  
  return $RecipeSourceInfoCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeCopyWith<$Res>? get recipe {
    if (_self.recipe == null) {
    return null;
  }

  return $RecipeCopyWith<$Res>(_self.recipe!, (value) {
    return _then(_self.copyWith(recipe: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecipeAnalysis].
extension RecipeAnalysisPatterns on RecipeAnalysis {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecipeAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecipeAnalysis() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecipeAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _RecipeAnalysis():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecipeAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _RecipeAnalysis() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  bool isRecipe,  String? notRecipeReasonHe,  RecipeSourceInfo source,  String sourceText,  Recipe? recipe,  List<Question> questions,  List<Answer> answers,  List<Gap> gaps,  List<ReferenceSource> sources,  List<String> assumptionsHe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecipeAnalysis() when $default != null:
return $default(_that.schemaVersion,_that.isRecipe,_that.notRecipeReasonHe,_that.source,_that.sourceText,_that.recipe,_that.questions,_that.answers,_that.gaps,_that.sources,_that.assumptionsHe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  bool isRecipe,  String? notRecipeReasonHe,  RecipeSourceInfo source,  String sourceText,  Recipe? recipe,  List<Question> questions,  List<Answer> answers,  List<Gap> gaps,  List<ReferenceSource> sources,  List<String> assumptionsHe)  $default,) {final _that = this;
switch (_that) {
case _RecipeAnalysis():
return $default(_that.schemaVersion,_that.isRecipe,_that.notRecipeReasonHe,_that.source,_that.sourceText,_that.recipe,_that.questions,_that.answers,_that.gaps,_that.sources,_that.assumptionsHe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  bool isRecipe,  String? notRecipeReasonHe,  RecipeSourceInfo source,  String sourceText,  Recipe? recipe,  List<Question> questions,  List<Answer> answers,  List<Gap> gaps,  List<ReferenceSource> sources,  List<String> assumptionsHe)?  $default,) {final _that = this;
switch (_that) {
case _RecipeAnalysis() when $default != null:
return $default(_that.schemaVersion,_that.isRecipe,_that.notRecipeReasonHe,_that.source,_that.sourceText,_that.recipe,_that.questions,_that.answers,_that.gaps,_that.sources,_that.assumptionsHe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecipeAnalysis implements RecipeAnalysis {
  const _RecipeAnalysis({this.schemaVersion = 1, required this.isRecipe, this.notRecipeReasonHe, required this.source, this.sourceText = '', this.recipe,  List<Question> questions = const [],  List<Answer> answers = const [],  List<Gap> gaps = const [],  List<ReferenceSource> sources = const [],  List<String> assumptionsHe = const []}): _questions = questions,_answers = answers,_gaps = gaps,_sources = sources,_assumptionsHe = assumptionsHe;
  factory _RecipeAnalysis.fromJson(Map<String, dynamic> json) => _$RecipeAnalysisFromJson(json);

@override@JsonKey() final  int schemaVersion;
@override final  bool isRecipe;
@override final  String? notRecipeReasonHe;
@override final  RecipeSourceInfo source;
@override@JsonKey() final  String sourceText;
@override final  Recipe? recipe;
 final  List<Question> _questions;
@override@JsonKey() List<Question> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

 final  List<Answer> _answers;
@override@JsonKey() List<Answer> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

 final  List<Gap> _gaps;
@override@JsonKey() List<Gap> get gaps {
  if (_gaps is EqualUnmodifiableListView) return _gaps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gaps);
}

 final  List<ReferenceSource> _sources;
@override@JsonKey() List<ReferenceSource> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}

 final  List<String> _assumptionsHe;
@override@JsonKey() List<String> get assumptionsHe {
  if (_assumptionsHe is EqualUnmodifiableListView) return _assumptionsHe;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assumptionsHe);
}


/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecipeAnalysisCopyWith<_RecipeAnalysis> get copyWith => __$RecipeAnalysisCopyWithImpl<_RecipeAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecipeAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecipeAnalysis&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.isRecipe, isRecipe) || other.isRecipe == isRecipe)&&(identical(other.notRecipeReasonHe, notRecipeReasonHe) || other.notRecipeReasonHe == notRecipeReasonHe)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceText, sourceText) || other.sourceText == sourceText)&&(identical(other.recipe, recipe) || other.recipe == recipe)&&const DeepCollectionEquality().equals(other.questions, _questions)&&const DeepCollectionEquality().equals(other.answers, _answers)&&const DeepCollectionEquality().equals(other.gaps, _gaps)&&const DeepCollectionEquality().equals(other.sources, _sources)&&const DeepCollectionEquality().equals(other.assumptionsHe, _assumptionsHe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,schemaVersion,isRecipe,notRecipeReasonHe,source,sourceText,recipe,const DeepCollectionEquality().hash(_questions),const DeepCollectionEquality().hash(_answers),const DeepCollectionEquality().hash(_gaps),const DeepCollectionEquality().hash(_sources),const DeepCollectionEquality().hash(_assumptionsHe));
}

@override
String toString() {
    return 'RecipeAnalysis(schemaVersion: $schemaVersion, isRecipe: $isRecipe, notRecipeReasonHe: $notRecipeReasonHe, source: $source, sourceText: $sourceText, recipe: $recipe, questions: $questions, answers: $answers, gaps: $gaps, sources: $sources, assumptionsHe: $assumptionsHe)';
}


}

/// @nodoc
abstract mixin class _$RecipeAnalysisCopyWith<$Res> implements $RecipeAnalysisCopyWith<$Res> {
  factory _$RecipeAnalysisCopyWith(_RecipeAnalysis value, $Res Function(_RecipeAnalysis) _then) = __$RecipeAnalysisCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, bool isRecipe, String? notRecipeReasonHe, RecipeSourceInfo source, String sourceText, Recipe? recipe, List<Question> questions, List<Answer> answers, List<Gap> gaps, List<ReferenceSource> sources, List<String> assumptionsHe
});


@override $RecipeSourceInfoCopyWith<$Res> get source;@override $RecipeCopyWith<$Res>? get recipe;

}
/// @nodoc
class __$RecipeAnalysisCopyWithImpl<$Res>
    implements _$RecipeAnalysisCopyWith<$Res> {
  __$RecipeAnalysisCopyWithImpl(this._self, this._then);

  final _RecipeAnalysis _self;
  final $Res Function(_RecipeAnalysis) _then;

/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? isRecipe = null,Object? notRecipeReasonHe = freezed,Object? source = null,Object? sourceText = null,Object? recipe = freezed,Object? questions = null,Object? answers = null,Object? gaps = null,Object? sources = null,Object? assumptionsHe = null,}) {
  return _then(_RecipeAnalysis(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,isRecipe: null == isRecipe ? _self.isRecipe : isRecipe // ignore: cast_nullable_to_non_nullable
as bool,notRecipeReasonHe: freezed == notRecipeReasonHe ? _self.notRecipeReasonHe : notRecipeReasonHe // ignore: cast_nullable_to_non_nullable
as String?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as RecipeSourceInfo,sourceText: null == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String,recipe: freezed == recipe ? _self.recipe : recipe // ignore: cast_nullable_to_non_nullable
as Recipe?,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<Question>,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<Answer>,gaps: null == gaps ? _self._gaps : gaps // ignore: cast_nullable_to_non_nullable
as List<Gap>,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<ReferenceSource>,assumptionsHe: null == assumptionsHe ? _self._assumptionsHe : assumptionsHe // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeSourceInfoCopyWith<$Res> get source {
  
  return $RecipeSourceInfoCopyWith<$Res>(_self.source, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of RecipeAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecipeCopyWith<$Res>? get recipe {
    if (_self.recipe == null) {
    return null;
  }

  return $RecipeCopyWith<$Res>(_self.recipe!, (value) {
    return _then(_self.copyWith(recipe: value));
  });
}
}

// dart format on
