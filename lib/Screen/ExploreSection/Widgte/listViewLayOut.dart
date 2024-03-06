import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Helper/routes.dart';
import 'package:eshop_multivendor/Provider/CartProvider.dart';
import 'package:eshop_multivendor/Provider/SettingProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Provider/homePageProvider.dart';
import 'package:eshop_multivendor/Provider/productDetailProvider.dart';
import 'package:eshop_multivendor/Screen/ProductDetail/Widget/commanFiledsofProduct.dart';
import 'package:eshop_multivendor/widgets/networkAvailablity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../../Helper/Constant.dart';
import '../../../Helper/String.dart';
import '../../../Model/Section_Model.dart';
import '../../../Provider/Favourite/FavoriteProvider.dart';
import '../../../Provider/explore_provider.dart';
import '../../../widgets/desing.dart';
import '../../../widgets/snackbar.dart';
import '../../../widgets/star_rating.dart';
import '../../Dashboard/Dashboard.dart';
import '../../Language/languageSettings.dart';
import '../../ProductDetail/productDetail.dart';

// ignore: library_prefixes
import '../../ProductList&SectionView/ProductList.dart';
import '../../SellerDetail/Seller_Details.dart' as sellerDetail;
import '../explore.dart' as explore;

// ignore: must_be_immutable
class ListViewLayOut extends StatefulWidget {
  bool fromExplore;
  Function update;
  Widget? addToCart;

  ListViewLayOut(
      {Key? key,
      required this.fromExplore,
      required this.update,
      this.addToCart})
      : super(key: key);

  @override
  State<ListViewLayOut> createState() => _ListViewLayOutState();
}

class _ListViewLayOutState extends State<ListViewLayOut> {
  int selectedPos = 0;
  bool? available, outOfStock;
  int? selectIndex = 0;
  final List<int?> _selectedIndex = [];
  Widget? choiceContainer;

  setStateNow() {
    setState(() {});
  }

  int _oldSelVarient = 0;

  cartTotalClear() {
    context.read<CartProvider>().totalPrice = 0;
    context.read<CartProvider>().taxPer = 0;
    context.read<CartProvider>().deliveryCharge = 0;
    context.read<CartProvider>().addressList.clear();
    context.read<CartProvider>().promoAmt = 0;
    context.read<CartProvider>().remWalBal = 0;
    context.read<CartProvider>().usedBalance = 0;
    context.read<CartProvider>().payMethod = null;
    context.read<CartProvider>().isPromoValid = false;
    context.read<CartProvider>().isPromoLen = false;
    context.read<CartProvider>().isUseWallet = false;
    context.read<CartProvider>().isPayLayShow = true;
    context.read<CartProvider>().selectedMethod = null;
    context.read<CartProvider>().selectedTime = null;
    context.read<CartProvider>().selectedDate = null;
    context.read<CartProvider>().selAddress = '';
    context.read<CartProvider>().selTime = '';
    context.read<CartProvider>().selDate = '';
    context.read<CartProvider>().promocode = '';
  }

  void confirmDialog() {
    showGeneralDialog(
      barrierColor: Theme.of(context).colorScheme.black.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(
            opacity: a1.value,
            child: AlertDialog(
              contentPadding: const EdgeInsets.all(0),
              elevation: 2.0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    circularBorderRadius5,
                  ),
                ),
              ),
              content: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  height: 110,
                  child: Column(
                    children: [
                      Text(
                        getTranslated(context,
                            'Your cart already has an items of another seller would you like to remove it ?')!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.lightBlack,
                          fontSize: textFontSize14,
                          fontFamily: 'ubuntu',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: SvgPicture.asset(
                            DesignConfiguration.setSvgPath('appbarCart'),
                            colorFilter: const ColorFilter.mode(
                                colors.primary, BlendMode.srcIn),
                            height: 50,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    getTranslated(context, 'CANCEL')!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack,
                      fontSize: textFontSize15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                  onPressed: () {
                    Routes.pop(context);
                  },
                ),
                TextButton(
                  child: Text(
                    getTranslated(context, 'Clear Cart')!,
                    style: const TextStyle(
                      color: colors.primary,
                      fontSize: textFontSize15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ubuntu',
                    ),
                  ),
                  onPressed: () {
                    if (CUR_USERID != null) {
                      context.read<UserProvider>().setCartCount('0');
                      context.read<ProductDetailProvider>().clearCartNow().then(
                            (value) {},
                          );
                      Future.delayed(const Duration(seconds: 1)).then(
                        (_) {
                          if (context.read<ProductDetailProvider>().error ==
                              false) {
                            if (context
                                    .read<ProductDetailProvider>()
                                    .snackbarmessage ==
                                'Data deleted successfully') {
                              setSnackbar(
                                  getTranslated(
                                      context, 'Cart Clear successfully ...!')!,
                                  context);
                            } else {
                              setSnackbar(
                                  context
                                      .read<ProductDetailProvider>()
                                      .snackbarmessage,
                                  context);
                            }
                          } else {
                            setSnackbar(
                                context
                                    .read<ProductDetailProvider>()
                                    .snackbarmessage,
                                context);
                          }
                          Routes.pop(context);
                        },
                      );
                    } else {
                      context.read<SettingProvider>().setCurrentSellerID('');
                      CurrentSellerID = '';
                      db.clearCart();
                      context.read<UserProvider>().setCartCount('0');
                      cartTotalClear();
                      Routes.pop(context);
                    }
                  },
                )
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: false,
      barrierLabel: '',
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return const SizedBox();
      },
    );
  }

  showSanckBarNowForAdd(
    Response response,
    Product model,
    int index,
  ) {
    //
    var getdata = json.decode(response.body);

    bool error = getdata['error'];
    String? msg = getdata['message'];
    if (!error) {
      index == -1
          ? model.isFav = '1'
          : context.read<ExploreProvider>().productList[index].isFav = '1';
      context.read<FavoriteProvider>().addFavItem(model);
      setSnackbar(msg!, context);
    } else {
      setSnackbar(msg!, context);
    }
    index == -1
        ? model.isFavLoading = false
        : context.read<ExploreProvider>().productList[index].isFavLoading =
            false;
    widget.update();
    setState(() {});
  }


  showSanckBarNowForRemove(
    Response response,
    int index,
    Product model,
  ) {
    //
    var getdata = json.decode(response.body);
    bool error = getdata['error'];
    String? msg = getdata['message'];
    if (!error) {
      index == -1
          ? model.isFav = '0'
          : context.read<ExploreProvider>().productList[index].isFav = '0';
      context
          .read<FavoriteProvider>()
          .removeFavItem(model.prVarientList![0].id!);
      setSnackbar(msg!, context);
    } else {
      setSnackbar(msg!, context);
    }
    index == -1
        ? model.isFavLoading = false
        : context.read<ExploreProvider>().productList[index].isFavLoading =
            false;
    widget.update();
  }

  List<String> proIds1 = [];
  List<Product> mostFavProList = [];

  getProFavIds(Product? model) async {
    proIds1 = (await db.getMostFav())!;
    getMostFavPro(model);
  }

  Future<void> getMostFavPro(Product? model) async {
    if (proIds1.isNotEmpty) {
      isNetworkAvail = await isNetworkAvailable();

      if (isNetworkAvail) {
        try {
          var parameter = {'product_ids': proIds1.join(',')};

          ApiBaseHelper().postAPICall(getProductApi, parameter).then(
              (getdata) async {
            bool error = getdata['error'];
            if (!error) {
              var data = getdata['data'];

              List<Product> tempList =
                  (data as List).map((data) => Product.fromJson(data)).toList();
              mostFavProList.clear();
              bool currentProductCheckingFlag = false;
              for (var element in tempList) {
                if (element.id == model!.id) {
                  currentProductCheckingFlag = true;
                }
              }
              if (!currentProductCheckingFlag) {
                mostFavProList.addAll(tempList);
              } else {
                tempList.removeWhere((element) => element.id == model!.id);
                mostFavProList.addAll(tempList);
              }
            }
            if (mounted) {
              setState(
                () {
                  context.read<HomePageProvider>().mostLikeLoading = false;
                },
              );
            }
          }, onError: (error) {
            setSnackbar(error.toString(), context);
          });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<HomePageProvider>().mostLikeLoading = false;
        }
      } else {
        if (mounted) {
          setState(() {
            isNetworkAvail = false;
            context.read<HomePageProvider>().mostLikeLoading = false;
          });
        }
      }
    } else {
      context.read<CartProvider>().setCartlist([]);
      setState(
        () {
          context.read<HomePageProvider>().mostLikeLoading = false;
        },
      );
    }
  }

  _setFav(int index, int from, Product? model) async {
    try {
      isNetworkAvail = await isNetworkAvailable();
      if (isNetworkAvail) {
        try {
          if (mounted) {
            setState(
              () {
                index == -1
                    ? model!.isFavLoading = true
                    : from == 1
                        ? context
                            .read<ExploreProvider>()
                            .productList[index]
                            .isFavLoading = true
                        : mostFavProList[index].isFavLoading = true;
              },
            );
          }
          var parameter = {
            USER_ID: CUR_USERID,
            PRODUCT_ID: from == 1
                ? context.read<ExploreProvider>().productList[index].id
                : model!.id
          };
          ApiBaseHelper().postAPICall(setFavoriteApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];
              if (!error) {
                index == -1
                    ? model!.isFav = '1'
                    : from == 1
                        ? context
                            .read<ExploreProvider>()
                            .productList[index]
                            .isFav = '1'
                        : mostFavProList[index].isFav = '1';
                context.read<FavoriteProvider>().addFavItem(from == 1
                    ? context.read<ExploreProvider>().productList[index]
                    : model);
                setSnackbar(msg!, context);
              } else {
                setSnackbar(msg!, context);
              }

              if (mounted) {
                setState(
                  () {
                    index == -1
                        ? model!.isFavLoading = false
                        : context
                            .read<ExploreProvider>()
                            .productList[index]
                            .isFavLoading = false;
                  },
                );
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(
            () {
              isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  _removeFav(int index, int from, Product? model) async {
    try {
      isNetworkAvail = await isNetworkAvailable();
      if (isNetworkAvail) {
        try {
          if (mounted) {
            setState(
              () {
                index == -1
                    ? model!.isFavLoading = true
                    : from == 1
                        ? context
                            .read<ExploreProvider>()
                            .productList[index]
                            .isFavLoading = true
                        : mostFavProList[index].isFavLoading = true;
              },
            );
          }
          var parameter = {
            USER_ID: CUR_USERID,
            PRODUCT_ID: from == 1
                ? context.read<ExploreProvider>().productList[index].id
                : model!.id,
          };
          ApiBaseHelper().postAPICall(removeFavApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];
              if (!error) {
                index == -1
                    ? model!.isFav = '0'
                    : from == 1
                        ? context
                            .read<ExploreProvider>()
                            .productList[index]
                            .isFav = '1'
                        : mostFavProList[index].isFav = '1';
                context.read<FavoriteProvider>().removeFavItem(
                      from == 1
                          ? context
                              .read<ExploreProvider>()
                              .productList[index]
                              .prVarientList![0]
                              .id!
                          : model!.prVarientList![0].id!,
                    );
                setSnackbar(msg!, context);
              } else {
                setSnackbar(msg!, context);
              }
              if (mounted) {
                setState(
                  () {
                    index == -1
                        ? model!.isFavLoading = false
                        : from == 1
                            ? context
                                .read<ExploreProvider>()
                                .productList[index]
                                .isFavLoading = false
                            : mostFavProList[index].isFavLoading = false;
                  },
                );
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
        }
      } else {
        if (mounted) {
          setState(
            () {
              isNetworkAvail = false;
            },
          );
        }
      }
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (overscroll) {
        overscroll.disallowIndicator();
        return true;
      },
      child: Stack(
        children: [
          ListView.builder(
            itemCount: context.read<ExploreProvider>().isFilter
                ? (context
                    .read<ExploreProvider>()
                    .productList
                    .where((element) =>
                        element.catName ==
                        context.read<ExploreProvider>().filterCategoryName)
                    .toList()
                    .length)
                : context.read<ExploreProvider>().productList.length,
            shrinkWrap: true,
            controller: widget.fromExplore
                ? explore.productsController
                : sellerDetail.productsController,
            itemBuilder: (BuildContext context, int index) {
              if (controllerText.length < index + 1) {
                controllerText.add(TextEditingController());
              }
              double price = double.parse(context
                  .read<ExploreProvider>()
                  .productList[index]
                  .prVarientList![0]
                  .disPrice!);
              if (price == 0) {
                price = double.parse(context
                    .read<ExploreProvider>()
                    .productList[index]
                    .prVarientList![0]
                    .price!);
              }
              if (controllerText.length < index + 1) {
                controllerText.add(TextEditingController());
              }
              controllerText[index].text = context
                  .read<ExploreProvider>()
                  .productList[index]
                  .prVarientList![context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!]
                  .cartCount!;
              double total = 0;
              return Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 10.0, end: 10.0, top: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.white,
                    borderRadius: BorderRadius.circular(circularBorderRadius10),
                  ),
                  child: InkWell(
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(
                              flex: 1,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft:
                                          Radius.circular(circularBorderRadius4),
                                      bottomLeft:
                                          Radius.circular(circularBorderRadius4),
                                    ),
                                    child: DesignConfiguration.getCacheNotworkImage(
                                      boxFit: BoxFit.cover,
                                      context: context,
                                      heightvalue: 107,
                                      widthvalue: 107,
                                      placeHolderSize: 50,
                                      imageurlString: context
                                          .read<ExploreProvider>()
                                          .productList[index]
                                          .image!,
                                    ),
                                  ),
                                  context
                                              .read<ExploreProvider>()
                                              .productList[index]
                                              .availability ==
                                          '0'
                                      ? Container(
                                          height: 107,
                                          width: 107,
                                          decoration: const BoxDecoration(
                                            color: colors.white70,
                                          ),
                                          child: Center(
                                            child: Text(
                                              getTranslated(
                                                  context, 'OUT_OF_STOCK_LBL')!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge!
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.red,
                                                    fontFamily: 'ubuntu',
                                                  ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox()
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        top: 15.0, start: 15.0),
                                    child: Text(
                                      context
                                          .read<ExploreProvider>()
                                          .productList[index]
                                          .name!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                              fontFamily: 'ubuntu',
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontWeight: FontWeight.w500,
                                              fontStyle: FontStyle.normal,
                                              fontSize: textFontSize14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  (context
                                              .read<ExploreProvider>()
                                              .productList[index]
                                              .brandName
                                              ?.isNotEmpty ??
                                          false)
                                      ? Padding(
                                          padding: const EdgeInsetsDirectional.only(
                                              top: 10.0, start: 15.0),
                                          child: Text(
                                            (context
                                                        .read<ExploreProvider>()
                                                        .productList[index]
                                                        .brandName
                                                        ?.isNotEmpty ??
                                                    false)
                                                ? 'Brand : ${context.read<ExploreProvider>().productList[index].brandName}'
                                                : '${context.read<ExploreProvider>().productList[index].brandName}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    fontFamily: 'ubuntu',
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: textFontSize12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        )
                                      : const SizedBox(),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        start: 15.0, top: 8.0),
                                    child: CUR_USERID != null
                                        ? Row(
                                            children: [
                                              Text(
                                                '₹ ${DesignConfiguration.getPriceFormat(context, price)}',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'ubuntu',
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 3,
                                              ),
                                              Text(
                                                double.parse(context
                                                            .read<ExploreProvider>()
                                                            .productList[index]
                                                            .prVarientList![0]
                                                            .disPrice!) !=
                                                        0
                                                    ? '₹ ${DesignConfiguration.getPriceFormat(context, double.parse(context.read<ExploreProvider>().productList[index].prVarientList![0].price!))}'
                                                    : '',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall!
                                                    .copyWith(
                                                        fontFamily: 'ubuntu',
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .lightBlack,
                                                        decoration: TextDecoration
                                                            .lineThrough,
                                                        decorationColor:
                                                            colors.darkColor3,
                                                        decorationStyle:
                                                            TextDecorationStyle
                                                                .solid,
                                                        decorationThickness: 2,
                                                        letterSpacing: 0),
                                              ),
                                            ],
                                          )
                                        : InkWell(
                                            onTap: () {
                                              Routes.navigateToLoginScreen(context);
                                            },
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.35,
                                              child: Text(
                                                'Login To See Price',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'ubuntu',
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsetsDirectional.only(
                                            top: 8.0, start: 15.0),
                                        child: StarRating(
                                          noOfRatings: context
                                              .read<ExploreProvider>()
                                              .productList[index]
                                              .noOfRating!,
                                          totalRating: context
                                              .read<ExploreProvider>()
                                              .productList[index]
                                              .rating!,
                                          needToShowNoOfRatings: true,
                                        ),
                                      ),
                                      // const Spacer(),
                                      // InkWell(
                                      //   child: Card(
                                      //     shape:
                                      //     RoundedRectangleBorder(
                                      //       borderRadius:
                                      //       BorderRadius
                                      //           .circular(
                                      //         circularBorderRadius50,
                                      //       ),
                                      //     ),
                                      //     child:
                                      //     const Padding(
                                      //       padding:
                                      //       EdgeInsets
                                      //           .all(
                                      //         10.0,
                                      //       ),
                                      //       child: Icon(
                                      //         Icons.remove,
                                      //         size: 15,
                                      //       ),
                                      //     ),
                                      //   ),
                                      //   onTap: () {
                                      //     if (isProgress ==
                                      //         false &&
                                      //         (int.parse(controllerText[
                                      //         index]
                                      //             .text) >
                                      //             0)) {
                                      //       removeCart(
                                      //           index,
                                      //           context
                                      //               .read<
                                      //               ExploreProvider>()
                                      //               .productList);
                                      //     }
                                      //   },
                                      // ),
                                      // SizedBox(
                                      //   width: 37,
                                      //   height: 20,
                                      //   child: Stack(
                                      //     children: [
                                      //       TextField(
                                      //         textAlign:
                                      //         TextAlign
                                      //             .center,
                                      //         readOnly: true,
                                      //         style: TextStyle(
                                      //             fontSize:
                                      //             textFontSize12,
                                      //             color: Theme
                                      //                 .of(
                                      //                 context)
                                      //                 .colorScheme
                                      //                 .fontColor),
                                      //         controller:
                                      //         controllerText[
                                      //         index],
                                      //         decoration:
                                      //         const InputDecoration(
                                      //           border:
                                      //           InputBorder
                                      //               .none,
                                      //         ),
                                      //       ),
                                      //       PopupMenuButton<
                                      //           String>(
                                      //         tooltip: '',
                                      //         icon:
                                      //         const Icon(
                                      //           Icons
                                      //               .arrow_drop_down,
                                      //           size: 1,
                                      //         ),
                                      //         onSelected:
                                      //             (String
                                      //         value) {
                                      //           // if (isProgress == false) {
                                      //           //   addToCart(widget.index!, value, 2);
                                      //           // }
                                      //         },
                                      //         itemBuilder:
                                      //             (BuildContext
                                      //         context) {
                                      //           return context
                                      //               .read<
                                      //               ExploreProvider>()
                                      //               .productList[
                                      //           index]
                                      //               .itemsCounter!
                                      //               .map<
                                      //               PopupMenuItem<
                                      //                   String>>(
                                      //                 (String
                                      //             value) {
                                      //               return PopupMenuItem(
                                      //                   value:
                                      //                   value,
                                      //                   child: Text(
                                      //                       value,
                                      //                       style: TextStyle(
                                      //                           color: Theme
                                      //                               .of(context)
                                      //                               .colorScheme
                                      //                               .fontColor)));
                                      //             },
                                      //           ).toList();
                                      //         },
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      // InkWell(
                                      //   child: Card(
                                      //     shape:
                                      //     RoundedRectangleBorder(
                                      //       borderRadius:
                                      //       BorderRadius
                                      //           .circular(
                                      //           circularBorderRadius50),
                                      //     ),
                                      //     child:
                                      //     const Padding(
                                      //       padding:
                                      //       EdgeInsets
                                      //           .all(10.0),
                                      //       child: Icon(
                                      //         Icons.add,
                                      //         size: 15,
                                      //       ),
                                      //     ),
                                      //   ),
                                      //   onTap: () {
                                      //     if (isProgress ==
                                      //         false) {
                                      //       if ((context
                                      //           .read<
                                      //           ExploreProvider>()
                                      //           .productList[
                                      //       index]
                                      //           .prVarientList
                                      //           ?.length ??
                                      //           1) >
                                      //           1) {
                                      //         showDialog(
                                      //           context:
                                      //           context,
                                      //           builder:
                                      //               (BuildContext
                                      //           context) {
                                      //             List<String> selList = context
                                      //                 .read<
                                      //                 ExploreProvider>()
                                      //                 .productList[
                                      //             index]
                                      //                 .prVarientList![
                                      //             _oldSelVarient]
                                      //                 .attribute_value_ids!
                                      //                 .split(
                                      //                 ',');
                                      //             _selectedIndex
                                      //                 .clear();
                                      //             for (int i =
                                      //             0;
                                      //             i < context
                                      //                 .read<ExploreProvider>()
                                      //                 .productList[index]
                                      //                 .attributeList!.length;
                                      //             i++) {
                                      //               List<
                                      //                   String> sinList = context
                                      //                   .read<
                                      //                   ExploreProvider>()
                                      //                   .productList[
                                      //               index]
                                      //                   .attributeList![
                                      //               i]
                                      //                   .id!
                                      //                   .split(
                                      //                   ',');
                                      //
                                      //               for (int j =
                                      //               0;
                                      //               j < sinList.length;
                                      //               j++) {
                                      //                 if (selList
                                      //                     .contains(
                                      //                     sinList[j])) {
                                      //                   _selectedIndex.insert(
                                      //                       i,
                                      //                       j);
                                      //                 }
                                      //               }
                                      //
                                      //               if (_selectedIndex
                                      //                   .length ==
                                      //                   i) {
                                      //                 _selectedIndex.insert(
                                      //                     i,
                                      //                     null);
                                      //               }
                                      //             }
                                      //             return StatefulBuilder(
                                      //               builder: (BuildContext
                                      //               context,
                                      //                   StateSetter
                                      //                   setStater) {
                                      //                 return AlertDialog(
                                      //                   contentPadding:
                                      //                   const EdgeInsets.all(
                                      //                       0.0),
                                      //                   shape:
                                      //                   const RoundedRectangleBorder(
                                      //                     borderRadius:
                                      //                     BorderRadius.all(
                                      //                       Radius.circular(
                                      //                           circularBorderRadius5),
                                      //                     ),
                                      //                   ),
                                      //                   content:
                                      //                   Padding(
                                      //                     padding: const EdgeInsetsDirectional
                                      //                         .only(
                                      //                         start: 10.0,
                                      //                         end: 10.0,
                                      //                         top: 5.0),
                                      //                     child:
                                      //                     Container(
                                      //                       height: MediaQuery
                                      //                           .of(context)
                                      //                           .size
                                      //                           .height * 0.47,
                                      //                       decoration: BoxDecoration(
                                      //                         color: Theme
                                      //                             .of(context)
                                      //                             .colorScheme
                                      //                             .white,
                                      //                         borderRadius: BorderRadius
                                      //                             .circular(
                                      //                             circularBorderRadius10),
                                      //                       ),
                                      //                       child: Column(
                                      //                         children: [
                                      //                           InkWell(
                                      //                             child: Stack(
                                      //                               children: [
                                      //                                 Row(
                                      //                                   crossAxisAlignment: CrossAxisAlignment
                                      //                                       .start,
                                      //                                   children: [
                                      //                                     Flexible(
                                      //                                       flex: 1,
                                      //                                       child: ClipRRect(
                                      //                                         borderRadius: const BorderRadius
                                      //                                             .only(
                                      //                                           topLeft: Radius
                                      //                                               .circular(
                                      //                                               circularBorderRadius4),
                                      //                                           bottomLeft: Radius
                                      //                                               .circular(
                                      //                                               circularBorderRadius4),
                                      //                                         ),
                                      //                                         child: DesignConfiguration
                                      //                                             .getCacheNotworkImage(
                                      //                                           boxFit: BoxFit
                                      //                                               .cover,
                                      //                                           context: context,
                                      //                                           heightvalue: 107,
                                      //                                           widthvalue: 107,
                                      //                                           placeHolderSize: 50,
                                      //                                           imageurlString: context
                                      //                                               .read<
                                      //                                               ExploreProvider>()
                                      //                                               .productList[index]
                                      //                                               .image!,
                                      //                                         ),
                                      //                                       ),
                                      //                                     ),
                                      //                                     Column(
                                      //                                       crossAxisAlignment: CrossAxisAlignment
                                      //                                           .start,
                                      //                                       children: [
                                      //                                         context
                                      //                                             .read<
                                      //                                             ExploreProvider>()
                                      //                                             .productList[index]
                                      //                                             .brandName !=
                                      //                                             '' &&
                                      //                                             context
                                      //                                                 .read<
                                      //                                                 ExploreProvider>()
                                      //                                                 .productList[index]
                                      //                                                 .brandName !=
                                      //                                                 null
                                      //                                             ? Padding(
                                      //                                           padding: const EdgeInsets
                                      //                                               .only(
                                      //                                             left: 15.0,
                                      //                                             right: 15.0,
                                      //                                             top: 16.0,
                                      //                                           ),
                                      //                                           child: Text(
                                      //                                             context
                                      //                                                 .read<
                                      //                                                 ExploreProvider>()
                                      //                                                 .productList[index]
                                      //                                                 .brandName ??
                                      //                                                 '',
                                      //                                             style: TextStyle(
                                      //                                               fontWeight: FontWeight
                                      //                                                   .bold,
                                      //                                               color: Theme
                                      //                                                   .of(
                                      //                                                   context)
                                      //                                                   .colorScheme
                                      //                                                   .lightBlack,
                                      //                                               fontSize: textFontSize14,
                                      //                                             ),
                                      //                                           ),
                                      //                                         )
                                      //                                             : const SizedBox(),
                                      //                                         GetTitleWidget(
                                      //                                           title: context
                                      //                                               .read<
                                      //                                               ExploreProvider>()
                                      //                                               .productList[index]
                                      //                                               .name ??
                                      //                                               '',
                                      //                                         ),
                                      //                                         available ??
                                      //                                             false ||
                                      //                                                 (outOfStock ??
                                      //                                                     false)
                                      //                                             ? GetPrice(
                                      //                                             pos: selectIndex,
                                      //                                             from: true,
                                      //                                             model: context
                                      //                                                 .read<
                                      //                                                 ExploreProvider>()
                                      //                                                 .productList[index])
                                      //                                             : GetPrice(
                                      //                                           pos: context
                                      //                                               .read<
                                      //                                               ExploreProvider>()
                                      //                                               .productList[index]
                                      //                                               .selVarient,
                                      //                                           from: false,
                                      //                                           model: context
                                      //                                               .read<
                                      //                                               ExploreProvider>()
                                      //                                               .productList[index],
                                      //                                         ),
                                      //                                       ],
                                      //                                     )
                                      //                                   ],
                                      //                                 ),
                                      //                               ],
                                      //                             ),
                                      //                             // onTap: () async {
                                      //                             //   Product model = context.read<ExploreProvider>().productList[index];
                                      //                             //   Navigator.push(
                                      //                             //     context,
                                      //                             //     PageRouteBuilder(
                                      //                             //       pageBuilder: (_, __, ___) => ProductDetail(
                                      //                             //         model: model,
                                      //                             //         secPos: 0,
                                      //                             //         index: index,
                                      //                             //         list: true,
                                      //                             //       ),
                                      //                             //     ),
                                      //                             //   );
                                      //                             // },
                                      //                           ),
                                      //                           Container(
                                      //                             color: Theme
                                      //                                 .of(
                                      //                                 context)
                                      //                                 .colorScheme
                                      //                                 .white,
                                      //                             child: Column(
                                      //                               crossAxisAlignment: CrossAxisAlignment
                                      //                                   .start,
                                      //                               mainAxisSize: MainAxisSize
                                      //                                   .min,
                                      //                               children: [
                                      //                                 Container(
                                      //                                   height: MediaQuery
                                      //                                       .of(
                                      //                                       context)
                                      //                                       .size
                                      //                                       .height *
                                      //                                       0.28,
                                      //                                   width: MediaQuery
                                      //                                       .of(
                                      //                                       context)
                                      //                                       .size
                                      //                                       .height *
                                      //                                       0.6,
                                      //                                   color: Theme
                                      //                                       .of(
                                      //                                       context)
                                      //                                       .colorScheme
                                      //                                       .white,
                                      //                                   child: Padding(
                                      //                                     padding: const EdgeInsets
                                      //                                         .only(
                                      //                                         top: 15.0),
                                      //                                     child: ListView
                                      //                                         .builder(
                                      //                                       scrollDirection: Axis
                                      //                                           .vertical,
                                      //                                       physics: const BouncingScrollPhysics(),
                                      //                                       itemCount: context
                                      //                                           .read<
                                      //                                           ExploreProvider>()
                                      //                                           .productList[index]
                                      //                                           .attributeList!
                                      //                                           .length,
                                      //                                       itemBuilder: (
                                      //                                           context,
                                      //                                           indexAt) {
                                      //                                         List<
                                      //                                             Widget?> chips = [
                                      //                                         ];
                                      //                                         List<
                                      //                                             String> att = context
                                      //                                             .read<
                                      //                                             ExploreProvider>()
                                      //                                             .productList[index]
                                      //                                             .attributeList![indexAt]
                                      //                                             .value!
                                      //                                             .split(
                                      //                                             ',');
                                      //                                         List<
                                      //                                             String> attId = context
                                      //                                             .read<
                                      //                                             ExploreProvider>()
                                      //                                             .productList[index]
                                      //                                             .attributeList![indexAt]
                                      //                                             .id!
                                      //                                             .split(
                                      //                                             ',');
                                      //                                         List<
                                      //                                             String> attSType = context
                                      //                                             .read<
                                      //                                             ExploreProvider>()
                                      //                                             .productList[index]
                                      //                                             .attributeList![indexAt]
                                      //                                             .sType!
                                      //                                             .split(
                                      //                                             ',');
                                      //                                         List<
                                      //                                             String> attSValue = context
                                      //                                             .read<
                                      //                                             ExploreProvider>()
                                      //                                             .productList[index]
                                      //                                             .attributeList![indexAt]
                                      //                                             .sValue!
                                      //                                             .split(
                                      //                                             ',');
                                      //                                         int? varSelected;
                                      //                                         List<
                                      //                                             String> wholeAtt = context
                                      //                                             .read<
                                      //                                             ExploreProvider>()
                                      //                                             .productList[index]
                                      //                                             .attrIds!
                                      //                                             .split(
                                      //                                             ',');
                                      //                                         for (int i = 0; i <
                                      //                                             att
                                      //                                                 .length; i++) {
                                      //                                           Widget itemLabel;
                                      //                                           if (attSType[i] ==
                                      //                                               '1') {
                                      //                                             String clr = (attSValue[i]
                                      //                                                 .substring(
                                      //                                                 1));
                                      //                                             String color = '0xff$clr';
                                      //                                             itemLabel =
                                      //                                                 Container(
                                      //                                                   width: 35,
                                      //                                                   height: 35,
                                      //                                                   decoration: BoxDecoration(
                                      //                                                     shape: BoxShape
                                      //                                                         .circle,
                                      //                                                     color: _selectedIndex[indexAt] ==
                                      //                                                         (i)
                                      //                                                         ? colors
                                      //                                                         .primary
                                      //                                                         : colors
                                      //                                                         .secondary,
                                      //                                                   ),
                                      //                                                   child: Center(
                                      //                                                     child: Container(
                                      //                                                       width: 25,
                                      //                                                       height: 25,
                                      //                                                       decoration: BoxDecoration(
                                      //                                                         shape: BoxShape
                                      //                                                             .circle,
                                      //                                                         color: Color(
                                      //                                                           int
                                      //                                                               .parse(
                                      //                                                               color),
                                      //                                                         ),
                                      //                                                       ),
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                 );
                                      //                                           }
                                      //                                           else
                                      //                                           if (attSType[i] ==
                                      //                                               '2') {
                                      //                                             itemLabel =
                                      //                                                 Container(
                                      //                                                   decoration: BoxDecoration(
                                      //                                                     gradient: LinearGradient(
                                      //                                                         begin: Alignment
                                      //                                                             .topLeft,
                                      //                                                         end: Alignment
                                      //                                                             .bottomRight,
                                      //                                                         colors: _selectedIndex[indexAt] ==
                                      //                                                             (i)
                                      //                                                             ? [
                                      //                                                           colors
                                      //                                                               .grad1Color,
                                      //                                                           colors
                                      //                                                               .grad2Color
                                      //                                                         ]
                                      //                                                             : [
                                      //                                                           Theme
                                      //                                                               .of(
                                      //                                                               context)
                                      //                                                               .colorScheme
                                      //                                                               .white,
                                      //                                                           Theme
                                      //                                                               .of(
                                      //                                                               context)
                                      //                                                               .colorScheme
                                      //                                                               .white,
                                      //                                                         ],
                                      //                                                         stops: const [
                                      //                                                           0,
                                      //                                                           1
                                      //                                                         ]),
                                      //                                                     borderRadius: const BorderRadius
                                      //                                                         .all(
                                      //                                                         Radius
                                      //                                                             .circular(
                                      //                                                             circularBorderRadius8)),
                                      //                                                     border: Border
                                      //                                                         .all(
                                      //                                                       color: _selectedIndex[indexAt] ==
                                      //                                                           (i)
                                      //                                                           ? const Color(
                                      //                                                           0xfffc6a57)
                                      //                                                           : Theme
                                      //                                                           .of(
                                      //                                                           context)
                                      //                                                           .colorScheme
                                      //                                                           .black,
                                      //                                                       width: 1,
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                   child: ClipRRect(
                                      //                                                     borderRadius: BorderRadius
                                      //                                                         .circular(
                                      //                                                         circularBorderRadius8),
                                      //                                                     child: Image
                                      //                                                         .network(
                                      //                                                       attSValue[i],
                                      //                                                       width: 80,
                                      //                                                       height: 80,
                                      //                                                       fit: BoxFit
                                      //                                                           .cover,
                                      //                                                       errorBuilder: (
                                      //                                                           context,
                                      //                                                           error,
                                      //                                                           stackTrace) =>
                                      //                                                           DesignConfiguration
                                      //                                                               .erroWidget(
                                      //                                                               80),
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                 );
                                      //                                           }
                                      //                                           else {
                                      //                                             itemLabel =
                                      //                                                 Container(
                                      //                                                   decoration: BoxDecoration(
                                      //                                                     gradient: LinearGradient(
                                      //                                                       begin: Alignment
                                      //                                                           .topLeft,
                                      //                                                       end: Alignment
                                      //                                                           .bottomRight,
                                      //                                                       colors: _selectedIndex[indexAt] ==
                                      //                                                           (i)
                                      //                                                           ? [
                                      //                                                         colors
                                      //                                                             .grad1Color,
                                      //                                                         colors
                                      //                                                             .grad2Color
                                      //                                                       ]
                                      //                                                           : [
                                      //                                                         Theme
                                      //                                                             .of(
                                      //                                                             context)
                                      //                                                             .colorScheme
                                      //                                                             .white,
                                      //                                                         Theme
                                      //                                                             .of(
                                      //                                                             context)
                                      //                                                             .colorScheme
                                      //                                                             .white,
                                      //                                                       ],
                                      //                                                       stops: const [
                                      //                                                         0,
                                      //                                                         1
                                      //                                                       ],
                                      //                                                     ),
                                      //                                                     borderRadius: const BorderRadius
                                      //                                                         .all(
                                      //                                                         Radius
                                      //                                                             .circular(
                                      //                                                             circularBorderRadius8)),
                                      //                                                     border: Border
                                      //                                                         .all(
                                      //                                                       color: _selectedIndex[indexAt] ==
                                      //                                                           (i)
                                      //                                                           ? const Color(
                                      //                                                           0xfffc6a57)
                                      //                                                           : Theme
                                      //                                                           .of(
                                      //                                                           context)
                                      //                                                           .colorScheme
                                      //                                                           .black,
                                      //                                                       width: 1,
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                   child: Padding(
                                      //                                                     padding: const EdgeInsets
                                      //                                                         .symmetric(
                                      //                                                       horizontal: 15,
                                      //                                                       vertical: 6,
                                      //                                                     ),
                                      //                                                     child: Text(
                                      //                                                       '${att[i]} ${context
                                      //                                                           .read<
                                      //                                                           ExploreProvider>()
                                      //                                                           .productList[index]
                                      //                                                           .attributeList![indexAt]
                                      //                                                           .name}',
                                      //                                                       style: TextStyle(
                                      //                                                         fontFamily: 'ubuntu',
                                      //                                                         color: _selectedIndex[indexAt] ==
                                      //                                                             (i)
                                      //                                                             ? Theme
                                      //                                                             .of(
                                      //                                                             context)
                                      //                                                             .colorScheme
                                      //                                                             .white
                                      //                                                             : Theme
                                      //                                                             .of(
                                      //                                                             context)
                                      //                                                             .colorScheme
                                      //                                                             .fontColor,
                                      //                                                       ),
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                 );
                                      //                                           }
                                      //                                           if (_selectedIndex[indexAt] !=
                                      //                                               null &&
                                      //                                               wholeAtt
                                      //                                                   .contains(
                                      //                                                   attId[i])) {
                                      //                                             choiceContainer =
                                      //                                                 Padding(
                                      //                                                   padding: const EdgeInsets
                                      //                                                       .only(
                                      //                                                     right: 10,
                                      //                                                   ),
                                      //                                                   child: InkWell(
                                      //                                                     onTap: () async {
                                      //                                                       if (att
                                      //                                                           .length !=
                                      //                                                           1) {
                                      //                                                         if (mounted) {
                                      //                                                           setStater(
                                      //                                                                 () {
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ExploreProvider>()
                                      //                                                                   .productList[index]
                                      //                                                                   .selVarient =
                                      //                                                                   i;
                                      //                                                               available =
                                      //                                                               false;
                                      //                                                               _selectedIndex[indexAt] =
                                      //                                                                   i;
                                      //                                                               List<
                                      //                                                                   int> selectedId = [
                                      //                                                               ]; //list where user choosen item id is stored
                                      //                                                               List<
                                      //                                                                   bool> check = [
                                      //                                                               ];
                                      //                                                               for (int i = 0; i <
                                      //                                                                   context
                                      //                                                                       .read<
                                      //                                                                       ExploreProvider>()
                                      //                                                                       .productList[index]
                                      //                                                                       .attributeList!
                                      //                                                                       .length; i++) {
                                      //                                                                 List<
                                      //                                                                     String> attId = context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .attributeList![i]
                                      //                                                                     .id!
                                      //                                                                     .split(
                                      //                                                                     ',');
                                      //                                                                 if (_selectedIndex[i] !=
                                      //                                                                     null) {
                                      //                                                                   selectedId
                                      //                                                                       .add(
                                      //                                                                     int
                                      //                                                                         .parse(
                                      //                                                                       attId[_selectedIndex[i]!],
                                      //                                                                     ),
                                      //                                                                   );
                                      //                                                                 }
                                      //                                                               }
                                      //
                                      //                                                               check
                                      //                                                                   .clear();
                                      //                                                               late List<
                                      //                                                                   String> sinId;
                                      //                                                               findMatch:
                                      //                                                               for (int i = 0; i <
                                      //                                                                   context
                                      //                                                                       .read<
                                      //                                                                       ExploreProvider>()
                                      //                                                                       .productList[index]
                                      //                                                                       .prVarientList!
                                      //                                                                       .length; i++) {
                                      //                                                                 sinId =
                                      //                                                                     context
                                      //                                                                         .read<
                                      //                                                                         ExploreProvider>()
                                      //                                                                         .productList[index]
                                      //                                                                         .prVarientList![i]
                                      //                                                                         .attribute_value_ids!
                                      //                                                                         .split(
                                      //                                                                         ',');
                                      //
                                      //                                                                 for (int j = 0; j <
                                      //                                                                     selectedId
                                      //                                                                         .length; j++) {
                                      //                                                                   if (sinId
                                      //                                                                       .contains(
                                      //                                                                       selectedId[j]
                                      //                                                                           .toString())) {
                                      //                                                                     check
                                      //                                                                         .add(
                                      //                                                                         true);
                                      //
                                      //                                                                     if (selectedId
                                      //                                                                         .length ==
                                      //                                                                         sinId
                                      //                                                                             .length &&
                                      //                                                                         check
                                      //                                                                             .length ==
                                      //                                                                             selectedId
                                      //                                                                                 .length) {
                                      //                                                                       varSelected =
                                      //                                                                           i;
                                      //                                                                       selectIndex =
                                      //                                                                           i;
                                      //                                                                       break findMatch;
                                      //                                                                     }
                                      //                                                                   } else {
                                      //                                                                     check
                                      //                                                                         .clear();
                                      //                                                                     selectIndex =
                                      //                                                                     null;
                                      //                                                                     break;
                                      //                                                                   }
                                      //                                                                 }
                                      //                                                               }
                                      //
                                      //                                                               if (selectedId
                                      //                                                                   .length ==
                                      //                                                                   sinId
                                      //                                                                       .length &&
                                      //                                                                   check
                                      //                                                                       .length ==
                                      //                                                                       selectedId
                                      //                                                                           .length) {
                                      //                                                                 if (context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .stockType ==
                                      //                                                                     '0' ||
                                      //                                                                     context
                                      //                                                                         .read<
                                      //                                                                         ExploreProvider>()
                                      //                                                                         .productList[index]
                                      //                                                                         .stockType ==
                                      //                                                                         '1') {
                                      //                                                                   if (context
                                      //                                                                       .read<
                                      //                                                                       ExploreProvider>()
                                      //                                                                       .productList[index]
                                      //                                                                       .availability ==
                                      //                                                                       '1') {
                                      //                                                                     available =
                                      //                                                                     true;
                                      //                                                                     outOfStock =
                                      //                                                                     false;
                                      //                                                                     _oldSelVarient =
                                      //                                                                     varSelected!;
                                      //                                                                   } else {
                                      //                                                                     available =
                                      //                                                                     false;
                                      //                                                                     outOfStock =
                                      //                                                                     true;
                                      //                                                                   }
                                      //                                                                 } else
                                      //                                                                 if (context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .stockType ==
                                      //                                                                     '') {
                                      //                                                                   available =
                                      //                                                                   true;
                                      //                                                                   outOfStock =
                                      //                                                                   false;
                                      //                                                                   _oldSelVarient =
                                      //                                                                   varSelected!;
                                      //                                                                 } else
                                      //                                                                 if (context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .stockType ==
                                      //                                                                     '2') {
                                      //                                                                   if (context
                                      //                                                                       .read<
                                      //                                                                       ExploreProvider>()
                                      //                                                                       .productList[index]
                                      //                                                                       .prVarientList![varSelected!]
                                      //                                                                       .availability ==
                                      //                                                                       '1') {
                                      //                                                                     available =
                                      //                                                                     true;
                                      //                                                                     outOfStock =
                                      //                                                                     false;
                                      //                                                                     _oldSelVarient =
                                      //                                                                     varSelected!;
                                      //                                                                   } else {
                                      //                                                                     available =
                                      //                                                                     false;
                                      //                                                                     outOfStock =
                                      //                                                                     true;
                                      //                                                                   }
                                      //                                                                 }
                                      //                                                               } else {
                                      //                                                                 available =
                                      //                                                                 false;
                                      //                                                                 outOfStock =
                                      //                                                                 false;
                                      //                                                               }
                                      //                                                               if (context
                                      //                                                                   .read<
                                      //                                                                   ExploreProvider>()
                                      //                                                                   .productList[index]
                                      //                                                                   .prVarientList![_oldSelVarient]
                                      //                                                                   .images!
                                      //                                                                   .isNotEmpty) {
                                      //                                                                 int oldVarTotal = 0;
                                      //                                                                 if (_oldSelVarient >
                                      //                                                                     0) {
                                      //                                                                   for (int i = 0; i <
                                      //                                                                       _oldSelVarient; i++) {
                                      //                                                                     oldVarTotal =
                                      //                                                                         oldVarTotal +
                                      //                                                                             context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .prVarientList![i]
                                      //                                                                                 .images!
                                      //                                                                                 .length;
                                      //                                                                   }
                                      //                                                                 }
                                      //                                                                 int p = context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .otherImage!
                                      //                                                                     .length +
                                      //                                                                     1 +
                                      //                                                                     oldVarTotal;
                                      //                                                               }
                                      //                                                             },
                                      //                                                           );
                                      //                                                         }
                                      //                                                         if (available!) {
                                      //                                                           if (CUR_USERID !=
                                      //                                                               null) {
                                      //                                                             if (context
                                      //                                                                 .read<
                                      //                                                                 ExploreProvider>()
                                      //                                                                 .productList[index]
                                      //                                                                 .prVarientList![_oldSelVarient]
                                      //                                                                 .cartCount! !=
                                      //                                                                 '0') {
                                      //                                                               qtyController
                                      //                                                                   .text =
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ExploreProvider>()
                                      //                                                                   .productList[index]
                                      //                                                                   .prVarientList![_oldSelVarient]
                                      //                                                                   .cartCount!;
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ProductDetailProvider>()
                                      //                                                                   .qtyChange =
                                      //                                                               true;
                                      //                                                             } else {
                                      //                                                               qtyController
                                      //                                                                   .text =
                                      //                                                                   context
                                      //                                                                       .read<
                                      //                                                                       ExploreProvider>()
                                      //                                                                       .productList[index]
                                      //                                                                       .minOrderQuntity
                                      //                                                                       .toString();
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ProductDetailProvider>()
                                      //                                                                   .qtyChange =
                                      //                                                               true;
                                      //                                                             }
                                      //                                                           } else {
                                      //                                                             String qty = (await db
                                      //                                                                 .checkCartItemExists(
                                      //                                                                 context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .id!,
                                      //                                                                 context
                                      //                                                                     .read<
                                      //                                                                     ExploreProvider>()
                                      //                                                                     .productList[index]
                                      //                                                                     .prVarientList![_oldSelVarient]
                                      //                                                                     .id!))!;
                                      //                                                             if (qty ==
                                      //                                                                 '0') {
                                      //                                                               qtyController
                                      //                                                                   .text =
                                      //                                                                   context
                                      //                                                                       .read<
                                      //                                                                       ExploreProvider>()
                                      //                                                                       .productList[index]
                                      //                                                                       .minOrderQuntity
                                      //                                                                       .toString();
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ProductDetailProvider>()
                                      //                                                                   .qtyChange =
                                      //                                                               true;
                                      //                                                             } else {
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ExploreProvider>()
                                      //                                                                   .productList[index]
                                      //                                                                   .prVarientList![_oldSelVarient]
                                      //                                                                   .cartCount =
                                      //                                                                   qty;
                                      //                                                               qtyController
                                      //                                                                   .text =
                                      //                                                                   qty;
                                      //                                                               context
                                      //                                                                   .read<
                                      //                                                                   ProductDetailProvider>()
                                      //                                                                   .qtyChange =
                                      //                                                               true;
                                      //                                                             }
                                      //                                                           }
                                      //                                                         }
                                      //                                                       }
                                      //                                                     },
                                      //                                                     child: Container(
                                      //                                                       child: itemLabel,
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                 );
                                      //                                             chips
                                      //                                                 .add(
                                      //                                                 choiceContainer);
                                      //                                           }
                                      //                                         }
                                      //
                                      //                                         String value = _selectedIndex[indexAt] !=
                                      //                                             null &&
                                      //                                             _selectedIndex[indexAt]! <=
                                      //                                                 att
                                      //                                                     .length
                                      //                                             ? att[_selectedIndex[indexAt]!]
                                      //                                             : getTranslated(
                                      //                                             context,
                                      //                                             'VAR_SEL')!
                                      //                                             .substring(
                                      //                                             2,
                                      //                                             getTranslated(
                                      //                                                 context,
                                      //                                                 'VAR_SEL')!
                                      //                                                 .length);
                                      //                                         return chips
                                      //                                             .isNotEmpty
                                      //                                             ? Container(
                                      //                                           color: Theme
                                      //                                               .of(
                                      //                                               context)
                                      //                                               .colorScheme
                                      //                                               .white,
                                      //                                           child: Padding(
                                      //                                             padding: const EdgeInsetsDirectional
                                      //                                                 .only(
                                      //                                               start: 10.0,
                                      //                                               end: 10.0,
                                      //                                             ),
                                      //                                             child: Column(
                                      //                                               crossAxisAlignment: CrossAxisAlignment
                                      //                                                   .start,
                                      //                                               children: <
                                      //                                                   Widget>[
                                      //                                                 Padding(
                                      //                                                   padding: const EdgeInsets
                                      //                                                       .only(
                                      //                                                       bottom: 15.0),
                                      //                                                   child: Text(
                                      //                                                     '${context
                                      //                                                         .read<
                                      //                                                         ExploreProvider>()
                                      //                                                         .productList[index]
                                      //                                                         .attributeList![indexAt]
                                      //                                                         .name!} : $value',
                                      //                                                     style: const TextStyle(
                                      //                                                       fontFamily: 'ubuntu',
                                      //                                                       fontWeight: FontWeight
                                      //                                                           .bold,
                                      //                                                     ),
                                      //                                                   ),
                                      //                                                 ),
                                      //                                                 ListView
                                      //                                                     .builder(
                                      //                                                   itemCount: chips
                                      //                                                       .length,
                                      //                                                   shrinkWrap: true,
                                      //                                                   physics: const NeverScrollableScrollPhysics(),
                                      //                                                   itemBuilder: (
                                      //                                                       context,
                                      //                                                       chipIndex) {
                                      //                                                     return Row(
                                      //                                                       children: [
                                      //                                                         chips[chipIndex] ??
                                      //                                                             Container(),
                                      //                                                         const Spacer(),
                                      //                                                         Row(
                                      //                                                           children: <
                                      //                                                               Widget>[
                                      //                                                             context
                                      //                                                                 .read<
                                      //                                                                 ExploreProvider>()
                                      //                                                                 .productList[index]
                                      //                                                                 .type ==
                                      //                                                                 'digital_product'
                                      //                                                                 ? const SizedBox()
                                      //                                                                 : InkWell(
                                      //                                                               child: Card(
                                      //                                                                 shape: RoundedRectangleBorder(
                                      //                                                                   borderRadius: BorderRadius
                                      //                                                                       .circular(
                                      //                                                                       circularBorderRadius50),
                                      //                                                                 ),
                                      //                                                                 child: const Padding(
                                      //                                                                   padding: EdgeInsets
                                      //                                                                       .all(
                                      //                                                                       8.0),
                                      //                                                                   child: Icon(
                                      //                                                                     Icons
                                      //                                                                         .remove,
                                      //                                                                     size: 15,
                                      //                                                                   ),
                                      //                                                                 ),
                                      //                                                               ),
                                      //                                                               onTap: () {
                                      //                                                                 if (context
                                      //                                                                     .read<
                                      //                                                                     CartProvider>()
                                      //                                                                     .isProgress ==
                                      //                                                                     false) {
                                      //                                                                   if (CUR_USERID !=
                                      //                                                                       null) {
                                      //                                                                     if (context
                                      //                                                                         .read<
                                      //                                                                         ExploreProvider>()
                                      //                                                                         .productList[index]
                                      //                                                                         .prVarientList![chipIndex]
                                      //                                                                         .quantity >
                                      //                                                                         1) {
                                      //                                                                       setStater(() {
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ExploreProvider>()
                                      //                                                                             .variantDecrement(
                                      //                                                                             index,
                                      //                                                                             chipIndex,
                                      //                                                                             (int
                                      //                                                                                 .parse(
                                      //                                                                                 context
                                      //                                                                                     .read<
                                      //                                                                                     ExploreProvider>()
                                      //                                                                                     .productList[index]
                                      //                                                                                     .qtyStepSize
                                      //                                                                                     .toString())));
                                      //                                                                       });
                                      //                                                                     } else {
                                      //                                                                       setSnackbar(
                                      //                                                                           '${getTranslated(
                                      //                                                                               context,
                                      //                                                                               'MIN_MSG')}${context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .quantity
                                      //                                                                               .toString()}',
                                      //                                                                           context);
                                      //                                                                     }
                                      //                                                                     log(
                                      //                                                                         'Vijay Minus Quantity');
                                      //                                                                     context
                                      //                                                                         .read<
                                      //                                                                         CartProvider>()
                                      //                                                                         .addQuantity(
                                      //                                                                       productList: context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index],
                                      //                                                                       qty: context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index]
                                      //                                                                           .prVarientList![chipIndex]
                                      //                                                                           .quantity
                                      //                                                                           .toString(),
                                      //                                                                       from: 1,
                                      //                                                                       totalLen: context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index]
                                      //                                                                           .itemsCounter!
                                      //                                                                           .length *
                                      //                                                                           int
                                      //                                                                               .parse(
                                      //                                                                               context
                                      //                                                                                   .read<
                                      //                                                                                   ExploreProvider>()
                                      //                                                                                   .productList[index]
                                      //                                                                                   .qtyStepSize!),
                                      //                                                                       index: index,
                                      //                                                                       price: price,
                                      //                                                                       selectedPos: selectedPos,
                                      //                                                                       total: total,
                                      //                                                                       pid: context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index]
                                      //                                                                           .id
                                      //                                                                           .toString(),
                                      //                                                                       vid: context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index]
                                      //                                                                           .prVarientList?[chipIndex]
                                      //                                                                           .id
                                      //                                                                           .toString() ??
                                      //                                                                           '',
                                      //                                                                       itemCounter: 0,
                                      //                                                                       context: context,
                                      //                                                                       update: setStateNow,
                                      //                                                                     );
                                      //                                                                   }
                                      //                                                                 }
                                      //                                                               },
                                      //                                                             ),
                                      //                                                             context
                                      //                                                                 .read<
                                      //                                                                 ExploreProvider>()
                                      //                                                                 .productList[index]
                                      //                                                                 .type ==
                                      //                                                                 'digital_product'
                                      //                                                                 ? const SizedBox()
                                      //                                                                 : Padding(
                                      //                                                               padding: const EdgeInsets
                                      //                                                                   .only(
                                      //                                                                   left: 10),
                                      //                                                               child: SizedBox(
                                      //                                                                   width: 20,
                                      //                                                                   child: Text(
                                      //                                                                     '${context
                                      //                                                                         .read<
                                      //                                                                         ExploreProvider>()
                                      //                                                                         .productList[index]
                                      //                                                                         .prVarientList![chipIndex]
                                      //                                                                         .quantity}',
                                      //                                                                     style: const TextStyle(
                                      //                                                                       fontFamily: 'ubuntu',
                                      //                                                                     ),
                                      //                                                                   )
                                      //                                                                 // Stack(
                                      //                                                                 //   children: [
                                      //                                                                 //     TextField(
                                      //                                                                 //       textAlign:
                                      //                                                                 //           TextAlign
                                      //                                                                 //               .center,
                                      //                                                                 //       readOnly: true,
                                      //                                                                 //       style: TextStyle(
                                      //                                                                 //           fontSize:
                                      //                                                                 //               textFontSize12,
                                      //                                                                 //           color: Theme.of(
                                      //                                                                 //                   context)
                                      //                                                                 //               .colorScheme
                                      //                                                                 //               .fontColor),
                                      //                                                                 //       controller: context
                                      //                                                                 //           .read<
                                      //                                                                 //               CartProvider>()
                                      //                                                                 //           .controller[index],
                                      //                                                                 //       decoration:
                                      //                                                                 //           const InputDecoration(
                                      //                                                                 //         border:
                                      //                                                                 //             InputBorder
                                      //                                                                 //                 .none,
                                      //                                                                 //       ),
                                      //                                                                 //     ),
                                      //                                                                 //     PopupMenuButton<
                                      //                                                                 //         String>(
                                      //                                                                 //       tooltip: '',
                                      //                                                                 //       icon: const Icon(
                                      //                                                                 //         Icons
                                      //                                                                 //             .arrow_drop_down,
                                      //                                                                 //         size: 1,
                                      //                                                                 //       ),
                                      //                                                                 //       onSelected:
                                      //                                                                 //           (String
                                      //                                                                 //               value) {
                                      //                                                                 //         if (context
                                      //                                                                 //                 .read<
                                      //                                                                 //                     CartProvider>()
                                      //                                                                 //                 .isProgress ==
                                      //                                                                 //             false) {
                                      //                                                                 //           if (CUR_USERID !=
                                      //                                                                 //               null) {
                                      //                                                                 //             context.read<CartProvider>().addToCart(
                                      //                                                                 //                 index:
                                      //                                                                 //                     index,
                                      //                                                                 //                 qty:
                                      //                                                                 //                     value,
                                      //                                                                 //                 cartList: [],
                                      //                                                                 //                 context:
                                      //                                                                 //                     context,
                                      //                                                                 //                 update:
                                      //                                                                 //                     setStateNow);
                                      //                                                                 //           } else {
                                      //                                                                 //             context.read<CartProvider>().addAndRemoveQty(
                                      //                                                                 //                 qty:
                                      //                                                                 //                     value,
                                      //                                                                 //                 from: 3,
                                      //                                                                 //                 totalLen: context.read<ExploreProvider>().productList[index].itemsCounter!.length *
                                      //                                                                 //                     int.parse(context
                                      //                                                                 //                         .read<
                                      //                                                                 //                             ExploreProvider>()
                                      //                                                                 //                         .productList[
                                      //                                                                 //                             index]
                                      //                                                                 //                         .qtyStepSize!),
                                      //                                                                 //                 index:
                                      //                                                                 //                     index,
                                      //                                                                 //                 price:
                                      //                                                                 //                     price,
                                      //                                                                 //                 selectedPos:
                                      //                                                                 //                     selectedPos,
                                      //                                                                 //                 total:
                                      //                                                                 //                     total,
                                      //                                                                 //                 cartList: [],
                                      //                                                                 //                 itemCounter: int.parse(context
                                      //                                                                 //                     .read<
                                      //                                                                 //                         ExploreProvider>()
                                      //                                                                 //                     .productList[
                                      //                                                                 //                         index]
                                      //                                                                 //                     .qtyStepSize!),
                                      //                                                                 //                 context:
                                      //                                                                 //                     context,
                                      //                                                                 //                 update:
                                      //                                                                 //                     setStateNow);
                                      //                                                                 //           }
                                      //                                                                 //         }
                                      //                                                                 //       },
                                      //                                                                 //       itemBuilder:
                                      //                                                                 //           (BuildContext
                                      //                                                                 //               context) {
                                      //                                                                 //         return context
                                      //                                                                 //             .read<
                                      //                                                                 //                 ExploreProvider>()
                                      //                                                                 //             .productList[
                                      //                                                                 //                 index]
                                      //                                                                 //             .itemsCounter!
                                      //                                                                 //             .map<
                                      //                                                                 //                 PopupMenuItem<
                                      //                                                                 //                     String>>(
                                      //                                                                 //           (String
                                      //                                                                 //               value) {
                                      //                                                                 //             return PopupMenuItem(
                                      //                                                                 //               value:
                                      //                                                                 //                   value,
                                      //                                                                 //               child:
                                      //                                                                 //                   Text(
                                      //                                                                 //                 value,
                                      //                                                                 //                 style:
                                      //                                                                 //                     TextStyle(
                                      //                                                                 //                   color: Theme.of(context)
                                      //                                                                 //                       .colorScheme
                                      //                                                                 //                       .fontColor,
                                      //                                                                 //                   fontFamily:
                                      //                                                                 //                       'ubuntu',
                                      //                                                                 //                 ),
                                      //                                                                 //               ),
                                      //                                                                 //             );
                                      //                                                                 //           },
                                      //                                                                 //         ).toList();
                                      //                                                                 //       },
                                      //                                                                 //     ),
                                      //                                                                 //   ],
                                      //                                                                 // ),
                                      //                                                               ),
                                      //                                                             ),
                                      //                                                             context
                                      //                                                                 .read<
                                      //                                                                 ExploreProvider>()
                                      //                                                                 .productList[index]
                                      //                                                                 .type ==
                                      //                                                                 'digital_product'
                                      //                                                                 ? const SizedBox()
                                      //                                                                 : InkWell(
                                      //                                                               child: Card(
                                      //                                                                 shape: RoundedRectangleBorder(
                                      //                                                                   borderRadius: BorderRadius
                                      //                                                                       .circular(
                                      //                                                                       circularBorderRadius50),
                                      //                                                                 ),
                                      //                                                                 child: const Padding(
                                      //                                                                   padding: EdgeInsets
                                      //                                                                       .all(
                                      //                                                                       8.0),
                                      //                                                                   child: Icon(
                                      //                                                                     Icons
                                      //                                                                         .add,
                                      //                                                                     size: 15,
                                      //                                                                   ),
                                      //                                                                 ),
                                      //                                                               ),
                                      //                                                               onTap: () async {
                                      //                                                                 if (att
                                      //                                                                     .length !=
                                      //                                                                     1) {
                                      //                                                                   if (mounted) {
                                      //                                                                     setStater(
                                      //                                                                           () {
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ExploreProvider>()
                                      //                                                                             .productList[index]
                                      //                                                                             .selVarient =
                                      //                                                                             chipIndex;
                                      //                                                                         available =
                                      //                                                                         false;
                                      //                                                                         _selectedIndex[indexAt] =
                                      //                                                                             chipIndex;
                                      //                                                                         List<
                                      //                                                                             int> selectedId = [
                                      //                                                                         ]; //list where user choosen item id is stored
                                      //                                                                         List<
                                      //                                                                             bool> check = [
                                      //                                                                         ];
                                      //                                                                         for (int i = 0; i <
                                      //                                                                             context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .attributeList!
                                      //                                                                                 .length; i++) {
                                      //                                                                           List<
                                      //                                                                               String> attId = context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .attributeList![i]
                                      //                                                                               .id!
                                      //                                                                               .split(
                                      //                                                                               ',');
                                      //                                                                           if (_selectedIndex[i] !=
                                      //                                                                               null) {
                                      //                                                                             selectedId
                                      //                                                                                 .add(
                                      //                                                                               int
                                      //                                                                                   .parse(
                                      //                                                                                 attId[_selectedIndex[i]!],
                                      //                                                                               ),
                                      //                                                                             );
                                      //                                                                           }
                                      //                                                                         }
                                      //
                                      //                                                                         check
                                      //                                                                             .clear();
                                      //                                                                         late List<
                                      //                                                                             String> sinId;
                                      //                                                                         findMatch:
                                      //                                                                         for (int i = 0; i <
                                      //                                                                             context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .prVarientList!
                                      //                                                                                 .length; i++) {
                                      //                                                                           sinId =
                                      //                                                                               context
                                      //                                                                                   .read<
                                      //                                                                                   ExploreProvider>()
                                      //                                                                                   .productList[index]
                                      //                                                                                   .prVarientList![i]
                                      //                                                                                   .attribute_value_ids!
                                      //                                                                                   .split(
                                      //                                                                                   ',');
                                      //
                                      //                                                                           for (int j = 0; j <
                                      //                                                                               selectedId
                                      //                                                                                   .length; j++) {
                                      //                                                                             if (sinId
                                      //                                                                                 .contains(
                                      //                                                                                 selectedId[j]
                                      //                                                                                     .toString())) {
                                      //                                                                               check
                                      //                                                                                   .add(
                                      //                                                                                   true);
                                      //
                                      //                                                                               if (selectedId
                                      //                                                                                   .length ==
                                      //                                                                                   sinId
                                      //                                                                                       .length &&
                                      //                                                                                   check
                                      //                                                                                       .length ==
                                      //                                                                                       selectedId
                                      //                                                                                           .length) {
                                      //                                                                                 varSelected =
                                      //                                                                                     i;
                                      //                                                                                 selectIndex =
                                      //                                                                                     i;
                                      //                                                                                 break findMatch;
                                      //                                                                               }
                                      //                                                                             } else {
                                      //                                                                               check
                                      //                                                                                   .clear();
                                      //                                                                               selectIndex =
                                      //                                                                               null;
                                      //                                                                               break;
                                      //                                                                             }
                                      //                                                                           }
                                      //                                                                         }
                                      //
                                      //                                                                         if (selectedId
                                      //                                                                             .length ==
                                      //                                                                             sinId
                                      //                                                                                 .length &&
                                      //                                                                             check
                                      //                                                                                 .length ==
                                      //                                                                                 selectedId
                                      //                                                                                     .length) {
                                      //                                                                           if (context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .stockType ==
                                      //                                                                               '0' ||
                                      //                                                                               context
                                      //                                                                                   .read<
                                      //                                                                                   ExploreProvider>()
                                      //                                                                                   .productList[index]
                                      //                                                                                   .stockType ==
                                      //                                                                                   '1') {
                                      //                                                                             if (context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .availability ==
                                      //                                                                                 '1') {
                                      //                                                                               available =
                                      //                                                                               true;
                                      //                                                                               outOfStock =
                                      //                                                                               false;
                                      //                                                                               _oldSelVarient =
                                      //                                                                               varSelected!;
                                      //                                                                             } else {
                                      //                                                                               available =
                                      //                                                                               false;
                                      //                                                                               outOfStock =
                                      //                                                                               true;
                                      //                                                                             }
                                      //                                                                           } else
                                      //                                                                           if (context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .stockType ==
                                      //                                                                               '') {
                                      //                                                                             available =
                                      //                                                                             true;
                                      //                                                                             outOfStock =
                                      //                                                                             false;
                                      //                                                                             _oldSelVarient =
                                      //                                                                             varSelected!;
                                      //                                                                           } else
                                      //                                                                           if (context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .stockType ==
                                      //                                                                               '2') {
                                      //                                                                             if (context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .prVarientList![varSelected!]
                                      //                                                                                 .availability ==
                                      //                                                                                 '1') {
                                      //                                                                               available =
                                      //                                                                               true;
                                      //                                                                               outOfStock =
                                      //                                                                               false;
                                      //                                                                               _oldSelVarient =
                                      //                                                                               varSelected!;
                                      //                                                                             } else {
                                      //                                                                               available =
                                      //                                                                               false;
                                      //                                                                               outOfStock =
                                      //                                                                               true;
                                      //                                                                             }
                                      //                                                                           }
                                      //                                                                         } else {
                                      //                                                                           available =
                                      //                                                                           false;
                                      //                                                                           outOfStock =
                                      //                                                                           false;
                                      //                                                                         }
                                      //                                                                         if (context
                                      //                                                                             .read<
                                      //                                                                             ExploreProvider>()
                                      //                                                                             .productList[index]
                                      //                                                                             .prVarientList![_oldSelVarient]
                                      //                                                                             .images!
                                      //                                                                             .isNotEmpty) {
                                      //                                                                           int oldVarTotal = 0;
                                      //                                                                           if (_oldSelVarient >
                                      //                                                                               0) {
                                      //                                                                             for (int i = 0; i <
                                      //                                                                                 _oldSelVarient; i++) {
                                      //                                                                               oldVarTotal =
                                      //                                                                                   oldVarTotal +
                                      //                                                                                       context
                                      //                                                                                           .read<
                                      //                                                                                           ExploreProvider>()
                                      //                                                                                           .productList[index]
                                      //                                                                                           .prVarientList![i]
                                      //                                                                                           .images!
                                      //                                                                                           .length;
                                      //                                                                             }
                                      //                                                                           }
                                      //                                                                           int p = context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .otherImage!
                                      //                                                                               .length +
                                      //                                                                               1 +
                                      //                                                                               oldVarTotal;
                                      //                                                                         }
                                      //                                                                       },
                                      //                                                                     );
                                      //                                                                   }
                                      //                                                                   if (available!) {
                                      //                                                                     if (CUR_USERID !=
                                      //                                                                         null) {
                                      //                                                                       if (context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index]
                                      //                                                                           .prVarientList![_oldSelVarient]
                                      //                                                                           .cartCount! !=
                                      //                                                                           '0') {
                                      //                                                                         qtyController
                                      //                                                                             .text =
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ExploreProvider>()
                                      //                                                                             .productList[index]
                                      //                                                                             .prVarientList![_oldSelVarient]
                                      //                                                                             .cartCount!;
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ProductDetailProvider>()
                                      //                                                                             .qtyChange =
                                      //                                                                         true;
                                      //                                                                       } else {
                                      //                                                                         qtyController
                                      //                                                                             .text =
                                      //                                                                             context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .minOrderQuntity
                                      //                                                                                 .toString();
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ProductDetailProvider>()
                                      //                                                                             .qtyChange =
                                      //                                                                         true;
                                      //                                                                       }
                                      //                                                                     } else {
                                      //                                                                       String qty = (await db
                                      //                                                                           .checkCartItemExists(
                                      //                                                                           context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .id!,
                                      //                                                                           context
                                      //                                                                               .read<
                                      //                                                                               ExploreProvider>()
                                      //                                                                               .productList[index]
                                      //                                                                               .prVarientList![_oldSelVarient]
                                      //                                                                               .id!))!;
                                      //                                                                       if (qty ==
                                      //                                                                           '0') {
                                      //                                                                         qtyController
                                      //                                                                             .text =
                                      //                                                                             context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .minOrderQuntity
                                      //                                                                                 .toString();
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ProductDetailProvider>()
                                      //                                                                             .qtyChange =
                                      //                                                                         true;
                                      //                                                                       } else {
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ExploreProvider>()
                                      //                                                                             .productList[index]
                                      //                                                                             .prVarientList![_oldSelVarient]
                                      //                                                                             .cartCount =
                                      //                                                                             qty;
                                      //                                                                         qtyController
                                      //                                                                             .text =
                                      //                                                                             qty;
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ProductDetailProvider>()
                                      //                                                                             .qtyChange =
                                      //                                                                         true;
                                      //                                                                       }
                                      //                                                                     }
                                      //                                                                   }
                                      //                                                                 }
                                      //                                                                 if (context
                                      //                                                                     .read<
                                      //                                                                     CartProvider>()
                                      //                                                                     .isProgress ==
                                      //                                                                     false) {
                                      //                                                                   setStater(() {
                                      //                                                                     _selectedIndex[indexAt] =
                                      //                                                                         chipIndex;
                                      //                                                                   });
                                      //                                                                   if (CUR_USERID !=
                                      //                                                                       null) {
                                      //                                                                     // Navigator.pop(context);
                                      //                                                                     var finalQuantity = context
                                      //                                                                         .read<
                                      //                                                                         ExploreProvider>()
                                      //                                                                         .productList[index]
                                      //                                                                         .prVarientList![chipIndex]
                                      //                                                                         .quantity +
                                      //                                                                         int
                                      //                                                                             .parse(
                                      //                                                                             context
                                      //                                                                                 .read<
                                      //                                                                                 ExploreProvider>()
                                      //                                                                                 .productList[index]
                                      //                                                                                 .qtyStepSize
                                      //                                                                                 .toString());
                                      //                                                                     setState(() {
                                      //                                                                       context
                                      //                                                                           .read<
                                      //                                                                           ExploreProvider>()
                                      //                                                                           .productList[index]
                                      //                                                                           .prVarientList![chipIndex]
                                      //                                                                           .quantity =
                                      //                                                                           finalQuantity;
                                      //                                                                     });
                                      //                                                                     // context.read<ExploreProvider>().variantIncrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                      //                                                                     addNewCart(
                                      //                                                                         index,
                                      //                                                                         context
                                      //                                                                             .read<
                                      //                                                                             ExploreProvider>()
                                      //                                                                             .productList[index]
                                      //                                                                             .prVarientList![chipIndex]
                                      //                                                                             .quantity
                                      //                                                                             .toString(),
                                      //                                                                         2);
                                      //                                                                     widget.update;
                                      //                                                                   }
                                      //                                                                   // else {
                                      //                                                                   //   log('Vijay 2');
                                      //                                                                   //   context
                                      //                                                                   //       .read<
                                      //                                                                   //       CartProvider>()
                                      //                                                                   //       .addQuantity(
                                      //                                                                   //     productList: context
                                      //                                                                   //         .read<
                                      //                                                                   //         ExploreProvider>()
                                      //                                                                   //         .productList[index],
                                      //                                                                   //     qty: context
                                      //                                                                   //         .read<
                                      //                                                                   //         ExploreProvider>()
                                      //                                                                   //         .productList[
                                      //                                                                   //     index].quantity.toString(),
                                      //                                                                   //     from: 1,
                                      //                                                                   //     totalLen: context
                                      //                                                                   //         .read<
                                      //                                                                   //         ExploreProvider>()
                                      //                                                                   //         .productList[
                                      //                                                                   //     index]
                                      //                                                                   //         .itemsCounter!
                                      //                                                                   //         .length *
                                      //                                                                   //         int.parse(context
                                      //                                                                   //             .read<ExploreProvider>()
                                      //                                                                   //             .productList[index]
                                      //                                                                   //             .qtyStepSize!),
                                      //                                                                   //     index:
                                      //                                                                   //     index,
                                      //                                                                   //     price:
                                      //                                                                   //     price,
                                      //                                                                   //     selectedPos:
                                      //                                                                   //     selectedPos,
                                      //                                                                   //     total:
                                      //                                                                   //     total,
                                      //                                                                   //     pid: context
                                      //                                                                   //         .read<
                                      //                                                                   //         ExploreProvider>()
                                      //                                                                   //         .productList[
                                      //                                                                   //     0]
                                      //                                                                   //         .id
                                      //                                                                   //         .toString(),
                                      //                                                                   //     vid: context
                                      //                                                                   //         .read<ExploreProvider>()
                                      //                                                                   //         .productList[0]
                                      //                                                                   //         .prVarientList?[selectedPos]
                                      //                                                                   //         .id
                                      //                                                                   //         .toString() ??
                                      //                                                                   //         '',
                                      //                                                                   //     itemCounter: int.parse(context
                                      //                                                                   //         .read<
                                      //                                                                   //         ExploreProvider>()
                                      //                                                                   //         .productList[
                                      //                                                                   //     index]
                                      //                                                                   //         .qtyStepSize!),
                                      //                                                                   //     context:
                                      //                                                                   //     context,
                                      //                                                                   //     update:
                                      //                                                                   //     setStateNow,
                                      //                                                                   //   );
                                      //                                                                   // }
                                      //                                                                 }
                                      //                                                               },
                                      //                                                             )
                                      //                                                           ],
                                      //                                                         ),
                                      //                                                       ],
                                      //                                                     );
                                      //                                                   },
                                      //                                                 )
                                      //                                               ],
                                      //                                             ),
                                      //                                           ),
                                      //                                         )
                                      //                                             : const SizedBox();
                                      //                                       },
                                      //                                     ),
                                      //                                   ),
                                      //                                 )
                                      //                               ],
                                      //                             ),
                                      //                           ),
                                      //                           Divider(
                                      //                             height: 2,
                                      //                             color: Theme
                                      //                                 .of(
                                      //                                 context)
                                      //                                 .colorScheme
                                      //                                 .lightWhite,
                                      //                           )
                                      //                         ],
                                      //                       ),
                                      //                     ),
                                      //                   ),
                                      //                 );
                                      //               },
                                      //             );
                                      //           },
                                      //         );
                                      //       } else {
                                      //         addCart(
                                      //             index,
                                      //             (int.parse(
                                      //                 controllerText[index]
                                      //                     .text) +
                                      //                 int.parse(context
                                      //                     .read<
                                      //                     ExploreProvider>()
                                      //                     .productList[index]
                                      //                     .qtyStepSize!))
                                      //                 .toString(),
                                      //             2);
                                      //       }
                                      //     }
                                      //   },
                                      // )
                                    ],
                                  ),
                                  context
                                          .read<ExploreProvider>()
                                          .productList[index]
                                          .attributeList!
                                          .isNotEmpty
                                      ? Container(
                                          color:
                                              Theme.of(context).colorScheme.white,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 5.0, left: 10.0),
                                            child: ListView.builder(
                                                padding: const EdgeInsets.all(0),
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount: context
                                                    .read<ExploreProvider>()
                                                    .productList[index]
                                                    .attributeList!
                                                    .length,
                                                itemBuilder: (context, indexAT) {
                                                  return Text(
                                                    '${context.read<ExploreProvider>().productList[index].attributeList!.first.value!.split(",").first} ${context.read<ExploreProvider>().productList[index].attributeList![indexAT].name!}',
                                                    style: const TextStyle(
                                                      fontFamily: 'ubuntu',
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  );
                                                }),
                                          ),
                                        )
                                      : const SizedBox(),
                                  SizedBox(
                                      height: MediaQuery.of(context).size.height *
                                          0.04),
                                ],
                              ),
                            ),
                            Selector<FavoriteProvider, List<String?>>(
                              builder: (context, data, child) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: 10.0,
                                    bottom: 10.0,
                                    top: 10.0,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          circularBorderRadius7),
                                      color: Theme.of(context).colorScheme.white,
                                    ),
                                    width: 33,
                                    height: 33,
                                    child: InkWell(
                                      onTap: () {
                                        getProFavIds(context
                                            .read<ExploreProvider>()
                                            .productList[index]);
                                        getMostFavPro(context
                                            .read<ExploreProvider>()
                                            .productList[index]);
                                        if (CUR_USERID != null) {
                                          !data.contains(context
                                                  .read<ExploreProvider>()
                                                  .productList[index]
                                                  .id)
                                              ? _setFav(
                                                  -1,
                                                  -1,
                                                  context
                                                      .read<ExploreProvider>()
                                                      .productList[index])
                                              : _removeFav(
                                                  -1,
                                                  -1,
                                                  context
                                                      .read<ExploreProvider>()
                                                      .productList[index]);
                                        } else {
                                          if (!data.contains(context
                                              .read<ExploreProvider>()
                                              .productList[index]
                                              .id)) {
                                            context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .isFavLoading = true;
                                            context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .isFav = '1';
                                            context
                                                .read<FavoriteProvider>()
                                                .addFavItem(context
                                                    .read<ExploreProvider>()
                                                    .productList[index]);
                                            db.addAndRemoveFav(
                                                context
                                                    .read<ExploreProvider>()
                                                    .productList[index]
                                                    .id!,
                                                true);
                                            context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .isFavLoading = false;
                                            setSnackbar(
                                                getTranslated(
                                                    context, 'Added to favorite')!,
                                                context);
                                          } else {
                                            context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .isFavLoading = true;
                                            context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .isFav = '0';
                                            context
                                                .read<FavoriteProvider>()
                                                .removeFavItem(context
                                                    .read<ExploreProvider>()
                                                    .productList[index]
                                                    .prVarientList![0]
                                                    .id!);
                                            db.addAndRemoveFav(
                                                context
                                                    .read<ExploreProvider>()
                                                    .productList[index]
                                                    .id!,
                                                false);
                                            context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .isFavLoading = false;
                                            setSnackbar(
                                                getTranslated(context,
                                                    'Removed from favorite')!,
                                                context);
                                          }
                                          setState(
                                            () {},
                                          );
                                        }
                                      },
                                      child: Icon(
                                        !data.contains(context
                                                .read<ExploreProvider>()
                                                .productList[index]
                                                .id)
                                            ? Icons.favorite_border
                                            : Icons.favorite,
                                        size: 20,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              selector: (_, provider) => provider.favIdList,
                            ),
                          ],
                        ),
                        Positioned.directional(
                          textDirection: Directionality.of(context),
                          end: 4,
                          top: 50,
                          child: CUR_USERID != null
                              ? Row(
                                  children: [
                                    InkWell(
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            circularBorderRadius50,
                                          ),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(
                                            6.0,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        if (isProgress == false &&
                                            (int.parse(controllerText[index].text) >
                                                0)) {
                                          if ((context
                                              .read<ExploreProvider>()
                                              .productList[index]
                                              .prVarientList
                                              ?.length ??
                                              1) >
                                              1) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                List<String> selList = context
                                                    .read<ExploreProvider>()
                                                    .productList[index]
                                                    .prVarientList![_oldSelVarient]
                                                    .attribute_value_ids!
                                                    .split(',');
                                                _selectedIndex.clear();
                                                for (int i = 0;
                                                i <
                                                    context
                                                        .read<ExploreProvider>()
                                                        .productList[index]
                                                        .attributeList!
                                                        .length;
                                                i++) {
                                                  List<String> sinList = context
                                                      .read<ExploreProvider>()
                                                      .productList[index]
                                                      .attributeList![i]
                                                      .id!
                                                      .split(',');

                                                  for (int j = 0;
                                                  j < sinList.length;
                                                  j++) {
                                                    if (selList
                                                        .contains(sinList[j])) {
                                                      _selectedIndex.insert(i, j);
                                                    }
                                                  }

                                                  if (_selectedIndex.length == i) {
                                                    _selectedIndex.insert(i, null);
                                                  }
                                                }
                                                return StatefulBuilder(
                                                  builder: (_,
                                                      StateSetter setStater) {
                                                    return AlertDialog(
                                                      contentPadding:
                                                      const EdgeInsets.all(0.0),
                                                      shape:
                                                      const RoundedRectangleBorder(
                                                        borderRadius:
                                                        BorderRadius.all(
                                                          Radius.circular(
                                                              circularBorderRadius5),
                                                        ),
                                                      ),
                                                      content: SizedBox(
                                                        height: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                            0.47,
                                                        child: Stack(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                              const EdgeInsetsDirectional
                                                                  .only(
                                                                  start: 10.0,
                                                                  end: 10.0,
                                                                  top: 5.0),
                                                              child: Container(
                                                                height:
                                                                MediaQuery.of(context)
                                                                    .size
                                                                    .height *
                                                                    0.47,
                                                                decoration: BoxDecoration(
                                                                  color: Theme.of(context)
                                                                      .colorScheme
                                                                      .white,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                      circularBorderRadius10),
                                                                ),
                                                                child: Column(
                                                                  children: [
                                                                    InkWell(
                                                                      child: Stack(
                                                                        children: [
                                                                          Row(
                                                                            crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .start,
                                                                            children: [
                                                                              Flexible(
                                                                                flex: 1,
                                                                                child:
                                                                                ClipRRect(
                                                                                  borderRadius:
                                                                                  const BorderRadius.only(
                                                                                    topLeft:
                                                                                    Radius.circular(circularBorderRadius4),
                                                                                    bottomLeft:
                                                                                    Radius.circular(circularBorderRadius4),
                                                                                  ),
                                                                                  child: DesignConfiguration
                                                                                      .getCacheNotworkImage(
                                                                                    boxFit:
                                                                                    BoxFit.cover,
                                                                                    context:
                                                                                    context,
                                                                                    heightvalue:
                                                                                    107,
                                                                                    widthvalue:
                                                                                    107,
                                                                                    placeHolderSize:
                                                                                    50,
                                                                                    imageurlString: context
                                                                                        .read<ExploreProvider>()
                                                                                        .productList[index]
                                                                                        .image!,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment:
                                                                                CrossAxisAlignment
                                                                                    .start,
                                                                                children: [
                                                                                  context.read<ExploreProvider>().productList[index].brandName != '' &&
                                                                                      context.read<ExploreProvider>().productList[index].brandName != null
                                                                                      ? Padding(
                                                                                    padding: const EdgeInsets.only(
                                                                                      left: 15.0,
                                                                                      right: 15.0,
                                                                                      top: 16.0,
                                                                                    ),
                                                                                    child: Text(
                                                                                      context.read<ExploreProvider>().productList[index].brandName ?? '',
                                                                                      style: TextStyle(
                                                                                        fontWeight: FontWeight.bold,
                                                                                        color: Theme.of(context).colorScheme.lightBlack,
                                                                                        fontSize: textFontSize14,
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                      : const SizedBox(),
                                                                                  GetTitleWidget(
                                                                                    title:
                                                                                    context.read<ExploreProvider>().productList[index].name ?? '',
                                                                                  ),
                                                                                  available ??
                                                                                      false || (outOfStock ?? false)
                                                                                      ? GetPrice(pos: selectIndex, from: true, model: context.read<ExploreProvider>().productList[index])
                                                                                      : GetPrice(
                                                                                    pos: context.read<ExploreProvider>().productList[index].selVarient,
                                                                                    from: false,
                                                                                    model: context.read<ExploreProvider>().productList[index],
                                                                                  ),
                                                                                ],
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      color: Theme.of(
                                                                          context)
                                                                          .colorScheme
                                                                          .white,
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                        mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                        children: [
                                                                          Container(
                                                                            height: MediaQuery.of(
                                                                                context)
                                                                                .size
                                                                                .height *
                                                                                0.28,
                                                                            width: MediaQuery.of(
                                                                                context)
                                                                                .size
                                                                                .height *
                                                                                0.6,
                                                                            color: Theme.of(
                                                                                context)
                                                                                .colorScheme
                                                                                .white,
                                                                            child:
                                                                            Padding(
                                                                              padding: const EdgeInsets
                                                                                  .only(
                                                                                  top:
                                                                                  15.0),
                                                                              child: ListView
                                                                                  .builder(
                                                                                scrollDirection:
                                                                                Axis.vertical,
                                                                                physics:
                                                                                const BouncingScrollPhysics(),
                                                                                itemCount: context
                                                                                    .read<
                                                                                    ExploreProvider>()
                                                                                    .productList[
                                                                                index]
                                                                                    .attributeList!
                                                                                    .length,
                                                                                itemBuilder:
                                                                                    (_,
                                                                                    indexAt) {
                                                                                  List<Widget?>
                                                                                  chips =
                                                                                  [];
                                                                                  List<String> att = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .value!
                                                                                      .split(',');
                                                                                  List<String> attId = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .id!
                                                                                      .split(',');
                                                                                  List<String> attSType = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .sType!
                                                                                      .split(',');
                                                                                  List<String> attSValue = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .sValue!
                                                                                      .split(',');
                                                                                  int?
                                                                                  varSelected;
                                                                                  List<String> wholeAtt = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attrIds!
                                                                                      .split(',');
                                                                                  for (int i =
                                                                                  0;
                                                                                  i < att.length;
                                                                                  i++) {
                                                                                    Widget
                                                                                    itemLabel;
                                                                                    if (attSType[i] ==
                                                                                        '1') {
                                                                                      String
                                                                                      clr =
                                                                                      (attSValue[i].substring(1));
                                                                                      String
                                                                                      color =
                                                                                          '0xff$clr';
                                                                                      itemLabel =
                                                                                          Container(
                                                                                            width: 35,
                                                                                            height: 35,
                                                                                            decoration: BoxDecoration(
                                                                                              shape: BoxShape.circle,
                                                                                              color: _selectedIndex[indexAt] == (i) ? colors.primary : colors.secondary,
                                                                                            ),
                                                                                            child: Center(
                                                                                              child: Container(
                                                                                                width: 25,
                                                                                                height: 25,
                                                                                                decoration: BoxDecoration(
                                                                                                  shape: BoxShape.circle,
                                                                                                  color: Color(
                                                                                                    int.parse(color),
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                    } else if (attSType[i] ==
                                                                                        '2') {
                                                                                      itemLabel =
                                                                                          Container(
                                                                                            decoration: BoxDecoration(
                                                                                              gradient: LinearGradient(
                                                                                                  begin: Alignment.topLeft,
                                                                                                  end: Alignment.bottomRight,
                                                                                                  colors: _selectedIndex[indexAt] == (i)
                                                                                                      ? [colors.grad1Color, colors.grad2Color]
                                                                                                      : [
                                                                                                    Theme.of(context).colorScheme.white,
                                                                                                    Theme.of(context).colorScheme.white,
                                                                                                  ],
                                                                                                  stops: const [0, 1]),
                                                                                              borderRadius: const BorderRadius.all(Radius.circular(circularBorderRadius8)),
                                                                                              border: Border.all(
                                                                                                color: _selectedIndex[indexAt] == (i) ? const Color(0xfffc6a57) : Theme.of(context).colorScheme.black,
                                                                                                width: 1,
                                                                                              ),
                                                                                            ),
                                                                                            child: ClipRRect(
                                                                                              borderRadius: BorderRadius.circular(circularBorderRadius8),
                                                                                              child: Image.network(
                                                                                                attSValue[i],
                                                                                                width: 80,
                                                                                                height: 80,
                                                                                                fit: BoxFit.cover,
                                                                                                errorBuilder: (context, error, stackTrace) => DesignConfiguration.erroWidget(80),
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                    }
                                                                                    else {
                                                                                      itemLabel =
                                                                                          Container(
                                                                                            decoration: BoxDecoration(
                                                                                              gradient: LinearGradient(
                                                                                                begin: Alignment.topLeft,
                                                                                                end: Alignment.bottomRight,
                                                                                                colors: _selectedIndex[indexAt] ==
                                                                                                    (i)
                                                                                                    ? [
                                                                                                  colors.grad1Color,
                                                                                                  colors.grad2Color
                                                                                                ]
                                                                                                    : [
                                                                                                  Theme.of(context).colorScheme.white,
                                                                                                  Theme.of(context).colorScheme.white,
                                                                                                ],
                                                                                                stops: const [
                                                                                                  0,
                                                                                                  1
                                                                                                ],
                                                                                              ),
                                                                                              borderRadius: const BorderRadius.all(Radius.circular(circularBorderRadius8)),
                                                                                              border: Border.all(
                                                                                                color: _selectedIndex[indexAt] == (i) ? const Color(0xfffc6a57) : Theme.of(context).colorScheme.black,
                                                                                                width: 1,
                                                                                              ),
                                                                                            ),
                                                                                            child: Padding(
                                                                                              padding: const EdgeInsets.symmetric(
                                                                                                horizontal: 15,
                                                                                                vertical: 6,
                                                                                              ),
                                                                                              child: Text(
                                                                                                '${att[i]} ${context.read<ExploreProvider>().productList[index].attributeList![indexAt].name}',
                                                                                                style: TextStyle(
                                                                                                  fontFamily: 'ubuntu',
                                                                                                  color: _selectedIndex[indexAt] == (i) ? Theme.of(context).colorScheme.white : Theme.of(context).colorScheme.fontColor,
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                    }
                                                                                    if (_selectedIndex[indexAt] != null &&
                                                                                        wholeAtt.contains(attId[i])) {
                                                                                      choiceContainer =
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.only(
                                                                                              right: 10,
                                                                                            ),
                                                                                            child: InkWell(
                                                                                              onTap: () async {
                                                                                                if (att.length != 1) {
                                                                                                  if (mounted) {
                                                                                                    setStater(
                                                                                                          () {
                                                                                                        context.read<ExploreProvider>().productList[index].selVarient = i;
                                                                                                        available = false;
                                                                                                        _selectedIndex[indexAt] = i;
                                                                                                        List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                        List<bool> check = [];
                                                                                                        for (int i = 0; i < context.read<ExploreProvider>().productList[index].attributeList!.length; i++) {
                                                                                                          List<String> attId = context.read<ExploreProvider>().productList[index].attributeList![i].id!.split(',');
                                                                                                          if (_selectedIndex[i] != null) {
                                                                                                            selectedId.add(
                                                                                                              int.parse(
                                                                                                                attId[_selectedIndex[i]!],
                                                                                                              ),
                                                                                                            );
                                                                                                          }
                                                                                                        }

                                                                                                        check.clear();
                                                                                                        late List<String> sinId;
                                                                                                        findMatch:
                                                                                                        for (int i = 0; i < context.read<ExploreProvider>().productList[index].prVarientList!.length; i++) {
                                                                                                          sinId = context.read<ExploreProvider>().productList[index].prVarientList![i].attribute_value_ids!.split(',');

                                                                                                          for (int j = 0; j < selectedId.length; j++) {
                                                                                                            if (sinId.contains(selectedId[j].toString())) {
                                                                                                              check.add(true);

                                                                                                              if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                                varSelected = i;
                                                                                                                selectIndex = i;
                                                                                                                break findMatch;
                                                                                                              }
                                                                                                            } else {
                                                                                                              check.clear();
                                                                                                              selectIndex = null;
                                                                                                              break;
                                                                                                            }
                                                                                                          }
                                                                                                        }

                                                                                                        if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                          if (context.read<ExploreProvider>().productList[index].stockType == '0' || context.read<ExploreProvider>().productList[index].stockType == '1') {
                                                                                                            if (context.read<ExploreProvider>().productList[index].availability == '1') {
                                                                                                              available = true;
                                                                                                              outOfStock = false;
                                                                                                              _oldSelVarient = varSelected!;
                                                                                                            } else {
                                                                                                              available = false;
                                                                                                              outOfStock = true;
                                                                                                            }
                                                                                                          } else if (context.read<ExploreProvider>().productList[index].stockType == '') {
                                                                                                            available = true;
                                                                                                            outOfStock = false;
                                                                                                            _oldSelVarient = varSelected!;
                                                                                                          } else if (context.read<ExploreProvider>().productList[index].stockType == '2') {
                                                                                                            if (context.read<ExploreProvider>().productList[index].prVarientList![varSelected!].availability == '1') {
                                                                                                              available = true;
                                                                                                              outOfStock = false;
                                                                                                              _oldSelVarient = varSelected!;
                                                                                                            } else {
                                                                                                              available = false;
                                                                                                              outOfStock = true;
                                                                                                            }
                                                                                                          }
                                                                                                        } else {
                                                                                                          available = false;
                                                                                                          outOfStock = false;
                                                                                                        }
                                                                                                        if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                          int oldVarTotal = 0;
                                                                                                          if (_oldSelVarient > 0) {
                                                                                                            for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                              oldVarTotal = oldVarTotal + context.read<ExploreProvider>().productList[index].prVarientList![i].images!.length;
                                                                                                            }
                                                                                                          }
                                                                                                          int p = context.read<ExploreProvider>().productList[index].otherImage!.length + 1 + oldVarTotal;
                                                                                                        }
                                                                                                      },
                                                                                                    );
                                                                                                  }
                                                                                                  if (available!) {
                                                                                                    if (CUR_USERID != null) {
                                                                                                      if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                        qtyController.text = context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount!;
                                                                                                        context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                      } else {
                                                                                                        qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                        context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                      }
                                                                                                    } else {
                                                                                                      String qty = (await db.checkCartItemExists(context.read<ExploreProvider>().productList[index].id!, context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].id!))!;
                                                                                                      if (qty == '0') {
                                                                                                        qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                        context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                      } else {
                                                                                                        context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount = qty;
                                                                                                        qtyController.text = qty;
                                                                                                        context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                      }
                                                                                                    }
                                                                                                  }
                                                                                                }
                                                                                              },
                                                                                              child: Container(
                                                                                                child: itemLabel,
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                      chips.add(choiceContainer);
                                                                                    }
                                                                                  }

                                                                                  String value = _selectedIndex[indexAt] != null &&
                                                                                      _selectedIndex[indexAt]! <= att.length
                                                                                      ? att[_selectedIndex[indexAt]!]
                                                                                      : getTranslated(context, 'VAR_SEL')!.substring(2, getTranslated(context, 'VAR_SEL')!.length);
                                                                                  return chips.isNotEmpty
                                                                                      ? Container(
                                                                                    color: Theme.of(context).colorScheme.white,
                                                                                    child: Padding(
                                                                                      padding: const EdgeInsetsDirectional.only(
                                                                                        start: 10.0,
                                                                                        end: 10.0,
                                                                                      ),
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: <Widget>[
                                                                                          Padding(
                                                                                            padding: const EdgeInsets.only(bottom: 15.0),
                                                                                            child: Text(
                                                                                              '${context.read<ExploreProvider>().productList[index].attributeList![indexAt].name!} : $value',
                                                                                              style: const TextStyle(
                                                                                                fontFamily: 'ubuntu',
                                                                                                fontWeight: FontWeight.bold,

                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          ListView.builder(
                                                                                            itemCount: chips.length,
                                                                                            shrinkWrap: true,
                                                                                            physics: const NeverScrollableScrollPhysics(),
                                                                                            itemBuilder: (context, chipIndex) {
                                                                                              return Row(
                                                                                                children: [
                                                                                                  chips[chipIndex] ?? Container(),
                                                                                                  const Spacer(),
                                                                                                  Row(
                                                                                                    children: <Widget>[
                                                                                                      context.read<ExploreProvider>().productList[index].type == 'digital_product'
                                                                                                          ? const SizedBox()
                                                                                                          : InkWell(
                                                                                                        child: Card(
                                                                                                          shape: RoundedRectangleBorder(
                                                                                                            borderRadius: BorderRadius.circular(circularBorderRadius50),
                                                                                                          ),
                                                                                                          child: const Padding(
                                                                                                            padding: EdgeInsets.all(8.0),
                                                                                                            child: Icon(
                                                                                                              Icons.remove,
                                                                                                              size: 15,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                        onTap: () {
                                                                                                          if (context.read<CartProvider>().isProgress == false) {
                                                                                                            if (CUR_USERID != null) {
                                                                                                              if (context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity >= 1) {
                                                                                                                setStater(() {
                                                                                                                  context.read<ExploreProvider>().variantDecrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                });
                                                                                                              } else {
                                                                                                                setSnackbar('${getTranslated(context, 'MIN_MSG')}${context.read<ExploreProvider>().productList[index].quantity.toString()}', context);
                                                                                                              }

                                                                                                              if (context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity != 0) {
                                                                                                                var finalQuantity = context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity - int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString());
                                                                                                                setStater(() {
                                                                                                                  context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                });
                                                                                                                newRemoveCart(index, context.read<ExploreProvider>().productList, context.read<ExploreProvider>().productList[index], chipIndex, context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity);
                                                                                                              }
                                                                                                            }
                                                                                                          }
                                                                                                        },
                                                                                                      ),
                                                                                                      context.read<ExploreProvider>().productList[index].type == 'digital_product'
                                                                                                          ? const SizedBox()
                                                                                                          : Padding(
                                                                                                        padding: const EdgeInsets.only(left: 10),
                                                                                                        child: SizedBox(
                                                                                                            width: 20,
                                                                                                            child: Text(
                                                                                                              '${context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity}',
                                                                                                              style:  TextStyle(
                                                                                                                  fontFamily: 'ubuntu',
                                                                                                                  color: Theme.of(context)
                                                                                                                      .colorScheme
                                                                                                                      .fontColor
                                                                                                              ),
                                                                                                            )
                                                                                                        ),
                                                                                                      ),
                                                                                                      context.read<ExploreProvider>().productList[index].type == 'digital_product'
                                                                                                          ? const SizedBox()
                                                                                                          : InkWell(
                                                                                                        child: Card(
                                                                                                          shape: RoundedRectangleBorder(
                                                                                                            borderRadius: BorderRadius.circular(circularBorderRadius50),
                                                                                                          ),
                                                                                                          child: const Padding(
                                                                                                            padding: EdgeInsets.all(8.0),
                                                                                                            child: Icon(
                                                                                                              Icons.add,
                                                                                                              size: 15,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                        onTap: () async {
                                                                                                          if (att.length != 1) {
                                                                                                            if (mounted) {
                                                                                                              setStater(
                                                                                                                    () {
                                                                                                                  context.read<ExploreProvider>().productList[index].selVarient = chipIndex;
                                                                                                                  available = false;
                                                                                                                  _selectedIndex[indexAt] = chipIndex;
                                                                                                                  List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                  List<bool> check = [];
                                                                                                                  for (int i = 0; i < context.read<ExploreProvider>().productList[index].attributeList!.length; i++) {
                                                                                                                    List<String> attId = context.read<ExploreProvider>().productList[index].attributeList![i].id!.split(',');
                                                                                                                    if (_selectedIndex[i] != null) {
                                                                                                                      selectedId.add(
                                                                                                                        int.parse(
                                                                                                                          attId[_selectedIndex[i]!],
                                                                                                                        ),
                                                                                                                      );
                                                                                                                    }
                                                                                                                  }

                                                                                                                  check.clear();
                                                                                                                  late List<String> sinId;
                                                                                                                  findMatch:
                                                                                                                  for (int i = 0; i < context.read<ExploreProvider>().productList[index].prVarientList!.length; i++) {
                                                                                                                    sinId = context.read<ExploreProvider>().productList[index].prVarientList![i].attribute_value_ids!.split(',');

                                                                                                                    for (int j = 0; j < selectedId.length; j++) {
                                                                                                                      if (sinId.contains(selectedId[j].toString())) {
                                                                                                                        check.add(true);

                                                                                                                        if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                                          varSelected = i;
                                                                                                                          selectIndex = i;
                                                                                                                          break findMatch;
                                                                                                                        }
                                                                                                                      } else {
                                                                                                                        check.clear();
                                                                                                                        selectIndex = null;
                                                                                                                        break;
                                                                                                                      }
                                                                                                                    }
                                                                                                                  }

                                                                                                                  if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                                    if (context.read<ExploreProvider>().productList[index].stockType == '0' || context.read<ExploreProvider>().productList[index].stockType == '1') {
                                                                                                                      if (context.read<ExploreProvider>().productList[index].availability == '1') {
                                                                                                                        available = true;
                                                                                                                        outOfStock = false;
                                                                                                                        _oldSelVarient = varSelected!;
                                                                                                                      } else {
                                                                                                                        available = false;
                                                                                                                        outOfStock = true;
                                                                                                                      }
                                                                                                                    } else if (context.read<ExploreProvider>().productList[index].stockType == '') {
                                                                                                                      available = true;
                                                                                                                      outOfStock = false;
                                                                                                                      _oldSelVarient = varSelected!;
                                                                                                                    } else if (context.read<ExploreProvider>().productList[index].stockType == '2') {
                                                                                                                      if (context.read<ExploreProvider>().productList[index].prVarientList![varSelected!].availability == '1') {
                                                                                                                        available = true;
                                                                                                                        outOfStock = false;
                                                                                                                        _oldSelVarient = varSelected!;
                                                                                                                      } else {
                                                                                                                        available = false;
                                                                                                                        outOfStock = true;
                                                                                                                      }
                                                                                                                    }
                                                                                                                  } else {
                                                                                                                    available = false;
                                                                                                                    outOfStock = false;
                                                                                                                  }
                                                                                                                  if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                    int oldVarTotal = 0;
                                                                                                                    if (_oldSelVarient > 0) {
                                                                                                                      for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                        oldVarTotal = oldVarTotal + context.read<ExploreProvider>().productList[index].prVarientList![i].images!.length;
                                                                                                                      }
                                                                                                                    }
                                                                                                                    int p = context.read<ExploreProvider>().productList[index].otherImage!.length + 1 + oldVarTotal;
                                                                                                                  }
                                                                                                                },
                                                                                                              );
                                                                                                            }
                                                                                                            if (available!) {
                                                                                                              if (CUR_USERID != null) {
                                                                                                                if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                  qtyController.text = context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                } else {
                                                                                                                  qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                }
                                                                                                              } else {
                                                                                                                String qty = (await db.checkCartItemExists(context.read<ExploreProvider>().productList[index].id!, context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].id!))!;
                                                                                                                if (qty == '0') {
                                                                                                                  qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                } else {
                                                                                                                  context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount = qty;
                                                                                                                  qtyController.text = qty;
                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                }
                                                                                                              }
                                                                                                            }
                                                                                                          }
                                                                                                          if (context.read<CartProvider>().isProgress == false) {
                                                                                                            setStater(() {
                                                                                                              _selectedIndex[indexAt] = chipIndex;
                                                                                                            });
                                                                                                            if (CUR_USERID != null) {
                                                                                                              var finalQuantity = context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity + int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString());
                                                                                                              setStater(() {
                                                                                                                context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                              });
                                                                                                              addNewCart(index, context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity.toString(), 2);
                                                                                                              // widget.update();
                                                                                                            }
                                                                                                          }
                                                                                                        },
                                                                                                      )
                                                                                                    ],
                                                                                                  ),
                                                                                                ],
                                                                                              );
                                                                                            },
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                    ),
                                                                                  )
                                                                                      : const SizedBox();
                                                                                },
                                                                              ),
                                                                            ),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Divider(
                                                                      height: 2,
                                                                      color: Theme.of(
                                                                          context)
                                                                          .colorScheme
                                                                          .lightWhite,
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
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
                                                  },
                                                );
                                              },
                                            );
                                          }
                                          else
                                          {
                                            removeCart(
                                                index,
                                                context
                                                    .read<ExploreProvider>()
                                                    .productList,context);
                                          }

                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 25,
                                      height: 20,
                                      child: Stack(
                                        children: [
                                          TextField(
                                            textAlign: TextAlign.center,
                                            readOnly: true,
                                            style: TextStyle(
                                                fontSize: textFontSize12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .fontColor),
                                            controller: controllerText[index],
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: '',
                                            icon: const Icon(
                                              Icons.arrow_drop_down,
                                              size: 1,
                                            ),
                                            onSelected: (String value) {
                                              // if (isProgress == false) {
                                              //   addToCart(widget.index!, value, 2);
                                              // }
                                            },
                                            itemBuilder: (BuildContext context) {
                                              return context
                                                  .read<ExploreProvider>()
                                                  .productList[index]
                                                  .itemsCounter!
                                                  .map<PopupMenuItem<String>>(
                                                (String value) {
                                                  return PopupMenuItem(
                                                      value: value,
                                                      child: Text(value,
                                                          style: TextStyle(
                                                              color:
                                                                  Theme.of(context)
                                                                      .colorScheme
                                                                      .fontColor)));
                                                },
                                              ).toList();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              circularBorderRadius50),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(
                                            Icons.add,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        if (isProgress == false) {
                                          if ((context
                                                      .read<ExploreProvider>()
                                                      .productList[index]
                                                      .prVarientList
                                                      ?.length ??
                                                  1) >
                                              1) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                List<String> selList = context
                                                    .read<ExploreProvider>()
                                                    .productList[index]
                                                    .prVarientList![_oldSelVarient]
                                                    .attribute_value_ids!
                                                    .split(',');
                                                _selectedIndex.clear();
                                                for (int i = 0;
                                                    i <
                                                        context
                                                            .read<ExploreProvider>()
                                                            .productList[index]
                                                            .attributeList!
                                                            .length;
                                                    i++) {
                                                  List<String> sinList = context
                                                      .read<ExploreProvider>()
                                                      .productList[index]
                                                      .attributeList![i]
                                                      .id!
                                                      .split(',');

                                                  for (int j = 0;
                                                      j < sinList.length;
                                                      j++) {
                                                    if (selList
                                                        .contains(sinList[j])) {
                                                      _selectedIndex.insert(i, j);
                                                    }
                                                  }

                                                  if (_selectedIndex.length == i) {
                                                    _selectedIndex.insert(i, null);
                                                  }
                                                }
                                                return StatefulBuilder(
                                                  builder: (_,
                                                      StateSetter setStater) {
                                                    return AlertDialog(
                                                      contentPadding:
                                                          const EdgeInsets.all(0.0),
                                                      shape:
                                                          const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(
                                                              circularBorderRadius5),
                                                        ),
                                                      ),
                                                      content: SizedBox(
                                                        height: MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                            0.47,
                                                        child: Stack(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsetsDirectional
                                                                          .only(
                                                                      start: 10.0,
                                                                      end: 10.0,
                                                                      top: 5.0),
                                                              child: Container(
                                                                height:
                                                                    MediaQuery.of(context)
                                                                            .size
                                                                            .height *
                                                                        0.47,
                                                                decoration: BoxDecoration(
                                                                  color: Theme.of(context)
                                                                      .colorScheme
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          circularBorderRadius10),
                                                                ),
                                                                child: Column(
                                                                  children: [
                                                                    InkWell(
                                                                      child: Stack(
                                                                        children: [
                                                                          Row(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment
                                                                                    .start,
                                                                            children: [
                                                                              Flexible(
                                                                                flex: 1,
                                                                                child:
                                                                                    ClipRRect(
                                                                                  borderRadius:
                                                                                      const BorderRadius.only(
                                                                                    topLeft:
                                                                                        Radius.circular(circularBorderRadius4),
                                                                                    bottomLeft:
                                                                                        Radius.circular(circularBorderRadius4),
                                                                                  ),
                                                                                  child: DesignConfiguration
                                                                                      .getCacheNotworkImage(
                                                                                    boxFit:
                                                                                        BoxFit.cover,
                                                                                    context:
                                                                                        context,
                                                                                    heightvalue:
                                                                                        107,
                                                                                    widthvalue:
                                                                                        107,
                                                                                    placeHolderSize:
                                                                                        50,
                                                                                    imageurlString: context
                                                                                        .read<ExploreProvider>()
                                                                                        .productList[index]
                                                                                        .image!,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment:
                                                                                    CrossAxisAlignment
                                                                                        .start,
                                                                                children: [
                                                                                  context.read<ExploreProvider>().productList[index].brandName != '' &&
                                                                                          context.read<ExploreProvider>().productList[index].brandName != null
                                                                                      ? Padding(
                                                                                          padding: const EdgeInsets.only(
                                                                                            left: 15.0,
                                                                                            right: 15.0,
                                                                                            top: 16.0,
                                                                                          ),
                                                                                          child: Text(
                                                                                            context.read<ExploreProvider>().productList[index].brandName ?? '',
                                                                                            style: TextStyle(
                                                                                              fontWeight: FontWeight.bold,
                                                                                              color: Theme.of(context).colorScheme.lightBlack,
                                                                                              fontSize: textFontSize14,
                                                                                            ),
                                                                                          ),
                                                                                        )
                                                                                      : const SizedBox(),
                                                                                  GetTitleWidget(
                                                                                    title:
                                                                                        context.read<ExploreProvider>().productList[index].name ?? '',
                                                                                  ),
                                                                                  available ??
                                                                                          false || (outOfStock ?? false)
                                                                                      ? GetPrice(pos: selectIndex, from: true, model: context.read<ExploreProvider>().productList[index])
                                                                                      : GetPrice(
                                                                                          pos: context.read<ExploreProvider>().productList[index].selVarient,
                                                                                          from: false,
                                                                                          model: context.read<ExploreProvider>().productList[index],
                                                                                        ),
                                                                                ],
                                                                              )
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .white,
                                                                      child: Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment
                                                                                .start,
                                                                        mainAxisSize:
                                                                            MainAxisSize
                                                                                .min,
                                                                        children: [
                                                                          Container(
                                                                            height: MediaQuery.of(
                                                                                        context)
                                                                                    .size
                                                                                    .height *
                                                                                0.28,
                                                                            width: MediaQuery.of(
                                                                                        context)
                                                                                    .size
                                                                                    .height *
                                                                                0.6,
                                                                            color: Theme.of(
                                                                                    context)
                                                                                .colorScheme
                                                                                .white,
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets
                                                                                      .only(
                                                                                  top:
                                                                                      15.0),
                                                                              child: ListView
                                                                                  .builder(
                                                                                scrollDirection:
                                                                                    Axis.vertical,
                                                                                physics:
                                                                                    const BouncingScrollPhysics(),
                                                                                itemCount: context
                                                                                    .read<
                                                                                        ExploreProvider>()
                                                                                    .productList[
                                                                                        index]
                                                                                    .attributeList!
                                                                                    .length,
                                                                                itemBuilder:
                                                                                    (_,
                                                                                        indexAt) {
                                                                                  List<Widget?>
                                                                                      chips =
                                                                                      [];
                                                                                  List<String> att = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .value!
                                                                                      .split(',');
                                                                                  List<String> attId = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .id!
                                                                                      .split(',');
                                                                                  List<String> attSType = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .sType!
                                                                                      .split(',');
                                                                                  List<String> attSValue = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attributeList![indexAt]
                                                                                      .sValue!
                                                                                      .split(',');
                                                                                  int?
                                                                                      varSelected;
                                                                                  List<String> wholeAtt = context
                                                                                      .read<ExploreProvider>()
                                                                                      .productList[index]
                                                                                      .attrIds!
                                                                                      .split(',');
                                                                                  for (int i =
                                                                                          0;
                                                                                      i < att.length;
                                                                                      i++) {
                                                                                    Widget
                                                                                        itemLabel;
                                                                                    if (attSType[i] ==
                                                                                        '1') {
                                                                                      String
                                                                                          clr =
                                                                                          (attSValue[i].substring(1));
                                                                                      String
                                                                                          color =
                                                                                          '0xff$clr';
                                                                                      itemLabel =
                                                                                          Container(
                                                                                        width: 35,
                                                                                        height: 35,
                                                                                        decoration: BoxDecoration(
                                                                                          shape: BoxShape.circle,
                                                                                          color: _selectedIndex[indexAt] == (i) ? colors.primary : colors.secondary,
                                                                                        ),
                                                                                        child: Center(
                                                                                          child: Container(
                                                                                            width: 25,
                                                                                            height: 25,
                                                                                            decoration: BoxDecoration(
                                                                                              shape: BoxShape.circle,
                                                                                              color: Color(
                                                                                                int.parse(color),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    } else if (attSType[i] ==
                                                                                        '2') {
                                                                                      itemLabel =
                                                                                          Container(
                                                                                        decoration: BoxDecoration(
                                                                                          gradient: LinearGradient(
                                                                                              begin: Alignment.topLeft,
                                                                                              end: Alignment.bottomRight,
                                                                                              colors: _selectedIndex[indexAt] == (i)
                                                                                                  ? [colors.grad1Color, colors.grad2Color]
                                                                                                  : [
                                                                                                      Theme.of(context).colorScheme.white,
                                                                                                      Theme.of(context).colorScheme.white,
                                                                                                    ],
                                                                                              stops: const [0, 1]),
                                                                                          borderRadius: const BorderRadius.all(Radius.circular(circularBorderRadius8)),
                                                                                          border: Border.all(
                                                                                            color: _selectedIndex[indexAt] == (i) ? const Color(0xfffc6a57) : Theme.of(context).colorScheme.black,
                                                                                            width: 1,
                                                                                          ),
                                                                                        ),
                                                                                        child: ClipRRect(
                                                                                          borderRadius: BorderRadius.circular(circularBorderRadius8),
                                                                                          child: Image.network(
                                                                                            attSValue[i],
                                                                                            width: 80,
                                                                                            height: 80,
                                                                                            fit: BoxFit.cover,
                                                                                            errorBuilder: (context, error, stackTrace) => DesignConfiguration.erroWidget(80),
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                    else {
                                                                                      itemLabel =
                                                                                          Container(
                                                                                        decoration: BoxDecoration(
                                                                                          gradient: LinearGradient(
                                                                                            begin: Alignment.topLeft,
                                                                                            end: Alignment.bottomRight,
                                                                                            colors: _selectedIndex[indexAt] ==
                                                                                                    (i)
                                                                                                ? [
                                                                                                    colors.grad1Color,
                                                                                                    colors.grad2Color
                                                                                                  ]
                                                                                                : [
                                                                                                    Theme.of(context).colorScheme.white,
                                                                                                    Theme.of(context).colorScheme.white,
                                                                                                  ],
                                                                                            stops: const [
                                                                                              0,
                                                                                              1
                                                                                            ],
                                                                                          ),
                                                                                          borderRadius: const BorderRadius.all(Radius.circular(circularBorderRadius8)),
                                                                                          border: Border.all(
                                                                                            color: _selectedIndex[indexAt] == (i) ? const Color(0xfffc6a57) : Theme.of(context).colorScheme.black,
                                                                                            width: 1,
                                                                                          ),
                                                                                        ),
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(
                                                                                            horizontal: 15,
                                                                                            vertical: 6,
                                                                                          ),
                                                                                          child: Text(
                                                                                            '${att[i]} ${context.read<ExploreProvider>().productList[index].attributeList![indexAt].name}',
                                                                                            style: TextStyle(
                                                                                              fontFamily: 'ubuntu',
                                                                                              color: _selectedIndex[indexAt] == (i) ? Theme.of(context).colorScheme.white : Theme.of(context).colorScheme.fontColor,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                    if (_selectedIndex[indexAt] != null &&
                                                                                        wholeAtt.contains(attId[i])) {
                                                                                      choiceContainer =
                                                                                          Padding(
                                                                                        padding: const EdgeInsets.only(
                                                                                          right: 10,
                                                                                        ),
                                                                                        child: InkWell(
                                                                                          onTap: () async {
                                                                                            if (att.length != 1) {
                                                                                              if (mounted) {
                                                                                                setStater(
                                                                                                  () {
                                                                                                    context.read<ExploreProvider>().productList[index].selVarient = i;
                                                                                                    available = false;
                                                                                                    _selectedIndex[indexAt] = i;
                                                                                                    List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                    List<bool> check = [];
                                                                                                    for (int i = 0; i < context.read<ExploreProvider>().productList[index].attributeList!.length; i++) {
                                                                                                      List<String> attId = context.read<ExploreProvider>().productList[index].attributeList![i].id!.split(',');
                                                                                                      if (_selectedIndex[i] != null) {
                                                                                                        selectedId.add(
                                                                                                          int.parse(
                                                                                                            attId[_selectedIndex[i]!],
                                                                                                          ),
                                                                                                        );
                                                                                                      }
                                                                                                    }

                                                                                                    check.clear();
                                                                                                    late List<String> sinId;
                                                                                                    findMatch:
                                                                                                    for (int i = 0; i < context.read<ExploreProvider>().productList[index].prVarientList!.length; i++) {
                                                                                                      sinId = context.read<ExploreProvider>().productList[index].prVarientList![i].attribute_value_ids!.split(',');

                                                                                                      for (int j = 0; j < selectedId.length; j++) {
                                                                                                        if (sinId.contains(selectedId[j].toString())) {
                                                                                                          check.add(true);

                                                                                                          if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                            varSelected = i;
                                                                                                            selectIndex = i;
                                                                                                            break findMatch;
                                                                                                          }
                                                                                                        } else {
                                                                                                          check.clear();
                                                                                                          selectIndex = null;
                                                                                                          break;
                                                                                                        }
                                                                                                      }
                                                                                                    }

                                                                                                    if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                      if (context.read<ExploreProvider>().productList[index].stockType == '0' || context.read<ExploreProvider>().productList[index].stockType == '1') {
                                                                                                        if (context.read<ExploreProvider>().productList[index].availability == '1') {
                                                                                                          available = true;
                                                                                                          outOfStock = false;
                                                                                                          _oldSelVarient = varSelected!;
                                                                                                        } else {
                                                                                                          available = false;
                                                                                                          outOfStock = true;
                                                                                                        }
                                                                                                      } else if (context.read<ExploreProvider>().productList[index].stockType == '') {
                                                                                                        available = true;
                                                                                                        outOfStock = false;
                                                                                                        _oldSelVarient = varSelected!;
                                                                                                      } else if (context.read<ExploreProvider>().productList[index].stockType == '2') {
                                                                                                        if (context.read<ExploreProvider>().productList[index].prVarientList![varSelected!].availability == '1') {
                                                                                                          available = true;
                                                                                                          outOfStock = false;
                                                                                                          _oldSelVarient = varSelected!;
                                                                                                        } else {
                                                                                                          available = false;
                                                                                                          outOfStock = true;
                                                                                                        }
                                                                                                      }
                                                                                                    } else {
                                                                                                      available = false;
                                                                                                      outOfStock = false;
                                                                                                    }
                                                                                                    if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                      int oldVarTotal = 0;
                                                                                                      if (_oldSelVarient > 0) {
                                                                                                        for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                          oldVarTotal = oldVarTotal + context.read<ExploreProvider>().productList[index].prVarientList![i].images!.length;
                                                                                                        }
                                                                                                      }
                                                                                                      int p = context.read<ExploreProvider>().productList[index].otherImage!.length + 1 + oldVarTotal;
                                                                                                    }
                                                                                                  },
                                                                                                );
                                                                                              }
                                                                                              if (available!) {
                                                                                                if (CUR_USERID != null) {
                                                                                                  if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                    qtyController.text = context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount!;
                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                  } else {
                                                                                                    qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                  }
                                                                                                } else {
                                                                                                  String qty = (await db.checkCartItemExists(context.read<ExploreProvider>().productList[index].id!, context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].id!))!;
                                                                                                  if (qty == '0') {
                                                                                                    qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                  } else {
                                                                                                    context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount = qty;
                                                                                                    qtyController.text = qty;
                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                  }
                                                                                                }
                                                                                              }
                                                                                            }
                                                                                          },
                                                                                          child: Container(
                                                                                            child: itemLabel,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                      chips.add(choiceContainer);
                                                                                    }
                                                                                  }

                                                                                  String value = _selectedIndex[indexAt] != null &&
                                                                                          _selectedIndex[indexAt]! <= att.length
                                                                                      ? att[_selectedIndex[indexAt]!]
                                                                                      : getTranslated(context, 'VAR_SEL')!.substring(2, getTranslated(context, 'VAR_SEL')!.length);
                                                                                  return chips.isNotEmpty
                                                                                      ? Container(
                                                                                          color: Theme.of(context).colorScheme.white,
                                                                                          child: Padding(
                                                                                            padding: const EdgeInsetsDirectional.only(
                                                                                              start: 10.0,
                                                                                              end: 10.0,
                                                                                            ),
                                                                                            child: Column(
                                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                                              children: <Widget>[
                                                                                                Padding(
                                                                                                  padding: const EdgeInsets.only(bottom: 15.0),
                                                                                                  child: Text(
                                                                                                    '${context.read<ExploreProvider>().productList[index].attributeList![indexAt].name!} : $value',
                                                                                                    style: const TextStyle(
                                                                                                      fontFamily: 'ubuntu',
                                                                                                      fontWeight: FontWeight.bold,

                                                                                                    ),
                                                                                                  ),
                                                                                                ),
                                                                                                ListView.builder(
                                                                                                  itemCount: chips.length,
                                                                                                  shrinkWrap: true,
                                                                                                  physics: const NeverScrollableScrollPhysics(),
                                                                                                  itemBuilder: (_, chipIndex) {
                                                                                                    return Row(
                                                                                                      children: [
                                                                                                        chips[chipIndex] ?? Container(),
                                                                                                        const Spacer(),
                                                                                                        Row(
                                                                                                          children: <Widget>[
                                                                                                            context.read<ExploreProvider>().productList[index].type == 'digital_product'
                                                                                                                ? const SizedBox()
                                                                                                                : InkWell(
                                                                                                                    child: Card(
                                                                                                                      shape: RoundedRectangleBorder(
                                                                                                                        borderRadius: BorderRadius.circular(circularBorderRadius50),
                                                                                                                      ),
                                                                                                                      child: const Padding(
                                                                                                                        padding: EdgeInsets.all(8.0),
                                                                                                                        child: Icon(
                                                                                                                          Icons.remove,
                                                                                                                          size: 15,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                    onTap: () {
                                                                                                                      if (context.read<CartProvider>().isProgress == false) {
                                                                                                                        if (CUR_USERID != null) {
                                                                                                                          if (context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity > 1) {
                                                                                                                            setStater(() {
                                                                                                                              context.read<ExploreProvider>().variantDecrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                            });
                                                                                                                          } else {
                                                                                                                            setSnackbar('${getTranslated(context, 'MIN_MSG')}${context.read<ExploreProvider>().productList[index].quantity.toString()}', context);
                                                                                                                          }

                                                                                                                          if (context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity != 0) {
                                                                                                                            var finalQuantity = context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity - int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString());

                                                                                                                            setStater((){
                                                                                                                              context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                            });
                                                                                                                            newRemoveCart(index, context.read<ExploreProvider>().productList, context.read<ExploreProvider>().productList[index], chipIndex, context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity);

                                                                                                                          }
                                                                                                                        }
                                                                                                                      }
                                                                                                                    },
                                                                                                                  ),
                                                                                                            context.read<ExploreProvider>().productList[index].type == 'digital_product'
                                                                                                                ? const SizedBox()
                                                                                                                : Padding(
                                                                                                                    padding: const EdgeInsets.only(left: 10),
                                                                                                                    child: SizedBox(
                                                                                                                        width: 20,
                                                                                                                        child: Text(
                                                                                                                          '${context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity}',
                                                                                                                          style:  TextStyle(
                                                                                                                            fontFamily: 'ubuntu',
                                                                                                                            color: Theme.of(context)
                                                                                                                                .colorScheme
                                                                                                                                .fontColor
                                                                                                                          ),
                                                                                                                        )
                                                                                                                        // Stack(
                                                                                                                        //   children: [
                                                                                                                        //     TextField(
                                                                                                                        //       textAlign:
                                                                                                                        //           TextAlign
                                                                                                                        //               .center,
                                                                                                                        //       readOnly: true,
                                                                                                                        //       style: TextStyle(
                                                                                                                        //           fontSize:
                                                                                                                        //               textFontSize12,
                                                                                                                        //           color: Theme.of(
                                                                                                                        //                   context)
                                                                                                                        //               .colorScheme
                                                                                                                        //               .fontColor),
                                                                                                                        //       controller: context
                                                                                                                        //           .read<
                                                                                                                        //               CartProvider>()
                                                                                                                        //           .controller[index],
                                                                                                                        //       decoration:
                                                                                                                        //           const InputDecoration(
                                                                                                                        //         border:
                                                                                                                        //             InputBorder
                                                                                                                        //                 .none,
                                                                                                                        //       ),
                                                                                                                        //     ),
                                                                                                                        //     PopupMenuButton<
                                                                                                                        //         String>(
                                                                                                                        //       tooltip: '',
                                                                                                                        //       icon: const Icon(
                                                                                                                        //         Icons
                                                                                                                        //             .arrow_drop_down,
                                                                                                                        //         size: 1,
                                                                                                                        //       ),
                                                                                                                        //       onSelected:
                                                                                                                        //           (String
                                                                                                                        //               value) {
                                                                                                                        //         if (context
                                                                                                                        //                 .read<
                                                                                                                        //                     CartProvider>()
                                                                                                                        //                 .isProgress ==
                                                                                                                        //             false) {
                                                                                                                        //           if (CUR_USERID !=
                                                                                                                        //               null) {
                                                                                                                        //             context.read<CartProvider>().addToCart(
                                                                                                                        //                 index:
                                                                                                                        //                     index,
                                                                                                                        //                 qty:
                                                                                                                        //                     value,
                                                                                                                        //                 cartList: [],
                                                                                                                        //                 context:
                                                                                                                        //                     context,
                                                                                                                        //                 update:
                                                                                                                        //                     setStateNow);
                                                                                                                        //           } else {
                                                                                                                        //             context.read<CartProvider>().addAndRemoveQty(
                                                                                                                        //                 qty:
                                                                                                                        //                     value,
                                                                                                                        //                 from: 3,
                                                                                                                        //                 totalLen: context.read<ExploreProvider>().productList[index].itemsCounter!.length *
                                                                                                                        //                     int.parse(context
                                                                                                                        //                         .read<
                                                                                                                        //                             ExploreProvider>()
                                                                                                                        //                         .productList[
                                                                                                                        //                             index]
                                                                                                                        //                         .qtyStepSize!),
                                                                                                                        //                 index:
                                                                                                                        //                     index,
                                                                                                                        //                 price:
                                                                                                                        //                     price,
                                                                                                                        //                 selectedPos:
                                                                                                                        //                     selectedPos,
                                                                                                                        //                 total:
                                                                                                                        //                     total,
                                                                                                                        //                 cartList: [],
                                                                                                                        //                 itemCounter: int.parse(context
                                                                                                                        //                     .read<
                                                                                                                        //                         ExploreProvider>()
                                                                                                                        //                     .productList[
                                                                                                                        //                         index]
                                                                                                                        //                     .qtyStepSize!),
                                                                                                                        //                 context:
                                                                                                                        //                     context,
                                                                                                                        //                 update:
                                                                                                                        //                     setStateNow);
                                                                                                                        //           }
                                                                                                                        //         }
                                                                                                                        //       },
                                                                                                                        //       itemBuilder:
                                                                                                                        //           (BuildContext
                                                                                                                        //               context) {
                                                                                                                        //         return context
                                                                                                                        //             .read<
                                                                                                                        //                 ExploreProvider>()
                                                                                                                        //             .productList[
                                                                                                                        //                 index]
                                                                                                                        //             .itemsCounter!
                                                                                                                        //             .map<
                                                                                                                        //                 PopupMenuItem<
                                                                                                                        //                     String>>(
                                                                                                                        //           (String
                                                                                                                        //               value) {
                                                                                                                        //             return PopupMenuItem(
                                                                                                                        //               value:
                                                                                                                        //                   value,
                                                                                                                        //               child:
                                                                                                                        //                   Text(
                                                                                                                        //                 value,
                                                                                                                        //                 style:
                                                                                                                        //                     TextStyle(
                                                                                                                        //                   color: Theme.of(context)
                                                                                                                        //                       .colorScheme
                                                                                                                        //                       .fontColor,
                                                                                                                        //                   fontFamily:
                                                                                                                        //                       'ubuntu',
                                                                                                                        //                 ),
                                                                                                                        //               ),
                                                                                                                        //             );
                                                                                                                        //           },
                                                                                                                        //         ).toList();
                                                                                                                        //       },
                                                                                                                        //     ),
                                                                                                                        //   ],
                                                                                                                        // ),
                                                                                                                        ),
                                                                                                                  ),
                                                                                                            context.read<ExploreProvider>().productList[index].type == 'digital_product'
                                                                                                                ? const SizedBox()
                                                                                                                : InkWell(
                                                                                                                    child: Card(
                                                                                                                      shape: RoundedRectangleBorder(
                                                                                                                        borderRadius: BorderRadius.circular(circularBorderRadius50),
                                                                                                                      ),
                                                                                                                      child: const Padding(
                                                                                                                        padding: EdgeInsets.all(8.0),
                                                                                                                        child: Icon(
                                                                                                                          Icons.add,
                                                                                                                          size: 15,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                    onTap: () async {
                                                                                                                      if (att.length != 1) {
                                                                                                                        if (mounted) {
                                                                                                                          setStater(
                                                                                                                            () {
                                                                                                                              context.read<ExploreProvider>().productList[index].selVarient = chipIndex;
                                                                                                                              available = false;
                                                                                                                              _selectedIndex[indexAt] = chipIndex;
                                                                                                                              List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                              List<bool> check = [];
                                                                                                                              for (int i = 0; i < context.read<ExploreProvider>().productList[index].attributeList!.length; i++) {
                                                                                                                                List<String> attId = context.read<ExploreProvider>().productList[index].attributeList![i].id!.split(',');
                                                                                                                                if (_selectedIndex[i] != null) {
                                                                                                                                  selectedId.add(
                                                                                                                                    int.parse(
                                                                                                                                      attId[_selectedIndex[i]!],
                                                                                                                                    ),
                                                                                                                                  );
                                                                                                                                }
                                                                                                                              }

                                                                                                                              check.clear();
                                                                                                                              late List<String> sinId;
                                                                                                                              findMatch:
                                                                                                                              for (int i = 0; i < context.read<ExploreProvider>().productList[index].prVarientList!.length; i++) {
                                                                                                                                sinId = context.read<ExploreProvider>().productList[index].prVarientList![i].attribute_value_ids!.split(',');

                                                                                                                                for (int j = 0; j < selectedId.length; j++) {
                                                                                                                                  if (sinId.contains(selectedId[j].toString())) {
                                                                                                                                    check.add(true);

                                                                                                                                    if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                                                      varSelected = i;
                                                                                                                                      selectIndex = i;
                                                                                                                                      break findMatch;
                                                                                                                                    }
                                                                                                                                  } else {
                                                                                                                                    check.clear();
                                                                                                                                    selectIndex = null;
                                                                                                                                    break;
                                                                                                                                  }
                                                                                                                                }
                                                                                                                              }

                                                                                                                              if (selectedId.length == sinId.length && check.length == selectedId.length) {
                                                                                                                                if (context.read<ExploreProvider>().productList[index].stockType == '0' || context.read<ExploreProvider>().productList[index].stockType == '1') {
                                                                                                                                  if (context.read<ExploreProvider>().productList[index].availability == '1') {
                                                                                                                                    available = true;
                                                                                                                                    outOfStock = false;
                                                                                                                                    _oldSelVarient = varSelected!;
                                                                                                                                  } else {
                                                                                                                                    available = false;
                                                                                                                                    outOfStock = true;
                                                                                                                                  }
                                                                                                                                } else if (context.read<ExploreProvider>().productList[index].stockType == '') {
                                                                                                                                  available = true;
                                                                                                                                  outOfStock = false;
                                                                                                                                  _oldSelVarient = varSelected!;
                                                                                                                                } else if (context.read<ExploreProvider>().productList[index].stockType == '2') {
                                                                                                                                  if (context.read<ExploreProvider>().productList[index].prVarientList![varSelected!].availability == '1') {
                                                                                                                                    available = true;
                                                                                                                                    outOfStock = false;
                                                                                                                                    _oldSelVarient = varSelected!;
                                                                                                                                  } else {
                                                                                                                                    available = false;
                                                                                                                                    outOfStock = true;
                                                                                                                                  }
                                                                                                                                }
                                                                                                                              } else {
                                                                                                                                available = false;
                                                                                                                                outOfStock = false;
                                                                                                                              }
                                                                                                                              if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                                int oldVarTotal = 0;
                                                                                                                                if (_oldSelVarient > 0) {
                                                                                                                                  for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                                    oldVarTotal = oldVarTotal + context.read<ExploreProvider>().productList[index].prVarientList![i].images!.length;
                                                                                                                                  }
                                                                                                                                }
                                                                                                                                int p = context.read<ExploreProvider>().productList[index].otherImage!.length + 1 + oldVarTotal;
                                                                                                                              }
                                                                                                                            },
                                                                                                                          );
                                                                                                                        }
                                                                                                                        if (available!) {
                                                                                                                          if (CUR_USERID != null) {
                                                                                                                            if (context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                              qtyController.text = context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                            } else {
                                                                                                                              qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                            }
                                                                                                                          } else {
                                                                                                                            String qty = (await db.checkCartItemExists(context.read<ExploreProvider>().productList[index].id!, context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].id!))!;
                                                                                                                            if (qty == '0') {
                                                                                                                              qtyController.text = context.read<ExploreProvider>().productList[index].minOrderQuntity.toString();
                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                            } else {
                                                                                                                              context.read<ExploreProvider>().productList[index].prVarientList![_oldSelVarient].cartCount = qty;
                                                                                                                              qtyController.text = qty;
                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                            }
                                                                                                                          }
                                                                                                                        }
                                                                                                                      }
                                                                                                                      if (context.read<CartProvider>().isProgress == false) {
                                                                                                                        setStater(() {
                                                                                                                          _selectedIndex[indexAt] = chipIndex;
                                                                                                                        });
                                                                                                                        if (CUR_USERID != null) {
                                                                                                                          // Navigator.pop(context);
                                                                                                                          var finalQuantity = context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity + int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString());
                                                                                                                          setStater(() {
                                                                                                                            context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                          });
                                                                                                                          // context.read<ExploreProvider>().variantIncrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                          addNewCart(index, context.read<ExploreProvider>().productList[index].prVarientList![chipIndex].quantity.toString(), 2);
                                                                                                                          // widget.update();
                                                                                                                        }
                                                                                                                      }
                                                                                                                    },
                                                                                                                  )
                                                                                                          ],
                                                                                                        ),
                                                                                                      ],
                                                                                                    );
                                                                                                  },
                                                                                                )
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        )
                                                                                      : const SizedBox();
                                                                                },
                                                                              ),
                                                                            ),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Divider(
                                                                      height: 2,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .colorScheme
                                                                          .lightWhite,
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
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
                                                  },
                                                );
                                              },
                                            );
                                          } else {

                                            addCart(
                                                index,
                                                (int.parse(controllerText[index]
                                                            .text) +
                                                        int.parse(context
                                                            .read<ExploreProvider>()
                                                            .productList[index]
                                                            .qtyStepSize!))
                                                    .toString(),
                                                2);
                                          }
                                        }
                                      },
                                    )
                                  ],
                                )
                              : const SizedBox(),
                        )
                        // controllerText[index].text == '0'
                        //     ? Positioned.directional(
                        //   textDirection: Directionality.of(context),
                        //   bottom: 4,
                        //   end: 4,
                        //   child: InkWell(
                        //     onTap: () {
                        //       if (isProgress == false) {
                        //         if ((context
                        //             .read<ExploreProvider>()
                        //             .productList[index]
                        //             .prVarientList
                        //             ?.length ??
                        //             1) >
                        //             1) {
                        //           showDialog(
                        //             context: context,
                        //             builder: (BuildContext context) {
                        //               List<String> selList = context
                        //                   .read<ExploreProvider>()
                        //                   .productList[index]
                        //                   .prVarientList![_oldSelVarient]
                        //                   .attribute_value_ids!
                        //                   .split(',');
                        //               _selectedIndex.clear();
                        //               for (int i = 0;
                        //               i <
                        //                   context
                        //                       .read<ExploreProvider>()
                        //                       .productList[index]
                        //                       .attributeList!
                        //                       .length;
                        //               i++) {
                        //                 List<String> sinList = context
                        //                     .read<ExploreProvider>()
                        //                     .productList[index]
                        //                     .attributeList![i]
                        //                     .id!
                        //                     .split(',');
                        //
                        //                 for (int j = 0;
                        //                 j < sinList.length;
                        //                 j++) {
                        //                   if (selList.contains(sinList[j])) {
                        //                     _selectedIndex.insert(i, j);
                        //                   }
                        //                 }
                        //
                        //                 if (_selectedIndex.length == i) {
                        //                   _selectedIndex.insert(i, null);
                        //                 }
                        //               }
                        //               return StatefulBuilder(
                        //                 builder: (BuildContext context,
                        //                     StateSetter setStater) {
                        //                   return AlertDialog(
                        //                     contentPadding:
                        //                     const EdgeInsets.all(0.0),
                        //                     shape:
                        //                     const RoundedRectangleBorder(
                        //                       borderRadius: BorderRadius.all(
                        //                         Radius.circular(
                        //                             circularBorderRadius5),
                        //                       ),
                        //                     ),
                        //                     content: Padding(
                        //                       padding:
                        //                       const EdgeInsetsDirectional
                        //                           .only(
                        //                           start: 10.0,
                        //                           end: 10.0,
                        //                           top: 5.0),
                        //                       child: Container(
                        //                         height: MediaQuery
                        //                             .of(
                        //                             context)
                        //                             .size
                        //                             .height *
                        //                             0.47,
                        //                         decoration: BoxDecoration(
                        //                           color: Theme
                        //                               .of(context)
                        //                               .colorScheme
                        //                               .white,
                        //                           borderRadius:
                        //                           BorderRadius.circular(
                        //                               circularBorderRadius10),
                        //                         ),
                        //                         child: Column(
                        //                           children: [
                        //                             InkWell(
                        //                               child: Stack(
                        //                                 children: [
                        //                                   Row(
                        //                                     crossAxisAlignment:
                        //                                     CrossAxisAlignment
                        //                                         .start,
                        //                                     children: [
                        //                                       Flexible(
                        //                                         flex: 1,
                        //                                         child:
                        //                                         ClipRRect(
                        //                                           borderRadius:
                        //                                           const BorderRadius
                        //                                               .only(
                        //                                             topLeft: Radius
                        //                                                 .circular(
                        //                                                 circularBorderRadius4),
                        //                                             bottomLeft:
                        //                                             Radius.circular(
                        //                                                 circularBorderRadius4),
                        //                                           ),
                        //                                           child: DesignConfiguration
                        //                                               .getCacheNotworkImage(
                        //                                             boxFit: BoxFit
                        //                                                 .cover,
                        //                                             context:
                        //                                             context,
                        //                                             heightvalue:
                        //                                             107,
                        //                                             widthvalue:
                        //                                             107,
                        //                                             placeHolderSize:
                        //                                             50,
                        //                                             imageurlString: context
                        //                                                 .read<
                        //                                                 ExploreProvider>()
                        //                                                 .productList[
                        //                                             index]
                        //                                                 .image!,
                        //                                           ),
                        //                                         ),
                        //                                       ),
                        //                                       Column(
                        //                                         crossAxisAlignment:
                        //                                         CrossAxisAlignment
                        //                                             .start,
                        //                                         children: [
                        //                                           context
                        //                                               .read<
                        //                                               ExploreProvider>()
                        //                                               .productList[index]
                        //                                               .brandName !=
                        //                                               '' &&
                        //                                               context
                        //                                                   .read<
                        //                                                   ExploreProvider>()
                        //                                                   .productList[index]
                        //                                                   .brandName !=
                        //                                                   null
                        //                                               ? Padding(
                        //                                             padding:
                        //                                             const EdgeInsets
                        //                                                 .only(
                        //                                               left: 15.0,
                        //                                               right: 15.0,
                        //                                               top: 16.0,
                        //                                             ),
                        //                                             child:
                        //                                             Text(
                        //                                               context
                        //                                                   .read<
                        //                                                   ExploreProvider>()
                        //                                                   .productList[index]
                        //                                                   .brandName ??
                        //                                                   '',
                        //                                               style: TextStyle(
                        //                                                 fontWeight: FontWeight
                        //                                                     .bold,
                        //                                                 color: Theme
                        //                                                     .of(
                        //                                                     context)
                        //                                                     .colorScheme
                        //                                                     .lightBlack,
                        //                                                 fontSize: textFontSize14,
                        //                                               ),
                        //                                             ),
                        //                                           )
                        //                                               : const SizedBox(),
                        //                                           GetTitleWidget(
                        //                                             title: context
                        //                                                 .read<
                        //                                                 ExploreProvider>()
                        //                                                 .productList[index]
                        //                                                 .name ??
                        //                                                 '',
                        //                                           ),
                        //                                           available ??
                        //                                               false ||
                        //                                                   (outOfStock ??
                        //                                                       false)
                        //                                               ? GetPrice(
                        //                                               pos:
                        //                                               selectIndex,
                        //                                               from:
                        //                                               true,
                        //                                               model:
                        //                                               context
                        //                                                   .read<
                        //                                                   ExploreProvider>()
                        //                                                   .productList[index])
                        //                                               : GetPrice(
                        //                                             pos:
                        //                                             context
                        //                                                 .read<
                        //                                                 ExploreProvider>()
                        //                                                 .productList[index]
                        //                                                 .selVarient,
                        //                                             from:
                        //                                             false,
                        //                                             model:
                        //                                             context
                        //                                                 .read<
                        //                                                 ExploreProvider>()
                        //                                                 .productList[index],
                        //                                           ),
                        //                                         ],
                        //                                       )
                        //                                     ],
                        //                                   ),
                        //                                 ],
                        //                               ),
                        //                               // onTap: () async {
                        //                               //   Product model = context.read<ExploreProvider>().productList[index];
                        //                               //   Navigator.push(
                        //                               //     context,
                        //                               //     PageRouteBuilder(
                        //                               //       pageBuilder: (_, __, ___) => ProductDetail(
                        //                               //         model: model,
                        //                               //         secPos: 0,
                        //                               //         index: index,
                        //                               //         list: true,
                        //                               //       ),
                        //                               //     ),
                        //                               //   );
                        //                               // },
                        //                             ),
                        //                             Container(
                        //                               color: Theme
                        //                                   .of(context)
                        //                                   .colorScheme
                        //                                   .white,
                        //                               child: Column(
                        //                                 crossAxisAlignment:
                        //                                 CrossAxisAlignment
                        //                                     .start,
                        //                                 mainAxisSize:
                        //                                 MainAxisSize.min,
                        //                                 children: [
                        //                                   Container(
                        //                                     height: MediaQuery
                        //                                         .of(
                        //                                         context)
                        //                                         .size
                        //                                         .height *
                        //                                         0.28,
                        //                                     width: MediaQuery
                        //                                         .of(
                        //                                         context)
                        //                                         .size
                        //                                         .height *
                        //                                         0.6,
                        //                                     color: Theme
                        //                                         .of(
                        //                                         context)
                        //                                         .colorScheme
                        //                                         .white,
                        //                                     child: Padding(
                        //                                       padding:
                        //                                       const EdgeInsets
                        //                                           .only(
                        //                                           top:
                        //                                           15.0),
                        //                                       child: ListView
                        //                                           .builder(
                        //                                         scrollDirection:
                        //                                         Axis.vertical,
                        //                                         physics:
                        //                                         const BouncingScrollPhysics(),
                        //                                         itemCount: context
                        //                                             .read<
                        //                                             ExploreProvider>()
                        //                                             .productList[
                        //                                         index]
                        //                                             .attributeList!
                        //                                             .length,
                        //                                         itemBuilder:
                        //                                             (context,
                        //                                             indexAt) {
                        //                                           List<Widget?>
                        //                                           chips =
                        //                                           [];
                        //                                           List<
                        //                                               String> att = context
                        //                                               .read<
                        //                                               ExploreProvider>()
                        //                                               .productList[
                        //                                           index]
                        //                                               .attributeList![
                        //                                           indexAt]
                        //                                               .value!
                        //                                               .split(
                        //                                               ',');
                        //                                           List<
                        //                                               String> attId = context
                        //                                               .read<
                        //                                               ExploreProvider>()
                        //                                               .productList[
                        //                                           index]
                        //                                               .attributeList![
                        //                                           indexAt]
                        //                                               .id!
                        //                                               .split(
                        //                                               ',');
                        //                                           List<
                        //                                               String> attSType = context
                        //                                               .read<
                        //                                               ExploreProvider>()
                        //                                               .productList[
                        //                                           index]
                        //                                               .attributeList![
                        //                                           indexAt]
                        //                                               .sType!
                        //                                               .split(
                        //                                               ',');
                        //                                           List<
                        //                                               String> attSValue = context
                        //                                               .read<
                        //                                               ExploreProvider>()
                        //                                               .productList[
                        //                                           index]
                        //                                               .attributeList![
                        //                                           indexAt]
                        //                                               .sValue!
                        //                                               .split(
                        //                                               ',');
                        //                                           int?
                        //                                           varSelected;
                        //                                           List<
                        //                                               String> wholeAtt = context
                        //                                               .read<
                        //                                               ExploreProvider>()
                        //                                               .productList[
                        //                                           index]
                        //                                               .attrIds!
                        //                                               .split(
                        //                                               ',');
                        //                                           for (int i =
                        //                                           0;
                        //                                           i < att.length;
                        //                                           i++) {
                        //                                             Widget
                        //                                             itemLabel;
                        //                                             if (attSType[
                        //                                             i] ==
                        //                                                 '1') {
                        //                                               String
                        //                                               clr =
                        //                                               (attSValue[i]
                        //                                                   .substring(
                        //                                                   1));
                        //                                               String
                        //                                               color =
                        //                                                   '0xff$clr';
                        //                                               itemLabel =
                        //                                                   Container(
                        //                                                     width:
                        //                                                     35,
                        //                                                     height:
                        //                                                     35,
                        //                                                     decoration:
                        //                                                     BoxDecoration(
                        //                                                       shape:
                        //                                                       BoxShape
                        //                                                           .circle,
                        //                                                       color: _selectedIndex[index] ==
                        //                                                           (i)
                        //                                                           ? colors
                        //                                                           .primary
                        //                                                           : colors
                        //                                                           .secondary,
                        //                                                     ),
                        //                                                     child:
                        //                                                     Center(
                        //                                                       child:
                        //                                                       Container(
                        //                                                         width: 25,
                        //                                                         height: 25,
                        //                                                         decoration: BoxDecoration(
                        //                                                           shape: BoxShape
                        //                                                               .circle,
                        //                                                           color: Color(
                        //                                                             int
                        //                                                                 .parse(
                        //                                                                 color),
                        //                                                           ),
                        //                                                         ),
                        //                                                       ),
                        //                                                     ),
                        //                                                   );
                        //                                             } else
                        //                                             if (attSType[
                        //                                             i] ==
                        //                                                 '2') {
                        //                                               itemLabel =
                        //                                                   Container(
                        //                                                     decoration:
                        //                                                     BoxDecoration(
                        //                                                       gradient: LinearGradient(
                        //                                                           begin: Alignment
                        //                                                               .topLeft,
                        //                                                           end: Alignment
                        //                                                               .bottomRight,
                        //                                                           colors: _selectedIndex[indexAt] ==
                        //                                                               (i)
                        //                                                               ? [
                        //                                                             colors
                        //                                                                 .grad1Color,
                        //                                                             colors
                        //                                                                 .grad2Color
                        //                                                           ]
                        //                                                               : [
                        //                                                             Theme
                        //                                                                 .of(
                        //                                                                 context)
                        //                                                                 .colorScheme
                        //                                                                 .white,
                        //                                                             Theme
                        //                                                                 .of(
                        //                                                                 context)
                        //                                                                 .colorScheme
                        //                                                                 .white,
                        //                                                           ],
                        //                                                           stops: const [
                        //                                                             0,
                        //                                                             1
                        //                                                           ]),
                        //                                                       borderRadius:
                        //                                                       const BorderRadius
                        //                                                           .all(
                        //                                                           Radius
                        //                                                               .circular(
                        //                                                               circularBorderRadius8)),
                        //                                                       border:
                        //                                                       Border
                        //                                                           .all(
                        //                                                         color: _selectedIndex[indexAt] ==
                        //                                                             (i)
                        //                                                             ? const Color(
                        //                                                             0xfffc6a57)
                        //                                                             : Theme
                        //                                                             .of(
                        //                                                             context)
                        //                                                             .colorScheme
                        //                                                             .black,
                        //                                                         width: 1,
                        //                                                       ),
                        //                                                     ),
                        //                                                     child:
                        //                                                     ClipRRect(
                        //                                                       borderRadius:
                        //                                                       BorderRadius
                        //                                                           .circular(
                        //                                                           circularBorderRadius8),
                        //                                                       child:
                        //                                                       Image
                        //                                                           .network(
                        //                                                         attSValue[i],
                        //                                                         width: 80,
                        //                                                         height: 80,
                        //                                                         fit: BoxFit
                        //                                                             .cover,
                        //                                                         errorBuilder: (
                        //                                                             context,
                        //                                                             error,
                        //                                                             stackTrace) =>
                        //                                                             DesignConfiguration
                        //                                                                 .erroWidget(
                        //                                                                 80),
                        //                                                       ),
                        //                                                     ),
                        //                                                   );
                        //                                             } else {
                        //                                               itemLabel =
                        //                                                   Container(
                        //                                                     decoration:
                        //                                                     BoxDecoration(
                        //                                                       gradient:
                        //                                                       LinearGradient(
                        //                                                         begin: Alignment
                        //                                                             .topLeft,
                        //                                                         end: Alignment
                        //                                                             .bottomRight,
                        //                                                         colors: _selectedIndex[indexAt] ==
                        //                                                             (i)
                        //                                                             ? [
                        //                                                           colors
                        //                                                               .grad1Color,
                        //                                                           colors
                        //                                                               .grad2Color
                        //                                                         ]
                        //                                                             : [
                        //                                                           Theme
                        //                                                               .of(
                        //                                                               context)
                        //                                                               .colorScheme
                        //                                                               .white,
                        //                                                           Theme
                        //                                                               .of(
                        //                                                               context)
                        //                                                               .colorScheme
                        //                                                               .white,
                        //                                                         ],
                        //                                                         stops: const [
                        //                                                           0,
                        //                                                           1
                        //                                                         ],
                        //                                                       ),
                        //                                                       borderRadius:
                        //                                                       const BorderRadius
                        //                                                           .all(
                        //                                                           Radius
                        //                                                               .circular(
                        //                                                               circularBorderRadius8)),
                        //                                                       border:
                        //                                                       Border
                        //                                                           .all(
                        //                                                         color: _selectedIndex[indexAt] ==
                        //                                                             (i)
                        //                                                             ? const Color(
                        //                                                             0xfffc6a57)
                        //                                                             : Theme
                        //                                                             .of(
                        //                                                             context)
                        //                                                             .colorScheme
                        //                                                             .black,
                        //                                                         width: 1,
                        //                                                       ),
                        //                                                     ),
                        //                                                     child:
                        //                                                     Padding(
                        //                                                       padding:
                        //                                                       const EdgeInsets
                        //                                                           .symmetric(
                        //                                                         horizontal: 15,
                        //                                                         vertical: 6,
                        //                                                       ),
                        //                                                       child:
                        //                                                       Text(
                        //                                                         '${att[i]} ${context
                        //                                                             .read<
                        //                                                             ExploreProvider>()
                        //                                                             .productList[index]
                        //                                                             .attributeList![indexAt]
                        //                                                             .name}',
                        //                                                         style: TextStyle(
                        //                                                           fontFamily: 'ubuntu',
                        //                                                           color: _selectedIndex[indexAt] ==
                        //                                                               (i)
                        //                                                               ? Theme
                        //                                                               .of(
                        //                                                               context)
                        //                                                               .colorScheme
                        //                                                               .white
                        //                                                               : Theme
                        //                                                               .of(
                        //                                                               context)
                        //                                                               .colorScheme
                        //                                                               .fontColor,
                        //                                                         ),
                        //                                                       ),
                        //                                                     ),
                        //                                                   );
                        //                                             }
                        //                                             if (_selectedIndex[indexAt] !=
                        //                                                 null &&
                        //                                                 wholeAtt
                        //                                                     .contains(
                        //                                                     attId[i])) {
                        //                                               choiceContainer =
                        //                                                   Padding(
                        //                                                     padding:
                        //                                                     const EdgeInsets
                        //                                                         .only(
                        //                                                       right:
                        //                                                       10,
                        //                                                     ),
                        //                                                     child:
                        //                                                     InkWell(
                        //                                                       onTap:
                        //                                                           () async {
                        //                                                         if (att
                        //                                                             .length !=
                        //                                                             1) {
                        //                                                           if (mounted) {
                        //                                                             setStater(
                        //                                                                   () {
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ExploreProvider>()
                        //                                                                     .productList[index]
                        //                                                                     .selVarient =
                        //                                                                     i;
                        //                                                                 available =
                        //                                                                 false;
                        //                                                                 _selectedIndex[indexAt] =
                        //                                                                     i;
                        //                                                                 List<
                        //                                                                     int> selectedId = [
                        //                                                                 ]; //list where user choosen item id is stored
                        //                                                                 List<
                        //                                                                     bool> check = [
                        //                                                                 ];
                        //                                                                 for (int i = 0; i <
                        //                                                                     context
                        //                                                                         .read<
                        //                                                                         ExploreProvider>()
                        //                                                                         .productList[index]
                        //                                                                         .attributeList!
                        //                                                                         .length; i++) {
                        //                                                                   List<
                        //                                                                       String> attId = context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .attributeList![i]
                        //                                                                       .id!
                        //                                                                       .split(
                        //                                                                       ',');
                        //                                                                   if (_selectedIndex[i] !=
                        //                                                                       null) {
                        //                                                                     selectedId
                        //                                                                         .add(
                        //                                                                       int
                        //                                                                           .parse(
                        //                                                                         attId[_selectedIndex[i]!],
                        //                                                                       ),
                        //                                                                     );
                        //                                                                   }
                        //                                                                 }
                        //
                        //                                                                 check
                        //                                                                     .clear();
                        //                                                                 late List<
                        //                                                                     String> sinId;
                        //                                                                 findMatch:
                        //                                                                 for (int i = 0; i <
                        //                                                                     context
                        //                                                                         .read<
                        //                                                                         ExploreProvider>()
                        //                                                                         .productList[index]
                        //                                                                         .prVarientList!
                        //                                                                         .length; i++) {
                        //                                                                   sinId =
                        //                                                                       context
                        //                                                                           .read<
                        //                                                                           ExploreProvider>()
                        //                                                                           .productList[index]
                        //                                                                           .prVarientList![i]
                        //                                                                           .attribute_value_ids!
                        //                                                                           .split(
                        //                                                                           ',');
                        //
                        //                                                                   for (int j = 0; j <
                        //                                                                       selectedId
                        //                                                                           .length; j++) {
                        //                                                                     if (sinId
                        //                                                                         .contains(
                        //                                                                         selectedId[j]
                        //                                                                             .toString())) {
                        //                                                                       check
                        //                                                                           .add(
                        //                                                                           true);
                        //
                        //                                                                       if (selectedId
                        //                                                                           .length ==
                        //                                                                           sinId
                        //                                                                               .length &&
                        //                                                                           check
                        //                                                                               .length ==
                        //                                                                               selectedId
                        //                                                                                   .length) {
                        //                                                                         varSelected =
                        //                                                                             i;
                        //                                                                         selectIndex =
                        //                                                                             i;
                        //                                                                         break findMatch;
                        //                                                                       }
                        //                                                                     } else {
                        //                                                                       check
                        //                                                                           .clear();
                        //                                                                       selectIndex =
                        //                                                                       null;
                        //                                                                       break;
                        //                                                                     }
                        //                                                                   }
                        //                                                                 }
                        //
                        //                                                                 if (selectedId
                        //                                                                     .length ==
                        //                                                                     sinId
                        //                                                                         .length &&
                        //                                                                     check
                        //                                                                         .length ==
                        //                                                                         selectedId
                        //                                                                             .length) {
                        //                                                                   if (context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .stockType ==
                        //                                                                       '0' ||
                        //                                                                       context
                        //                                                                           .read<
                        //                                                                           ExploreProvider>()
                        //                                                                           .productList[index]
                        //                                                                           .stockType ==
                        //                                                                           '1') {
                        //                                                                     if (context
                        //                                                                         .read<
                        //                                                                         ExploreProvider>()
                        //                                                                         .productList[index]
                        //                                                                         .availability ==
                        //                                                                         '1') {
                        //                                                                       available =
                        //                                                                       true;
                        //                                                                       outOfStock =
                        //                                                                       false;
                        //                                                                       _oldSelVarient =
                        //                                                                       varSelected!;
                        //                                                                     } else {
                        //                                                                       available =
                        //                                                                       false;
                        //                                                                       outOfStock =
                        //                                                                       true;
                        //                                                                     }
                        //                                                                   } else
                        //                                                                   if (context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .stockType ==
                        //                                                                       '') {
                        //                                                                     available =
                        //                                                                     true;
                        //                                                                     outOfStock =
                        //                                                                     false;
                        //                                                                     _oldSelVarient =
                        //                                                                     varSelected!;
                        //                                                                   } else
                        //                                                                   if (context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .stockType ==
                        //                                                                       '2') {
                        //                                                                     if (context
                        //                                                                         .read<
                        //                                                                         ExploreProvider>()
                        //                                                                         .productList[index]
                        //                                                                         .prVarientList![varSelected!]
                        //                                                                         .availability ==
                        //                                                                         '1') {
                        //                                                                       available =
                        //                                                                       true;
                        //                                                                       outOfStock =
                        //                                                                       false;
                        //                                                                       _oldSelVarient =
                        //                                                                       varSelected!;
                        //                                                                     } else {
                        //                                                                       available =
                        //                                                                       false;
                        //                                                                       outOfStock =
                        //                                                                       true;
                        //                                                                     }
                        //                                                                   }
                        //                                                                 } else {
                        //                                                                   available =
                        //                                                                   false;
                        //                                                                   outOfStock =
                        //                                                                   false;
                        //                                                                 }
                        //                                                                 if (context
                        //                                                                     .read<
                        //                                                                     ExploreProvider>()
                        //                                                                     .productList[index]
                        //                                                                     .prVarientList![_oldSelVarient]
                        //                                                                     .images!
                        //                                                                     .isNotEmpty) {
                        //                                                                   int oldVarTotal = 0;
                        //                                                                   if (_oldSelVarient >
                        //                                                                       0) {
                        //                                                                     for (int i = 0; i <
                        //                                                                         _oldSelVarient; i++) {
                        //                                                                       oldVarTotal =
                        //                                                                           oldVarTotal +
                        //                                                                               context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .prVarientList![i]
                        //                                                                                   .images!
                        //                                                                                   .length;
                        //                                                                     }
                        //                                                                   }
                        //                                                                   int p = context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .otherImage!
                        //                                                                       .length +
                        //                                                                       1 +
                        //                                                                       oldVarTotal;
                        //                                                                 }
                        //                                                               },
                        //                                                             );
                        //                                                           }
                        //                                                           if (available!) {
                        //                                                             if (CUR_USERID !=
                        //                                                                 null) {
                        //                                                               if (context
                        //                                                                   .read<
                        //                                                                   ExploreProvider>()
                        //                                                                   .productList[index]
                        //                                                                   .prVarientList![_oldSelVarient]
                        //                                                                   .cartCount! !=
                        //                                                                   '0') {
                        //                                                                 qtyController
                        //                                                                     .text =
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ExploreProvider>()
                        //                                                                     .productList[index]
                        //                                                                     .prVarientList![_oldSelVarient]
                        //                                                                     .cartCount!;
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ProductDetailProvider>()
                        //                                                                     .qtyChange =
                        //                                                                 true;
                        //                                                               } else {
                        //                                                                 qtyController
                        //                                                                     .text =
                        //                                                                     context
                        //                                                                         .read<
                        //                                                                         ExploreProvider>()
                        //                                                                         .productList[index]
                        //                                                                         .minOrderQuntity
                        //                                                                         .toString();
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ProductDetailProvider>()
                        //                                                                     .qtyChange =
                        //                                                                 true;
                        //                                                               }
                        //                                                             } else {
                        //                                                               String qty = (await db
                        //                                                                   .checkCartItemExists(
                        //                                                                   context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .id!,
                        //                                                                   context
                        //                                                                       .read<
                        //                                                                       ExploreProvider>()
                        //                                                                       .productList[index]
                        //                                                                       .prVarientList![_oldSelVarient]
                        //                                                                       .id!))!;
                        //                                                               if (qty ==
                        //                                                                   '0') {
                        //                                                                 qtyController
                        //                                                                     .text =
                        //                                                                     context
                        //                                                                         .read<
                        //                                                                         ExploreProvider>()
                        //                                                                         .productList[index]
                        //                                                                         .minOrderQuntity
                        //                                                                         .toString();
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ProductDetailProvider>()
                        //                                                                     .qtyChange =
                        //                                                                 true;
                        //                                                               } else {
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ExploreProvider>()
                        //                                                                     .productList[index]
                        //                                                                     .prVarientList![_oldSelVarient]
                        //                                                                     .cartCount =
                        //                                                                     qty;
                        //                                                                 qtyController
                        //                                                                     .text =
                        //                                                                     qty;
                        //                                                                 context
                        //                                                                     .read<
                        //                                                                     ProductDetailProvider>()
                        //                                                                     .qtyChange =
                        //                                                                 true;
                        //                                                               }
                        //                                                             }
                        //                                                           }
                        //                                                         }
                        //                                                       },
                        //                                                       child:
                        //                                                       Container(
                        //                                                         child: itemLabel,
                        //                                                       ),
                        //                                                     ),
                        //                                                   );
                        //                                               chips.add(
                        //                                                   choiceContainer);
                        //                                             }
                        //                                           }
                        //
                        //                                           String value = _selectedIndex[indexAt] !=
                        //                                               null &&
                        //                                               _selectedIndex[indexAt]! <=
                        //                                                   att
                        //                                                       .length
                        //                                               ? att[_selectedIndex[
                        //                                           indexAt]!]
                        //                                               : getTranslated(
                        //                                               context,
                        //                                               'VAR_SEL')!
                        //                                               .substring(
                        //                                               2,
                        //                                               getTranslated(
                        //                                                   context,
                        //                                                   'VAR_SEL')!
                        //                                                   .length);
                        //                                           return chips
                        //                                               .isNotEmpty
                        //                                               ? Container(
                        //                                             color:
                        //                                             Theme
                        //                                                 .of(context)
                        //                                                 .colorScheme
                        //                                                 .white,
                        //                                             child:
                        //                                             Padding(
                        //                                               padding: const EdgeInsetsDirectional
                        //                                                   .only(
                        //                                                 start: 10.0,
                        //                                                 end: 10.0,
                        //                                               ),
                        //                                               child: Column(
                        //                                                 crossAxisAlignment: CrossAxisAlignment
                        //                                                     .start,
                        //                                                 children: <
                        //                                                     Widget>[
                        //                                                   Padding(
                        //                                                     padding: const EdgeInsets
                        //                                                         .only(
                        //                                                         bottom: 15.0),
                        //                                                     child: Text(
                        //                                                       '${context
                        //                                                           .read<
                        //                                                           ExploreProvider>()
                        //                                                           .productList[index]
                        //                                                           .attributeList![indexAt]
                        //                                                           .name!} : $value',
                        //                                                       style: const TextStyle(
                        //                                                         fontFamily: 'ubuntu',
                        //                                                         fontWeight: FontWeight
                        //                                                             .bold,
                        //                                                       ),
                        //                                                     ),
                        //                                                   ),
                        //                                                   ListView
                        //                                                       .builder(
                        //                                                     itemCount: chips
                        //                                                         .length,
                        //                                                     shrinkWrap: true,
                        //                                                     physics:
                        //                                                     const NeverScrollableScrollPhysics(),
                        //                                                     itemBuilder: (
                        //                                                         context,
                        //                                                         chipIndex) {
                        //                                                       return Row(
                        //                                                         children: [
                        //                                                           chips[chipIndex] ??
                        //                                                               Container(),
                        //                                                           const Spacer(),
                        //                                                           Row(
                        //                                                             children: <
                        //                                                                 Widget>[
                        //                                                               context
                        //                                                                   .read<
                        //                                                                   ExploreProvider>()
                        //                                                                   .productList[index]
                        //                                                                   .type ==
                        //                                                                   'digital_product'
                        //                                                                   ? const SizedBox()
                        //                                                                   : InkWell(
                        //                                                                 child: Card(
                        //                                                                   shape: RoundedRectangleBorder(
                        //                                                                     borderRadius: BorderRadius
                        //                                                                         .circular(
                        //                                                                         circularBorderRadius50),
                        //                                                                   ),
                        //                                                                   child: const Padding(
                        //                                                                     padding: EdgeInsets
                        //                                                                         .all(
                        //                                                                         8.0),
                        //                                                                     child: Icon(
                        //                                                                       Icons
                        //                                                                           .remove,
                        //                                                                       size: 15,
                        //                                                                     ),
                        //                                                                   ),
                        //                                                                 ),
                        //                                                                 onTap: () {
                        //                                                                   if (context
                        //                                                                       .read<
                        //                                                                       CartProvider>()
                        //                                                                       .isProgress ==
                        //                                                                       false) {
                        //                                                                     if (CUR_USERID !=
                        //                                                                         null) {
                        //                                                                       if (context
                        //                                                                           .read<
                        //                                                                           ExploreProvider>()
                        //                                                                           .productList[index]
                        //                                                                           .prVarientList![chipIndex]
                        //                                                                           .quantity >
                        //                                                                           1) {
                        //                                                                         setStater(() {
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .variantDecrement(
                        //                                                                               index,
                        //                                                                               chipIndex,
                        //                                                                               (int
                        //                                                                                   .parse(
                        //                                                                                   context
                        //                                                                                       .read<
                        //                                                                                       ExploreProvider>()
                        //                                                                                       .productList[index]
                        //                                                                                       .qtyStepSize
                        //                                                                                       .toString())));
                        //                                                                         });
                        //                                                                       } else {
                        //                                                                         setSnackbar(
                        //                                                                             '${getTranslated(
                        //                                                                                 context,
                        //                                                                                 'MIN_MSG')}${context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .quantity
                        //                                                                                 .toString()}',
                        //                                                                             context);
                        //                                                                       }
                        //                                                                       removeCart(
                        //                                                                           index,
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .productList);
                        //                                                                     }
                        //                                                                   }
                        //                                                                 },
                        //                                                               ),
                        //                                                               context
                        //                                                                   .read<
                        //                                                                   ExploreProvider>()
                        //                                                                   .productList[index]
                        //                                                                   .type ==
                        //                                                                   'digital_product'
                        //                                                                   ? const SizedBox()
                        //                                                                   : Padding(
                        //                                                                 padding: const EdgeInsets
                        //                                                                     .only(
                        //                                                                     left: 10),
                        //                                                                 child: SizedBox(
                        //                                                                     width: 20,
                        //                                                                     child: Text(
                        //                                                                       '${context
                        //                                                                           .read<
                        //                                                                           ExploreProvider>()
                        //                                                                           .productList[index]
                        //                                                                           .prVarientList![chipIndex]
                        //                                                                           .quantity}',
                        //                                                                       style: const TextStyle(
                        //                                                                         fontFamily: 'ubuntu',
                        //                                                                       ),
                        //                                                                     )
                        //                                                                   // Stack(
                        //                                                                   //   children: [
                        //                                                                   //     TextField(
                        //                                                                   //       textAlign:
                        //                                                                   //           TextAlign
                        //                                                                   //               .center,
                        //                                                                   //       readOnly: true,
                        //                                                                   //       style: TextStyle(
                        //                                                                   //           fontSize:
                        //                                                                   //               textFontSize12,
                        //                                                                   //           color: Theme.of(
                        //                                                                   //                   context)
                        //                                                                   //               .colorScheme
                        //                                                                   //               .fontColor),
                        //                                                                   //       controller: context
                        //                                                                   //           .read<
                        //                                                                   //               CartProvider>()
                        //                                                                   //           .controller[index],
                        //                                                                   //       decoration:
                        //                                                                   //           const InputDecoration(
                        //                                                                   //         border:
                        //                                                                   //             InputBorder
                        //                                                                   //                 .none,
                        //                                                                   //       ),
                        //                                                                   //     ),
                        //                                                                   //     PopupMenuButton<
                        //                                                                   //         String>(
                        //                                                                   //       tooltip: '',
                        //                                                                   //       icon: const Icon(
                        //                                                                   //         Icons
                        //                                                                   //             .arrow_drop_down,
                        //                                                                   //         size: 1,
                        //                                                                   //       ),
                        //                                                                   //       onSelected:
                        //                                                                   //           (String
                        //                                                                   //               value) {
                        //                                                                   //         if (context
                        //                                                                   //                 .read<
                        //                                                                   //                     CartProvider>()
                        //                                                                   //                 .isProgress ==
                        //                                                                   //             false) {
                        //                                                                   //           if (CUR_USERID !=
                        //                                                                   //               null) {
                        //                                                                   //             context.read<CartProvider>().addToCart(
                        //                                                                   //                 index:
                        //                                                                   //                     index,
                        //                                                                   //                 qty:
                        //                                                                   //                     value,
                        //                                                                   //                 cartList: [],
                        //                                                                   //                 context:
                        //                                                                   //                     context,
                        //                                                                   //                 update:
                        //                                                                   //                     setStateNow);
                        //                                                                   //           } else {
                        //                                                                   //             context.read<CartProvider>().addAndRemoveQty(
                        //                                                                   //                 qty:
                        //                                                                   //                     value,
                        //                                                                   //                 from: 3,
                        //                                                                   //                 totalLen: context.read<ExploreProvider>().productList[index].itemsCounter!.length *
                        //                                                                   //                     int.parse(context
                        //                                                                   //                         .read<
                        //                                                                   //                             ExploreProvider>()
                        //                                                                   //                         .productList[
                        //                                                                   //                             index]
                        //                                                                   //                         .qtyStepSize!),
                        //                                                                   //                 index:
                        //                                                                   //                     index,
                        //                                                                   //                 price:
                        //                                                                   //                     price,
                        //                                                                   //                 selectedPos:
                        //                                                                   //                     selectedPos,
                        //                                                                   //                 total:
                        //                                                                   //                     total,
                        //                                                                   //                 cartList: [],
                        //                                                                   //                 itemCounter: int.parse(context
                        //                                                                   //                     .read<
                        //                                                                   //                         ExploreProvider>()
                        //                                                                   //                     .productList[
                        //                                                                   //                         index]
                        //                                                                   //                     .qtyStepSize!),
                        //                                                                   //                 context:
                        //                                                                   //                     context,
                        //                                                                   //                 update:
                        //                                                                   //                     setStateNow);
                        //                                                                   //           }
                        //                                                                   //         }
                        //                                                                   //       },
                        //                                                                   //       itemBuilder:
                        //                                                                   //           (BuildContext
                        //                                                                   //               context) {
                        //                                                                   //         return context
                        //                                                                   //             .read<
                        //                                                                   //                 ExploreProvider>()
                        //                                                                   //             .productList[
                        //                                                                   //                 index]
                        //                                                                   //             .itemsCounter!
                        //                                                                   //             .map<
                        //                                                                   //                 PopupMenuItem<
                        //                                                                   //                     String>>(
                        //                                                                   //           (String
                        //                                                                   //               value) {
                        //                                                                   //             return PopupMenuItem(
                        //                                                                   //               value:
                        //                                                                   //                   value,
                        //                                                                   //               child:
                        //                                                                   //                   Text(
                        //                                                                   //                 value,
                        //                                                                   //                 style:
                        //                                                                   //                     TextStyle(
                        //                                                                   //                   color: Theme.of(context)
                        //                                                                   //                       .colorScheme
                        //                                                                   //                       .fontColor,
                        //                                                                   //                   fontFamily:
                        //                                                                   //                       'ubuntu',
                        //                                                                   //                 ),
                        //                                                                   //               ),
                        //                                                                   //             );
                        //                                                                   //           },
                        //                                                                   //         ).toList();
                        //                                                                   //       },
                        //                                                                   //     ),
                        //                                                                   //   ],
                        //                                                                   // ),
                        //                                                                 ),
                        //                                                               ),
                        //                                                               // : Container(
                        //                                                               //     width: 37,
                        //                                                               //     height: 20,
                        //                                                               //     decoration: BoxDecoration(
                        //                                                               //       color: Theme.of(context).colorScheme.white,
                        //                                                               //       borderRadius: BorderRadius.circular(circularBorderRadius5),
                        //                                                               //     ),
                        //                                                               //     child: Stack(
                        //                                                               //       children: [
                        //                                                               //         TextField(
                        //                                                               //           textAlign: TextAlign.center,
                        //                                                               //           readOnly: true,
                        //                                                               //           style: TextStyle(fontSize: textFontSize12, color: Theme.of(context).colorScheme.fontColor),
                        //                                                               //           controller: controllerText[index],
                        //                                                               //           decoration: const InputDecoration(
                        //                                                               //             border: InputBorder.none,
                        //                                                               //           ),
                        //                                                               //         ),
                        //                                                               //         PopupMenuButton<String>(
                        //                                                               //           tooltip: '',
                        //                                                               //           icon: const Icon(
                        //                                                               //             Icons.arrow_drop_down,
                        //                                                               //             size: 0,
                        //                                                               //           ),
                        //                                                               //           onSelected: (String value) {
                        //                                                               //             // if (isProgress ==
                        //                                                               //             //     false) {
                        //                                                               //             //   addToCart(
                        //                                                               //             //       widget.index!,
                        //                                                               //             //       value,
                        //                                                               //             //       2);
                        //                                                               //             // }
                        //                                                               //           },
                        //                                                               //           itemBuilder: (BuildContext context) {
                        //                                                               //             return context.read<ExploreProvider>().productList[index].itemsCounter!.map<PopupMenuItem<String>>(
                        //                                                               //               (String value) {
                        //                                                               //                 return PopupMenuItem(
                        //                                                               //                   value: value,
                        //                                                               //                   child: Text(
                        //                                                               //                     value,
                        //                                                               //                     style: TextStyle(
                        //                                                               //                       color: Theme.of(context).colorScheme.fontColor,
                        //                                                               //                       fontFamily: 'ubuntu',
                        //                                                               //                     ),
                        //                                                               //                   ),
                        //                                                               //                 );
                        //                                                               //               },
                        //                                                               //             ).toList();
                        //                                                               //           },
                        //                                                               //         ),
                        //                                                               //       ],
                        //                                                               //     ),
                        //                                                               //   ),
                        //                                                               //     : Padding(
                        //                                                               //   padding: const EdgeInsets.only(left: 10),
                        //                                                               //   child: SizedBox(
                        //                                                               //       width: 20,
                        //                                                               //       child:  Text(
                        //                                                               //         '${context
                        //                                                               //             .read<
                        //                                                               //             ExploreProvider>()
                        //                                                               //             .productList[index].prVarientList![chipIndex].quantity}',
                        //                                                               //         style: const TextStyle(
                        //                                                               //           fontFamily: 'ubuntu',
                        //                                                               //         ),
                        //                                                               //       )
                        //                                                               //     // Stack(
                        //                                                               //     //   children: [
                        //                                                               //     //     TextField(
                        //                                                               //     //       textAlign:
                        //                                                               //     //           TextAlign
                        //                                                               //     //               .center,
                        //                                                               //     //       readOnly: true,
                        //                                                               //     //       style: TextStyle(
                        //                                                               //     //           fontSize:
                        //                                                               //     //               textFontSize12,
                        //                                                               //     //           color: Theme.of(
                        //                                                               //     //                   context)
                        //                                                               //     //               .colorScheme
                        //                                                               //     //               .fontColor),
                        //                                                               //     //       controller: context
                        //                                                               //     //           .read<
                        //                                                               //     //               CartProvider>()
                        //                                                               //     //           .controller[index],
                        //                                                               //     //       decoration:
                        //                                                               //     //           const InputDecoration(
                        //                                                               //     //         border:
                        //                                                               //     //             InputBorder
                        //                                                               //     //                 .none,
                        //                                                               //     //       ),
                        //                                                               //     //     ),
                        //                                                               //     //     PopupMenuButton<
                        //                                                               //     //         String>(
                        //                                                               //     //       tooltip: '',
                        //                                                               //     //       icon: const Icon(
                        //                                                               //     //         Icons
                        //                                                               //     //             .arrow_drop_down,
                        //                                                               //     //         size: 1,
                        //                                                               //     //       ),
                        //                                                               //     //       onSelected:
                        //                                                               //     //           (String
                        //                                                               //     //               value) {
                        //                                                               //     //         if (context
                        //                                                               //     //                 .read<
                        //                                                               //     //                     CartProvider>()
                        //                                                               //     //                 .isProgress ==
                        //                                                               //     //             false) {
                        //                                                               //     //           if (CUR_USERID !=
                        //                                                               //     //               null) {
                        //                                                               //     //             context.read<CartProvider>().addToCart(
                        //                                                               //     //                 index:
                        //                                                               //     //                     index,
                        //                                                               //     //                 qty:
                        //                                                               //     //                     value,
                        //                                                               //     //                 cartList: [],
                        //                                                               //     //                 context:
                        //                                                               //     //                     context,
                        //                                                               //     //                 update:
                        //                                                               //     //                     setStateNow);
                        //                                                               //     //           } else {
                        //                                                               //     //             context.read<CartProvider>().addAndRemoveQty(
                        //                                                               //     //                 qty:
                        //                                                               //     //                     value,
                        //                                                               //     //                 from: 3,
                        //                                                               //     //                 totalLen: context.read<ExploreProvider>().productList[index].itemsCounter!.length *
                        //                                                               //     //                     int.parse(context
                        //                                                               //     //                         .read<
                        //                                                               //     //                             ExploreProvider>()
                        //                                                               //     //                         .productList[
                        //                                                               //     //                             index]
                        //                                                               //     //                         .qtyStepSize!),
                        //                                                               //     //                 index:
                        //                                                               //     //                     index,
                        //                                                               //     //                 price:
                        //                                                               //     //                     price,
                        //                                                               //     //                 selectedPos:
                        //                                                               //     //                     selectedPos,
                        //                                                               //     //                 total:
                        //                                                               //     //                     total,
                        //                                                               //     //                 cartList: [],
                        //                                                               //     //                 itemCounter: int.parse(context
                        //                                                               //     //                     .read<
                        //                                                               //     //                         ExploreProvider>()
                        //                                                               //     //                     .productList[
                        //                                                               //     //                         index]
                        //                                                               //     //                     .qtyStepSize!),
                        //                                                               //     //                 context:
                        //                                                               //     //                     context,
                        //                                                               //     //                 update:
                        //                                                               //     //                     setStateNow);
                        //                                                               //     //           }
                        //                                                               //     //         }
                        //                                                               //     //       },
                        //                                                               //     //       itemBuilder:
                        //                                                               //     //           (BuildContext
                        //                                                               //     //               context) {
                        //                                                               //     //         return context
                        //                                                               //     //             .read<
                        //                                                               //     //                 ExploreProvider>()
                        //                                                               //     //             .productList[
                        //                                                               //     //                 index]
                        //                                                               //     //             .itemsCounter!
                        //                                                               //     //             .map<
                        //                                                               //     //                 PopupMenuItem<
                        //                                                               //     //                     String>>(
                        //                                                               //     //           (String
                        //                                                               //     //               value) {
                        //                                                               //     //             return PopupMenuItem(
                        //                                                               //     //               value:
                        //                                                               //     //                   value,
                        //                                                               //     //               child:
                        //                                                               //     //                   Text(
                        //                                                               //     //                 value,
                        //                                                               //     //                 style:
                        //                                                               //     //                     TextStyle(
                        //                                                               //     //                   color: Theme.of(context)
                        //                                                               //     //                       .colorScheme
                        //                                                               //     //                       .fontColor,
                        //                                                               //     //                   fontFamily:
                        //                                                               //     //                       'ubuntu',
                        //                                                               //     //                 ),
                        //                                                               //     //               ),
                        //                                                               //     //             );
                        //                                                               //     //           },
                        //                                                               //     //         ).toList();
                        //                                                               //     //       },
                        //                                                               //     //     ),
                        //                                                               //     //   ],
                        //                                                               //     // ),
                        //                                                               //   ),
                        //                                                               // ),
                        //                                                               context
                        //                                                                   .read<
                        //                                                                   ExploreProvider>()
                        //                                                                   .productList[index]
                        //                                                                   .type ==
                        //                                                                   'digital_product'
                        //                                                                   ? const SizedBox()
                        //                                                                   : InkWell(
                        //                                                                 child: Card(
                        //                                                                   shape: RoundedRectangleBorder(
                        //                                                                     borderRadius: BorderRadius
                        //                                                                         .circular(
                        //                                                                         circularBorderRadius50),
                        //                                                                   ),
                        //                                                                   child: const Padding(
                        //                                                                     padding: EdgeInsets
                        //                                                                         .all(
                        //                                                                         8.0),
                        //                                                                     child: Icon(
                        //                                                                       Icons
                        //                                                                           .add,
                        //                                                                       size: 15,
                        //                                                                     ),
                        //                                                                   ),
                        //                                                                 ),
                        //                                                                 onTap: () async {
                        //                                                                   if (att
                        //                                                                       .length !=
                        //                                                                       1) {
                        //                                                                     if (mounted) {
                        //                                                                       setStater(
                        //                                                                             () {
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .productList[index]
                        //                                                                               .selVarient =
                        //                                                                               chipIndex;
                        //                                                                           available =
                        //                                                                           false;
                        //                                                                           _selectedIndex[indexAt] =
                        //                                                                               chipIndex;
                        //                                                                           List<
                        //                                                                               int> selectedId = [
                        //                                                                           ]; //list where user choosen item id is stored
                        //                                                                           List<
                        //                                                                               bool> check = [
                        //                                                                           ];
                        //                                                                           for (int i = 0; i <
                        //                                                                               context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .attributeList!
                        //                                                                                   .length; i++) {
                        //                                                                             List<
                        //                                                                                 String> attId = context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .attributeList![i]
                        //                                                                                 .id!
                        //                                                                                 .split(
                        //                                                                                 ',');
                        //                                                                             if (_selectedIndex[i] !=
                        //                                                                                 null) {
                        //                                                                               selectedId
                        //                                                                                   .add(
                        //                                                                                 int
                        //                                                                                     .parse(
                        //                                                                                   attId[_selectedIndex[i]!],
                        //                                                                                 ),
                        //                                                                               );
                        //                                                                             }
                        //                                                                           }
                        //
                        //                                                                           check
                        //                                                                               .clear();
                        //                                                                           late List<
                        //                                                                               String> sinId;
                        //                                                                           findMatch:
                        //                                                                           for (int i = 0; i <
                        //                                                                               context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .prVarientList!
                        //                                                                                   .length; i++) {
                        //                                                                             sinId =
                        //                                                                                 context
                        //                                                                                     .read<
                        //                                                                                     ExploreProvider>()
                        //                                                                                     .productList[index]
                        //                                                                                     .prVarientList![i]
                        //                                                                                     .attribute_value_ids!
                        //                                                                                     .split(
                        //                                                                                     ',');
                        //
                        //                                                                             for (int j = 0; j <
                        //                                                                                 selectedId
                        //                                                                                     .length; j++) {
                        //                                                                               if (sinId
                        //                                                                                   .contains(
                        //                                                                                   selectedId[j]
                        //                                                                                       .toString())) {
                        //                                                                                 check
                        //                                                                                     .add(
                        //                                                                                     true);
                        //
                        //                                                                                 if (selectedId
                        //                                                                                     .length ==
                        //                                                                                     sinId
                        //                                                                                         .length &&
                        //                                                                                     check
                        //                                                                                         .length ==
                        //                                                                                         selectedId
                        //                                                                                             .length) {
                        //                                                                                   varSelected =
                        //                                                                                       i;
                        //                                                                                   selectIndex =
                        //                                                                                       i;
                        //                                                                                   break findMatch;
                        //                                                                                 }
                        //                                                                               } else {
                        //                                                                                 check
                        //                                                                                     .clear();
                        //                                                                                 selectIndex =
                        //                                                                                 null;
                        //                                                                                 break;
                        //                                                                               }
                        //                                                                             }
                        //                                                                           }
                        //
                        //                                                                           if (selectedId
                        //                                                                               .length ==
                        //                                                                               sinId
                        //                                                                                   .length &&
                        //                                                                               check
                        //                                                                                   .length ==
                        //                                                                                   selectedId
                        //                                                                                       .length) {
                        //                                                                             if (context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .stockType ==
                        //                                                                                 '0' ||
                        //                                                                                 context
                        //                                                                                     .read<
                        //                                                                                     ExploreProvider>()
                        //                                                                                     .productList[index]
                        //                                                                                     .stockType ==
                        //                                                                                     '1') {
                        //                                                                               if (context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .availability ==
                        //                                                                                   '1') {
                        //                                                                                 available =
                        //                                                                                 true;
                        //                                                                                 outOfStock =
                        //                                                                                 false;
                        //                                                                                 _oldSelVarient =
                        //                                                                                 varSelected!;
                        //                                                                               } else {
                        //                                                                                 available =
                        //                                                                                 false;
                        //                                                                                 outOfStock =
                        //                                                                                 true;
                        //                                                                               }
                        //                                                                             } else
                        //                                                                             if (context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .stockType ==
                        //                                                                                 '') {
                        //                                                                               available =
                        //                                                                               true;
                        //                                                                               outOfStock =
                        //                                                                               false;
                        //                                                                               _oldSelVarient =
                        //                                                                               varSelected!;
                        //                                                                             } else
                        //                                                                             if (context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .stockType ==
                        //                                                                                 '2') {
                        //                                                                               if (context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .prVarientList![varSelected!]
                        //                                                                                   .availability ==
                        //                                                                                   '1') {
                        //                                                                                 available =
                        //                                                                                 true;
                        //                                                                                 outOfStock =
                        //                                                                                 false;
                        //                                                                                 _oldSelVarient =
                        //                                                                                 varSelected!;
                        //                                                                               } else {
                        //                                                                                 available =
                        //                                                                                 false;
                        //                                                                                 outOfStock =
                        //                                                                                 true;
                        //                                                                               }
                        //                                                                             }
                        //                                                                           } else {
                        //                                                                             available =
                        //                                                                             false;
                        //                                                                             outOfStock =
                        //                                                                             false;
                        //                                                                           }
                        //                                                                           if (context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .productList[index]
                        //                                                                               .prVarientList![_oldSelVarient]
                        //                                                                               .images!
                        //                                                                               .isNotEmpty) {
                        //                                                                             int oldVarTotal = 0;
                        //                                                                             if (_oldSelVarient >
                        //                                                                                 0) {
                        //                                                                               for (int i = 0; i <
                        //                                                                                   _oldSelVarient; i++) {
                        //                                                                                 oldVarTotal =
                        //                                                                                     oldVarTotal +
                        //                                                                                         context
                        //                                                                                             .read<
                        //                                                                                             ExploreProvider>()
                        //                                                                                             .productList[index]
                        //                                                                                             .prVarientList![i]
                        //                                                                                             .images!
                        //                                                                                             .length;
                        //                                                                               }
                        //                                                                             }
                        //                                                                             int p = context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .otherImage!
                        //                                                                                 .length +
                        //                                                                                 1 +
                        //                                                                                 oldVarTotal;
                        //                                                                           }
                        //                                                                         },
                        //                                                                       );
                        //                                                                     }
                        //                                                                     if (available!) {
                        //                                                                       if (CUR_USERID !=
                        //                                                                           null) {
                        //                                                                         if (context
                        //                                                                             .read<
                        //                                                                             ExploreProvider>()
                        //                                                                             .productList[index]
                        //                                                                             .prVarientList![_oldSelVarient]
                        //                                                                             .cartCount! !=
                        //                                                                             '0') {
                        //                                                                           qtyController
                        //                                                                               .text =
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .productList[index]
                        //                                                                               .prVarientList![_oldSelVarient]
                        //                                                                               .cartCount!;
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ProductDetailProvider>()
                        //                                                                               .qtyChange =
                        //                                                                           true;
                        //                                                                         } else {
                        //                                                                           qtyController
                        //                                                                               .text =
                        //                                                                               context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .minOrderQuntity
                        //                                                                                   .toString();
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ProductDetailProvider>()
                        //                                                                               .qtyChange =
                        //                                                                           true;
                        //                                                                         }
                        //                                                                       } else {
                        //                                                                         String qty = (await db
                        //                                                                             .checkCartItemExists(
                        //                                                                             context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .id!,
                        //                                                                             context
                        //                                                                                 .read<
                        //                                                                                 ExploreProvider>()
                        //                                                                                 .productList[index]
                        //                                                                                 .prVarientList![_oldSelVarient]
                        //                                                                                 .id!))!;
                        //                                                                         if (qty ==
                        //                                                                             '0') {
                        //                                                                           qtyController
                        //                                                                               .text =
                        //                                                                               context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .minOrderQuntity
                        //                                                                                   .toString();
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ProductDetailProvider>()
                        //                                                                               .qtyChange =
                        //                                                                           true;
                        //                                                                         } else {
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .productList[index]
                        //                                                                               .prVarientList![_oldSelVarient]
                        //                                                                               .cartCount =
                        //                                                                               qty;
                        //                                                                           qtyController
                        //                                                                               .text =
                        //                                                                               qty;
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ProductDetailProvider>()
                        //                                                                               .qtyChange =
                        //                                                                           true;
                        //                                                                         }
                        //                                                                       }
                        //                                                                     }
                        //                                                                   }
                        //                                                                   if (context
                        //                                                                       .read<
                        //                                                                       CartProvider>()
                        //                                                                       .isProgress ==
                        //                                                                       false) {
                        //                                                                     setStater(() {
                        //                                                                       _selectedIndex[indexAt] =
                        //                                                                           chipIndex;
                        //                                                                     });
                        //                                                                     if (CUR_USERID !=
                        //                                                                         null) {
                        //                                                                       Navigator
                        //                                                                           .pop(
                        //                                                                           context);
                        //                                                                       context
                        //                                                                           .read<
                        //                                                                           ExploreProvider>()
                        //                                                                           .variantIncrement(
                        //                                                                           index,
                        //                                                                           chipIndex,
                        //                                                                           (int
                        //                                                                               .parse(
                        //                                                                               context
                        //                                                                                   .read<
                        //                                                                                   ExploreProvider>()
                        //                                                                                   .productList[index]
                        //                                                                                   .qtyStepSize
                        //                                                                                   .toString())));
                        //                                                                       addNewCart(
                        //                                                                           index,
                        //                                                                           context
                        //                                                                               .read<
                        //                                                                               ExploreProvider>()
                        //                                                                               .productList[index]
                        //                                                                               .prVarientList![chipIndex]
                        //                                                                               .quantity
                        //                                                                               .toString(),
                        //                                                                           1);
                        //                                                                       widget.update;
                        //                                                                     }
                        //                                                                     // else {
                        //                                                                     //   log('Vijay 2');
                        //                                                                     //   context
                        //                                                                     //       .read<
                        //                                                                     //       CartProvider>()
                        //                                                                     //       .addQuantity(
                        //                                                                     //     productList: context
                        //                                                                     //         .read<
                        //                                                                     //         ExploreProvider>()
                        //                                                                     //         .productList[index],
                        //                                                                     //     qty: context
                        //                                                                     //         .read<
                        //                                                                     //         ExploreProvider>()
                        //                                                                     //         .productList[
                        //                                                                     //     index].quantity.toString(),
                        //                                                                     //     from: 1,
                        //                                                                     //     totalLen: context
                        //                                                                     //         .read<
                        //                                                                     //         ExploreProvider>()
                        //                                                                     //         .productList[
                        //                                                                     //     index]
                        //                                                                     //         .itemsCounter!
                        //                                                                     //         .length *
                        //                                                                     //         int.parse(context
                        //                                                                     //             .read<ExploreProvider>()
                        //                                                                     //             .productList[index]
                        //                                                                     //             .qtyStepSize!),
                        //                                                                     //     index:
                        //                                                                     //     index,
                        //                                                                     //     price:
                        //                                                                     //     price,
                        //                                                                     //     selectedPos:
                        //                                                                     //     selectedPos,
                        //                                                                     //     total:
                        //                                                                     //     total,
                        //                                                                     //     pid: context
                        //                                                                     //         .read<
                        //                                                                     //         ExploreProvider>()
                        //                                                                     //         .productList[
                        //                                                                     //     0]
                        //                                                                     //         .id
                        //                                                                     //         .toString(),
                        //                                                                     //     vid: context
                        //                                                                     //         .read<ExploreProvider>()
                        //                                                                     //         .productList[0]
                        //                                                                     //         .prVarientList?[selectedPos]
                        //                                                                     //         .id
                        //                                                                     //         .toString() ??
                        //                                                                     //         '',
                        //                                                                     //     itemCounter: int.parse(context
                        //                                                                     //         .read<
                        //                                                                     //         ExploreProvider>()
                        //                                                                     //         .productList[
                        //                                                                     //     index]
                        //                                                                     //         .qtyStepSize!),
                        //                                                                     //     context:
                        //                                                                     //     context,
                        //                                                                     //     update:
                        //                                                                     //     setStateNow,
                        //                                                                     //   );
                        //                                                                     // }
                        //                                                                   }
                        //                                                                 },
                        //                                                               )
                        //                                                             ],
                        //                                                           ),
                        //                                                         ],
                        //                                                       );
                        //                                                     },
                        //                                                   )
                        //                                                 ],
                        //                                               ),
                        //                                             ),
                        //                                           )
                        //                                               : const SizedBox();
                        //                                         },
                        //                                       ),
                        //                                     ),
                        //                                   )
                        //                                 ],
                        //                               ),
                        //                             ),
                        //                             Divider(
                        //                               height: 2,
                        //                               color: Theme
                        //                                   .of(context)
                        //                                   .colorScheme
                        //                                   .lightWhite,
                        //                             )
                        //                           ],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   );
                        //                 },
                        //               );
                        //             },
                        //           );
                        //         } else {
                        //           addCart(
                        //               index,
                        //               (int.parse(controllerText[index].text) +
                        //                   int.parse(context
                        //                       .read<ExploreProvider>()
                        //                       .productList[index]
                        //                       .qtyStepSize!))
                        //                   .toString(),
                        //               1);
                        //         }
                        //       }
                        //     },
                        //     child: const Padding(
                        //       padding: EdgeInsets.all(8.0),
                        //       child: Icon(
                        //         Icons.shopping_cart_outlined,
                        //         size: 20,
                        //       ),
                        //     ),
                        //   ),
                        // )
                        //     : const SizedBox(),
                      ],
                    ),
                    onTap: () async {
                      Product model =
                          context.read<ExploreProvider>().productList[index];
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => ProductDetail(
                            model: model,
                            secPos: 0,
                            index: index,
                            list: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
    );
  }

  Future<void> addCart(int index, String qty, int from) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.update();
        }

        if (int.parse(qty) <
            context
                .read<ExploreProvider>()
                .productList[index]
                .minOrderQuntity!) {
          qty = context
              .read<ExploreProvider>()
              .productList[index]
              .minOrderQuntity
              .toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: context
              .read<ExploreProvider>()
              .productList[index]
              .prVarientList![context
                  .read<ExploreProvider>()
                  .productList[index]
                  .selVarient!]
              .id,
          QTY: qty
        };

        apiBaseHelper.postAPICall(manageCartApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              var data = getdata['data'];

              String? qty = data['total_quantity'];
              context.read<UserProvider>().setCartCount(data['cart_count']);
              context
                  .read<ExploreProvider>()
                  .productList[index]
                  .prVarientList![context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!]
                  .cartCount = qty.toString();

              var cart = getdata['cart'];
              List<SectionModel> cartList = (cart as List)
                  .map((cart) => SectionModel.fromCart(cart))
                  .toList();
              context.read<CartProvider>().setCartlist(cartList);
            } else {
              setSnackbar(msg!, context);
            }
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.update();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.update();
            }
          },
        );
      }
      else {
        context.read<CartProvider>().setProgress(true);
        widget.update();

        if (singleSellerOrderSystem) {
          if (CurrentSellerID == '' ||
              CurrentSellerID ==
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .seller_id) {
            CurrentSellerID =
                context.read<ExploreProvider>().productList[index].seller_id!;
            if (from == 1) {
              List<Product>? prList = [];
              prList.add(context.read<ExploreProvider>().productList[index]);
              context.read<CartProvider>().addCartItem(
                    SectionModel(
                      qty: qty,
                      productList: prList,
                      varientId: context
                          .read<ExploreProvider>()
                          .productList[index]
                          .prVarientList![context
                              .read<ExploreProvider>()
                              .productList[index]
                              .selVarient!]
                          .id!,
                      id: context.read<ExploreProvider>().productList[index].id,
                      sellerId: context
                          .read<ExploreProvider>()
                          .productList[index]
                          .seller_id,
                    ),
                  );
              db.insertCart(
                context.read<ExploreProvider>().productList[index].id!,
                context
                    .read<ExploreProvider>()
                    .productList[index]
                    .prVarientList![context
                        .read<ExploreProvider>()
                        .productList[index]
                        .selVarient!]
                    .id!,
                qty,
                context,
              );
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                  context);
            } else {
              if (int.parse(qty) >
                  int.parse(context
                      .read<ExploreProvider>()
                      .productList[index]
                      .itemsCounter!
                      .last)) {
                setSnackbar(
                    "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                    context);
              } else {
                context.read<CartProvider>().updateCartItem(
                    context.read<ExploreProvider>().productList[index].id!,
                    qty,
                    context
                        .read<ExploreProvider>()
                        .productList[index]
                        .selVarient!,
                    context
                        .read<ExploreProvider>()
                        .productList[index]
                        .prVarientList![context
                            .read<ExploreProvider>()
                            .productList[index]
                            .selVarient!]
                        .id!);
                db.updateCart(
                  context.read<ExploreProvider>().productList[index].id!,
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .prVarientList![context
                          .read<ExploreProvider>()
                          .productList[index]
                          .selVarient!]
                      .id!,
                  qty,
                );
                setSnackbar(getTranslated(context, 'Cart Update Successfully')!,
                    context);
              }
            }
          } else {
            setSnackbar(
                getTranslated(context, 'only Single Seller Product Allow')!,
                context);
          }
        } else {
          if (from == 1) {
            List<Product>? prList = [];
            prList.add(context.read<ExploreProvider>().productList[index]);
            context.read<CartProvider>().addCartItem(
                  SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: context
                        .read<ExploreProvider>()
                        .productList[index]
                        .prVarientList![context
                            .read<ExploreProvider>()
                            .productList[index]
                            .selVarient!]
                        .id!,
                    id: context.read<ExploreProvider>().productList[index].id,
                    sellerId: context
                        .read<ExploreProvider>()
                        .productList[index]
                        .seller_id,
                  ),
                );
            db.insertCart(
              context.read<ExploreProvider>().productList[index].id!,
              context
                  .read<ExploreProvider>()
                  .productList[index]
                  .prVarientList![context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!]
                  .id!,
              qty,
              context,
            );
            setSnackbar(
                "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                context);
          } else {
            if (int.parse(qty) >
                int.parse(context
                    .read<ExploreProvider>()
                    .productList[index]
                    .itemsCounter!
                    .last)) {
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                  context);
            } else {
              context.read<CartProvider>().updateCartItem(
                  context.read<ExploreProvider>().productList[index].id!,
                  qty,
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!,
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .prVarientList![context
                          .read<ExploreProvider>()
                          .productList[index]
                          .selVarient!]
                      .id!);
              db.updateCart(
                context.read<ExploreProvider>().productList[index].id!,
                context
                    .read<ExploreProvider>()
                    .productList[index]
                    .prVarientList![context
                        .read<ExploreProvider>()
                        .productList[index]
                        .selVarient!]
                    .id!,
                qty,
              );
              setSnackbar(
                  getTranslated(context, 'Cart Update Successfully')!, context);
            }
          }
        }
        context.read<CartProvider>().setProgress(false);
        widget.update();
      }
    }
    else {
      if (mounted) {
        isNetworkAvail = false;
        widget.update();
      }
    }
  }

  Future<void> addNewCart(int index, String qty, int from) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.update();
        }
        if (int.parse(qty) <
            context
                .read<ExploreProvider>()
                .productList[index]
                .minOrderQuntity!) {
          qty = context
              .read<ExploreProvider>()
              .productList[index]
              .minOrderQuntity
              .toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }
        Map<String, String?> parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: context
              .read<ExploreProvider>()
              .productList[index]
              .prVarientList![context
                  .read<ExploreProvider>()
                  .productList[index]
                  .selVarient!]
              .id,
          QTY: qty
        };
        apiBaseHelper.postAPICall(manageCartApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              var data = getdata['data'];

              String? qty = data['total_quantity'];
              context.read<UserProvider>().setCartCount(data['cart_count']);
              context
                  .read<ExploreProvider>()
                  .productList[index]
                  .prVarientList![context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!]
                  .cartCount = qty.toString();

              var cart = getdata['cart'];
              List<SectionModel> cartList = (cart as List)
                  .map((cart) => SectionModel.fromCart(cart))
                  .toList();
              context.read<CartProvider>().setCartlist(cartList);

            } else {

              setSnackbar(msg!, context);
            }

            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.update();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.update();
            }
          },
        );
      }
      else {
        context.read<CartProvider>().setProgress(true);
        widget.update();
        if (singleSellerOrderSystem) {
          if (CurrentSellerID == '' ||
              CurrentSellerID ==
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .seller_id) {
            CurrentSellerID =
                context.read<ExploreProvider>().productList[index].seller_id!;
            if (from == 1) {
              List<Product>? prList = [];
              prList.add(context.read<ExploreProvider>().productList[index]);
              context.read<CartProvider>().addCartItem(
                    SectionModel(
                      qty: qty,
                      productList: prList,
                      varientId: context
                          .read<ExploreProvider>()
                          .productList[index]
                          .prVarientList![context
                              .read<ExploreProvider>()
                              .productList[index]
                              .selVarient!]
                          .id!,
                      id: context.read<ExploreProvider>().productList[index].id,
                      sellerId: context
                          .read<ExploreProvider>()
                          .productList[index]
                          .seller_id,
                    ),
                  );
              db.insertCart(
                context.read<ExploreProvider>().productList[index].id!,
                context
                    .read<ExploreProvider>()
                    .productList[index]
                    .prVarientList![context
                        .read<ExploreProvider>()
                        .productList[index]
                        .selVarient!]
                    .id!,
                qty,
                context,
              );
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                  context);
            } else {
              if (int.parse(qty) >
                  int.parse(context
                      .read<ExploreProvider>()
                      .productList[index]
                      .itemsCounter!
                      .last)) {
                setSnackbar(
                    "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                    context);
              } else {
                context.read<CartProvider>().updateCartItem(
                    context.read<ExploreProvider>().productList[index].id!,
                    qty,
                    context
                        .read<ExploreProvider>()
                        .productList[index]
                        .selVarient!,
                    context
                        .read<ExploreProvider>()
                        .productList[index]
                        .prVarientList![context
                            .read<ExploreProvider>()
                            .productList[index]
                            .selVarient!]
                        .id!);
                db.updateCart(
                  context.read<ExploreProvider>().productList[index].id!,
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .prVarientList![context
                          .read<ExploreProvider>()
                          .productList[index]
                          .selVarient!]
                      .id!,
                  qty,
                );
                setSnackbar(getTranslated(context, 'Cart Update Successfully')!,
                    context);
              }
            }
          } else {
            setSnackbar(
                getTranslated(context, 'only Single Seller Product Allow')!,
                context);
          }
        }
        else {
          if (from == 1) {
            List<Product>? prList = [];
            prList.add(context.read<ExploreProvider>().productList[index]);
            context.read<CartProvider>().addCartItem(
                  SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: context
                        .read<ExploreProvider>()
                        .productList[index]
                        .prVarientList![context
                            .read<ExploreProvider>()
                            .productList[index]
                            .selVarient!]
                        .id!,
                    id: context.read<ExploreProvider>().productList[index].id,
                    sellerId: context
                        .read<ExploreProvider>()
                        .productList[index]
                        .seller_id,
                  ),
                );
            db.insertCart(
              context.read<ExploreProvider>().productList[index].id!,
              context
                  .read<ExploreProvider>()
                  .productList[index]
                  .prVarientList![context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!]
                  .id!,
              qty,
              context,
            );
            setSnackbar(
                "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                context);
          } else {
            if (int.parse(qty) >
                int.parse(context
                    .read<ExploreProvider>()
                    .productList[index]
                    .itemsCounter!
                    .last)) {
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${context.read<ExploreProvider>().productList[index].itemsCounter!.last}",
                  context);
            } else {
              context.read<CartProvider>().updateCartItem(
                  context.read<ExploreProvider>().productList[index].id!,
                  qty,
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .selVarient!,
                  context
                      .read<ExploreProvider>()
                      .productList[index]
                      .prVarientList![context
                          .read<ExploreProvider>()
                          .productList[index]
                          .selVarient!]
                      .id!);
              db.updateCart(
                context.read<ExploreProvider>().productList[index].id!,
                context
                    .read<ExploreProvider>()
                    .productList[index]
                    .prVarientList![context
                        .read<ExploreProvider>()
                        .productList[index]
                        .selVarient!]
                    .id!,
                qty,
              );
              setSnackbar(
                  getTranslated(context, 'Cart Update Successfully')!, context);
            }
          }
        }
        context.read<CartProvider>().setProgress(false);
        widget.update();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.update();
      }
    }
  }

  Future<void> removeCart(int index, List<Product> productList,BuildContext context) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.update();
        }

        int qty;

        qty = (int.parse(controllerText[index].text) -
            int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;
        }

        var parameter = {
          PRODUCT_VARIENT_ID: productList[index]
              .prVarientList![productList[index].selVarient!]
              .id,
          USER_ID: CUR_USERID,
          QTY: qty.toString()
        };

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            var data = getdata['data'];

            String? qty = data['total_quantity'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .cartCount = qty.toString();

            var cart = getdata['cart'];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted) {
            context.read<CartProvider>().setProgress(false);
            widget.update();
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<CartProvider>().setProgress(false);
          widget.update();
        });

      } else {
        context.read<CartProvider>().setProgress(true);
        widget.update();

        int qty;

        qty = (int.parse(controllerText[index].text) -
            int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;
          db.removeCart(
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!,
              productList[index].id!,
              context);
          context.read<CartProvider>().removeCartItem(productList[index]
              .prVarientList![productList[index].selVarient!]
              .id!);
        } else {
          context.read<CartProvider>().updateCartItem(
              productList[index].id!,
              qty.toString(),
              productList[index].selVarient!,
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!);
          db.updateCart(
            productList[index].id!,
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .id!,
            qty.toString(),
          );
        }
        context.read<CartProvider>().setProgress(false);
        widget.update();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.update();
      }
    }
  }

  newRemoveCart(int index, List<Product> productList, Product? model,
      int varietIndex, int qty) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {

        if (mounted) {
          log("ISMOUNTED");
          context.read<CartProvider>().setProgress(true);
          widget.update();
        }

        var parameter = {
          PRODUCT_VARIENT_ID: model!.prVarientList![varietIndex].id,
          USER_ID: CUR_USERID,
          QTY: qty.toString()
        };
        log('PARAMETER===${parameter.keys}');
        log('PARAMETER===${parameter.values}');

        apiBaseHelper.postAPICall(manageCartApi, parameter).then((getdata) {
          bool error = getdata['error'];
          String? msg = getdata['message'];
          if (!error) {
            var data = getdata['data'];

            String? qty = data['total_quantity'];

            context.read<UserProvider>().setCartCount(data['cart_count']);
            model.prVarientList![varietIndex].cartCount = qty.toString();

            var cart = getdata['cart'];
            List<SectionModel> cartList = (cart as List)
                .map((cart) => SectionModel.fromCart(cart))
                .toList();
            context.read<CartProvider>().setCartlist(cartList);
          } else {
            setSnackbar(msg!, context);
          }

          if (mounted) {
            context.read<CartProvider>().setProgress(false);
            widget.update();
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<CartProvider>().setProgress(false);
          widget.update();
        });
      } else {
        context.read<CartProvider>().setProgress(true);
        widget.update();

        int qty;

        qty = (int.parse(controllerText[index].text) -
            int.parse(productList[index].qtyStepSize!));

        if (qty < productList[index].minOrderQuntity!) {
          qty = 0;
          db.removeCart(
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!,
              productList[index].id!,
              context);
          context.read<CartProvider>().removeCartItem(productList[index]
              .prVarientList![productList[index].selVarient!]
              .id!);
        } else {
          context.read<CartProvider>().updateCartItem(
              productList[index].id!,
              qty.toString(),
              productList[index].selVarient!,
              productList[index]
                  .prVarientList![productList[index].selVarient!]
                  .id!);
          db.updateCart(
            productList[index].id!,
            productList[index]
                .prVarientList![productList[index].selVarient!]
                .id!,
            qty.toString(),
          );
        }
        context.read<CartProvider>().setProgress(false);
        widget.update();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.update();
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }
}
