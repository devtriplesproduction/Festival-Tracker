import 'dart:io';

void main() {
  final files = [
    'lib/screens/clients/clients_screen.dart',
    'lib/screens/festivals/festivals_screen.dart',
    'lib/screens/alerts/alerts_screen.dart',
    'lib/screens/team/team_screen.dart',
    'lib/screens/pipeline/upload_poster_screen.dart',
    'lib/screens/pipeline/pipeline_screen.dart'
  ];

  for (final f in files) {
    final file = File(f);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // 1. Revert ALL body: to child:
    content = content.replaceAll('body:', 'child:');
    
    // 2. Fix Scaffold specifically
    content = content.replaceAll('],\n      ),\n      child:', '],\n      ),\n      body:');
    content = content.replaceAll('], \n      ), \n      child:', '],\n      ),\n      body:');
    content = content.replaceAll('      ),\n      child: SafeArea(', '      ),\n      body: SafeArea(');
    content = content.replaceAll('      ),\n      child: material.SafeArea(', '      ),\n      body: material.SafeArea(');
    content = content.replaceAll('      ),\n      child: list.isEmpty', '      ),\n      body: list.isEmpty');
    content = content.replaceAll('      ),\n      child: Column(', '      ),\n      body: Column(');
    content = content.replaceAll('      ),\n      child: IndexedStack(', '      ),\n      body: IndexedStack(');
    content = content.replaceAll('      ),\n      child: const Center(', '      ),\n      body: const Center(');

    file.writeAsStringSync(content);
  }
}
