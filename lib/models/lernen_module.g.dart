// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lernen_module.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LernenModule _$LernenModuleFromJson(Map<String, dynamic> json) => LernenModule(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
);

Map<String, dynamic> _$LernenModuleToJson(LernenModule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };
