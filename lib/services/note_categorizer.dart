class NoteCategorizer {
  static const Map<String, List<String>> _subjectKeywords = <String, List<String>>{
    'Biology': <String>[
      'photosynthesis', 'cell', 'organism', 'genetics', 'evolution', 'dna',
      'protein', 'enzyme', 'ecosystem', 'species', 'plant', 'animal', 'bacteria',
      'virus', 'metabolism', 'respiration', 'digestion', 'reproduction',
    ],
    'Physics': <String>[
      'force', 'energy', 'motion', 'velocity', 'acceleration', 'gravity',
      'momentum', 'electricity', 'magnetism', 'wave', 'light', 'sound',
      'quantum', 'atom', 'nuclear', 'thermodynamics', 'optics', 'mechanics',
    ],
    'Chemistry': <String>[
      'reaction', 'element', 'compound', 'molecule', 'atom', 'bond',
      'acid', 'base', 'solution', 'mixture', 'periodic', 'chemical',
      'oxidation', 'reduction', 'catalyst', 'equilibrium', 'organic',
    ],
    'Mathematics': <String>[
      'equation', 'algebra', 'geometry', 'calculus', 'function', 'graph',
      'number', 'probability', 'statistics', 'integral', 'derivative',
      'theorem', 'proof', 'variable', 'matrix', 'vector', 'formula',
    ],
    'History': <String>[
      'war', 'history', 'ancient', 'civilization', 'empire', 'revolution',
      'century', 'decade', 'medieval', 'modern', 'colonial', 'independence',
      'dynasty', 'king', 'queen', 'battle', 'treaty',
    ],
    'Geography': <String>[
      'map', 'continent', 'country', 'city', 'river', 'mountain', 'ocean',
      'climate', 'weather', 'latitude', 'longitude', 'region', 'terrain',
      'population', 'capital', 'border', 'island', 'desert',
    ],
    'Literature': <String>[
      'poem', 'novel', 'story', 'author', 'book', 'character', 'plot',
      'theme', 'genre', 'fiction', 'narrative', 'prose', 'verse', 'drama',
      'essay', 'literary', 'writing', 'classic',
    ],
    'Computer Science': <String>[
      'code', 'programming', 'algorithm', 'software', 'hardware', 'computer',
      'data', 'database', 'network', 'internet', 'web', 'app', 'function',
      'variable', 'loop', 'array', 'class', 'object', 'api', 'debug',
    ],
  };

  static String detectSubject(String text) {
    final lowerText = text.toLowerCase();
    
    int maxMatches = 0;
    String bestSubject = 'General';
    
    for (final entry in _subjectKeywords.entries) {
      final subject = entry.key;
      final keywords = entry.value;
      
      int matches = 0;
      for (final keyword in keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          matches++;
        }
      }
      
      if (matches > maxMatches) {
        maxMatches = matches;
        bestSubject = subject;
      }
    }
    
    return bestSubject;
  }
}
