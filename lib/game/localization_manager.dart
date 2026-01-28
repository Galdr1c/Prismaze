import 'package:flutter/foundation.dart';
import 'settings_manager.dart';

class LocalizationManager {
  // Singleton
  static final LocalizationManager _instance = LocalizationManager._internal();
  factory LocalizationManager() => _instance;
  LocalizationManager._internal();

  String _languageCode = 'tr'; // Default

  Future<void> init() async {
      // Load from Settings
      final sm = SettingsManager();
      await sm.init();
      _languageCode = sm.languageCode;
  }

  void setLanguage(String code) {
      _languageCode = code;
      // Ideally notify listeners or reload UI. 
      // Since this is a simple implementation, mostly requires restart or SetState in root.
      // SettingsManager update expected elsewhere.
  }
  
  bool get isRTL => _languageCode == 'ar' || _languageCode == 'he' || _languageCode == 'fa';

  String getString(String key) {
      if (_localizedValues.containsKey(key)) {
          return _localizedValues[key]![_languageCode] ?? _localizedValues[key]!['en'] ?? key;
      }
      return key; // Fallback to key if missing
  }

  String getStringParam(String key, Map<String, String> params) {
    String text = getString(key);
    params.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
    return text;
  }

  // Dictionary
  static final Map<String, Map<String, String>> _localizedValues = {
      // --- GENERAL ---
      'app_title': {'tr': 'PRISMAZE', 'en': 'PRISMAZE'},
      'loading': {'tr': 'Yükleniyor...', 'en': 'Loading...'},
      'close': {'tr': 'KAPAT', 'en': 'CLOSE'},
      'btn_close': {'tr': 'KAPAT', 'en': 'CLOSE'},
      'continue': {'tr': 'DEVAM ET', 'en': 'CONTINUE'},
      'levels': {'tr': 'BÖLÜMLER', 'en': 'LEVELS'},
      'endless_mode': {'tr': 'SONSUZ MOD', 'en': 'ENDLESS MODE'},
      'last_played': {'tr': 'SON OYNANAN', 'en': 'LAST PLAYED'},
      'splash_subtitle': {'tr': 'Işığı yönlendir, hedefi aydınlat!', 'en': 'Guide the light, illuminate the target!'},
      'tap_to_start': {'tr': 'Başlamak için dokun', 'en': 'Tap to start'},
            
      // --- CAMPAIGN EPISODES ---
      'ep_1_title': {'tr': 'Başlangıç Işıkları', 'en': 'Beginning Lights'},
      'ep_1_desc': {'tr': 'Temel mekanikler', 'en': 'Basic mechanics'},
      
      'ep_2_title': {'tr': 'Renk Spektrumu', 'en': 'Color Spectrum'},
      'ep_2_desc': {'tr': 'Basit bulmacalar', 'en': 'Simple puzzles'},
      
      'ep_3_title': {'tr': 'Karışım Ustası', 'en': 'Mix Master'},
      'ep_3_desc': {'tr': 'Renk karıştırma', 'en': 'Color mixing'},
      
      'ep_4_title': {'tr': 'Kristal Labirent', 'en': 'Crystal Labyrinth'},
      'ep_4_desc': {'tr': 'Karmaşık yollar', 'en': 'Complex routing'},
      
      'ep_5_title': {'tr': 'Zamanın Ötesi', 'en': 'Beyond Time'},
      'ep_5_desc': {'tr': 'Usta işi bulmacalar', 'en': 'Master puzzles'},
      
      // --- MENU BOTTOM ---
      'menu_customize': {'tr': 'KİŞİSEL', 'en': 'CUSTOMIZE'},
      'menu_mission': {'tr': 'GÖREV', 'en': 'MISSIONS'},
      'menu_achievements': {'tr': 'BAŞARIM', 'en': 'TROPHIES'},
      'menu_store': {'tr': 'MAĞAZA', 'en': 'STORE'},
      'menu_about': {'tr': 'HAKKINDA', 'en': 'ABOUT'},
      'menu_stats': {'tr': 'İSTATİSTİK', 'en': 'STATS'},
      
      // --- SETTINGS ---
      'settings_title': {'tr': 'AYARLAR', 'en': 'SETTINGS'},
      
      // --- STATISTICS ---
      'stat_title': {'tr': 'İSTATİSTİKLER', 'en': 'STATISTICS'},
      'stat_personal': {'tr': 'Kişisel Veriler', 'en': 'Personal Data'},
      'stat_playtime': {'tr': 'Toplam Süre', 'en': 'Play Time'},
      'stat_completed': {'tr': 'Tamamlanan', 'en': 'Completed'},
      'stat_3stars': {'tr': '3 Yıldız', 'en': '3 Stars'},
      'stat_fastest': {'tr': 'En Hızlı', 'en': 'Fastest'},
      'stat_hints': {'tr': 'İpucu', 'en': 'Hints Used'},
      'stat_tokens': {'tr': 'Toplam İpucu', 'en': 'Total Hints'},
      'stat_weekly': {'tr': 'Haftalık Aktivite', 'en': 'Weekly Activity'},
      'stat_distribution': {'tr': 'Başarım Dağılımı', 'en': 'Achievement Distribution'},
      'settings_music': {'tr': 'MÜZİK', 'en': 'MUSIC'},
      'settings_sfx': {'tr': 'SES EFEKT', 'en': 'SFX'},
      'settings_vibration': {'tr': 'TİTREŞİM', 'en': 'HAPTICS'},
      'settings_language': {'tr': 'DİL', 'en': 'LANGUAGE'},
      
      // --- GAME HUD ---
      'episode_prefix': {'tr': 'BÖLÜM', 'en': 'EPISODE'},
      'level_prefix': {'tr': 'SEVİYE', 'en': 'LEVEL'},
      'target_current': {'tr': 'Hedef / Mevcut', 'en': 'Par / Current'}, // Note: UI uses "99 / 5" format, maybe no label needed
      'btn_restart': {'tr': 'Yeniden Başlat', 'en': 'Restart'},
      'btn_undo': {'tr': 'Geri Al', 'en': 'Undo'},
      'btn_speed': {'tr': 'Hızlandır', 'en': 'Speed Up'},
      'btn_skip': {'tr': 'ATLA', 'en': 'SKIP'},
      
      // --- TUTORIALS ---
      'tut_lvl_1': {'tr': 'Aynayı sürükle ve döndür', 'en': 'Drag and rotate the mirror'},
      'tut_lvl_2': {'tr': 'Işığı kırarak hedefe ulaştır', 'en': 'Refract light to the target'},
      'tut_lvl_3': {'tr': 'Kırmızı ışığı kırmızı hedefe ulaştır', 'en': 'Match red light to red target'},
      'tut_lvl_4': {'tr': 'Takıldığında ipucu kullanabilirsin! (+3 Hediye)', 'en': 'Stuck? Use a hint! (+3 Gift)'},
      'hint_prompt': {'tr': 'İpucu için 💡\'a dokun!', 'en': 'Tap 💡 for a Hint!'},
      
      // --- TIPS ---
      'tip_15': {'tr': 'İpucu: Işığı duvardan sektirebilirsin!', 'en': 'Tip: You can bounce light off walls!'},
      'tip_35': {'tr': 'Taktik: Önce hedefleri planla, sonra başla', 'en': 'Tactic: Plan targets before starting.'},
      'tip_60': {'tr': 'Bilgi: İki ışın birleşince renk karışır', 'en': 'Info: Merging beams mixes colors.'},
      'tip_85': {'tr': 'Trick: Hareketli prizmaların zamanlamasını izle', 'en': 'Trick: Watch the timing of moving prisms.'},
      
      // --- ACHIEVEMENTS (Refactored Keys) ---
      // Keys used in backend: 'ach_first_light', 'ach_quick_thinker', etc.
      'ach_first_light': {'tr': 'İlk Işık', 'en': 'First Light'},
      'ach_desc_first_light': {'tr': 'Level 1\'i tamamla', 'en': 'Complete Level 1'},
      
      'ach_quick_thinker': {'tr': 'Hızlı Düşünür', 'en': 'Quick Thinker'},
      'ach_desc_quick_thinker': {'tr': '10 saniyede bitir', 'en': 'Finish in 10s'},
      
      'ach_perfectionist': {'tr': 'Mükemmelliyetçi', 'en': 'Perfectionist'},
      'ach_desc_perfectionist': {'tr': 'Arka arkaya 5 kez 3 yıldız', 'en': '5 consecutive 3-stars'},
      
      'ach_patient': {'tr': 'Sabırlı', 'en': 'Patient'},
      'ach_desc_patient': {'tr': 'İpucu kullanmadan 20 level', 'en': '20 levels without hints'},
      
      'ach_light_apprentice': {'tr': 'Işık Çırağı', 'en': 'Light Apprentice'},
      'ach_desc_light_apprentice': {'tr': '100 Level tamamla', 'en': 'Complete 100 Levels'},
      
      'ach_light_master': {'tr': 'Işık Ustası', 'en': 'Light Master'},
      
      'ach_darkness': {'tr': 'Karanlıkta Işık', 'en': 'Light in the Dark'},
      'ach_desc_darkness': {'tr': 'Ayarlar kapalıyken kazan', 'en': 'Win with settings off'},
      
      'ach_minimalist': {'tr': 'Minimalist', 'en': 'Minimalist'},
      'ach_desc_minimalist': {'tr': 'Tek hamlede bitir', 'en': 'Finish in 1 move'},
      
      'ach_one_shot_master': {'tr': 'Tek Atış Ustası', 'en': 'One-Shot Master'},
      'ach_desc_one_shot_master': {'tr': '5 seviyeyi tek hamlede tamamla', 'en': 'Complete 5 levels in 1 move'},
      
      'ach_lucky_7': {'tr': 'Şanslı 7', 'en': 'Lucky 7'},
      'ach_night_owl': {'tr': 'Gece Kuşu', 'en': 'Night Owl'},
      'ach_patience_stone': {'tr': 'Sabır Taşı', 'en': 'Stone of Patience'},
      
      // Category Tiers
      'ach_speed_1': {'tr': 'Hız I (5 Level)', 'en': 'Speed I (5 Levels)'},
      'ach_speed_master': {'tr': 'Hız Ustası', 'en': 'Speed Master'},
      
      'ach_perfect_1': {'tr': 'Mükemmellik I', 'en': 'Perfection I'},
      'ach_perfect_master': {'tr': 'Mükemmellik Ustası', 'en': 'Perfection Master'},
      
      'ach_marathon_1': {'tr': 'Maraton I', 'en': 'Marathon I'},
      'ach_marathon_master': {'tr': 'Maraton Ustası', 'en': 'Marathon Master'},
      
      'ach_independent_1': {'tr': 'Bağımsız I', 'en': 'Independent I'},
      'ach_independent_master': {'tr': 'Bağımsız Ustası', 'en': 'Independent Master'},
      
      'ach_legend': {'tr': 'Prizma Efsanesi', 'en': 'Prisma Legend'},
      
      // New Achievements
      'ach_warmup': {'tr': 'Isınma Turları', 'en': 'Warm Up'},
      'ach_desc_warmup': {'tr': 'Tek oturuşta 3 level bitir', 'en': 'Complete 3 levels in one session'},
      
      'ach_focused': {'tr': 'Odaklanmış', 'en': 'Focused'},
      'ach_desc_focused': {'tr': 'Tek oturuşta 50 level bitir', 'en': 'Complete 50 levels in one session'},
      
      'ach_self_starter': {'tr': 'Kendi Halinde', 'en': 'Self Starter'},
      'ach_desc_self_starter': {'tr': '5 level ipucu kullanmadan', 'en': '5 levels without hints'},
      
      'ach_problem_solver': {'tr': 'Bulmaca Çözücü', 'en': 'Problem Solver'},
      'ach_desc_problem_solver': {'tr': '50 level ipucu kullanmadan', 'en': '50 levels without hints'},
      
      'ach_star_hunter': {'tr': 'Yıldız Avcısı', 'en': 'Star Hunter'},
      'ach_desc_star_hunter': {'tr': 'Toplam 50 yıldız topla', 'en': 'Collect 50 stars total'},
      
      'ach_clean_sweep': {'tr': 'Tam Temizlik', 'en': 'Clean Sweep'},
      'ach_desc_clean_sweep': {'tr': 'Bir bölümü full 3 yıldızla bitir', 'en': 'Complete a chapter with all 3 stars'},

      // --- VIDEOS ---
      'vid_welcome': {'tr': 'Prismaze\'e Hoş Geldin', 'en': 'Welcome to Prismaze'},
      'vid_mixing': {'tr': 'Renk Karıştırma Rehberi', 'en': 'Color Mixing Guide'},
      'vid_tactics': {'tr': 'İleri Seviye Taktikler', 'en': 'Advanced Tactics'},
      'vid_continue': {'tr': 'Devam Et (+5 İpucu)', 'en': 'Continue (+5 Hints)'},
      'vid_playing': {'tr': 'Oynatılıyor...', 'en': 'Playing...'},
      
      // --- STATISTICS ---
      'stat_title': {'tr': 'İstatistikler', 'en': 'Statistics'},
      'stat_playtime': {'tr': 'Toplam Süre', 'en': 'Total Time'},
      'stat_completed': {'tr': 'Tamamlanan', 'en': 'Completed'},
      'stat_3stars': {'tr': '3 Yıldız', 'en': '3 Stars'},
      'stat_fastest': {'tr': 'En Hızlı', 'en': 'Fastest'},
      'stat_hints': {'tr': 'İpucu', 'en': 'Hints'},
      'stat_weekly': {'tr': 'Haftalık Aktivite', 'en': 'Weekly Activity'},
      'stat_distribution': {'tr': 'Başarım Dağılımı', 'en': 'Achievement Distribution'},
      'stat_personal': {'tr': 'Kişisel Veriler', 'en': 'Personal Data'},
      
      // --- NOTIFICATIONS ---
      'notif_1d_title': {'tr': 'Işıklar seni bekliyor! 🌟', 'en': 'Lights await you! 🌟'},
      'notif_1d_body': {'tr': 'Prismaze\'e dön ve ışığı yönet.', 'en': 'Return to Prismaze and guide the light.'},
      
      'notif_3d_title': {'tr': 'Hediye İpuçları! 💡', 'en': 'Gift Hints! 💡'},
      'notif_3d_body': {'tr': '3 ücretsiz ipucu seni bekliyor. Hemen al!', 'en': '3 free hints waiting. Claim now!'},
      
      'notif_7d_title': {'tr': 'Yeni Bölümler! 🎮', 'en': 'New Levels! 🎮'},
      'notif_7d_body': {'tr': 'Sınırlarını zorlayacak yeni bulmacalar geldi.', 'en': 'New puzzles to test your limits arrived.'},
      
      'notif_daily_title': {'tr': 'Günlük Görev Hazır 🎁', 'en': 'Daily Mission Ready 🎁'},
      'notif_daily_body': {'tr': 'Tamamla ve 5 ipucu kazan!', 'en': 'Complete and earn 5 hints!'},
      
      'notif_bonus_reset': {'tr': 'Bonus Sıfırlanıyor! ⏰', 'en': 'Bonus Resetting! ⏰'},
      'notif_bonus_body': {'tr': 'Günlük bonusun 2 saat içinde yanacak.', 'en': 'Daily bonus expires in 2 hours.'},
      
      'notif_event_winter': {'tr': 'Kış Kristalleri! ❄️', 'en': 'Winter Crystals! ❄️'},
      'notif_skin_limited': {'tr': 'Sınırlı Süreli Skin! 🔥', 'en': 'Limited Time Skin! 🔥'},
      
      // --- SETTINGS OVERLAY ---
      'settings_section_audio': {'tr': 'Ses & Müzik', 'en': 'Audio & Music'},
      'settings_section_gameplay': {'tr': 'Oynanış', 'en': 'Gameplay'},
      'settings_section_accessibility': {'tr': 'Erişilebilirlik', 'en': 'Accessibility'},
      'settings_section_notifications': {'tr': 'Bildirimler', 'en': 'Notifications'},
      'settings_section_data': {'tr': 'Veri Yönetimi', 'en': 'Data Management'},
      'settings_section_language': {'tr': 'Dil', 'en': 'Language'},
      'settings_about': {'tr': 'Hakkında', 'en': 'About'},
      
      'settings_audio_master': {'tr': 'Ana Ses', 'en': 'Master Volume'},
      'settings_audio_music': {'tr': 'Müzik', 'en': 'Music'},
      'settings_audio_sfx': {'tr': 'Efektler', 'en': 'SFX'},
      'settings_audio_ambient': {'tr': 'Ortam', 'en': 'Ambient'},
      'settings_audio_voice': {'tr': 'Ses (Tutorial)', 'en': 'Voice (Tutorial)'},
      'settings_audio_mute_all': {'tr': 'Tümünü Kapat', 'en': 'Mute All'},
      
      'settings_gameplay_vibration': {'tr': 'Titreşim', 'en': 'Vibration'},
      
      'vib_off': {'tr': 'Kapalı', 'en': 'Off'},
      'vib_50': {'tr': '%50', 'en': '50%'},
      'vib_100': {'tr': '%100', 'en': '100%'},
      'vib_150': {'tr': '%150', 'en': '150%'},
      
      'settings_acc_colorblind': {'tr': 'Renk Körlüğü', 'en': 'Color Blindness'},
      'settings_acc_big_text': {'tr': 'Büyük Metin (+150%)', 'en': 'Big Text (+150%)'},
      'settings_acc_high_contrast': {'tr': 'Yüksek Kontrast', 'en': 'High Contrast'},
      'settings_acc_reduced_glow': {'tr': 'Azaltılmış Parıltı', 'en': 'Reduced Glow'},
      
      'cb_normal': {'tr': 'Normal', 'en': 'Normal'},
      'cb_deuteranopia': {'tr': 'Deuteranopia', 'en': 'Deuteranopia'},
      'cb_protanopia': {'tr': 'Protanopia', 'en': 'Protanopia'},
      'cb_tritanopia': {'tr': 'Tritanopia', 'en': 'Tritanopia'},

      'preview_primary': {'tr': 'Ana Renk', 'en': 'Primary'},
      'preview_accent': {'tr': 'Vurgu', 'en': 'Accent'},
      'preview_success': {'tr': 'Başarılı', 'en': 'Success'},
      'preview_error': {'tr': 'Hata', 'en': 'Error'},
      
      'settings_settings_data_export': {'tr': 'Verileri İndir', 'en': 'Export Data'},
      'settings_notif_daily': {'tr': 'Günlük Görevler', 'en': 'Daily Tasks'},
      'settings_notif_events': {'tr': 'Etkinlikler', 'en': 'Events'},
      'settings_notif_reminders': {'tr': 'Hatırlatıcılar', 'en': 'Reminders'},
      
      'settings_data_analytics': {'tr': 'Analytics Etkin', 'en': 'Analytics Enabled'},
      'settings_data_ads': {'tr': 'Kişiselleştirilmiş Reklamlar', 'en': 'Personalized Ads'},
      'settings_data_restore': {'tr': 'İlerlemeyi Geri Yükle', 'en': 'Restore Progress'},
      'settings_data_delete_all': {'tr': 'Tüm Verileri Sil', 'en': 'Delete All Data'},
      'settings_data_export': {'tr': 'Verileri İndir', 'en': 'Export Data'},

      'age_gate_title': {'tr': 'Doğum Yılın', 'en': 'Your Birth Year'},
      'age_gate_body': {'tr': 'Yaşını doğrulamak için lütfen doğum yılını seç.', 'en': 'Please select your birth year to verify your age.'},
      'age_gate_continue': {'tr': 'DEVAM ET', 'en': 'CONTINUE'},
      'child_mode_active': {'tr': 'Çocuk Modu Aktif', 'en': 'Child Mode Active'},
      'child_mode_desc': {'tr': 'Kişisel veri toplanmaz.\nKişiselleştirilmiş reklam gösterilmez.', 'en': 'No personal data collected.\nNo personalized ads shown.'},
      
      'dialog_restore_title': {'tr': 'İlerlemeyi Geri Yükle', 'en': 'Restore Progress'},
      'dialog_restore_msg': {'tr': 'Cloud\'dan veri yüklensin mi?', 'en': 'Download data from Cloud?'},
      'btn_restore': {'tr': 'YÜKLE', 'en': 'RESTORE'},
      
      'dialog_delete_title': {'tr': 'Tüm Verileri Sil', 'en': 'Delete All Data'},
      'dialog_delete_msg': {'tr': 'Bu işlem cihazındaki tüm oyun ilerlemesini ve ayarları silecek!\n(Sunucularımızda size ait kişisel veri tutulmamaktadır.)\nEmin misiniz?', 'en': 'This will delete all local game progress and settings!\n(We do not store personal data on our servers.)\nAre you sure?'},
      'btn_delete': {'tr': 'SİL VE SIFIRLA', 'en': 'DELETE & RESET'},
      
      'dialog_final_title': {'tr': 'Son Onay', 'en': 'Final Confirmation'},
      'dialog_final_msg': {'tr': 'Geri dönüşü yoktur!\nCloud yedeği oluşturulsun mu?', 'en': 'There is no going back!\nCreate Cloud backup?'},
      'btn_delete_backup': {'tr': 'SİL VE YEDEKLE', 'en': 'DELETE & BACKUP'},
      'btn_cancel': {'tr': 'İPTAL', 'en': 'CANCEL'},
      
      'language_change_notice': {'tr': 'Dil değişikliği uygulandı. Tam etki için uygulamayı yeniden başlatın.', 'en': 'Language change applied. Restart app for full effect.'},
      
      // --- MISSING UI KEYS ---
      'btn_hint': {'tr': 'İpucu', 'en': 'Hint'},
      'btn_ad_plus_one': {'tr': '+1', 'en': '+1'},
      'msg_no_ad': {'tr': 'Reklam bulunamadı', 'en': 'No ad available'},
      'level_complete_success': {'tr': 'SEVİYE TAMAMLANDI', 'en': 'LEVEL COMPLETE'},
      'level_complete_fail': {'tr': 'BAŞARISIZ', 'en': 'FAILED'},
      'btn_next_level': {'tr': 'SONRAKİ SEVİYE', 'en': 'NEXT LEVEL'},
      'btn_try_again': {'tr': 'TEKRAR DENE', 'en': 'TRY AGAIN'},
      'btn_replay': {'tr': 'TEKRAR', 'en': 'REPLAY'},
      'btn_menu': {'tr': 'MENÜ', 'en': 'MENU'},
      'lbl_moves': {'tr': 'HAMLE', 'en': 'MOVES'},
      'lbl_earnings': {'tr': 'KAZANÇ', 'en': 'EARNINGS'},
      'lbl_tokens': {'tr': ' İPUCU', 'en': ' HINTS'},
      
      // --- ENDLESS MODE ---
      'endless_subtitle': {'tr': 'Prosedürel oluşturulan sonsuz levellar', 'en': 'Procedurally generated endless levels'},
      'stat_highest': {'tr': 'En Yüksek', 'en': 'Highest'},
      'stat_difficulty': {'tr': 'Zorluk', 'en': 'Difficulty'},
      'diff_easy': {'tr': 'Kolay', 'en': 'Easy'},
      'diff_medium': {'tr': 'Orta', 'en': 'Medium'},
      'diff_hard': {'tr': 'Zor', 'en': 'Hard'},
      'diff_expert': {'tr': 'Uzman', 'en': 'Expert'},
      'diff_master': {'tr': 'Usta', 'en': 'Master'},
      'btn_continue_level': {'tr': 'DEVAM ET (Level {0})', 'en': 'CONTINUE (Level {0})'}, // Logic handled in UI
      'btn_start_new': {'tr': 'BAŞTAN BAŞLA', 'en': 'RESTART'},
      'btn_start': {'tr': 'BAŞLA', 'en': 'START'},
      
      // --- DAILY LOGIN ---
      'daily_login_title': {'tr': 'Günlük Giriş', 'en': 'Daily Login'},
      'daily_login_subtitle': {'tr': 'Her gün gir, ödülleri kap!', 'en': 'Log in daily, claim rewards!'},
      'btn_claim': {'tr': 'TOPLA', 'en': 'CLAIM'},
      'msg_claimed': {'tr': 'Toplandı!', 'en': 'Claimed!'},
      'claimed_today': {'tr': 'Bugün alındı', 'en': 'Claimed today'},
      'streak_lost': {'tr': 'SERİ KIRILDI!', 'en': 'STREAK LOST!'},
      'watch_ad': {'tr': 'REKLAM İZLE', 'en': 'WATCH AD'},
      'days': {'tr': 'gün', 'en': 'days'},
      'not_enough_tokens': {'tr': 'Yeterli ipucu yok', 'en': 'Not enough hints'},
      'daily_reward': {'tr': 'GÜNLÜK ÖDÜL', 'en': 'DAILY REWARD'},
      
      // --- DAILY QUESTS SCREEN ---
      'daily_quests_title': {'tr': 'Günlük Görevler', 'en': 'Daily Quests'},
      'refresh_in': {'tr': 'Yenilenme: {hours}s {minutes}dk', 'en': 'Refresh: {hours}h {minutes}m'},
      'section_daily_missions': {'tr': 'GÜNLÜK GÖREVLER', 'en': 'DAILY MISSIONS'},
      'section_limited_event': {'tr': 'SINIRLI SÜRE ETKİNLİK', 'en': 'LIMITED TIME EVENT'},
      'no_active_event': {'tr': 'Şu anda aktif etkinlik yok', 'en': 'No active event right now'},
      'new_events_soon': {'tr': 'Yakında yeni etkinlikler!', 'en': 'New events coming soon!'},
      'days_left': {'tr': '{days} gün kaldı', 'en': '{days} days left'},
      'all_completed': {'tr': 'Tümü Tamamlandı!', 'en': 'All Completed!'},
      'bonus_claimed': {'tr': 'Bonus alındı!', 'en': 'Bonus claimed!'},
      'bonus_reward': {'tr': '+{amount} Bonus', 'en': '+{amount} Bonus'},
      'btn_collect': {'tr': 'AL', 'en': 'COLLECT'},
      
      // Mission Descriptions (Dynamic)
      'mission_playLevels': {'tr': '{target} seviye tamamla', 'en': 'Complete {target} levels'},
      'mission_stars3': {'tr': '{target} seviye 3 yıldızla bitir', 'en': 'Finish {target} levels with 3 stars'},
      'mission_perfectFinish': {'tr': '{target} seviye mükemmel çöz', 'en': 'Solve {target} levels perfectly'},
      'mission_noHint': {'tr': '{target} seviye ipucu kullanmadan bitir', 'en': 'Complete {target} levels without hints'},
      'mission_watchAd': {'tr': '{target} reklam izle', 'en': 'Watch {target} ads'},
      'mission_playTime': {'tr': '{target} dakika oyna', 'en': 'Play for {target} minutes'},
      'mission_undoFree': {'tr': '{target} seviye geri alma kullanmadan bitir', 'en': 'Complete {target} levels without undo'},
      'mission_fastComplete': {'tr': '{target} seviye 30 saniyede bitir', 'en': 'Complete {target} levels under 30s'},
      'mission_exactMoves': {'tr': '{target} seviye tam hamleyle bitir', 'en': 'Finst {target} levels with exact moves'},

      // --- STORE SCREEN ---
      'store_title': {'tr': 'MAĞAZA', 'en': 'STORE'},
      'store_tab_bundles': {'tr': 'Paketler', 'en': 'Bundles'},
      'store_tab_tokens': {'tr': 'İpuçları', 'en': 'Hints'},
      'store_tab_premium': {'tr': 'Premium', 'en': 'Premium'},
      'store_tab_seasonal': {'tr': 'Sezonluk', 'en': 'Seasonal'},
      'store_seasonal_empty': {'tr': 'Şu anda aktif sezonluk paket yok.\nYakında yeni etkinlikler!', 'en': 'No active seasonal packs.\nNew events coming soon!'},
      'store_badge_limited': {'tr': 'Sınırlı Süre', 'en': 'Limited Time'},
      'btn_subscribe': {'tr': 'ABONE OL', 'en': 'SUBSCRIBE'},
      'btn_buy': {'tr': 'SATIN AL', 'en': 'BUY'},
      'msg_purchase_success': {'tr': '{0} satın alındı! ✅', 'en': '{0} purchased! ✅'},
      'msg_purchase_fail': {'tr': 'Satın alma başarısız: {0}', 'en': 'Purchase failed: {0}'},
      'msg_restore_success': {'tr': 'Satın almalar geri yüklendi! ✅', 'en': 'Purchases restored! ✅'},
      
      // --- IAP PRODUCTS ---
      // Names
      'prod_name_hint_50': {'tr': '50 İpucu', 'en': '50 Hints'},
      'prod_name_hint_150': {'tr': '150 İpucu', 'en': '150 Hints'},
      'prod_name_hint_500': {'tr': '500 İpucu', 'en': '500 Hints'},
      'prod_name_hint_1500': {'tr': '1500 İpucu', 'en': '1500 Hints'},
      'prod_name_starter': {'tr': 'Başlangıç Paketi', 'en': 'Starter Pack'},
      'prod_name_full': {'tr': 'Tam Paket', 'en': 'Full Bundle'},
      'prod_name_monthly': {'tr': 'Premium Aylık', 'en': 'Premium Monthly'},
      'prod_name_yearly': {'tr': 'Premium Yıllık', 'en': 'Premium Yearly'},
      'prod_name_winter': {'tr': 'Kış Paketi', 'en': 'Winter Pack'},
      'prod_name_summer': {'tr': 'Yaz Paketi', 'en': 'Summer Pack'},
      'prod_name_halloween': {'tr': 'Cadılar Bayramı', 'en': 'Halloween Pack'},
      'prod_name_valentines': {'tr': 'Sevgililer Günü', 'en': 'Valentines Pack'},
      'prod_name_remove_ads': {'tr': 'Reklamları Kaldır', 'en': 'Remove Ads'},
      
      // Descriptions
      'prod_desc_hint_50': {'tr': 'Küçük ipucu paketi', 'en': 'Small hint pack'},
      'prod_desc_hint_150': {'tr': 'Orta ipucu paketi', 'en': 'Medium hint pack'},
      'prod_desc_hint_500': {'tr': 'Büyük ipucu paketi', 'en': 'Large hint pack'},
      'prod_desc_hint_1500': {'tr': 'Dev ipucu paketi', 'en': 'Giant hint pack'},
      'prod_desc_starter': {'tr': 'Yeni oyuncular için mükemmel başlangıç!', 'en': 'Perfect start for new players!'},
      'prod_desc_full': {'tr': 'Her şey dahil, sonsuza dek!', 'en': 'All inclusive, forever!'},
      'prod_desc_monthly': {'tr': 'Her ay yenilenir. İstediğin zaman iptal et.', 'en': 'Renews monthly. Cancel anytime.'},
      'prod_desc_yearly': {'tr': '12 ay boyunca. 2 ay bedava!', 'en': 'For 12 months. 2 months free!'},
      'prod_desc_winter': {'tr': 'Sınırlı süre! Kış temasıyla don!', 'en': 'Limited time! Freeze with winter theme!'},
      'prod_desc_summer': {'tr': 'Sınırlı süre! Yaz enerjisi!', 'en': 'Limited time! Summer energy!'},
      'prod_desc_halloween': {'tr': 'Korkunç indirimler! 🎃', 'en': 'Spooky discounts! 🎃'},
      'prod_desc_valentines': {'tr': 'Aşkına prizma hediye et! 💝', 'en': 'Gift a prism to your love! 💝'},
      'prod_desc_remove_ads': {'tr': 'Bir kez satın al, sonsuza dek reklamsız!', 'en': 'Buy once, no ads forever!'},
      
      // Contents (Reusable)
      'cont_50_tokens': {'tr': '50 ipucu', 'en': '50 hints'},
      'cont_150_tokens': {'tr': '150 ipucu', 'en': '150 hints'},
      'cont_200_tokens': {'tr': '200 ipucu', 'en': '200 hints'},
      'cont_300_tokens': {'tr': '300 ipucu', 'en': '300 hints'},
      'cont_500_tokens': {'tr': '500 ipucu', 'en': '500 hints'},
      'cont_1500_tokens': {'tr': '1500 ipucu', 'en': '1500 hints'},
      'cont_3_skins': {'tr': '3 özel skin', 'en': '3 special skins'},
      'cont_5_skins_winter': {'tr': '5 kış temalı skin', 'en': '5 winter themed skins'},
      'cont_5_skins_summer': {'tr': '5 yaz temalı skin', 'en': '5 summer themed skins'},
      'cont_skins_halloween': {'tr': 'Hayalet ve Kabak skinleri', 'en': 'Ghost & Pumpkin skins'},
      'cont_skins_valentines': {'tr': 'Kalp temalı skinler', 'en': 'Heart themed skins'},
      'cont_theme_halloween': {'tr': 'Karanlık Mod Teması', 'en': 'Dark Mode Theme'},
      'cont_effect_hearts': {'tr': 'Kalp Efekti', 'en': 'Hearts Effect'},
      'cont_no_ads_1w': {'tr': 'Reklamsız 1 hafta', 'en': 'No ads for 1 week'},
      'cont_no_ads_forever': {'tr': 'Reklamsız (sürekli)', 'en': 'No ads (forever)'},
      'cont_unlimited_hints': {'tr': 'Sınırsız ipucu (sürekli)', 'en': 'Unlimited hints (forever)'},
      'cont_all_skins': {'tr': 'Tüm skinler açık', 'en': 'All skins unlocked'},
      'cont_dlc_discount': {'tr': 'Gelecek DLC\'ler %50 indirimli', 'en': 'Future DLCs 50% off'},
      'cont_daily_10': {'tr': 'Her gün 10 ipucu', 'en': '10 hints daily'},
      'cont_no_ads_exp': {'tr': 'Reklamsız deneyim', 'en': 'Ad-free experience'},
      'cont_badge_sub': {'tr': 'Özel abone rozeti', 'en': 'Special subscriber badge'},
      'cont_badge_gold': {'tr': 'Özel altın abone rozeti', 'en': 'Special gold subscriber badge'},
      'cont_early_access': {'tr': 'Yeni levellara 1 hafta erken erişim', 'en': '1 week early access to new levels'},
      'cont_skin_yearly': {'tr': 'Özel yıllık skin', 'en': 'Special yearly skin'},
      'cont_effect_snow': {'tr': 'Kar yağışı efekti', 'en': 'Snowfall effect'},
      'cont_effect_sun': {'tr': 'Güneş pırıltısı efekti', 'en': 'Sun shine effect'},
      'cont_remove_all_ads': {'tr': 'Tüm reklamlar kaldırılır', 'en': 'All ads removed'},

      // Badges
      'badge_popular': {'tr': 'En Popüler!', 'en': 'Most Popular!'},
      'badge_starter': {'tr': 'Yeni Başlayanlar İçin!', 'en': 'For Beginners!'},
      'badge_best_value': {'tr': 'EN İYİ DEĞER!', 'en': 'BEST VALUE!'},
      'badge_2_months_free': {'tr': '2 Ay Bedava!', 'en': '2 Months Free!'},
      'badge_limited': {'tr': 'Sınırlı Süre!', 'en': 'Limited Time!'},
      'badge_save_percent': {'tr': '%{0} Tasarruf!', 'en': 'Save %{0}!'},
      
      'btn_back': {'tr': 'GERİ', 'en': 'BACK'},
      
      // --- ACHIEVEMENTS SCREEN ---
      'ach_title': {'tr': 'BAŞARILAR', 'en': 'ACHIEVEMENTS'},
      'cat_speed': {'tr': 'Hız', 'en': 'Speed'},
      'cat_perfection': {'tr': 'Mükemmellik', 'en': 'Perfection'},
      'cat_marathon': {'tr': 'Maraton', 'en': 'Marathon'},
      'cat_independence': {'tr': 'Bağımsızlık', 'en': 'Independence'},
      'cat_secret': {'tr': 'Gizli', 'en': 'Secret'},
      'cat_legend': {'tr': 'Efsane', 'en': 'Legend'},
      
      // --- ABOUT SCREEN ---
      'about_title': {'tr': 'HAKKINDA', 'en': 'ABOUT'},
      
      // --- CUSTOMIZATION SCREEN ---
      'cust_title': {'tr': 'KİŞİSELLEŞTİR', 'en': 'CUSTOMIZE'},
      'cust_tab_prism': {'tr': 'Prizma', 'en': 'Prism'},
      'cust_tab_effect': {'tr': 'Efekt', 'en': 'Effect'},
      'cust_tab_theme': {'tr': 'Tema', 'en': 'Theme'},
      
      // --- LEVEL COMPLETE OVERLAY ---
      'level_complete_success': {'tr': 'SEVİYE TAMAMLANDI!', 'en': 'LEVEL COMPLETE!'},
      'level_complete_fail': {'tr': 'TEKRAR DENEYİN', 'en': 'TRY AGAIN'},
      'btn_next_level': {'tr': 'SONRAKİ SEVİYE', 'en': 'NEXT LEVEL'},
      'btn_try_again': {'tr': 'TEKRAR DENE', 'en': 'TRY AGAIN'},
      'btn_replay': {'tr': 'Tekrar', 'en': 'Replay'},
      'btn_menu': {'tr': 'Menü', 'en': 'Menu'},
      'lbl_moves': {'tr': 'Hamle', 'en': 'Moves'},
      'lbl_earnings': {'tr': 'Kazanılan', 'en': 'Earned'},
      'lbl_tokens': {'tr': 'jeton', 'en': 'tokens'},
      
      // --- NEWLY EXTRACTED ---
      'game_paused': {'tr': 'DURAKLATILDI', 'en': 'PAUSED'},
      'game_resume': {'tr': 'DEVAM ET', 'en': 'RESUME'},
      'game_exit': {'tr': 'MENÜYE DÖN', 'en': 'EXIT TO MENU'},
      
      'level_locked': {'tr': 'Seviye Kilitli', 'en': 'Level Locked'},
      'level_locked_msg': {'tr': 'Önce {level}. seviyeyi tamamla!', 'en': 'Complete Level {level} first!'},
      'level_world_title': {'tr': 'BÖLÜM {id}', 'en': 'CHAPTER {id}'},
      
      'sync_now': {'tr': 'Şimdi Eşitle', 'en': 'Sync Now'},
      'sync_online': {'tr': 'Çevrimiçi', 'en': 'Online'},
      'sync_offline': {'tr': 'Çevrimdışı', 'en': 'Offline'},
      'debug_tools': {'tr': 'GELİŞTİRİCİ ARAÇLARI', 'en': 'DEBUG TOOLS'},
      'debug_unlock_all': {'tr': 'TÜMÜNÜ AÇ', 'en': 'UNLOCK ALL'},
      'debug_reset': {'tr': 'SIFIRLA', 'en': 'RESET PROGRESS'},
      
      'video_playing_time': {'tr': 'Oynatılıyor... {time}s', 'en': 'Playing... {time}s'},
      'video_skip': {'tr': 'Atla', 'en': 'Skip'},
      
      'start_bonus': {'tr': 'Başlangıç Bonusu', 'en': 'Starter Bonus'},
      'infinity_symbol': {'tr': '∞', 'en': '∞'}, // Just in case fonts differ

      // --- PRIVACY ---
      'privacy_policy_title': {'tr': 'Gizlilik ve Veri', 'en': 'Privacy & Data'},
      'privacy_analytics': {'tr': 'Analitik Paylaş', 'en': 'Share Analytics'},
      'privacy_consent_title': {'tr': 'Veri Gizliliği', 'en': 'Data Privacy'},
      'privacy_consent_body': {'tr': 'Oyunu geliştirmek için analitik verileri kullanıyoruz. Anonim kullanım verilerini paylaşmayı kabul ediyor musunuz? Ayarlardan değiştirebilirsiniz.', 'en': 'We use analytics to improve the game. Do you consent to sharing anonymous usage data? You can change this in settings.'},
      'privacy_accept': {'tr': 'Kabul Et', 'en': 'Accept'},
      'privacy_decline': {'tr': 'Reddet', 'en': 'Decline'},
  };
}

