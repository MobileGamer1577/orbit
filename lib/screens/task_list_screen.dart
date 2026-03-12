import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../storage/task_store.dart';
import '../theme/orbit_theme.dart';
import '../widgets/orbit_glass_card.dart';

class TaskListScreen extends StatefulWidget {
  final String title;

  /// Leer → Screen zeigt „Kommt bald".
  final String jsonAssetPath;

  const TaskListScreen({
    super.key,
    required this.title,
    required this.jsonAssetPath,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  Map<String, dynamic>? data;
  String query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final path = widget.jsonAssetPath.trim();
    if (path.isEmpty) {
      setState(() => data = null);
      return;
    }
    try {
      final raw = await rootBundle.loadString(path);
      setState(() => data = (jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      setState(() => data = {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // "Kommt bald"-Screen
    if (widget.jsonAssetPath.trim().isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: OrbitBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(title: widget.title),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OrbitGlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            color: Colors.white.withOpacity(0.70),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Kommt bald ✅',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Lädt noch
    if (data == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF10041E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
        ),
      );
    }

    final tasks = (data!['tasks'] as List).cast<Map>();
    final q = query.trim().toLowerCase();

    final visible = tasks.where((t) {
      final title = (t['title'] as String?) ?? '';
      final desc = (t['description'] as String?) ?? '';
      if (q.isEmpty) return true;
      return title.toLowerCase().contains(q) ||
          desc.toLowerCase().contains(q);
    }).toList();

    final doneCount =
        tasks.where((t) => TaskStore.isDone(t['id'] as String)).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OrbitBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: _Header(title: widget.title),
              ),

              // Fortschrittsbalken + Suchfeld
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fortschritt
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF9C6FFF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$doneCount / $total',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Suchfeld
                    OrbitGlassCard(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: Colors.white.withOpacity(0.55),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Suchen…',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.40),
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                                onChanged: (v) => setState(() => query = v),
                              ),
                            ),
                            if (query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => query = '');
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white.withOpacity(0.45),
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
                    Text(
                      '${visible.length} Aufträge',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Aufgaben-Liste
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final task = visible[i];
                    final id = task['id'] as String;
                    final title = (task['title'] as String?) ?? '';
                    final desc = (task['description'] as String?) ?? '';
                    final done = TaskStore.isDone(id);

                    return _TaskCard(
                      title: title,
                      desc: desc,
                      done: done,
                      onToggle: () async {
                        await TaskStore.setDone(id, !done);
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Header (Zurück + Titel)
// ──────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white.withOpacity(0.90),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Task Card
// ──────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final String title;
  final String desc;
  final bool done;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.title,
    required this.desc,
    required this.done,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return OrbitGlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox-Ersatz
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF7C4DFF).withOpacity(0.85)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: done
                          ? const Color(0xFF9C6FFF)
                          : Colors.white.withOpacity(0.22),
                      width: 1.5,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: done
                            ? Colors.white.withOpacity(0.45)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    if (desc.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          color: Colors.white.withOpacity(done ? 0.30 : 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
