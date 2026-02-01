import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// User-friendly error messages
class ErrorMessages {
  static const String supportEmail = 'kynora.studio@gmail.com';
  
  // Error code to friendly message mapping
  static String getFriendlyMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    // Network errors
    if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('connection')) {
      return 'İnternet bağlantısı bulunamadı. Offline modunda oynayabilirsin!';
    }
    
    // Purchase errors
    if (errorStr.contains('purchase') || errorStr.contains('payment') || errorStr.contains('billing')) {
      return 'Ödeme alınamadı. Lütfen tekrar dene veya "Satın Alımları Geri Yükle" seçeneğini kullan.';
    }
    
    // Storage errors
    if (errorStr.contains('storage') || errorStr.contains('disk') || errorStr.contains('space')) {
      return 'Depolama alanı yetersiz. Biraz yer açar mısın?';
    }
    
    // Auth errors
    if (errorStr.contains('auth') || errorStr.contains('login') || errorStr.contains('credential')) {
      return 'Giriş yapılamadı. Lütfen tekrar dene.';
    }
    
    // Timeout
    if (errorStr.contains('timeout')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar dene.';
    }
    
    // Generic fallback
    return 'Hay aksi! Bir şeyler ters gitti. Oyunu yeniden başlatmayı dener misin?';
  }
  
  /// Show error dialog with friendly message
  static Future<void> showErrorDialog(BuildContext context, dynamic error, {VoidCallback? onRetry}) async {
    final message = getFriendlyMessage(error);
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 10),
            Text('Oops!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onRetry();
              },
              child: const Text('Tekrar Dene', style: TextStyle(color: Colors.cyanAccent)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SupportManager.openHelp(context);
            },
            child: const Text('Yardım', style: TextStyle(color: Colors.purpleAccent)),
          ),
        ],
      ),
    );
  }
}

/// FAQ entries
class FAQEntry {
  final String question;
  final String answer;
  
  const FAQEntry(this.question, this.answer);
}

/// Support and Help system
class SupportManager {
  static const String supportEmail = 'kynora.studio@gmail.com';
  static const String privacyUrl = 'https://prismaze.app/privacy';
  static const String termsUrl = 'https://prismaze.app/terms';
  
  static const List<FAQEntry> faqEntries = [
    FAQEntry(
      'Progresim kayboldu, ne yapmalıyım?',
      'Ayarlar > Veri & Bulut > "Geri Yükle" butonuna tıkla. Cloud hesabın varsa veriler geri gelecektir.',
    ),
    FAQEntry(
      'Satın aldığım jeton görünmüyor.',
      'Ayarlar > Veri & Bulut > "Satın Alımları Geri Yükle" seçeneğini dene. Sorun devam ederse destek ekibimize ulaş.',
    ),
    FAQEntry(
      'Oyun dondu/takıldı.',
      'Oyunu tamamen kapatıp yeniden aç. Sorun devam ederse "Sorun Bildir" butonuyla bize bildir.',
    ),
    FAQEntry(
      'Reklam kapanmıyor.',
      'Genellikle reklamlar 5 saniye sonra kapatılabilir olur. "X" butonu görünmezse uygulamayı yeniden başlat.',
    ),
    FAQEntry(
      'İpucu jetonlarım neden azaldı?',
      'Her ipucu kullanımı 1 jeton harcar. Daha fazla jeton için günlük görevleri tamamla veya mağazadan satın al.',
    ),
    FAQEntry(
      'Offline oynayabilir miyim?',
      'Evet! Temel oyun tamamen offline çalışır. Bulut senkronizasyonu ve satın almalar için internet gerekir.',
    ),
    FAQEntry(
      'Hesabımı nasıl silerim?',
      'Ayarlar > Gizlilik > "Verilerimi Sil" butonuna tıkla. Bu işlem geri alınamaz.',
    ),
  ];
  
  /// Open Help/FAQ screen
  static void openHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HelpScreen()),
    );
  }
  
  /// Send bug report via email
  static Future<void> sendBugReport({
    required String description,
    String? deviceInfo,
    String? logs,
  }) async {
    final subject = Uri.encodeComponent('PrisMaze Bug Report');
    final body = Uri.encodeComponent('''
Açıklama:
$description

Cihaz Bilgisi:
${deviceInfo ?? 'Bilinmiyor'}

${logs != null ? 'Log:\n$logs' : ''}
''');
    
    final uri = Uri.parse('mailto:$supportEmail?subject=$subject&body=$body');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
  
  /// Get device info string
  static Future<String> getDeviceInfo() async {
    final info = StringBuffer();
    if (kIsWeb) {
      info.writeln('Platform: Web');
      info.writeln('UserAgent: Browser'); 
    } else {
      info.writeln('Platform: ${Platform.operatingSystem}');
      info.writeln('Version: ${Platform.operatingSystemVersion}');
      info.writeln('Locale: ${Platform.localeName}');
    }
    return info.toString();
  }
}

/// Help/FAQ Screen
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Yardım & Destek'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            _buildQuickActions(context),
            
            const SizedBox(height: 30),
            
            // FAQ Section
            const Text(
              'Sıkça Sorulan Sorular',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            ...SupportManager.faqEntries.map((faq) => _buildFAQItem(faq)),
            
            const SizedBox(height: 30),
            
            // Contact Section
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.bug_report,
            label: 'Sorun Bildir',
            color: Colors.redAccent,
            onTap: () => _showBugReportDialog(context),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionCard(
            icon: Icons.email,
            label: 'Email Gönder',
            color: Colors.blueAccent,
            onTap: () => SupportManager.sendBugReport(description: ''),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFAQItem(FAQEntry faq) {
    return ExpansionTile(
      title: Text(faq.question, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      iconColor: Colors.cyanAccent,
      collapsedIconColor: Colors.white38,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Text(faq.answer, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
      ],
    );
  }
  
  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent, color: Colors.purpleAccent, size: 40),
          const SizedBox(height: 10),
          const Text('Hala yardıma mı ihtiyacın var?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(
            'Email: ${SupportManager.supportEmail}',
            style: const TextStyle(color: Colors.cyanAccent),
          ),
          const SizedBox(height: 5),
          const Text(
            'Ortalama yanıt süresi: 24 saat',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  void _showBugReportDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A2E),
        title: const Text('Sorun Bildir', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sorunu detaylı açıkla. Cihaz bilgilerin otomatik eklenir.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Sorunu açıkla...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deviceInfo = await SupportManager.getDeviceInfo();
              await SupportManager.sendBugReport(
                description: controller.text,
                deviceInfo: deviceInfo,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }
}

