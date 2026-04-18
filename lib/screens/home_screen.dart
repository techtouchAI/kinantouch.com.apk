import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'article_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Post> _allPosts = [];
  List<Post> _displayPosts = [];
  List<Category> _categories = [];
  String _selectedCategoryId = 'all';
  bool _isLoading = true;
  String _searchQuery = '';
  int _perPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _apiService.init();
    await _loadContent();
  }

  Future<void> _loadContent() async {
    final results = await Future.wait([
      _apiService.fetchCategories(),
      _apiService.fetchPostsSummary(),
    ]);

    if (mounted) {
      setState(() {
        _categories = results[0] as List<Category>;
        _allPosts = results[1] as List<Post>;
        _currentPage = 1;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Post> filtered = _allPosts.where((post) {
      final matchesCategory = _selectedCategoryId == 'all' || post.category == _selectedCategoryId;
      final matchesSearch = post.title.contains(_searchQuery) || post.summary.contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    setState(() {
      _displayPosts = filtered.take(_currentPage * _perPage).toList();
    });
  }

  void _loadMore() {
    setState(() {
      _currentPage++;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildCategoryBar(),
          ),
          _isLoading ? _buildSliverLoading() : _buildSliverPostList(),
          if (!_isLoading && _displayPosts.length < _allPosts.length && _searchQuery.isEmpty && _selectedCategoryId == 'all')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text('تحميل المزيد', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'كينان تاتش',
          style: TextStyle(
            color: Colors.blue[900],
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: () => _showSearchDialog(),
        ),
      ],
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ابحث عن أي شيء...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final catId = isAll ? 'all' : _categories[index - 1].id;
          final catName = isAll ? 'الكل' : _categories[index - 1].name;
          final isSelected = _selectedCategoryId == catId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(catName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryId = catId;
                  _applyFilters();
                });
              },
              selectedColor: Colors.blue[600],
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverPostList() {
    if (_displayPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(50), child: Text('لا يوجد محتوى متوفر'))),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = _displayPosts[index];
            return _buildPostCard(post);
          },
          childCount: _displayPosts.length,
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArticleDetailScreen(postSummary: post)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.image,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            post.category.toUpperCase(),
                            style: TextStyle(color: Colors.blue[800], fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(post.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.summary,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverLoading() {
    return SliverPadding(
      padding: const EdgeInsets.all(12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 280,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
          ),
          childCount: 3,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('كينان تاتش', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text('kinantouch.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
            decoration: BoxDecoration(color: Colors.blue[900]),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('الرئيسية'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('المفضلة'),
            onTap: () {
              // TODO: Implement Favorites Screen
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(FontAwesomeIcons.globe),
            title: const Text('الموقع الرسمي'),
            onTap: () => _launchURL('https://kinantouch.com'),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('إصدار 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
