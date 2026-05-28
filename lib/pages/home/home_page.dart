import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../pages/home/feed/home_feed_page.dart';
import '../../pages/home/return_top_controller.dart';
import '../../pages/home/topic/home_topic_page.dart';
import '../../utils/storage_util.dart';
import '../../utils/utils.dart';

// ignore: constant_identifier_names
enum TabType { FOLLOW, FEED, HOT, TOPIC, PRODUCT, COOLPIC, NONE }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late List<TabType> _tabTypes;
  StreamSubscription<dynamic>? _homeTabsSubscription;
  final ReturnTopController _pageScrollController =
      Get.find<ReturnTopController>(tag: 'home');
  // late final _config = Provider.of<AppConfigProvider>(context, listen: false);
  // late bool _showFab = true; //_config.isLogin;

  void scrollToTop(int index) {
    _pageScrollController.setIndex(index);
  }

  List<TabType> _getTabTypes() {
    final tabs = GStorage.homeTabs
        .map((name) => TabType.values.firstWhereOrNull(
              (type) => type.name == name,
            ))
        .whereType<TabType>()
        .where((type) => type != TabType.NONE)
        .toList();
    return tabs.isEmpty ? [TabType.FEED] : tabs;
  }

  void _resetTabs({int? previousIndex}) {
    _tabTypes = _getTabTypes();
    final initialIndex = (previousIndex ?? 0).clamp(0, _tabTypes.length - 1);
    _tabController = TabController(
      vsync: this,
      initialIndex: initialIndex,
      length: _tabTypes.length,
    );
  }

  Widget _buildPage(TabType type, int index) {
    return KeyedSubtree(
      key: ValueKey(type.name),
      child: switch (type) {
        TabType.TOPIC || TabType.PRODUCT => HomeTopicPage(tabType: type),
        _ => HomeFeedPage(tabType: type, tabIndex: index),
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _resetTabs(previousIndex: GStorage.homeTabs.indexOf(TabType.FEED.name));
    _homeTabsSubscription =
        GStorage.settings.watch(key: SettingsBoxKey.homeTabs).listen((_) {
      if (!mounted) {
        return;
      }
      final previousIndex = _tabController.index;
      _tabController.dispose();
      setState(() => _resetTabs(previousIndex: previousIndex));
    });

    _pageScrollController.index.listen((index) {
      if (index == 998) {
        scrollToTop(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _homeTabsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TabBar(
          controller: _tabController,
          tabs: _tabTypes.map((type) => Tab(text: type.name)).toList(),
          isScrollable: true,
          onTap: (index) {
            if (!_tabController.indexIsChanging) {
              scrollToTop(index);
            }
          },
          tabAlignment: Utils.isWideLandscape(context)
              ? TabAlignment.center
              : TabAlignment.startOffset,
        ),
        actions: [
          IconButton(
            onPressed: () => Get.toNamed('/search'),
            icon: const Icon(Icons.search),
            tooltip: '搜索',
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (int i = 0; i < _tabTypes.length; i++)
            _buildPage(_tabTypes[i], i),
        ],
      ),
    );
  }
}
