import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../pages/home/return_top_controller.dart';
import '../../pages/home/home_page.dart';
import '../../pages/home/topic/home_topic_page.dart';
import '../../pages/main/main_controller.dart';
import '../../pages/message/message_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../utils/storage_util.dart';
import '../../utils/utils.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ReturnTopController _pageScrollController =
      Get.put(ReturnTopController(), tag: 'home');
  int _selectedIndex = 0;
  final _indexSctream = StreamController<int>.broadcast();
  late final MainController _mainController = Get.put(MainController());
  final _contrller = PageController();

  @override
  void initState() {
    super.initState();
    _mainController.checkLoginInfo();
  }

  @override
  void dispose() async {
    await GStorage.close();
    Get.delete<ReturnTopController>(tag: 'home');
    Get.delete<MainController>();
    super.dispose();
  }

  void onBackPressed() async {
    if (_selectedIndex != 0) {
      onDestinationSelected(0);
    } else {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      const SafeArea(
        left: false,
        right: false,
        bottom: false,
        child: HomeTopicPage(tabType: TabType.TOPIC),
      ),
      if (!GStorage.hideBottomMessageTab) const MessagePage(),
      const SettingsPage(),
    ];

    final barDestinations = <NavigationDestination>[
      const NavigationDestination(
        selectedIcon: Icon(Icons.home),
        icon: Icon(Icons.home_outlined),
        label: '主页',
      ),
      const NavigationDestination(
        selectedIcon: Icon(Icons.tag),
        icon: Icon(Icons.tag_outlined),
        label: 'TOPIC',
      ),
      if (!GStorage.hideBottomMessageTab)
        const NavigationDestination(
          selectedIcon: Icon(Icons.message),
          icon: Icon(Icons.message_outlined),
          label: '消息',
        ),
      const NavigationDestination(
        selectedIcon: Icon(Icons.settings),
        icon: Icon(Icons.settings_outlined),
        label: '设置',
      ),
    ];

    final railDestinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        selectedIcon: Icon(Icons.home),
        icon: Icon(Icons.home_outlined),
        label: Text('主页'),
      ),
      const NavigationRailDestination(
        selectedIcon: Icon(Icons.tag),
        icon: Icon(Icons.tag_outlined),
        label: Text('TOPIC'),
      ),
      if (!GStorage.hideBottomMessageTab)
        const NavigationRailDestination(
          selectedIcon: Icon(Icons.message),
          icon: Icon(Icons.message_outlined),
          label: Text('消息'),
        ),
      const NavigationRailDestination(
        selectedIcon: Icon(Icons.settings),
        icon: Icon(Icons.settings_outlined),
        label: Text('设置'),
      ),
    ];

    if (_selectedIndex >= pages.length) {
      _selectedIndex = pages.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_contrller.hasClients) {
          _contrller.jumpToPage(_selectedIndex);
        }
        _indexSctream.add(_selectedIndex);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, obj) async {
        onBackPressed();
      },
      child: LayoutBuilder(
        builder: (context, _) {
          return Scaffold(
            body: Row(children: [
              if (!Utils.isPortrait(context))
                StreamBuilder(
                    initialData: _selectedIndex,
                    stream: _indexSctream.stream,
                    builder: (_, snapshot) => Padding(
                          padding: EdgeInsets.only(
                              top: Platform.isMacOS ? 25.0 : 10.0),
                          child: NavigationRail(
                            destinations: railDestinations,
                            selectedIndex: _safeSelectedIndex(
                              snapshot.data!,
                              pages.length,
                            ),
                            onDestinationSelected: onDestinationSelected,
                            labelType: NavigationRailLabelType.none,
                            extended: true,
                          ),
                        )),
              if (!Utils.isPortrait(context)) const VerticalDivider(width: 1),
              if (Utils.isWideLandscape(context)) const Spacer(),
              Expanded(
                flex: 8,
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _contrller,
                  children: pages,
                ),
              ),
              if (Utils.isWideLandscape(context)) const Spacer(),
            ]),
            bottomNavigationBar: Utils.isPortrait(context)
                ? StreamBuilder(
                    initialData: _selectedIndex,
                    stream: _indexSctream.stream,
                    builder: (_, snapshot) {
                      final hideBottomBarText = GStorage.hideBottomBarText;
                      return NavigationBar(
                        height: hideBottomBarText ? 56 : null,
                        destinations: barDestinations,
                        selectedIndex: _safeSelectedIndex(
                          snapshot.data!,
                          pages.length,
                        ),
                        onDestinationSelected: onDestinationSelected,
                        labelBehavior: hideBottomBarText
                            ? NavigationDestinationLabelBehavior.alwaysHide
                            : NavigationDestinationLabelBehavior
                                .onlyShowSelected,
                      );
                    },
                  )
                : null,
          );
        },
      ),
    );
  }

  void onDestinationSelected(int index) {
    if (index == 0 && _selectedIndex == 0) {
      _pageScrollController.setIndex(998);
    }
    _contrller.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
    _selectedIndex = index;
    _indexSctream.add(index);
  }

  int _safeSelectedIndex(int index, int length) {
    if (index < 0) return 0;
    if (index >= length) return length - 1;
    return index;
  }
}
