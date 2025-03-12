import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/content_item.dart';

class SampleData {
  static Future<List<ContentItem>> getItemsByType(ContentType type, bool isMale) async {
    final String folderPath = 'assets/images/content/${type.getFolderPath(isMale)}';
    final List<ContentItem> items = [];
    
    try {
      // AssetManifest'i yükle
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map.from(
        Map.castFrom<String, dynamic, String, dynamic>(
          await json.decode(manifestContent),
        ),
      );
      
      // Belirtilen klasördeki tüm resimleri bul
      final imageAssets = manifestMap.keys
          .where((String key) => key.startsWith(folderPath) && key.endsWith('.jpg'))
          .toList();
      
      // Her resim için bir ContentItem oluştur
      for (int i = 0; i < imageAssets.length; i++) {
        final String imageUrl = imageAssets[i];
        final int level = i + 1;
        
        items.add(ContentItem(
          id: level.toString(),
          imageUrl: imageUrl,
          title: 'Bölüm $level',
          description: '${type.title} - Bölüm $level',
          type: type,
          additionalData: {
            'isMale': isMale,
            'level': level,
          },
          gameData: {
            'isMale': isMale,
            'level': level,
          },
          level: level,
          isMale: isMale,
        ));
      }
      
      // Bölüm numarasına göre sırala
      items.sort((a, b) => a.level.compareTo(b.level));
    } catch (e) {
      print('Resimler yüklenirken hata oluştu: $e');
      
      // Hata durumunda varsayılan olarak 9 öğe oluştur
      for (int i = 1; i <= 9; i++) {
        items.add(ContentItem(
          id: i.toString(),
          imageUrl: '$folderPath/${i.toString().padLeft(3, '0')}.jpg',
          title: 'Bölüm $i',
          description: '${type.title} - Bölüm $i',
          type: type,
          additionalData: {
            'isMale': isMale,
            'level': i,
          },
          gameData: {
            'isMale': isMale,
            'level': i,
          },
          level: i,
          isMale: isMale,
        ));
      }
    }
    
    return items;
  }

  static Future<List<ContentItem>> getModelItems(bool isMale) async => 
    await getItemsByType(ContentType.model, isMale);
  
  static Future<List<ContentItem>> getAnimeItems(bool isMale) async => 
    await getItemsByType(ContentType.anime, isMale);
  
  static Future<List<ContentItem>> getKarakterItems(bool isMale) async => 
    await getItemsByType(ContentType.karakter, isMale);

  static List<ContentItem> getContentItems(ContentType type, bool isMale) {
    final List<ContentItem> items = [];
    final String gender = isMale ? 'men' : 'women';
    final String typeStr = type.toString().split('.').last.toLowerCase();

    // Her seviye için bir ContentItem oluştur
    for (int i = 1; i <= 9; i++) {
      items.add(
        ContentItem(
          id: i.toString(),
          imageUrl: 'assets/images/content/${gender}_$typeStr/${i.toString().padLeft(3, '0')}.jpg',
          title: 'Bölüm $i',
          description: '${type.title} - Bölüm $i',
          type: type,
          additionalData: {
            'isMale': isMale,
            'level': i,
          },
          gameData: {
            'isMale': isMale,
            'level': i,
          },
          level: i,
          isMale: isMale,
        ),
      );
    }

    return items;
  }
} 