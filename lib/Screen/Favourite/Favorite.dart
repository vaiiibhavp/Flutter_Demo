import 'dart:async';
import 'package:eshop_multivendor/Provider/CartProvider.dart';
import 'package:eshop_multivendor/Provider/explore_provider.dart';
import 'package:eshop_multivendor/Screen/SQLiteData/SqliteData.dart';
import 'package:eshop_multivendor/Provider/Favourite/FavoriteProvider.dart';
import 'package:eshop_multivendor/Screen/Favourite/Widget/FavProductData.dart';
import 'package:eshop_multivendor/widgets/desing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Helper/Color.dart';
import '../../Helper/String.dart';
import '../../widgets/appBar.dart';
import '../Language/languageSettings.dart';
import '../../widgets/networkAvailablity.dart';
import '../../widgets/simmerEffect.dart';
import '../NoInterNetWidget/NoInterNet.dart';

class Favorite extends StatefulWidget {
  const Favorite({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StateFav();
}

class StateFav extends State<Favorite> with TickerProviderStateMixin {
  Animation? buttonSqueezeanimation;
  final List<TextEditingController> controllerText = [];
  AnimationController? buttonController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  ScrollController controller = ScrollController();
  List<String>? proIds;
  var db = DatabaseHelper();
  bool isLoadingMore = false;

  backFromCartFunct() {
    _refresh();
    setState(() {});
  }

  setStateNow() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    callApi();
    controller.addListener(_scrollListener);
    buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  callApi() async {
    if (CUR_USERID != null) {
      Future.delayed(Duration.zero).then(
        (value) => context.read<FavoriteProvider>().getFav(isLoadingMore: true),
      );
    } else {
      context.read<FavoriteProvider>().changeStatus(FavStatus.inProgress);
      proIds = (await db.getFav())!;
      context
          .read<FavoriteProvider>()
          .getOfflineFavorateProducts(context, setStateNow)
          .then(
        (value) {
          context.read<FavoriteProvider>().changeStatus(FavStatus.isSuccsess);
        },
      );
    }
  }

  _scrollListener() async {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange &&
        !isLoadingMore) {
      if (mounted) {
        if (context.read<FavoriteProvider>().hasMoreData) {
          setState(
            () {
              isLoadingMore = true;
            },
          );

          await context
              .read<FavoriteProvider>()
              .getFav(isLoadingMore: false)
              .then(
            (value) {
              setState(
                () {
                  isLoadingMore = false;
                },
              );
            },
          );
        }
      }
    }
  }

  @override
  void dispose() {
    buttonController!.dispose();
    controller.dispose();
    for (int i = 0;
        i < context.read<FavoriteProvider>().controllerText.length;
        i++) {
      context.read<FavoriteProvider>().controllerText[i].dispose();
    }
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  setStateNoInternate() async {
    _playAnimation();
    Future.delayed(const Duration(seconds: 2)).then(
      (_) async {
        isNetworkAvail = await isNetworkAvailable();
        if (isNetworkAvail) {
          Future.delayed(Duration.zero).then(
            (value) =>
                context.read<FavoriteProvider>().getFav(isLoadingMore: false),
          );
        } else {
          await buttonController!.reverse();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          getAppBar(getTranslated(context, 'FAVORITE')!, context, setStateNow),
      body: isNetworkAvail
          ? _showContent(context)
          : NoInterNet(
              buttonController: buttonController,
              buttonSqueezeanimation: buttonSqueezeanimation,
              setStateNoInternate: setStateNoInternate,
            ),
    );
  }

  Future _refresh() async {
    if (mounted) {
      if (CUR_USERID != null) {
        return Future.delayed(Duration.zero).then((value) =>
            context.read<FavoriteProvider>().getFav(isLoadingMore: true));
      } else {
        proIds = (await db.getFav())!;
        return context
            .read<FavoriteProvider>()
            .getOfflineFavorateProducts(context, setStateNow);
      }
    }
  }

  _showContent(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, value, child) {
        if (value.getCurrentStatus == FavStatus.isSuccsess) {
          return value.favoriteList.isEmpty
              ? Center(
                  child: Text(
                    getTranslated(context, 'noFav')!,
                    style: const TextStyle(
                      fontFamily: 'ubuntu',
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: colors.primary,
                  key: _refreshIndicatorKey,
                  onRefresh: _refresh,
                  child: NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: (overscroll) {
                      overscroll.disallowIndicator();
                      return true;
                    },
                    child: Stack(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          controller: controller,
                          itemCount: value.favoriteList.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (controllerText.length < index + 1) {
                              controllerText.add(TextEditingController());
                            }
                            if (controllerText.length < index + 1) {
                              controllerText.add(TextEditingController());
                            }
                            controllerText[index].text = value.favoriteList[index]
                                .prVarientList![context
                                .read<ExploreProvider>()
                                .productList[index]
                                .selVarient!]
                                .cartCount!;
                            return (index == value.favoriteList.length &&
                                    isLoadingMore)
                                ? const SingleItemSimmer()
                                : FavProductData(
                                    controller:controllerText[index],
                                    index: index,
                                    favList: value.favoriteList,
                                    updateNow: setStateNow,
                                  );
                          },
                        ),
                        Selector<CartProvider, bool>(
                          builder: (context, data, child) {
                            return DesignConfiguration.showCircularProgress(
                              data,
                              colors.primary,
                            );
                          },
                          selector: (_, provider) => provider.isProgress,
                        )
                      ],
                    ),
                  ),
                );
        } else if (value.getCurrentStatus == FavStatus.isFailure) {
          return Center(
            child: Text(
              value.errorMessage,
              style: const TextStyle(
                fontFamily: 'ubuntu',
              ),
            ),
          );
        }
        return const ShimmerEffect();
      },
    );
  }
}
