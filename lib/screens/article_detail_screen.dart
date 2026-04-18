import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Post postSummary;

  const ArticleDetailScreen({Key? key, required this.postSummary}) : super(key: key);

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ApiService _apiService = ApiService();
  Post? _fullPost;
  bool _isLoading = true;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _loadPostDetail();
  }

  Future<void> _loadPostDetail() async {
    final post = await _apiService.fetchPostDetail(widget.postSummary.id);
    if (mounted) {
      setState(() {
        _fullPost = post;
        _isLoading = false;
        _isFav = _apiService.isFavorite(widget.postSummary.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _isLoading ? _buildLoading() : _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading ? null : _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.blue[900],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'post_image_${widget.postSummary.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: widget.postSummary.image,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black38, Colors.transparent, Colors.black54],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => Share.share('${widget.postSummary.title}\nhttps://kinantouch.com/posts/${widget.postSummary.id}'),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 400,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent() {
    if (_fullPost == null) {
      return const Center(child: Padding(padding: EdgeInsets.all(50), child: Text('فشل في تحميل المحتوى')));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
            child: Text(
              _fullPost!.category,
              style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _fullPost!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(_fullPost!.date, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Divider(height: 40),
          HtmlWidget(
            _fullPost!.content,
            textStyle: const TextStyle(fontSize: 18, height: 1.7, color: Colors.black87),
            onTapUrl: (url) async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return true;
              }
              return false;
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border, color: _isFav ? Colors.red : Colors.grey),
              onPressed: () async {
                await _apiService.toggleFavorite(_fullPost!);
                setState(() {
                  _isFav = !_isFav;
                });
              },
            ),
            ElevatedButton.icon(
              onPressed: () => Share.share('شاهد هذا المقال الممتع: ${widget.postSummary.title}'),
              icon: const Icon(Icons.share),
              label: const Text('مشاركة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
