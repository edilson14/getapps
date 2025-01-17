import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:getapps/app/(public)/home/widgets/widgets.dart';
import 'package:getapps/app/app.dart';
import 'package:getapps/app/design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'package:uicons/uicons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with HookStateMixin {
  final debounceSearch = Debounce(delay: const Duration(milliseconds: 800));
  final _keyRefreshTop = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyRefreshTop.currentState?.show();
    });
  }

  void onChanged(String value) {
    debounceSearch.call(() {
      setSearchTextAction(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apps = useAtomState(filteredAppsState);
    final favoriteApps = useAtomState(favoriteAppsState);

    final isFavoriteView =
        favoriteApps.isNotEmpty && searchTextState.state.isEmpty;
    final size = MediaQuery.sizeOf(context);
    final primary = Theme.of(context).colors.red;

    return Scaffold(
        body: SafeArea(
      child: RefreshIndicator(
        key: _keyRefreshTop,
        color: primary,
        onRefresh: () {
          return Future.value(checkUpdatesActions(appsState.state));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppbarHome(
              onChanged: onChanged,
              onMyApp: () => Routefly.push(routePaths.myApps),
              onRegisterApp: () => Routefly.push(routePaths.registerApp),
              onRemoveSearch: () => setSearchTextAction(''),
            ),
            SliverToBoxAdapter(
              child: AnimatedAlign(
                alignment:
                    isFavoriteView ? Alignment.center : Alignment.bottomCenter,
                curve: Curves.easeOut,
                heightFactor: isFavoriteView ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(32),
                    TitleSectionHome(title: "favorite-title".i18n()),
                    SizedBox(
                      height: 120,
                      width: size.width,
                      child: ListView.builder(
                        itemCount: favoriteApps.length,
                        padding: const EdgeInsets.only(left: 12),
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final appModel = favoriteApps[index];

                          return SizedBox(
                            width: 300,
                            child: AnimatedBuilder(
                              key: ObjectKey(appModel),
                              animation: appModel,
                              builder: (context, child) {
                                final app = appModel.app;
                                late Widget buttonLabel;

                                if (app.appNotInstall) {
                                  buttonLabel = _buildButtonLabel(
                                      'install-app'.i18n(),
                                      UIcons.regularRounded.download);
                                } else if (app.updateIsAvailable) {
                                  buttonLabel = _buildButtonLabel(
                                      'update-app'.i18n(),
                                      UIcons.regularRounded.refresh);
                                } else {
                                  buttonLabel = _buildButtonLabel(
                                      'open-app'.i18n(),
                                      UIcons.regularRounded.play);
                                }
                                return HighlightCard(
                                  title: app.appName,
                                  infoLabel: app.packageInfo.id,
                                  sizeLabel: app.packageInfo.version,
                                  imageBytes:
                                      appModel.app.packageInfo.imageBytes,
                                  trailing: StatusAppButton(
                                    isLoading: appModel.isLoading,
                                    progress: appModel.downloadPercent,
                                    buttonLabel: buttonLabel,
                                    onTap: () {
                                      if (app.appNotInstall ||
                                          app.updateIsAvailable) {
                                        installAppAction(appModel, '');
                                      } else {
                                        openApp(app);
                                      }
                                    },
                                    onOptions: () {
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return AppDetailModalWidget(
                                              appModel: appModel);
                                        },
                                      );
                                    },
                                    onCancel: () => cancelInstallAppAction(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverGap(32),
            SliverToBoxAdapter(
              child: TitleSectionHome(title: "my-apps".i18n()),
            ),
            SliverToBoxAdapter(
              child: AnimatedAppsList(models: apps),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: 32.0.paddingTop + 24.0.paddingBottom,
                child: const Center(
                  child: VersionWidget(),
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }
}

class AnimatedAppsList extends StatelessWidget {
  final List<AppModel> models;
  const AnimatedAppsList({super.key, required this.models});

  Widget _buildItem(List<AppModel> apps) {
    return apps.isEmpty
        ? const SizedBox()
        : Padding(
            key: ObjectKey(models),
            padding: 12.0.paddingHorizontal,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double itemHeight = 100;
                double itemWidth = 300;
                int crossAxisCount = (constraints.maxWidth / itemWidth).floor();
                final aspect =
                    (constraints.maxWidth / crossAxisCount) / itemHeight;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 8,
                    childAspectRatio: aspect,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final appModel = apps[index];

                    return AnimatedBuilder(
                      key: ObjectKey(appModel),
                      animation: appModel,
                      builder: (context, child) {
                        final app = appModel.app;
                        late Widget buttonLabel;

                        if (app.appNotInstall) {
                          buttonLabel = _buildButtonLabel('install-app'.i18n(),
                              UIcons.regularRounded.download);
                        } else if (app.updateIsAvailable) {
                          buttonLabel = _buildButtonLabel('update-app'.i18n(),
                              UIcons.regularRounded.refresh);
                        } else {
                          buttonLabel = _buildButtonLabel(
                              'open-app'.i18n(), UIcons.regularRounded.play);
                        }
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AppTile.horizontal(
                              imageBytes: app.packageInfo.imageBytes,
                              title: app.appName,
                              infoLabel: app.packageInfo.id,
                              sizeLabel: app.packageInfo.version,
                              trailing: StatusAppButton(
                                isLoading: appModel.isLoading,
                                progress: appModel.downloadPercent,
                                buttonLabel: buttonLabel,
                                onTap: () {
                                  if (app.appNotInstall ||
                                      app.updateIsAvailable) {
                                    installAppAction(appModel, '');
                                  } else {
                                    openApp(app);
                                  }
                                },
                                onOptions: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return AppDetailModalWidget(
                                        appModel: appModel,
                                      );
                                    },
                                  );
                                },
                                onCancel: () => cancelInstallAppAction(),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  itemCount: apps.length,
                );
              },
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _buildItem(models),
      ),
    );
  }
}

Widget _buildButtonLabel(String label, IconData icon) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      const Gap(6),
      Icon(
        icon,
        color: Colors.grey[700],
        size: 12,
      ),
      const Gap(6),
      Text(
        label,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 12,
        ),
      ),
    ],
  );
}

class AppDetailModalWidget extends StatelessWidget with HookMixin {
  final AppModel appModel;

  const AppDetailModalWidget({super.key, required this.appModel});

  @override
  Widget build(BuildContext context) {
    useListenable(appModel);
    final primary = Theme.of(context).colors.red;
    return Padding(
      padding: 16.0.paddingHorizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(16),
          AppTile.horizontal(
            title: appModel.app.appName,
            infoLabel: appModel.app.packageInfo.id,
            sizeLabel: appModel.app.packageInfo.version,
            imageBytes: appModel.app.packageInfo.imageBytes,
            trailing: appModel.app.appNotInstall
                ? const SizedBox()
                : Center(
                    child: GestureDetector(
                      onTap: () {
                        favoriteAppAction(appModel);
                      },
                      child: Icon(
                        appModel.app.favorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: primary,
                        size: 35,
                      ),
                    ),
                  ),
          ),
          const Gap(30),
          ElevatedButton(
            onPressed: () {
              openRepository(appModel);
              Navigator.pop(context);
            },
            child: Text(
              'open-repository'.i18n(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Gap(16),
          if (appModel.app.appNotInstall)
            ElevatedButton(
              onPressed: () {
                installAppAction(appModel, '');
                Navigator.pop(context);
              },
              child: Text(
                'install-app'.i18n(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (appModel.app.updateIsAvailable)
            ElevatedButton(
              onPressed: () {
                installAppAction(appModel, '');
                Navigator.pop(context);
              },
              child: Text(
                'update-app'.i18n(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (!appModel.app.appNotInstall && !appModel.app.updateIsAvailable)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openApp(appModel.app);
              },
              child: Text('open-app'.i18n(),
                  style: const TextStyle(color: Colors.white)),
            ),
          const Gap(48),
        ],
      ),
    );
  }
}

class VersionWidget extends StatelessWidget with HookMixin {
  const VersionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final version = useAtomState(appVersionState);
    return Text(
      'version'.i18n([version]),
      style: context.textTheme.labelLarge
          ?.copyWith(color: const Color(0xff939AA5)),
    );
  }
}

class StatusAppButton extends StatefulWidget {
  final bool isLoading;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback onOptions;
  final VoidCallback onCancel;
  final Widget buttonLabel;

  const StatusAppButton({
    super.key,
    required this.buttonLabel,
    required this.isLoading,
    this.progress,
    required this.onTap,
    required this.onOptions,
    required this.onCancel,
  });

  @override
  State<StatusAppButton> createState() => _StatusAppButtonState();
}

class _StatusAppButtonState extends State<StatusAppButton>
    with SingleTickerProviderStateMixin, HookStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _opacityLoadingBackgroundAnimation;
  late final Animation<double> _internalLoadingChildOpacityAnimation;
  late final Animation<double> _radiusLoadingAnimation;
  late final Animation<double> _widthLoadingAnimation;

  final heightSize = 35.0;

  @override
  void initState() {
    super.initState();

    _opacityLoadingBackgroundAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3),
    ));

    _internalLoadingChildOpacityAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0),
    ));
    _radiusLoadingAnimation =
        Tween<double>(begin: 12, end: heightSize / 2).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3),
    ));
    _widthLoadingAnimation =
        Tween<double>(begin: 120, end: heightSize).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.6),
    ));
  }

  @override
  void didUpdateWidget(covariant StatusAppButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    useListenable(_controller);
    final backgroundColor = Colors.grey[200]!;
    final textColor = Colors.grey[700]!;

    return Stack(
      children: [
        if (_opacityLoadingBackgroundAnimation.value < 1.0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_radiusLoadingAnimation.value),
                  bottomLeft: Radius.circular(_radiusLoadingAnimation.value),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_radiusLoadingAnimation.value),
                    bottomLeft: Radius.circular(_radiusLoadingAnimation.value),
                  ),
                  onTap: widget.onTap,
                  child: Container(
                    width: _widthLoadingAnimation.value * 0.7,
                    height: heightSize,
                    alignment: Alignment.center,
                    child: widget.buttonLabel,
                  ),
                ),
              ),
              Gap(_widthLoadingAnimation.value * 0.03),
              Material(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(_radiusLoadingAnimation.value),
                  bottomRight: Radius.circular(_radiusLoadingAnimation.value),
                ),
                color: backgroundColor,
                child: InkWell(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(_radiusLoadingAnimation.value),
                    bottomRight: Radius.circular(_radiusLoadingAnimation.value),
                  ),
                  onTap: widget.onOptions,
                  child: Container(
                    width: _widthLoadingAnimation.value * 0.27,
                    height: heightSize,
                    alignment: Alignment.center,
                    child: Icon(Icons.more_vert, color: textColor, size: 20),
                  ),
                ),
              ),
            ],
          ),
        if (_opacityLoadingBackgroundAnimation.value > 0)
          Opacity(
            opacity: _opacityLoadingBackgroundAnimation.value,
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.all(
                  Radius.circular(_radiusLoadingAnimation.value)),
              child: InkWell(
                onTap: widget.onCancel,
                borderRadius: BorderRadius.all(
                    Radius.circular(_radiusLoadingAnimation.value)),
                child: Container(
                  width: _widthLoadingAnimation.value,
                  height: heightSize,
                  alignment: Alignment.center,
                  child: Opacity(
                    opacity: _internalLoadingChildOpacityAnimation.value,
                    child: Stack(
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            color: textColor,
                            value: widget.progress,
                          ),
                        ),
                        Center(
                          child: Container(
                            width: heightSize * 0.4,
                            height: heightSize * 0.4,
                            decoration: BoxDecoration(
                              color: textColor,
                              borderRadius: BorderRadius.circular(3),
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
      ],
    );
  }
}
