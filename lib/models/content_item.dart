import 'package:flutter/material.dart';

enum ContentType {
  model,
  anime,
  karakter,
  dialog;    // Diyalog oyunu

  String getFolderPath(bool isMale) {
    if (this == ContentType.dialog) {
      return 'dialog_games';
    }
    final baseType = toString().split('.').last;
    return isMale ? 'men_$baseType' : baseType;
  }

  String get title {
    switch (this) {
      case ContentType.model:
        return 'MODEL';
      case ContentType.anime:
        return 'ANİME';
      case ContentType.karakter:
        return 'KARAKTER';
      case ContentType.dialog:
        return 'DİYALOG OYUNU';
    }
  }

  Color get color {
    switch (this) {
      case ContentType.model:
        return Colors.pink;
      case ContentType.anime:
        return Colors.purple;
      case ContentType.karakter:
        return Colors.blue;
      case ContentType.dialog:
        return Colors.teal;
    }
  }

  bool get isGame {
    return this == ContentType.dialog;
  }
}

class ContentItem {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final Map<String, dynamic> additionalData;
  final ContentType type;
  double _blurLevel; // private yapıyoruz
  final bool isCompleted;
  final Map<String, dynamic> gameData;
  final int level;
  final bool isMale;

  // Getter ve setter
  double get blurLevel => _blurLevel;
  set blurLevel(double value) {
    _blurLevel = value.clamp(0.0, 10.0);
  }

  String get imagePath {
    final gender = isMale ? 'men_' : '';
    final typeName = type.name.toLowerCase();
    final formattedLevel = level.toString().padLeft(3, '0');
    return 'assets/images/content/$gender$typeName/$formattedLevel.jpg';
  }

  ContentItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.description = '',
    this.additionalData = const {},
    required this.type,
    double blurLevel = 10.0,
    this.isCompleted = false,
    required this.gameData,
    required this.level,
    required this.isMale,
  }) : _blurLevel = blurLevel;

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      additionalData: json['additionalData'] as Map<String, dynamic>? ?? {},
      type: ContentType.values.firstWhere(
        (e) => e.toString() == 'ContentType.${json['type']}',
        orElse: () => ContentType.anime,
      ),
      blurLevel: (json['blurLevel'] as num?)?.toDouble() ?? 10.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      gameData: json['gameData'] as Map<String, dynamic>? ?? {},
      level: json['level'] as int? ?? 1,
      isMale: json['isMale'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'additionalData': additionalData,
      'type': type.toString().split('.').last,
      'blurLevel': _blurLevel,
      'isCompleted': isCompleted,
      'gameData': gameData,
      'level': level,
      'isMale': isMale,
    };
  }

  // Bölümü tamamlandı olarak işaretler ve bulanıklığı kaldırır
  ContentItem markAsCompleted() {
    return copyWith(
      isCompleted: true,
      blurLevel: 0.0,
    );
  }

  ContentItem copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? description,
    Map<String, dynamic>? additionalData,
    ContentType? type,
    double? blurLevel,
    bool? isCompleted,
    Map<String, dynamic>? gameData,
    int? level,
    bool? isMale,
  }) {
    return ContentItem(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      additionalData: additionalData ?? this.additionalData,
      type: type ?? this.type,
      blurLevel: blurLevel ?? this._blurLevel,
      isCompleted: isCompleted ?? this.isCompleted,
      gameData: gameData ?? this.gameData,
      level: level ?? this.level,
      isMale: isMale ?? this.isMale,
    );
  }
} 