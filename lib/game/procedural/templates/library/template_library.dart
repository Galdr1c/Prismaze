import '../template_models.dart';
import 'episode_1_templates.dart';
import 'episode_2_templates.dart';
import 'episode_3_templates.dart';
import 'episode_4_templates.dart';
import 'episode_5_templates.dart';

/// Registry of all level templates
class TemplateLibrary {
  static final TemplateLibrary _instance = TemplateLibrary._();
  factory TemplateLibrary() => _instance;
  TemplateLibrary._();

  /// All registered templates by ID
  final Map<String, LevelTemplate> _templates = {};
  
  /// Cached list by episode
  final Map<int, List<LevelTemplate>> _byEpisode = {};

  void register(LevelTemplate template) {
    _templates[template.id] = template;
    _byEpisode.putIfAbsent(template.episode, () => []).add(template);
  }
  
  void registerAll(List<LevelTemplate> templates) {
    for (var t in templates) {
      register(t);
    }
  }

  List<LevelTemplate> getTemplatesForEpisode(int episode) {
    return _byEpisode[episode] ?? [];
  }
  
  LevelTemplate? getTemplate(String id) => _templates[id];
  
  /// Load all templates (Entry point)
  void loadAll() {
    _templates.clear();
    _byEpisode.clear();
    
    // Register E1
    registerAll(Episode1Templates.all);
    registerAll(Episode2Templates.all);
    registerAll(Episode3Templates.all);
    registerAll(Episode4Templates.all);
    registerAll(Episode5Templates.all);
  }
}
