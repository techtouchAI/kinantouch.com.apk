import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AccountFinderApp());
}

class AccountFinderApp extends StatelessWidget {
  const AccountFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.tajawalTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.system,
      home: const AccountFinderHome(),
    );
  }
}

class PlatformConfig {
  final String name;
  final Color color;
  final IconData icon;
  final FaIconData? faIcon;
  final String? Function(String) linkTemplate;
  final bool isNumberOnly;
  final bool alwaysShow;

  PlatformConfig({
    required this.name,
    required this.color,
    required this.icon,
    this.faIcon,
    required this.linkTemplate,
    this.isNumberOnly = false,
    this.alwaysShow = false,
  });
}

class AccountFinderHome extends StatefulWidget {
  const AccountFinderHome({super.key});

  @override
  State<AccountFinderHome> createState() => _AccountFinderHomeState();
}

class _AccountFinderHomeState extends State<AccountFinderHome> {
  final TextEditingController _controller = TextEditingController();
  List<String> _history = [];
  final List<PlatformConfig> _platforms = [
    PlatformConfig(
      name: 'WhatsApp',
      color: const Color(0xFF25D366),
      icon: Icons.chat,
      faIcon: FontAwesomeIcons.whatsapp,
      linkTemplate: (value) => 'https://wa.me/${value.replaceAll(RegExp(r'\s+'), '')}',
      isNumberOnly: true,
    ),
    PlatformConfig(
      name: 'Telegram',
      color: const Color(0xFF0088cc),
      icon: Icons.send,
      faIcon: FontAwesomeIcons.telegram,
      linkTemplate: (value) => 'tg://resolve?domain=$value',
    ),
    PlatformConfig(
      name: 'Instagram',
      color: const Color(0xFFE1306C),
      icon: Icons.camera_alt,
      faIcon: FontAwesomeIcons.instagram,
      linkTemplate: (value) => 'instagram://user?username=$value',
    ),
    PlatformConfig(
      name: 'Facebook',
      color: const Color(0xFF1877F2),
      icon: Icons.facebook,
      faIcon: FontAwesomeIcons.facebook,
      linkTemplate: (value) => 'fb://profile/$value',
    ),
    PlatformConfig(
      name: 'Twitter (X)',
      color: Colors.black,
      icon: Icons.close,
      faIcon: FontAwesomeIcons.xTwitter,
      linkTemplate: (value) => 'twitter://user?screen_name=$value',
    ),
    PlatformConfig(
      name: 'TikTok',
      color: Colors.black,
      icon: Icons.music_note,
      faIcon: FontAwesomeIcons.tiktok,
      linkTemplate: (value) => 'https://www.tiktok.com/@$value',
    ),
    PlatformConfig(
      name: 'Snapchat',
      color: const Color(0xFFFFCB00),
      icon: Icons.snapchat,
      faIcon: FontAwesomeIcons.snapchat,
      linkTemplate: (value) => 'snapchat://add/$value',
    ),
    PlatformConfig(
      name: 'Truecaller',
      color: const Color(0xFF0087FF),
      icon: Icons.phone,
      faIcon: FontAwesomeIcons.phone,
      linkTemplate: (value) => 'truecaller://search?q=$value',
      isNumberOnly: true,
    ),
    PlatformConfig(
      name: 'بحث جوجل',
      color: Colors.grey,
      icon: Icons.search,
      faIcon: FontAwesomeIcons.google,
      linkTemplate: (value) => 'https://www.google.com/search?q=${Uri.encodeComponent(value)}',
      alwaysShow: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList('searchHistory') ?? [];
    });
  }

  Future<void> _saveToHistory(String value) async {
    if (value.length < 3) return;
    final prefs = await SharedPreferences.getInstance();
    _history.remove(value);
    _history.insert(0, value);
    if (_history.length > 20) _history.removeLast();
    await prefs.setStringList('searchHistory', _history);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    setState(() {
      _history = [];
    });
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الرابط: $url')),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم النسخ إلى الحافظة')),
    );
  }

  bool _isPotentialNumber(String value) {
    return RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value.replaceAll(RegExp(r'\s+'), ''));
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text.trim();
    final isNumber = _isPotentialNumber(value);
    final showResults = value.length >= 3;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'البحث عن حسابات التواصل',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                onChanged: (val) => setState(() {}),
                onSubmitted: (val) {
                  if (val.length >= 3) _saveToHistory(val);
                },
                decoration: InputDecoration(
                  hintText: 'أدخل رقم هاتف أو اسم مستخدم...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),
              if (showResults) ...[
                ..._platforms.where((p) {
                  if (p.alwaysShow) return true;
                  if (p.isNumberOnly) return isNumber;
                  return !isNumber;
                }).map((platform) {
                  final link = platform.linkTemplate(value);
                  final FaIconData? faIconData = platform.faIcon;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _saveToHistory(value);
                              if (link != null) _launchURL(link);
                            },
                            icon: faIconData != null
                                ? FaIcon(faIconData, color: Colors.white)
                                : Icon(platform.icon, color: Colors.white),
                            label: Text(
                              'فتح ${platform.name}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: platform.color,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _copyToClipboard(link ?? ''),
                          icon: const Icon(Icons.copy),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                const Text(
                  'ملاحظة: محاولة فتح التطبيق قد توجهك للمتجر إذا لم يكن التطبيق مثبتاً.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'عمليات البحث السابقة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: _clearHistory,
                          child: const Text('مسح السجل', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('لا يوجد سجل بحث حالياً.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_history[index]),
                            onTap: () {
                              _controller.text = _history[index];
                              setState(() {});
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تذكر: استخدام هذه الأداة للبحث عن معلومات الآخرين يجب أن يتم بمسؤولية واحترام للخصوصية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
