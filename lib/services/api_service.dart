import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/post.dart';
import '../models/category.dart';

class ApiService {
  // Update with the actual CDN link when deployed
  static const String baseUrl = 'https://cdn.jsdelivr.net/gh/kinanmjeed88/kinantouch.com.apk@main';
  
  static const String postsBoxName = 'posts_cache';
  static const String categoriesBoxName = 'categories_cache';
  static const String favoritesBoxName = 'favorites';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(postsBoxName);
    await Hive.openBox(categoriesBoxName);
    await Hive.openBox(favoritesBoxName);
  }

  Future<List<Category>> fetchCategories() async {
    final box = Hive.box(categoriesBoxName);
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories.json')).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        await box.put('all', response.body);
        return data.map((d) => Category.fromJson(d)).toList();
      }
    } catch (e) {
      print('Categories network error: $e');
    }

    final cached = box.get('all');
    if (cached != null) {
      final List data = json.decode(cached);
      return data.map((d) => Category.fromJson(d)).toList();
    }
    return [];
  }

  Future<List<Post>> fetchPostsSummary() async {
    final box = Hive.box(postsBoxName);
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts.json')).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        await box.put('summary_list', response.body);
        return data.map((d) => Post.fromJson(d)).toList();
      }
    } catch (e) {
      print('Posts summary network error: $e');
    }

    final cached = box.get('summary_list');
    if (cached != null) {
      final List data = json.decode(cached);
      return data.map((d) => Post.fromJson(d)).toList();
    }
    return [];
  }

  Future<Post?> fetchPostDetail(String id) async {
    final box = Hive.box(postsBoxName);
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$id.json')).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        await box.put('post_$id', response.body);
        return Post.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Post detail error ($id): $e');
    }

    final cached = box.get('post_$id');
    if (cached != null) {
      return Post.fromJson(json.decode(cached));
    }
    return null;
  }

  // Favorites logic
  bool isFavorite(String id) {
    return Hive.box(favoritesBoxName).containsKey(id);
  }

  Future<void> toggleFavorite(Post post) async {
    final box = Hive.box(favoritesBoxName);
    if (box.containsKey(post.id)) {
      await box.delete(post.id);
    } else {
      await box.put(post.id, json.encode(post.toJson()));
    }
  }

  List<Post> getFavorites() {
    final box = Hive.box(favoritesBoxName);
    return box.values.map((v) => Post.fromJson(json.decode(v))).toList();
  }
}
