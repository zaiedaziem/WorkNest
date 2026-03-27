import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zdowwkuswwczzwrjcffn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpkb3d3a3Vzd3djenp3cmpjZmZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MzI4MDksImV4cCI6MjA5MDIwODgwOX0.-jNrd01Cj2KKBXNX6a_7YkGW0HNwXA86_cpR_V_Jh4s',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkNest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    final data = await supabase
        .from('notes')
        .select()
        .order('created_at', ascending: false);
    setState(() {
      _notes = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _addNote() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;

    await supabase.from('notes').insert({'body': body});
    _controller.clear();
    await _fetchNotes();
  }

  Future<void> _deleteNote(int id) async {
    await supabase.from('notes').delete().eq('id', id);
    await _fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WorkNest Notes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter a note...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addNote, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                ? const Center(child: Text('No notes yet.'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return ListTile(
                        title: Text(note['body'] ?? ''),
                        subtitle: Text(note['created_at'].toString()),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNote(note['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
