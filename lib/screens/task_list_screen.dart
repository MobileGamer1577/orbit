import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../storage/task_store.dart';

class TaskListScreen extends StatefulWidget {
  final String title;
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
  String query = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(widget.jsonAssetPath);
    setState(() => data = jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tasks = (data!['tasks'] as List).cast<Map<String, dynamic>>();

    final visible = tasks.where((t) {
      final title = (t['title'] as String?) ?? '';
      final desc = (t['description'] as String?) ?? '';
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return title.toLowerCase().contains(q) || desc.toLowerCase().contains(q);
    }).toList();

    final doneCount = tasks.where((t) => TaskStore.isDone(t['id'] as String)).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: LinearProgressIndicator(value: progress)),
                    const SizedBox(width: 12),
                    Text('$doneCount/$total'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Suchen (Titel oder Beschreibung)…',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Angezeigt: ${visible.length}'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final task = visible[i];
                final id = task['id'] as String;
                final title = (task['title'] as String?) ?? '';
                final desc = (task['description'] as String?) ?? '';

                final done = TaskStore.isDone(id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: ListTile(
                    title: Text(title),
                    subtitle: desc.trim().isEmpty ? null : Text(desc),
                    trailing: Checkbox(
                      value: done,
                      onChanged: (v) async {
                        if (v == null) return;
                        await TaskStore.setDone(id, v);
                        if (mounted) setState(() {});
                      },
                    ),
                    onTap: () async {
                      await TaskStore.setDone(id, !done);
                      if (mounted) setState(() {});
                    },
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