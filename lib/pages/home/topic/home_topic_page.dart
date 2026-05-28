import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/network_image.dart';
import '../../../logic/model/feed/datum.dart';
import '../../../logic/model/feed/entity.dart';
import '../../../logic/network/network_repo.dart';
import '../../../logic/state/loading_state.dart';
import '../../../pages/carousel/carousel_page.dart';
import '../../../pages/home/topic/controller.dart';
import '../../../pages/home/home_page.dart' show TabType;
import '../../../utils/cache_util.dart';
import '../../../utils/storage_util.dart';

class HomeTopicPage extends StatefulWidget {
  const HomeTopicPage({super.key, required this.tabType});

  final TabType tabType;

  @override
  State<HomeTopicPage> createState() => _HomeTopicPageState();
}

class _HomeTopicPageState extends State<HomeTopicPage>
    with AutomaticKeepAliveClientMixin {
  late HomeTopicController _homeTopicController;
  late PageController _controller;
  StreamSubscription<dynamic>? _followedTopicsSubscription;

  static const _localFollowedTopicsUrl = 'local://followedTopics';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _homeTopicController = Get.put(
      HomeTopicController(tabType: widget.tabType),
      tag: widget.tabType.name,
    );
    _followedTopicsSubscription =
        GStorage.settings.watch(key: SettingsBoxKey.followedTopics).listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _followedTopicsSubscription?.cancel();
    _controller.dispose();
    Get.delete<HomeTopicController>(
      tag: widget.tabType.name,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _homeTopicController.obx(
      (data) {
        if (widget.tabType == TabType.TOPIC) {
          return _buildTopicLayout(data!);
        }
        return _buildProductLayout(data!);
      },
      onEmpty: GestureDetector(
        onTap: _homeTopicController.onReload,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10.0),
          child: const Text('EMPTY'),
        ),
      ),
      onError: (error) => GestureDetector(
        onTap: _homeTopicController.onReload,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10.0),
          child: Text(error ?? 'unknown error'),
        ),
      ),
    );
  }

  Widget _buildTopicLayout(List<Datum> data) {
    final entities = _getTopicEntities(data);
    return Row(
      children: [
        _buildSideList(
          itemCount: entities.length,
          titleBuilder: (index) => entities[index].title.toString(),
          onTap: (index) {
            _homeTopicController.currentIndex.value = index;
            _controller.jumpToPage(index);
          },
        ),
        _buildContent(
          itemCount: entities.length,
          itemBuilder: (context, index) {
            final entity = entities[index];
            if (_isLocalFollowedTopics(entity)) {
              return const _LocalFollowedTopicsPage();
            }
            return CarouselPage(
              isInit: false,
              url: entity.url,
              title: entity.title,
              isHomeCard: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductLayout(List<Datum> data) {
    return Row(
      children: [
        _buildSideList(
          itemCount: data.length,
          titleBuilder: (index) => data[index].title.toString(),
          onTap: (index) {
            _homeTopicController.currentIndex.value = index;
            _controller.jumpToPage(index);
          },
        ),
        _buildContent(
          itemCount: data.length,
          itemBuilder: (context, index) => CarouselPage(
            isInit: false,
            url: data[index].url,
            title: data[index].title,
            isHomeCard: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSideList({
    required int itemCount,
    required String Function(int index) titleBuilder,
    required void Function(int index) onTap,
  }) {
    return Expanded(
      flex: 22,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => IntrinsicHeight(
          child: Obx(
            () => InkWell(
              onTap: () => onTap(index),
              child: Ink(
                color: index == _homeTopicController.currentIndex.value
                    ? Theme.of(context).colorScheme.onInverseSurface
                    : Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: double.infinity,
                      width: 3,
                      color: index == _homeTopicController.currentIndex.value
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          titleBuilder(index),
                          style: TextStyle(
                            color:
                                index == _homeTopicController.currentIndex.value
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    return Expanded(
      flex: 78,
      child: Container(
        color: Theme.of(context).colorScheme.onInverseSurface,
        child: PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }

  List<Entity> _getTopicEntities(List<Datum> data) {
    final entities = data.first.entities ?? <Entity>[];
    return [
      Entity(title: '我的关注', url: _localFollowedTopicsUrl),
      ...entities.where((item) {
        final title = item.title ?? '';
        final url = item.url ?? '';
        return title != '我的关注' && !url.contains('userFollowTagList');
      }),
    ];
  }

  bool _isLocalFollowedTopics(Entity entity) {
    return entity.url == _localFollowedTopicsUrl;
  }
}

class _LocalFollowedTopicsPage extends StatelessWidget {
  const _LocalFollowedTopicsPage();

  @override
  Widget build(BuildContext context) {
    final topics = GStorage.followedTopics
        .where((item) => !GStorage.checkTopic(item['title'] ?? ''))
        .toList();
    if (topics.isEmpty) {
      return const Center(child: Text('暂无关注话题'));
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(10),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FollowedTopicCard(topic: topics[index]),
        );
      },
    );
  }
}

class _FollowedTopicCard extends StatefulWidget {
  const _FollowedTopicCard({required this.topic});

  final Map<String, String> topic;

  @override
  State<_FollowedTopicCard> createState() => _FollowedTopicCardState();
}

class _FollowedTopicCardState extends State<_FollowedTopicCard> {
  late final Future<String?> _localLogoFuture = _prepareLocalLogo();

  @override
  Widget build(BuildContext context) {
    final title = widget.topic['title'] ?? '';
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () => Get.toNamed('/t/${Uri.encodeComponent(title)}'),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FutureBuilder<String?>(
                future: _localLogoFuture,
                builder: (context, snapshot) {
                  final path = snapshot.data;
                  if (path != null && File(path).existsSync()) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(path),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  return clipNetworkImage(
                    '',
                    radius: 8,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _prepareLocalLogo() async {
    final title = widget.topic['title'] ?? '';
    final currentLocalLogo = widget.topic['localLogo'] ?? '';
    if (currentLocalLogo.isNotEmpty && await File(currentLocalLogo).exists()) {
      return currentLocalLogo;
    }

    var logo = widget.topic['logo'] ?? '';
    if (logo.isEmpty) {
      final detail = await NetworkRepo.getDataFromUrl(
        url: '/v6/topic/newTagDetail',
        data: {'tag': title},
      );
      if (detail is Success) {
        final data = detail.response as Datum;
        logo = data.logo ?? data.pic ?? data.cover ?? data.coverPic ?? '';
        if (logo.isNotEmpty) {
          await GStorage.updateFollowedTopic(title, logo: logo);
        }
      }
    }

    if (logo.isEmpty) {
      return null;
    }

    final dir = Directory(
      '${(await CacheManage.getAppTempDirectory()).path}${Platform.pathSeparator}followed_topic_logos',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(
      '${dir.path}${Platform.pathSeparator}${Uri.encodeComponent(title)}.img',
    );
    if (await file.exists()) {
      await GStorage.updateFollowedTopic(title, localLogo: file.path);
      return file.path;
    }

    final response = await Dio().get<List<int>>(
      logo,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null) {
      return null;
    }
    await file.writeAsBytes(response.data!);
    await GStorage.updateFollowedTopic(
      title,
      logo: logo,
      localLogo: file.path,
    );
    return file.path;
  }
}
