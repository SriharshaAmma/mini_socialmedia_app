import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/generated_classes.dart';

part 'feed_repository.g.dart';

@riverpod
class FeedRepository extends _$FeedRepository {
  @override
  Future<List<Posts>> build() async {
    final client = Supabase.instance.client;

    final response = await client
        .from('posts')
        .select('id, caption, image_url, created_at, user_id, profiles(*)')
        .order('created_at', ascending: false);

    return (response as List).map((item) => Posts.fromJson(item)).toList();
  }
}
