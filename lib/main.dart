import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const KetikApp());

class KetikApp extends StatelessWidget {
  const KetikApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'Keranjang Prompt',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  static const _ch = MethodChannel('ketik/inbox');
  final _tpl = TextEditingController();
  List<String> items = [];
  SharedPreferences? _p;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _drain();
  }

  Future<void> _init() async {
    _p = await SharedPreferences.getInstance();
    items = _p!.getStringList('items') ?? [];
    _tpl.text = _p!.getString('tpl') ?? '';
    _tpl.addListener(() => _p?.setString('tpl', _tpl.text));
    await _drain();
    setState(() {});
  }

  // Ambil teks yang dikirim dari aplikasi lain (menu seleksi / Bagikan)
  Future<void> _drain() async {
    try {
      final r = await _ch.invokeListMethod<String>('drain') ?? [];
      if (r.isNotEmpty) _add(r);
    } catch (_) {}
  }

  void _add(List<String> t) {
    setState(() => items.addAll(t.where((e) => e.trim().isNotEmpty)));
    _save();
  }

  void _save() => _p?.setStringList('items', items);

  String get _prompt {
    final body = items.join('\n\n');
    final t = _tpl.text.trim();
    return t.isEmpty ? body : '$t\n\n$body';
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _prompt));
    _snack('Prompt disalin');
  }

  Future<void> _open(String url) async {
    await Clipboard.setData(ClipboardData(text: _prompt));
    _snack('Disalin, tinggal tempel di chat');
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _scan(ImageSource src) async {
    final f = await ImagePicker().pickImage(source: src);
    if (f == null) return;
    final rec = TextRecognizer();
    final res = await rec.recognizeText(InputImage.fromFilePath(f.path));
    await rec.close();
    final blocks =
        res.blocks.map((b) => b.text.replaceAll('\n', ' ')).toList();
    if (!mounted) return;
    if (blocks.isEmpty) return _snack('Teks tidak terdeteksi');
    final sel = await showModalBottomSheet<List<String>>(
        context: context, isScrollControlled: true, builder: (_) => _Pick(blocks));
    if (sel != null) _add(sel);
  }

  Future<void> _edit(int i) async {
    final c = TextEditingController(text: items[i]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit potongan'),
        content: TextField(controller: c, maxLines: 8, minLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => items[i] = c.text);
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang (${items.length})'),
        actions: [
          IconButton(
            tooltip: 'Kosongkan',
            icon: const Icon(Icons.delete_sweep),
            onPressed: items.isEmpty ? null : () { setState(items.clear); _save(); },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _tpl,
            decoration: const InputDecoration(
              labelText: 'Template prompt (opsional)',
              hintText: 'Contoh: Ringkas teks berikut:',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Keranjang kosong.\n\nBlok teks di aplikasi apa pun lalu pilih "Tambah ke Keranjang", '
                      'atau ambil dari kamera/galeri dengan tombol di bawah.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  itemCount: items.length,
                  onReorder: (o, n) {
                    if (n > o) n--;
                    setState(() => items.insert(n, items.removeAt(o)));
                    _save();
                  },
                  itemBuilder: (_, i) => ListTile(
                    key: ValueKey('$i-${items[i]}'),
                    title: Text(items[i], maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: () => _edit(i),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () { setState(() => items.removeAt(i)); _save(); },
                    ),
                  ),
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              IconButton.filledTonal(icon: const Icon(Icons.photo_camera), tooltip: 'Kamera', onPressed: () => _scan(ImageSource.camera)),
              const SizedBox(width: 6),
              IconButton.filledTonal(icon: const Icon(Icons.image), tooltip: 'Galeri / screenshot', onPressed: () => _scan(ImageSource.gallery)),
              const Spacer(),
              PopupMenuButton<String>(
                enabled: items.isNotEmpty,
                onSelected: _open,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'https://claude.ai/new', child: Text('Buka Claude')),
                  PopupMenuItem(value: 'https://chatgpt.com', child: Text('Buka ChatGPT')),
                  PopupMenuItem(value: 'https://gemini.google.com/app', child: Text('Buka Gemini')),
                ],
                icon: const Icon(Icons.open_in_new),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: items.isEmpty ? null : _copy,
                icon: const Icon(Icons.copy),
                label: const Text('Copy'),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Pick extends StatefulWidget {
  final List<String> blocks;
  const _Pick(this.blocks);
  @override
  State<_Pick> createState() => _PickState();
}

class _PickState extends State<_Pick> {
  final sel = <int>{};
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(padding: EdgeInsets.all(12), child: Text('Pilih teks yang mau diambil')),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.blocks.length,
            itemBuilder: (_, i) => CheckboxListTile(
              value: sel.contains(i),
              title: Text(widget.blocks[i]),
              onChanged: (v) => setState(() => v! ? sel.add(i) : sel.remove(i)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            TextButton(
              onPressed: () => setState(() => sel.addAll(List.generate(widget.blocks.length, (i) => i))),
              child: const Text('Pilih semua'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: sel.isEmpty
                  ? null
                  : () => Navigator.pop(context, (sel.toList()..sort()).map((i) => widget.blocks[i]).toList()),
              child: Text('Tambah (${sel.length})'),
            ),
          ]),
        ),
      ]),
    );
  }
}
