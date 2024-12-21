import '/image.dart';

class HistoryManager {
  final Function getImage;
  final Function? updateCallback;

  final List<List<Map<String, SlyRangeAttribute>>> _undoList = [];
  final List<List<Map<String, SlyRangeAttribute>>> _redoList = [];
  bool canUndo = false;
  bool canRedo = false;

  HistoryManager(this.getImage, this.updateCallback);

  void update({bool redo = false, bool clearRedo = true}) {
    List<Map<String, SlyRangeAttribute>> newItem = [];

    for (final attributes in [
      getImage().lightAttributes,
      getImage().colorAttributes,
      getImage().effectAttributes,
    ]) {
      final Map<String, SlyRangeAttribute> newMap = {};

      for (MapEntry<String, SlyRangeAttribute> entry in attributes.entries) {
        newMap[entry.key] = SlyRangeAttribute.copy(entry.value);
      }
      newItem.add(newMap);
    }

    (redo ? _redoList : _undoList).add(newItem);
    if (!redo && clearRedo) _redoList.clear();

    canUndo = _undoList.isNotEmpty;
    canRedo = _redoList.isNotEmpty;
  }

  void undo() => _undoOrRedo(redo: false);

  void redo() => _undoOrRedo(redo: true);

  void _undoOrRedo({required bool redo}) {
    final list = redo ? _redoList : _undoList;
    final last = list.lastOrNull;
    if (last == null) return;

    list.removeLast();

    update(redo: !redo, clearRedo: false);

    for (int i = 0; i < 3; i++) {
      for (MapEntry<String, SlyRangeAttribute> entry in last[i].entries) {
        [
          getImage().lightAttributes,
          getImage().colorAttributes,
          getImage().effectAttributes
        ][i][entry.key] = entry.value;
      }
    }

    if (updateCallback == null) return;
    updateCallback!();
  }
}
