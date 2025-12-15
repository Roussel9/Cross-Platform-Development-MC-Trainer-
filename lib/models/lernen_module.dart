import 'package:json_annotation/json_annotation.dart';

part 'lernen_module.g.dart';

@JsonSerializable()
class LernenModule {
  final int id;
  final String name;
  final String? description;

  LernenModule({
    required this.id,
    required this.name,
    this.description,
  });

  factory LernenModule.fromJson(Map<String, dynamic> json) => _$LernenModuleFromJson(json);
  Map<String, dynamic> toJson() => _$LernenModuleToJson(this);
}