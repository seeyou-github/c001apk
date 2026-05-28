import 'package:flutter/material.dart';

import '../../utils/storage_util.dart';

class HomeTabSettingsPage extends StatefulWidget {
  const HomeTabSettingsPage({super.key});

  @override
  State<HomeTabSettingsPage> createState() => _HomeTabSettingsPageState();
}

class _HomeTabSettingsPageState extends State<HomeTabSettingsPage> {
  late List<String> _visibleTabs;
  late List<String> _hiddenTabs;

  @override
  void initState() {
    super.initState();
    _visibleTabs = List<String>.from(GStorage.homeTabs);
    _hiddenTabs = GStorage.defaultHomeTabs
        .where((tab) => !_visibleTabs.contains(tab))
        .toList();
  }

  Future<void> _save() async {
    await GStorage.setHomeTabs(_visibleTabs);
  }

  Future<void> _setVisible(String tab, bool visible) async {
    setState(() {
      if (visible) {
        _hiddenTabs.remove(tab);
        if (!_visibleTabs.contains(tab)) {
          _visibleTabs.add(tab);
        }
      } else if (_visibleTabs.length > 1) {
        _visibleTabs.remove(tab);
        if (!_hiddenTabs.contains(tab)) {
          _hiddenTabs.add(tab);
        }
      }
    });
    await _save();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final tab = _visibleTabs.removeAt(oldIndex);
      _visibleTabs.insert(newIndex, tab);
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主页顶栏 Tab'),
      ),
      body: ListView(
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _visibleTabs.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final tab = _visibleTabs[index];
              return SwitchListTile(
                key: ValueKey(tab),
                secondary: const Icon(Icons.drag_handle),
                title: Text(tab),
                value: true,
                onChanged: (value) => _setVisible(tab, value),
              );
            },
          ),
          for (final tab in _hiddenTabs)
            SwitchListTile(
              key: ValueKey(tab),
              secondary: const Icon(Icons.visibility_off_outlined),
              title: Text(tab),
              value: false,
              onChanged: (value) => _setVisible(tab, value),
            ),
        ],
      ),
    );
  }
}
