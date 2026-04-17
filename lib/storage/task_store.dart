import 'package:hive/hive.dart';

class TaskStore {
  static Box get _box => Hive.box('task_state');

  static String _doneKey(String id) => 'done:$id';

  static bool isDone(String id) {
    return (_box.get(_doneKey(id), defaultValue: false) as bool);
  }

  static Future<void> setDone(String id, bool value) async {
    await _box.put(_doneKey(id), value);
  }

  static Future<void> resetAllDone() async {
    final keys = _box.keys.where((k) => k.toString().startsWith('done:')).toList();
    await _box.deleteAll(keys);
  }
}