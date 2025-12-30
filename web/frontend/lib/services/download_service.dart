import 'dart:io';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/content_item.dart';

// Conditional import for web-specific code
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('✅ DownloadService: Initializing database...');
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'downloads.db');

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE downloads (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              creator TEXT,
              cover_image TEXT,
              audio_url TEXT NOT NULL,
              local_path TEXT NOT NULL,
              duration INTEGER,
              category TEXT,
              file_size INTEGER,
              downloaded_at INTEGER NOT NULL
            )
          ''');
        },
      );
      print('✅ DownloadService: Database initialized successfully');
      return db;
    } catch (e) {
      print('❌ DownloadService: Error initializing database: $e');
      rethrow; // Re-throw to let caller handle
    }
  }

  Future<bool> downloadContent(ContentItem item) async {
    try {
      if (item.audioUrl == null || item.audioUrl!.isEmpty) {
        return false;
      }

      final db = await database;

      // Check if already downloaded
      final existing = await db.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (existing.isNotEmpty) {
        // Already downloaded
        return true;
      }

      // Get download directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Download file
      final response = await http.get(Uri.parse(item.audioUrl!));
      if (response.statusCode != 200) {
        return false;
      }

      final fileName =
          '${item.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      // Save to database
      await db.insert('downloads', {
        'id': item.id,
        'title': item.title,
        'creator': item.creator,
        'cover_image': item.coverImage ?? '',
        'audio_url': item.audioUrl ?? '',
        'local_path': file.path,
        'duration': item.duration?.inSeconds,
        'category': item.category,
        'file_size': await file.length(),
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('Error downloading content: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    try {
      final db = await database;
      return await db.query(
        'downloads',
        orderBy: 'downloaded_at DESC',
      );
    } catch (e) {
      print('Error getting downloads: $e');
      return [];
    }
  }

  Future<bool> deleteDownload(String id) async {
    try {
      final db = await database;

      // Get local path
      final downloads = await db.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (downloads.isNotEmpty) {
        final localPath = downloads.first['local_path'] as String;
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from database
      await db.delete(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );

      return true;
    } catch (e) {
      print('Error deleting download: $e');
      return false;
    }
  }

  /// Get downloads from localStorage (web only)
  Future<List<Map<String, dynamic>>> _getDownloadsWeb() async {
    if (!kIsWeb) return [];

    try {
      final downloadsJson = html.window.localStorage['cnt_downloads'] ?? '[]';
      if (downloadsJson.isEmpty) return [];

      final List<dynamic> downloadsList =
          convert.jsonDecode(downloadsJson) as List;
      return downloadsList.map((d) => d as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error reading downloads from localStorage: $e');
      return [];
    }
  }

  Future<String?> getLocalPath(String id) async {
    try {
      if (kIsWeb) {
        // Web: return audio_url from localStorage
        final downloads = await _getDownloadsWeb();
        final download = downloads.firstWhere(
          (d) => d['id'] == id,
          orElse: () => <String, dynamic>{},
        );
        return download['audio_url'] as String?;
      } else {
        final db = await database;
        final downloads = await db.query(
          'downloads',
          where: 'id = ?',
          whereArgs: [id],
          columns: ['local_path'],
        );

        if (downloads.isNotEmpty) {
          final localPath = downloads.first['local_path'] as String;
          final file = File(localPath);
          if (await file.exists()) {
            return localPath;
          }
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> isDownloaded(String id) async {
    try {
      if (kIsWeb) {
        final downloads = await _getDownloadsWeb();
        return downloads.any((d) => d['id'] == id);
      } else {
        final db = await database;
        final downloads = await db.query(
          'downloads',
          where: 'id = ?',
          whereArgs: [id],
        );
        return downloads.isNotEmpty;
      }
    } catch (e) {
      return false;
    }
  }
}
