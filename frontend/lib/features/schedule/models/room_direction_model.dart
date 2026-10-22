import 'package:flutter/material.dart';

class DirectionStep {
  final int step;
  final String title;
  final String desc;
  final String icon;

  const DirectionStep({
    required this.step,
    required this.title,
    required this.desc,
    required this.icon,
  });

  factory DirectionStep.fromJson(Map<String, dynamic> json) {
    return DirectionStep(
      step: json['step'] is int
          ? json['step'] as int
          : int.tryParse(json['step'].toString()) ?? 1,
      title: json['title']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'compass',
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'desc': desc,
        'icon': icon,
      };

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'compass':
      case 'explore':
      case 'navigation':
        return Icons.explore_outlined;
      case 'home':
      case 'domain':
      case 'business':
        return Icons.business_outlined;
      case 'arrow-up-circle':
      case 'arrow_upward':
      case 'stairs':
        return Icons.stairs_outlined;
      case 'map-pin':
      case 'pin':
      case 'location':
      case 'room':
        return Icons.location_on_outlined;
      default:
        return Icons.place_outlined;
    }
  }
}

class RoomDirectionInfo {
  final String room;
  final String building;
  final String buildingCode;
  final String floor;
  final String mapQuery;
  final List<DirectionStep> steps;
  final List<String> tips;

  const RoomDirectionInfo({
    required this.room,
    required this.building,
    required this.buildingCode,
    this.floor = '',
    required this.mapQuery,
    required this.steps,
    this.tips = const [],
  });

  factory RoomDirectionInfo.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List? ?? [];
    final steps = rawSteps
        .map((s) => DirectionStep.fromJson(Map<String, dynamic>.from(s)))
        .toList();
    final rawTips = json['tips'] as List? ?? [];
    final tips = rawTips.map((t) => t.toString()).toList();

    return RoomDirectionInfo(
      room: json['room']?.toString() ?? '',
      building: json['building']?.toString() ?? '',
      buildingCode: json['buildingCode']?.toString() ??
          json['building_code']?.toString() ??
          '',
      floor: json['floor']?.toString() ?? '',
      mapQuery: json['mapQuery']?.toString() ??
          json['map_query']?.toString() ??
          '',
      steps: steps,
      tips: tips,
    );
  }

  Map<String, dynamic> toJson() => {
        'room': room,
        'building': building,
        'buildingCode': buildingCode,
        'floor': floor,
        'mapQuery': mapQuery,
        'steps': steps.map((s) => s.toJson()).toList(),
        'tips': tips,
      };
}
