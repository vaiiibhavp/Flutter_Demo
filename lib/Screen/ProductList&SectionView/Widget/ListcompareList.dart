import 'dart:async';
import 'dart:developer';
import 'package:eshop_multivendor/Helper/routes.dart';
import 'package:eshop_multivendor/Provider/explore_provider.dart';
import 'package:eshop_multivendor/Provider/productDetailProvider.dart';
import 'package:eshop_multivendor/Screen/ProductDetail/Widget/commanFiledsofProduct.dart';
import 'package:eshop_multivendor/Screen/ProductList&SectionView/ProductList.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Helper/Color.dart';
import '../../../Helper/Constant.dart';
import '../../../Helper/String.dart';
import '../../../Model/Section_Model.dart';
import '../../../Provider/CartProvider.dart';
import '../../../Provider/Favourite/FavoriteProvider.dart';
import '../../../Provider/UserProvider.dart';
import '../../../widgets/desing.dart';
import '../../Language/languageSettings.dart';
import '../../../widgets/networkAvailablity.dart';
import '../../../widgets/snackbar.dart';
import '../../../widgets/star_rating.dart';
import '../../Dashboard/Dashboard.dart';
import '../../ProductDetail/productDetail.dart';
import 'package:collection/src/iterable_extensions.dart';

class ListIteamListWidget extends StatefulWidget {
  List<Product>? productList;
  final int? index;
  int? length;
  Function setState;

  ListIteamListWidget({
    Key? key,
    this.productList,
    this.index,
    required this.setState,
    this.length,
  }) : super(key: key);

  @override
  State<ListIteamListWidget> createState() => _ListIteamListWidgetState();
}

class _ListIteamListWidgetState extends State<ListIteamListWidget> {
  _removeFav(int index, Product model) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        if (mounted) {
          index == -1
              ? model.isFavLoading = true
              : widget.productList![index].isFavLoading = true;
          widget.setState();
        }

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        apiBaseHelper.postAPICall(removeFavApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              index == -1
                  ? model.isFav = '0'
                  : widget.productList![index].isFav = '0';
              context
                  .read<FavoriteProvider>()
                  .removeFavItem(model.prVarientList![0].id!);
              setSnackbar(msg!, context);
            } else {
              setSnackbar(msg!, context);
            }

            if (mounted) {
              index == -1
                  ? model.isFavLoading = false
                  : widget.productList![index].isFavLoading = false;
              widget.setState();
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
        isNetworkAvail = false;
        widget.setState();
      }
    }
  }

  final List<int?> _selectedIndex = [];
  int _oldSelVarient = 0;
  bool? available, outOfStock;
  int? selectIndex = 0;
  Widget? choiceContainer;

  removeFromCart(int index) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.setState();
        }

        int qty;

        qty = (int.parse(controllerText[index].text) -
            int.parse(widget.productList![index].qtyStepSize!));

        if (qty < widget.productList![index].minOrderQuntity!) {
          qty = 0;
        }

        var parameter = {
          PRODUCT_VARIENT_ID: widget.productList![index]
              .prVarientList![widget.productList![index].selVarient!].id,
          USER_ID: CUR_USERID,
          QTY: qty.toString()
        };

        apiBaseHelper.postAPICall(manageCartApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              var data = getdata['data'];

              String? qty = data['total_quantity'];

              context.read<UserProvider>().setCartCount(data['cart_count']);
              widget
                  .productList![index]
                  .prVarientList![widget.productList![index].selVarient!]
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
              widget.setState();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            context.read<CartProvider>().setProgress(false);
            widget.setState();
          },
        );
      } else {
        context.read<CartProvider>().setProgress(true);
        widget.setState();

        int qty;

        qty = (int.parse(controllerText[index].text) -
            int.parse(widget.productList![index].qtyStepSize!));

        if (qty < widget.productList![index].minOrderQuntity!) {
          qty = 0;
          db.removeCart(
              widget.productList![index]
                  .prVarientList![widget.productList![index].selVarient!].id!,
              widget.productList![index].id!,
              context);
          context.read<CartProvider>().removeCartItem(widget.productList![index]
              .prVarientList![widget.productList![index].selVarient!].id!);
        } else {
          context.read<CartProvider>().updateCartItem(
              widget.productList![index].id!,
              qty.toString(),
              widget.productList![index].selVarient!,
              widget.productList![index]
                  .prVarientList![widget.productList![index].selVarient!].id!);
          db.updateCart(
            widget.productList![index].id!,
            widget.productList![index]
                .prVarientList![widget.productList![index].selVarient!].id!,
            qty.toString(),
          );
        }
        context.read<CartProvider>().setProgress(false);
        widget.setState();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.setState();
      }
    }
  }

  Future<void> addNewCart(int index, String qty, int from) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.setState();
        }

        if (int.parse(qty) <
            widget
                .productList![index]
                .minOrderQuntity!) {
          qty = widget
              .productList![index]
              .minOrderQuntity
              .toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: widget
              .productList![index]
              .prVarientList![widget
              .productList![index]
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
              widget
                  .productList![index]
                  .prVarientList![widget
                  .productList![index]
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
              widget.setState();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.setState();
            }
          },
        );
      }
      else {
        context.read<CartProvider>().setProgress(true);
        widget.setState();

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
        widget.setState();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
      }
    }
  }

  newRemoveCart(int index, List<Product> productList, Product? model,
      int varietIndex, int qty) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.setState();
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
            widget.setState();
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<CartProvider>().setProgress(false);
          widget.setState();
        });
      }
      else {
        context.read<CartProvider>().setProgress(true);
        widget.setState();

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
        widget.setState();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.setState();
      }
    }
  }

  _setFav(int index, Product model) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        if (mounted) {
          index == -1
              ? model.isFavLoading = true
              : widget.productList![index].isFavLoading = true;
          widget.setState();
        }

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        apiBaseHelper.postAPICall(setFavoriteApi, parameter).then(
          (getdata) {
            bool error = getdata['error'];
            String? msg = getdata['message'];
            if (!error) {
              index == -1
                  ? model.isFav = '1'
                  : widget.productList![index].isFav = '1';

              context.read<FavoriteProvider>().addFavItem(model);
              setSnackbar(msg!, context);
            } else {
              setSnackbar(msg!, context);
            }

            if (mounted) {
              index == -1
                  ? model.isFavLoading = false
                  : widget.productList![index].isFavLoading = false;
              widget.setState();
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
        isNetworkAvail = false;
        widget.setState();
      }
    }
  }

  Future<void> addToCart(int index, String qty, int from) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.setState();
        }

        if (int.parse(qty) < widget.productList![index].minOrderQuntity!) {
          qty = widget.productList![index].minOrderQuntity.toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: widget.productList![index]
              .prVarientList![widget.productList![index].selVarient!].id,
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
              widget
                  .productList![index]
                  .prVarientList![widget.productList![index].selVarient!]
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
              widget.setState();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.setState();
            }
          },
        );
      } else {
        context.read<CartProvider>().setProgress(true);
        widget.setState();

        if (singleSellerOrderSystem) {
          if (CurrentSellerID == '' ||
              CurrentSellerID == widget.productList![index].seller_id) {
            CurrentSellerID = widget.productList![index].seller_id!;
            if (from == 1) {
              List<Product>? prList = [];
              prList.add(widget.productList![index]);
              context.read<CartProvider>().addCartItem(
                    SectionModel(
                      qty: qty,
                      productList: prList,
                      varientId: widget
                          .productList![index]
                          .prVarientList![
                              widget.productList![index].selVarient!]
                          .id!,
                      id: widget.productList![index].id,
                      sellerId: widget.productList![index].seller_id,
                    ),
                  );
              db.insertCart(
                widget.productList![index].id!,
                widget.productList![index]
                    .prVarientList![widget.productList![index].selVarient!].id!,
                qty,
                context,
              );
              setSnackbar(getTranslated(context, 'Product Added Successfully')!,
                  context);
            } else {
              if (int.parse(qty) >
                  int.parse(widget.productList![index].itemsCounter!.last)) {
                setSnackbar(
                    "${getTranslated(context, 'MAXQTY')!} ${widget.productList![index].itemsCounter!.last}",
                    context);
              } else {
                context.read<CartProvider>().updateCartItem(
                      widget.productList![index].id!,
                      qty,
                      widget.productList![index].selVarient!,
                      widget
                          .productList![index]
                          .prVarientList![
                              widget.productList![index].selVarient!]
                          .id!,
                    );
                db.updateCart(
                  widget.productList![index].id!,
                  widget
                      .productList![index]
                      .prVarientList![widget.productList![index].selVarient!]
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
            prList.add(widget.productList![index]);
            context.read<CartProvider>().addCartItem(
                  SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: widget
                        .productList![index]
                        .prVarientList![widget.productList![index].selVarient!]
                        .id!,
                    id: widget.productList![index].id,
                    sellerId: widget.productList![index].seller_id,
                  ),
                );
            db.insertCart(
              widget.productList![index].id!,
              widget.productList![index]
                  .prVarientList![widget.productList![index].selVarient!].id!,
              qty,
              context,
            );
            setSnackbar(
                getTranslated(context, 'Product Added Successfully')!, context);
          } else {
            if (int.parse(qty) >
                int.parse(widget.productList![index].itemsCounter!.last)) {
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${widget.productList![index].itemsCounter!.last}",
                  context);
            } else {
              context.read<CartProvider>().updateCartItem(
                    widget.productList![index].id!,
                    qty,
                    widget.productList![index].selVarient!,
                    widget
                        .productList![index]
                        .prVarientList![widget.productList![index].selVarient!]
                        .id!,
                  );
              db.updateCart(
                widget.productList![index].id!,
                widget.productList![index]
                    .prVarientList![widget.productList![index].selVarient!].id!,
                qty,
              );
              setSnackbar(
                  getTranslated(context, 'Cart Update Successfully')!, context);
            }
          }
        }
        context.read<CartProvider>().setProgress(false);
        widget.setState();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.setState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index! < widget.productList!.length) {
      Product model = widget.productList![widget.index!];

      totalProduct = model.total;

      if (controllerText.length < widget.index! + 1) {
        controllerText.add(TextEditingController());
      }

      List att = [], val = [];
      if (model.prVarientList![model.selVarient!].attr_name != null) {
        att = model.prVarientList![model.selVarient!].attr_name!.split(',');
        val = model.prVarientList![model.selVarient!].varient_value!.split(',');
      }

      double price =
          double.parse(model.prVarientList![model.selVarient!].disPrice!);
      if (price == 0) {
        price = double.parse(model.prVarientList![model.selVarient!].price!);
      }

      double off = 0;
      if (model.prVarientList![model.selVarient!].disPrice! != '0') {
        off = (double.parse(model.prVarientList![model.selVarient!].price!) -
                double.parse(model.prVarientList![model.selVarient!].disPrice!))
            .toDouble();
        off = off *
            100 /
            double.parse(model.prVarientList![model.selVarient!].price!);
      }
      return Padding(
          padding: const EdgeInsetsDirectional.only(
              start: 10.0, end: 10.0, top: 5.0),
          child: Selector<CartProvider, List<SectionModel>>(
              builder: (context, data, child) {
                SectionModel? tempId = data.firstWhereOrNull((cp) =>
                    cp.id == model.id &&
                    cp.varientId ==
                        model.prVarientList![model.selVarient!].id!);
                if (tempId != null) {
                  controllerText[widget.index!].text = tempId.qty!.toString();
                } else {
                  if (CUR_USERID != null) {
                    controllerText[widget.index!].text =
                        model.prVarientList![model.selVarient!].cartCount!;
                  } else {
                    controllerText[widget.index!].text = '0';
                  }
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      elevation: 0,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(circularBorderRadius10),
                        child: Stack(
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Hero(
                                  tag:
                                      '$heroTagUniqueString${widget.index}${model.id}',
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(
                                          circularBorderRadius4),
                                      bottomLeft: Radius.circular(
                                          circularBorderRadius4),
                                    ),
                                    child: Stack(
                                      children: [
                                        DesignConfiguration
                                            .getCacheNotworkImage(
                                          boxFit: BoxFit.fitHeight,
                                          context: context,
                                          heightvalue: 125.0,
                                          widthvalue: 110.0,
                                          imageurlString: model.image!,
                                          placeHolderSize: 125,
                                        ),
                                        Positioned.fill(
                                          child: model.availability == '0'
                                              ? Container(
                                                  height: 55,
                                                  color: colors.white70,
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  child: Center(
                                                    child: Text(
                                                      getTranslated(context,
                                                          'OUT_OF_STOCK_LBL')!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                            color: colors.red,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox(),
                                        ),
                                        off != 0
                                            ? Container(
                                                decoration: const BoxDecoration(
                                                  color: colors.red,
                                                ),
                                                margin: const EdgeInsets.all(5),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: Text(
                                                    '${off.round().toStringAsFixed(2)}%',
                                                    style: const TextStyle(
                                                      color: colors.whiteTemp,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: textFontSize9,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox()
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                            top: 2.0,
                                            start: 15.0,
                                          ),
                                          child: Text(
                                            widget.productList![widget.index!]
                                                .name!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
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
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                            top: 2.0,
                                            start: 15.0,
                                          ),
                                          child: Text(
                                            'Brand: ${widget.productList![widget.index!].brandName.toString()}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor,
                                                    fontWeight: FontWeight.w400,
                                                    fontStyle: FontStyle.normal,
                                                    fontSize: textFontSize12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                            start: 15.0,
                                            top: 4.0,
                                          ),
                                          child: Row(
                                            children: [
                                              CUR_USERID != null
                                                  ? Text(
                                                      '₹ ${DesignConfiguration.getPriceFormat(context, price)!}',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .blue,
                                                        fontSize:
                                                            textFontSize14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontStyle:
                                                            FontStyle.normal,
                                                      ),
                                                    )
                                                  : InkWell(
                                                      onTap: () {
                                                        Routes
                                                            .navigateToLoginScreen(
                                                                context);
                                                      },
                                                      child: SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.35,
                                                        child: Text(
                                                          'Login To See Price',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .blue,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'ubuntu',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsetsDirectional
                                                          .only(
                                                    start: 10.0,
                                                    top: 5,
                                                  ),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Text(
                                                        double.parse(widget
                                                                    .productList![
                                                                        widget
                                                                            .index!]
                                                                    .prVarientList![
                                                                        0]
                                                                    .disPrice!) !=
                                                                0
                                                            ? '₹ ${DesignConfiguration.getPriceFormat(context, double.parse(widget.productList![widget.index!].prVarientList![0].price!))}'
                                                            : '',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall!
                                                            .copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .lightBlack,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                              decorationColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .gray,
                                                              decorationStyle:
                                                                  TextDecorationStyle
                                                                      .solid,
                                                              decorationThickness:
                                                                  2,
                                                              letterSpacing: 0,
                                                              fontSize:
                                                                  textFontSize10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              fontStyle:
                                                                  FontStyle
                                                                      .normal,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  top: 5.0, start: 15.0),
                                          child: StarRating(
                                            noOfRatings: widget
                                                .productList![widget.index!]
                                                .noOfRating!,
                                            totalRating: widget
                                                .productList![widget.index!]
                                                .rating!,
                                            needToShowNoOfRatings: true,
                                          ),
                                        ),
                                        widget.productList![widget.index!]
                                                .attributeList!.isNotEmpty
                                            ? Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .white,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 5.0,
                                                          left: 10.0),
                                                  child: ListView.builder(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              0),
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      itemCount: widget
                                                          .productList![
                                                              widget.index!]
                                                          .attributeList!
                                                          .length,
                                                      itemBuilder:
                                                          (context, indexAT) {
                                                        return Text(
                                                          '${widget.productList![widget.index!].attributeList!.first.value!.split(",").first} ${widget.productList![widget.index!].attributeList![indexAT].name!}',
                                                          style:
                                                              const TextStyle(
                                                            fontFamily:
                                                                'ubuntu',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        );
                                                      }),
                                                ),
                                              )
                                            : const SizedBox(),

                                        // controllerText[widget.index!].text !=
                                        //         '0'
                                        //     ? Row(
                                        //         children: [
                                        //           model.availability == '0'
                                        //               ? const SizedBox()
                                        //               : cartBtnList
                                        //                   ? Row(
                                        //                       children: <Widget>[
                                        //                         Row(
                                        //                           children: <Widget>[
                                        //                             InkWell(
                                        //                               child:
                                        //                                   Card(
                                        //                                 shape:
                                        //                                     RoundedRectangleBorder(
                                        //                                   borderRadius:
                                        //                                       BorderRadius.circular(
                                        //                                     circularBorderRadius50,
                                        //                                   ),
                                        //                                 ),
                                        //                                 child:
                                        //                                     const Padding(
                                        //                                   padding:
                                        //                                       EdgeInsets.all(
                                        //                                     8.0,
                                        //                                   ),
                                        //                                   child:
                                        //                                       Icon(
                                        //                                     Icons.remove,
                                        //                                     size:
                                        //                                         15,
                                        //                                   ),
                                        //                                 ),
                                        //                               ),
                                        //                               onTap:
                                        //                                   () {
                                        //                                 if (isProgress ==
                                        //                                         false &&
                                        //                                     (int.parse(controllerText[widget.index!].text) >
                                        //                                         0)) {
                                        //                                   removeFromCart(
                                        //                                       widget.index!);
                                        //                                 }
                                        //                               },
                                        //                             ),
                                        //                             SizedBox(
                                        //                               width: 37,
                                        //                               height:
                                        //                                   20,
                                        //                               child:
                                        //                                   Stack(
                                        //                                 children: [
                                        //                                   TextField(
                                        //                                     textAlign:
                                        //                                         TextAlign.center,
                                        //                                     readOnly:
                                        //                                         true,
                                        //                                     style:
                                        //                                         TextStyle(fontSize: textFontSize12, color: Theme.of(context).colorScheme.fontColor),
                                        //                                     controller:
                                        //                                         controllerText[widget.index!],
                                        //                                     decoration:
                                        //                                         const InputDecoration(
                                        //                                       border: InputBorder.none,
                                        //                                     ),
                                        //                                   ),
                                        //                                   PopupMenuButton<
                                        //                                       String>(
                                        //                                     tooltip:
                                        //                                         '',
                                        //                                     icon:
                                        //                                         const Icon(
                                        //                                       Icons.arrow_drop_down,
                                        //                                       size: 1,
                                        //                                     ),
                                        //                                     onSelected:
                                        //                                         (String value) {
                                        //                                       if (isProgress == false) {
                                        //                                         addToCart(widget.index!, value, 2);
                                        //                                       }
                                        //                                     },
                                        //                                     itemBuilder:
                                        //                                         (BuildContext context) {
                                        //                                       return model.itemsCounter!.map<PopupMenuItem<String>>(
                                        //                                         (String value) {
                                        //                                           return PopupMenuItem(value: value, child: Text(value, style: TextStyle(color: Theme.of(context).colorScheme.fontColor)));
                                        //                                         },
                                        //                                       ).toList();
                                        //                                     },
                                        //                                   ),
                                        //                                 ],
                                        //                               ),
                                        //                             ),
                                        //                             InkWell(
                                        //                               child:
                                        //                                   Card(
                                        //                                 shape:
                                        //                                     RoundedRectangleBorder(
                                        //                                   borderRadius:
                                        //                                       BorderRadius.circular(circularBorderRadius50),
                                        //                                 ),
                                        //                                 child:
                                        //                                     const Padding(
                                        //                                   padding:
                                        //                                       EdgeInsets.all(8.0),
                                        //                                   child:
                                        //                                       Icon(
                                        //                                     Icons.add,
                                        //                                     size:
                                        //                                         15,
                                        //                                   ),
                                        //                                 ),
                                        //                               ),
                                        //                               onTap:
                                        //                                   () {
                                        //                                 if (isProgress ==
                                        //                                     false) {
                                        //                                   addToCart(
                                        //                                     widget.index!,
                                        //                                     (int.parse(controllerText[widget.index!].text) + int.parse(model.qtyStepSize!)).toString(),
                                        //                                     2,
                                        //                                   );
                                        //                                 }
                                        //                               },
                                        //                             )
                                        //                           ],
                                        //                         ),
                                        //                       ],
                                        //                     )
                                        //                   : const SizedBox(),
                                        //         ],
                                        //       )
                                        //     : const SizedBox(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          Product model = widget.productList![widget.index!];
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => ProductDetail(
                                model: model,
                                index: widget.index,
                                secPos: 0,
                                list: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.directional(
                        textDirection: Directionality.of(context),
                        top: 45,
                        end: 6,
                        child: CUR_USERID != null
                            ? Row(
                                children: [
                                  model.availability == '0'
                                      ? const SizedBox()
                                      : cartBtnList
                                          ? Row(
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    InkWell(
                                                      child: Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            circularBorderRadius50,
                                                          ),
                                                        ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                            6.0,
                                                          ),
                                                          child: Icon(
                                                            Icons.remove,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        if (context.read<CartProvider>().isProgress == false) {
                                                          if ((widget
                                                              .productList![
                                                          widget
                                                              .index!]
                                                              .prVarientList
                                                              ?.length ??
                                                              1) >
                                                              1) {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                              context) {
                                                                List<String> selList = widget
                                                                    .productList![
                                                                widget
                                                                    .index!]
                                                                    .prVarientList![
                                                                _oldSelVarient]
                                                                    .attribute_value_ids!
                                                                    .split(',');
                                                                _selectedIndex
                                                                    .clear();
                                                                for (int i = 0;
                                                                i <
                                                                    widget
                                                                        .productList![widget.index!]
                                                                        .attributeList!
                                                                        .length;
                                                                i++) {
                                                                  List<String> sinList = widget
                                                                      .productList![
                                                                  widget
                                                                      .index!]
                                                                      .attributeList![
                                                                  i]
                                                                      .id!
                                                                      .split(
                                                                      ',');

                                                                  for (int j =
                                                                  0;
                                                                  j <
                                                                      sinList
                                                                          .length;
                                                                  j++) {
                                                                    if (selList.contains(
                                                                        sinList[
                                                                        j])) {
                                                                      _selectedIndex
                                                                          .insert(
                                                                          i,
                                                                          j);
                                                                    }
                                                                  }

                                                                  if (_selectedIndex
                                                                      .length ==
                                                                      i) {
                                                                    _selectedIndex
                                                                        .insert(
                                                                        i,
                                                                        null);
                                                                  }
                                                                }
                                                                return StatefulBuilder(
                                                                  builder: (BuildContext
                                                                  context,
                                                                      StateSetter
                                                                      setStater) {
                                                                    return AlertDialog(
                                                                      contentPadding:
                                                                      const EdgeInsets.all(
                                                                          0.0),
                                                                      shape:
                                                                      const RoundedRectangleBorder(
                                                                        borderRadius:
                                                                        BorderRadius.all(
                                                                          Radius.circular(
                                                                              circularBorderRadius5),
                                                                        ),
                                                                      ),
                                                                      content:
                                                                      SizedBox(
                                                                        height:
                                                                        MediaQuery.of(context).size.height * 0.47,
                                                                        child: Stack(
                                                                          children: [
                                                                            Padding(
                                                                              padding: const EdgeInsetsDirectional.only(
                                                                                  start:
                                                                                  10.0,
                                                                                  end:
                                                                                  10.0,
                                                                                  top:
                                                                                  5.0),
                                                                              child:
                                                                              Container(
                                                                                height:
                                                                                MediaQuery.of(context).size.height * 0.47,
                                                                                decoration:
                                                                                BoxDecoration(
                                                                                  color:
                                                                                  Theme.of(context).colorScheme.white,
                                                                                  borderRadius:
                                                                                  BorderRadius.circular(circularBorderRadius10),
                                                                                ),
                                                                                child:
                                                                                Column(
                                                                                  children: [
                                                                                    InkWell(
                                                                                      child: Stack(
                                                                                        children: [
                                                                                          Row(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Flexible(
                                                                                                flex: 1,
                                                                                                child: ClipRRect(
                                                                                                  borderRadius: const BorderRadius.only(
                                                                                                    topLeft: Radius.circular(circularBorderRadius4),
                                                                                                    bottomLeft: Radius.circular(circularBorderRadius4),
                                                                                                  ),
                                                                                                  child: DesignConfiguration.getCacheNotworkImage(
                                                                                                    boxFit: BoxFit.cover,
                                                                                                    context: context,
                                                                                                    heightvalue: 107,
                                                                                                    widthvalue: 107,
                                                                                                    placeHolderSize: 50,
                                                                                                    imageurlString: widget.productList![widget.index!].image!,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  widget.productList![widget.index!].brandName != '' && widget.productList![widget.index!].brandName != null
                                                                                                      ? Padding(
                                                                                                    padding: const EdgeInsets.only(
                                                                                                      left: 15.0,
                                                                                                      right: 15.0,
                                                                                                      top: 16.0,
                                                                                                    ),
                                                                                                    child: Text(
                                                                                                      widget.productList![widget.index!].brandName ?? '',
                                                                                                      style: TextStyle(
                                                                                                        fontWeight: FontWeight.bold,
                                                                                                        color: Theme.of(context).colorScheme.lightBlack,
                                                                                                        fontSize: textFontSize14,
                                                                                                      ),
                                                                                                    ),
                                                                                                  )
                                                                                                      : const SizedBox(),
                                                                                                  GetTitleWidget(
                                                                                                    title: widget.productList![widget.index!].name ?? '',
                                                                                                  ),
                                                                                                  available ?? false || (outOfStock ?? false)
                                                                                                      ? GetPrice(pos: selectIndex, from: true, model: widget.productList![widget.index!])
                                                                                                      : GetPrice(
                                                                                                    pos: widget.productList![widget.index!].selVarient,
                                                                                                    from: false,
                                                                                                    model: widget.productList![widget.index!],
                                                                                                  ),
                                                                                                ],
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                      // onTap: () async {
                                                                                      //   Product model = context.read<ExploreProvider>().productList[index];
                                                                                      //   Navigator.push(
                                                                                      //     context,
                                                                                      //     PageRouteBuilder(
                                                                                      //       pageBuilder: (_, __, ___) => ProductDetail(
                                                                                      //         model: model,
                                                                                      //         secPos: 0,
                                                                                      //         index: index,
                                                                                      //         list: true,
                                                                                      //       ),
                                                                                      //     ),
                                                                                      //   );
                                                                                      // },
                                                                                    ),
                                                                                    Container(
                                                                                      color: Theme.of(context).colorScheme.white,
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                          Container(
                                                                                            height: MediaQuery.of(context).size.height * 0.28,
                                                                                            width: MediaQuery.of(context).size.height * 0.6,
                                                                                            color: Theme.of(context).colorScheme.white,
                                                                                            child: Padding(
                                                                                              padding: const EdgeInsets.only(top: 15.0),
                                                                                              child: ListView.builder(
                                                                                                scrollDirection: Axis.vertical,
                                                                                                physics: const BouncingScrollPhysics(),
                                                                                                itemCount: widget.productList![widget.index!].attributeList!.length,
                                                                                                itemBuilder: (context, indexAt) {
                                                                                                  List<Widget?> chips = [];
                                                                                                  List<String> att = widget.productList![widget.index!].attributeList![indexAt].value!.split(',');
                                                                                                  List<String> attId = widget.productList![widget.index!].attributeList![indexAt].id!.split(',');
                                                                                                  List<String> attSType = widget.productList![widget.index!].attributeList![indexAt].sType!.split(',');
                                                                                                  List<String> attSValue = widget.productList![widget.index!].attributeList![indexAt].sValue!.split(',');
                                                                                                  int? varSelected;
                                                                                                  List<String> wholeAtt = widget.productList![widget.index!].attrIds!.split(',');
                                                                                                  for (int i = 0; i < att.length; i++) {
                                                                                                    Widget itemLabel;
                                                                                                    if (attSType[i] == '1') {
                                                                                                      String clr = (attSValue[i].substring(1));
                                                                                                      String color = '0xff$clr';
                                                                                                      itemLabel = Container(
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
                                                                                                    } else if (attSType[i] == '2') {
                                                                                                      itemLabel = Container(
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
                                                                                                    } else {
                                                                                                      itemLabel = Container(
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
                                                                                                            stops: const [0, 1],
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
                                                                                                            '${att[i]} ${widget.productList![widget.index!].attributeList![indexAt].name}',
                                                                                                            style: TextStyle(
                                                                                                              fontFamily: 'ubuntu',
                                                                                                              color: _selectedIndex[indexAt] == (i) ? Theme.of(context).colorScheme.white : Theme.of(context).colorScheme.fontColor,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      );
                                                                                                    }
                                                                                                    if (_selectedIndex[indexAt] != null && wholeAtt.contains(attId[i])) {
                                                                                                      choiceContainer = Padding(
                                                                                                        padding: const EdgeInsets.only(
                                                                                                          right: 10,
                                                                                                        ),
                                                                                                        child: InkWell(
                                                                                                          onTap: () async {
                                                                                                            if (att.length != 1) {
                                                                                                              if (mounted) {
                                                                                                                setStater(
                                                                                                                      () {
                                                                                                                    widget.productList![widget.index!].selVarient = i;
                                                                                                                    available = false;
                                                                                                                    _selectedIndex[indexAt] = i;
                                                                                                                    List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                    List<bool> check = [];
                                                                                                                    for (int i = 0; i < widget.productList![widget.index!].attributeList!.length; i++) {
                                                                                                                      List<String> attId = widget.productList![widget.index!].attributeList![i].id!.split(',');
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
                                                                                                                    for (int i = 0; i < widget.productList![widget.index!].prVarientList!.length; i++) {
                                                                                                                      sinId = widget.productList![widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                                      if (widget.productList![widget.index!].stockType == '0' || widget.productList![widget.index!].stockType == '1') {
                                                                                                                        if (widget.productList![widget.index!].availability == '1') {
                                                                                                                          available = true;
                                                                                                                          outOfStock = false;
                                                                                                                          _oldSelVarient = varSelected!;
                                                                                                                        } else {
                                                                                                                          available = false;
                                                                                                                          outOfStock = true;
                                                                                                                        }
                                                                                                                      } else if (widget.productList![widget.index!].stockType == '') {
                                                                                                                        available = true;
                                                                                                                        outOfStock = false;
                                                                                                                        _oldSelVarient = varSelected!;
                                                                                                                      } else if (widget.productList![widget.index!].stockType == '2') {
                                                                                                                        if (widget.productList![widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                                    if (widget.productList![widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                      int oldVarTotal = 0;
                                                                                                                      if (_oldSelVarient > 0) {
                                                                                                                        for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                          oldVarTotal = oldVarTotal + widget.productList![widget.index!].prVarientList![i].images!.length;
                                                                                                                        }
                                                                                                                      }
                                                                                                                      int p = widget.productList![widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                                    }
                                                                                                                  },
                                                                                                                );
                                                                                                              }
                                                                                                              if (available!) {
                                                                                                                if (CUR_USERID != null) {
                                                                                                                  if (widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                    qtyController.text = widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  } else {
                                                                                                                    qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  }
                                                                                                                } else {
                                                                                                                  String qty = (await db.checkCartItemExists(widget.productList![widget.index!].id!, widget.productList![widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                                  if (qty == '0') {
                                                                                                                    qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  } else {
                                                                                                                    widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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

                                                                                                  String value = _selectedIndex[indexAt] != null && _selectedIndex[indexAt]! <= att.length ? att[_selectedIndex[indexAt]!] : getTranslated(context, 'VAR_SEL')!.substring(2, getTranslated(context, 'VAR_SEL')!.length);
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
                                                                                                              '${widget.productList![widget.index!].attributeList![indexAt].name!} : $value',
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
                                                                                                                      widget.productList![widget.index!].type == 'digital_product'
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
                                                                                                                              if (widget.productList![widget.index!].prVarientList![chipIndex].quantity >= 1) {
                                                                                                                                setStater(() {
                                                                                                                                  context.read<ExploreProvider>().variantDecrement(widget.index!, chipIndex, (int.parse(widget.productList![widget.index!].qtyStepSize.toString())));
                                                                                                                                });
                                                                                                                              } else {
                                                                                                                                setSnackbar('${getTranslated(context, 'MIN_MSG')}${widget.productList![widget.index!].quantity.toString()}', context);
                                                                                                                              }
                                                                                                                              log('Vijay Minus Quantity');
                                                                                                                              if (widget.productList![widget.index!].prVarientList![chipIndex].quantity != 0) {
                                                                                                                                var finalQuantity = widget.productList![widget.index!].prVarientList![chipIndex].quantity - int.parse(widget.productList![widget.index!].qtyStepSize.toString());
                                                                                                                                setStater(() {
                                                                                                                                  widget.productList![widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                                });
                                                                                                                                newRemoveCart(widget.index!, widget.productList!, widget.productList![widget.index!], chipIndex, widget.productList![widget.index!].prVarientList![chipIndex].quantity);
                                                                                                                              }

                                                                                                                            }
                                                                                                                          }
                                                                                                                        },
                                                                                                                      ),
                                                                                                                      widget.productList![widget.index!].type == 'digital_product'
                                                                                                                          ? const SizedBox()
                                                                                                                          : Padding(
                                                                                                                        padding: const EdgeInsets.only(left: 10),
                                                                                                                        child: SizedBox(
                                                                                                                            width: 20,
                                                                                                                            child: Text(
                                                                                                                              '${widget.productList![widget.index!].prVarientList![chipIndex].quantity}',
                                                                                                                              style:  TextStyle(
                                                                                                                                color: Theme.of(context)
                                                                                                                                    .colorScheme
                                                                                                                                    .fontColor,
                                                                                                                                fontFamily: 'ubuntu',
                                                                                                                              ),
                                                                                                                            )
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      widget.productList![widget.index!].type == 'digital_product'
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
                                                                                                                                  widget.productList![widget.index!].selVarient = chipIndex;
                                                                                                                                  available = false;
                                                                                                                                  _selectedIndex[indexAt] = chipIndex;
                                                                                                                                  List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                                  List<bool> check = [];
                                                                                                                                  for (int i = 0; i < widget.productList![widget.index!].attributeList!.length; i++) {
                                                                                                                                    List<String> attId = widget.productList![widget.index!].attributeList![i].id!.split(',');
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
                                                                                                                                  for (int i = 0; i < widget.productList![widget.index!].prVarientList!.length; i++) {
                                                                                                                                    sinId = widget.productList![widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                                                    if (widget.productList![widget.index!].stockType == '0' || widget.productList![widget.index!].stockType == '1') {
                                                                                                                                      if (widget.productList![widget.index!].availability == '1') {
                                                                                                                                        available = true;
                                                                                                                                        outOfStock = false;
                                                                                                                                        _oldSelVarient = varSelected!;
                                                                                                                                      } else {
                                                                                                                                        available = false;
                                                                                                                                        outOfStock = true;
                                                                                                                                      }
                                                                                                                                    } else if (widget.productList![widget.index!].stockType == '') {
                                                                                                                                      available = true;
                                                                                                                                      outOfStock = false;
                                                                                                                                      _oldSelVarient = varSelected!;
                                                                                                                                    } else if (widget.productList![widget.index!].stockType == '2') {
                                                                                                                                      if (widget.productList![widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                                                  if (widget.productList![widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                                    int oldVarTotal = 0;
                                                                                                                                    if (_oldSelVarient > 0) {
                                                                                                                                      for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                                        oldVarTotal = oldVarTotal + widget.productList![widget.index!].prVarientList![i].images!.length;
                                                                                                                                      }
                                                                                                                                    }
                                                                                                                                    int p = widget.productList![widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                                                  }
                                                                                                                                },
                                                                                                                              );
                                                                                                                            }
                                                                                                                            if (available!) {
                                                                                                                              if (CUR_USERID != null) {
                                                                                                                                if (widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                                  qtyController.text = widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                                } else {
                                                                                                                                  qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                                }
                                                                                                                              } else {
                                                                                                                                String qty = (await db.checkCartItemExists(widget.productList![widget.index!].id!, widget.productList![widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                                                if (qty == '0') {
                                                                                                                                  qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                                  context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                                } else {
                                                                                                                                  widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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
                                                                                                                              var finalQuantity = widget.productList![widget.index!].prVarientList![chipIndex].quantity + int.parse(widget.productList![widget.index!].qtyStepSize.toString());
                                                                                                                              setStater(() {
                                                                                                                                widget.productList![widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                              });
                                                                                                                              // context.read<ExploreProvider>().variantIncrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                              addNewCart(widget.index!, widget.productList![widget.index!].prVarientList![chipIndex].quantity.toString(), 2);
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
                                                                                      color: Theme.of(context).colorScheme.lightWhite,
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
                                                            removeFromCart(
                                                                widget.index!);
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
                                                            textAlign: TextAlign
                                                                .center,
                                                            readOnly: true,
                                                            style: TextStyle(
                                                                fontSize:
                                                                    textFontSize12,
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .fontColor),
                                                            controller:
                                                                controllerText[
                                                                    widget
                                                                        .index!],
                                                            decoration:
                                                                const InputDecoration(
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                            ),
                                                          ),
                                                          PopupMenuButton<
                                                              String>(
                                                            tooltip: '',
                                                            icon: const Icon(
                                                              Icons
                                                                  .arrow_drop_down,
                                                              size: 1,
                                                            ),
                                                            onSelected:
                                                                (String value) {
                                                              if (isProgress ==
                                                                  false) {
                                                                addToCart(
                                                                    widget
                                                                        .index!,
                                                                    value,
                                                                    2);
                                                              }
                                                            },
                                                            itemBuilder:
                                                                (BuildContext
                                                                    context) {
                                                              return model
                                                                  .itemsCounter!
                                                                  .map<
                                                                      PopupMenuItem<
                                                                          String>>(
                                                                (String value) {
                                                                  return PopupMenuItem(
                                                                      value:
                                                                          value,
                                                                      child: Text(
                                                                          value,
                                                                          style:
                                                                              TextStyle(color: Theme.of(context).colorScheme.fontColor)));
                                                                },
                                                              ).toList();
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    InkWell(
                                                      child: Card(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  circularBorderRadius50),
                                                        ),
                                                        child: const Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  6.0),
                                                          child: Icon(
                                                            Icons.add,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                      onTap: () {
                                                        if (isProgress ==
                                                            false) {
                                                          if ((widget
                                                                      .productList![
                                                                          widget
                                                                              .index!]
                                                                      .prVarientList
                                                                      ?.length ??
                                                                  1) >
                                                              1) {
                                                            showDialog(
                                                              context: context,
                                                              builder:
                                                                  (BuildContext
                                                                      context) {
                                                                List<String> selList = widget
                                                                    .productList![
                                                                        widget
                                                                            .index!]
                                                                    .prVarientList![
                                                                        _oldSelVarient]
                                                                    .attribute_value_ids!
                                                                    .split(',');
                                                                _selectedIndex
                                                                    .clear();
                                                                for (int i = 0;
                                                                    i <
                                                                        widget
                                                                            .productList![widget.index!]
                                                                            .attributeList!
                                                                            .length;
                                                                    i++) {
                                                                  List<String> sinList = widget
                                                                      .productList![
                                                                          widget
                                                                              .index!]
                                                                      .attributeList![
                                                                          i]
                                                                      .id!
                                                                      .split(
                                                                          ',');

                                                                  for (int j =
                                                                          0;
                                                                      j <
                                                                          sinList
                                                                              .length;
                                                                      j++) {
                                                                    if (selList.contains(
                                                                        sinList[
                                                                            j])) {
                                                                      _selectedIndex
                                                                          .insert(
                                                                              i,
                                                                              j);
                                                                    }
                                                                  }

                                                                  if (_selectedIndex
                                                                          .length ==
                                                                      i) {
                                                                    _selectedIndex
                                                                        .insert(
                                                                            i,
                                                                            null);
                                                                  }
                                                                }
                                                                return StatefulBuilder(
                                                                  builder: (BuildContext
                                                                          context,
                                                                      StateSetter
                                                                          setStater) {
                                                                    return AlertDialog(
                                                                      contentPadding:
                                                                          const EdgeInsets.all(
                                                                              0.0),
                                                                      shape:
                                                                          const RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.all(
                                                                          Radius.circular(
                                                                              circularBorderRadius5),
                                                                        ),
                                                                      ),
                                                                      content:
                                                                          SizedBox(
                                                                            height:
                                                                            MediaQuery.of(context).size.height * 0.47,
                                                                            child: Stack(
                                                                              children: [
                                                                                Padding(
                                                                        padding: const EdgeInsetsDirectional.only(
                                                                                  start:
                                                                                      10.0,
                                                                                  end:
                                                                                      10.0,
                                                                                  top:
                                                                                      5.0),
                                                                        child:
                                                                                  Container(
                                                                                height:
                                                                                    MediaQuery.of(context).size.height * 0.47,
                                                                                decoration:
                                                                                    BoxDecoration(
                                                                                  color:
                                                                                      Theme.of(context).colorScheme.white,
                                                                                  borderRadius:
                                                                                      BorderRadius.circular(circularBorderRadius10),
                                                                                ),
                                                                                child:
                                                                                    Column(
                                                                                  children: [
                                                                                    InkWell(
                                                                                      child: Stack(
                                                                                        children: [
                                                                                          Row(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Flexible(
                                                                                                flex: 1,
                                                                                                child: ClipRRect(
                                                                                                  borderRadius: const BorderRadius.only(
                                                                                                    topLeft: Radius.circular(circularBorderRadius4),
                                                                                                    bottomLeft: Radius.circular(circularBorderRadius4),
                                                                                                  ),
                                                                                                  child: DesignConfiguration.getCacheNotworkImage(
                                                                                                    boxFit: BoxFit.cover,
                                                                                                    context: context,
                                                                                                    heightvalue: 107,
                                                                                                    widthvalue: 107,
                                                                                                    placeHolderSize: 50,
                                                                                                    imageurlString: widget.productList![widget.index!].image!,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  widget.productList![widget.index!].brandName != '' && widget.productList![widget.index!].brandName != null
                                                                                                      ? Padding(
                                                                                                          padding: const EdgeInsets.only(
                                                                                                            left: 15.0,
                                                                                                            right: 15.0,
                                                                                                            top: 16.0,
                                                                                                          ),
                                                                                                          child: Text(
                                                                                                            widget.productList![widget.index!].brandName ?? '',
                                                                                                            style: TextStyle(
                                                                                                              fontWeight: FontWeight.bold,
                                                                                                              color: Theme.of(context).colorScheme.lightBlack,
                                                                                                              fontSize: textFontSize14,
                                                                                                            ),
                                                                                                          ),
                                                                                                        )
                                                                                                      : const SizedBox(),
                                                                                                  GetTitleWidget(
                                                                                                    title: widget.productList![widget.index!].name ?? '',
                                                                                                  ),
                                                                                                  available ?? false || (outOfStock ?? false)
                                                                                                      ? GetPrice(pos: selectIndex, from: true, model: widget.productList![widget.index!])
                                                                                                      : GetPrice(
                                                                                                          pos: widget.productList![widget.index!].selVarient,
                                                                                                          from: false,
                                                                                                          model: widget.productList![widget.index!],
                                                                                                        ),
                                                                                                ],
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                      // onTap: () async {
                                                                                      //   Product model = context.read<ExploreProvider>().productList[index];
                                                                                      //   Navigator.push(
                                                                                      //     context,
                                                                                      //     PageRouteBuilder(
                                                                                      //       pageBuilder: (_, __, ___) => ProductDetail(
                                                                                      //         model: model,
                                                                                      //         secPos: 0,
                                                                                      //         index: index,
                                                                                      //         list: true,
                                                                                      //       ),
                                                                                      //     ),
                                                                                      //   );
                                                                                      // },
                                                                                    ),
                                                                                    Container(
                                                                                      color: Theme.of(context).colorScheme.white,
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        mainAxisSize: MainAxisSize.min,
                                                                                        children: [
                                                                                          Container(
                                                                                            height: MediaQuery.of(context).size.height * 0.28,
                                                                                            width: MediaQuery.of(context).size.height * 0.6,
                                                                                            color: Theme.of(context).colorScheme.white,
                                                                                            child: Padding(
                                                                                              padding: const EdgeInsets.only(top: 15.0),
                                                                                              child: ListView.builder(
                                                                                                scrollDirection: Axis.vertical,
                                                                                                physics: const BouncingScrollPhysics(),
                                                                                                itemCount: widget.productList![widget.index!].attributeList!.length,
                                                                                                itemBuilder: (context, indexAt) {
                                                                                                  List<Widget?> chips = [];
                                                                                                  List<String> att = widget.productList![widget.index!].attributeList![indexAt].value!.split(',');
                                                                                                  List<String> attId = widget.productList![widget.index!].attributeList![indexAt].id!.split(',');
                                                                                                  List<String> attSType = widget.productList![widget.index!].attributeList![indexAt].sType!.split(',');
                                                                                                  List<String> attSValue = widget.productList![widget.index!].attributeList![indexAt].sValue!.split(',');
                                                                                                  int? varSelected;
                                                                                                  List<String> wholeAtt = widget.productList![widget.index!].attrIds!.split(',');
                                                                                                  for (int i = 0; i < att.length; i++) {
                                                                                                    Widget itemLabel;
                                                                                                    if (attSType[i] == '1') {
                                                                                                      String clr = (attSValue[i].substring(1));
                                                                                                      String color = '0xff$clr';
                                                                                                      itemLabel = Container(
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
                                                                                                    } else if (attSType[i] == '2') {
                                                                                                      itemLabel = Container(
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
                                                                                                    } else {
                                                                                                      itemLabel = Container(
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
                                                                                                            stops: const [0, 1],
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
                                                                                                            '${att[i]} ${widget.productList![widget.index!].attributeList![indexAt].name}',
                                                                                                            style: TextStyle(
                                                                                                              fontFamily: 'ubuntu',
                                                                                                              color: _selectedIndex[indexAt] == (i) ? Theme.of(context).colorScheme.white : Theme.of(context).colorScheme.fontColor,
                                                                                                            ),
                                                                                                          ),
                                                                                                        ),
                                                                                                      );
                                                                                                    }
                                                                                                    if (_selectedIndex[indexAt] != null && wholeAtt.contains(attId[i])) {
                                                                                                      choiceContainer = Padding(
                                                                                                        padding: const EdgeInsets.only(
                                                                                                          right: 10,
                                                                                                        ),
                                                                                                        child: InkWell(
                                                                                                          onTap: () async {
                                                                                                            if (att.length != 1) {
                                                                                                              if (mounted) {
                                                                                                                setStater(
                                                                                                                  () {
                                                                                                                    widget.productList![widget.index!].selVarient = i;
                                                                                                                    available = false;
                                                                                                                    _selectedIndex[indexAt] = i;
                                                                                                                    List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                    List<bool> check = [];
                                                                                                                    for (int i = 0; i < widget.productList![widget.index!].attributeList!.length; i++) {
                                                                                                                      List<String> attId = widget.productList![widget.index!].attributeList![i].id!.split(',');
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
                                                                                                                    for (int i = 0; i < widget.productList![widget.index!].prVarientList!.length; i++) {
                                                                                                                      sinId = widget.productList![widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                                      if (widget.productList![widget.index!].stockType == '0' || widget.productList![widget.index!].stockType == '1') {
                                                                                                                        if (widget.productList![widget.index!].availability == '1') {
                                                                                                                          available = true;
                                                                                                                          outOfStock = false;
                                                                                                                          _oldSelVarient = varSelected!;
                                                                                                                        } else {
                                                                                                                          available = false;
                                                                                                                          outOfStock = true;
                                                                                                                        }
                                                                                                                      } else if (widget.productList![widget.index!].stockType == '') {
                                                                                                                        available = true;
                                                                                                                        outOfStock = false;
                                                                                                                        _oldSelVarient = varSelected!;
                                                                                                                      } else if (widget.productList![widget.index!].stockType == '2') {
                                                                                                                        if (widget.productList![widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                                    if (widget.productList![widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                      int oldVarTotal = 0;
                                                                                                                      if (_oldSelVarient > 0) {
                                                                                                                        for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                          oldVarTotal = oldVarTotal + widget.productList![widget.index!].prVarientList![i].images!.length;
                                                                                                                        }
                                                                                                                      }
                                                                                                                      int p = widget.productList![widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                                    }
                                                                                                                  },
                                                                                                                );
                                                                                                              }
                                                                                                              if (available!) {
                                                                                                                if (CUR_USERID != null) {
                                                                                                                  if (widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                    qtyController.text = widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  } else {
                                                                                                                    qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  }
                                                                                                                } else {
                                                                                                                  String qty = (await db.checkCartItemExists(widget.productList![widget.index!].id!, widget.productList![widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                                  if (qty == '0') {
                                                                                                                    qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  } else {
                                                                                                                    widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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

                                                                                                  String value = _selectedIndex[indexAt] != null && _selectedIndex[indexAt]! <= att.length ? att[_selectedIndex[indexAt]!] : getTranslated(context, 'VAR_SEL')!.substring(2, getTranslated(context, 'VAR_SEL')!.length);
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
                                                                                                                    '${widget.productList![widget.index!].attributeList![indexAt].name!} : $value',
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
                                                                                                                            widget.productList![widget.index!].type == 'digital_product'
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
                                                                                                                                      log("ABC======${widget.productList![widget.index!]
                                                                                                                                          .name}");
                                                                                                                                      log("ID PRODUCT======${widget.productList![widget.index!]
                                                                                                                                          .id}");
                                                                                                                                      if (context.read<CartProvider>().isProgress == false) {
                                                                                                                                        if (CUR_USERID != null) {
                                                                                                                                          if (widget.productList![widget.index!].prVarientList![chipIndex].quantity >= 1) {
                                                                                                                                            setStater(() {
                                                                                                                                              context.read<ExploreProvider>().variantDecrement(widget.index!, chipIndex, (int.parse(widget.productList![widget.index!].qtyStepSize.toString())));
                                                                                                                                            });
                                                                                                                                          } else {
                                                                                                                                            setSnackbar('${getTranslated(context, 'MIN_MSG')}${widget.productList![widget.index!].quantity.toString()}', context);
                                                                                                                                          }

                                                                                                                                          if (widget.productList![widget.index!].prVarientList![chipIndex].quantity != 0) {
                                                                                                                                            var finalQuantity = widget.productList![widget.index!].prVarientList![chipIndex].quantity - int.parse(widget.productList![widget.index!].qtyStepSize.toString());
                                                                                                                                            setStater(() {
                                                                                                                                              widget.productList![widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                                            });
                                                                                                                                            log('Vijay Minus ABC Quantity====${ widget.productList![widget.index!].prVarientList![chipIndex].quantity}');
                                                                                                                                            newRemoveCart(widget.index!, widget.productList!, model, chipIndex, widget.productList![widget.index!].prVarientList![chipIndex].quantity);
                                                                                                                                          }

                                                                                                                                          // context.read<CartProvider>().addQuantity(
                                                                                                                                          //       productList: widget
                                                                                                                                          //           .productList![widget.index!],
                                                                                                                                          //       qty: widget
                                                                                                                                          //           .productList![widget.index!].prVarientList![chipIndex].quantity.toString(),
                                                                                                                                          //       from: 1,
                                                                                                                                          //       totalLen: widget
                                                                                                                                          //           .productList![widget.index!].itemsCounter!.length * int.parse(widget
                                                                                                                                          //           .productList![widget.index!].qtyStepSize!),
                                                                                                                                          //       index: widget.index!,
                                                                                                                                          //       price: price,
                                                                                                                                          //       selectedPos: selectedPos,
                                                                                                                                          //       total: total,
                                                                                                                                          //       pid: widget
                                                                                                                                          //           .productList![widget.index!].id.toString(),
                                                                                                                                          //       vid: widget
                                                                                                                                          //           .productList![widget.index!].prVarientList?[chipIndex].id.toString() ?? '',
                                                                                                                                          //       itemCounter: 0,
                                                                                                                                          //       context: context,
                                                                                                                                          //       update: setStateNow,
                                                                                                                                          //     );
                                                                                                                                        }
                                                                                                                                      }
                                                                                                                                    },
                                                                                                                                  ),
                                                                                                                            widget.productList![widget.index!].type == 'digital_product'
                                                                                                                                ? const SizedBox()
                                                                                                                                : Padding(
                                                                                                                                    padding: const EdgeInsets.only(left: 10),
                                                                                                                                    child: SizedBox(
                                                                                                                                        width: 20,
                                                                                                                                        child: Text(
                                                                                                                                          '${widget.productList![widget.index!].prVarientList![chipIndex].quantity}',
                                                                                                                                          style:  TextStyle(
                                                                                                                                            color: Theme.of(context)
                                                                                                                                                .colorScheme
                                                                                                                                                .fontColor,
                                                                                                                                            fontFamily: 'ubuntu',
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
                                                                                                                            widget.productList![widget.index!].type == 'digital_product'
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
                                                                                                                                              widget.productList![widget.index!].selVarient = chipIndex;
                                                                                                                                              available = false;
                                                                                                                                              _selectedIndex[indexAt] = chipIndex;
                                                                                                                                              List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                                              List<bool> check = [];
                                                                                                                                              for (int i = 0; i < widget.productList![widget.index!].attributeList!.length; i++) {
                                                                                                                                                List<String> attId = widget.productList![widget.index!].attributeList![i].id!.split(',');
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
                                                                                                                                              for (int i = 0; i < widget.productList![widget.index!].prVarientList!.length; i++) {
                                                                                                                                                sinId = widget.productList![widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                                                                if (widget.productList![widget.index!].stockType == '0' || widget.productList![widget.index!].stockType == '1') {
                                                                                                                                                  if (widget.productList![widget.index!].availability == '1') {
                                                                                                                                                    available = true;
                                                                                                                                                    outOfStock = false;
                                                                                                                                                    _oldSelVarient = varSelected!;
                                                                                                                                                  } else {
                                                                                                                                                    available = false;
                                                                                                                                                    outOfStock = true;
                                                                                                                                                  }
                                                                                                                                                } else if (widget.productList![widget.index!].stockType == '') {
                                                                                                                                                  available = true;
                                                                                                                                                  outOfStock = false;
                                                                                                                                                  _oldSelVarient = varSelected!;
                                                                                                                                                } else if (widget.productList![widget.index!].stockType == '2') {
                                                                                                                                                  if (widget.productList![widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                                                              if (widget.productList![widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                                                int oldVarTotal = 0;
                                                                                                                                                if (_oldSelVarient > 0) {
                                                                                                                                                  for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                                                    oldVarTotal = oldVarTotal + widget.productList![widget.index!].prVarientList![i].images!.length;
                                                                                                                                                  }
                                                                                                                                                }
                                                                                                                                                int p = widget.productList![widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                                                              }
                                                                                                                                            },
                                                                                                                                          );
                                                                                                                                        }
                                                                                                                                        if (available!) {
                                                                                                                                          if (CUR_USERID != null) {
                                                                                                                                            if (widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                                              qtyController.text = widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                                            } else {
                                                                                                                                              qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                                            }
                                                                                                                                          } else {
                                                                                                                                            String qty = (await db.checkCartItemExists(widget.productList![widget.index!].id!, widget.productList![widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                                                            if (qty == '0') {
                                                                                                                                              qtyController.text = widget.productList![widget.index!].minOrderQuntity.toString();
                                                                                                                                              context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                                            } else {
                                                                                                                                              widget.productList![widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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
                                                                                                                                          var finalQuantity = widget.productList![widget.index!].prVarientList![chipIndex].quantity + int.parse(widget.productList![widget.index!].qtyStepSize.toString());
                                                                                                                                          setStater(() {
                                                                                                                                            widget.productList![widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                                          });
                                                                                                                                          // context.read<ExploreProvider>().variantIncrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                                          addNewCart(widget.index!, widget.productList![widget.index!].prVarientList![chipIndex].quantity.toString(), 2);
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
                                                                                      color: Theme.of(context).colorScheme.lightWhite,
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
                                                            addToCart(
                                                              widget.index!,
                                                              (int.parse(controllerText[widget
                                                                              .index!]
                                                                          .text) +
                                                                      int.parse(
                                                                          model
                                                                              .qtyStepSize!))
                                                                  .toString(),
                                                              2,
                                                            );
                                                          }
                                                        }
                                                      },
                                                    )
                                                  ],
                                                ),
                                              ],
                                            )
                                          : const SizedBox(),
                                ],
                              )
                            : SizedBox()
                        // InkWell(
                        //   onTap: () {
                        //     if (isProgress == false) {
                        //       addToCart(
                        //         widget.index!,
                        //         (int.parse(controllerText[widget.index!]
                        //                     .text) +
                        //                 int.parse(model.qtyStepSize!))
                        //             .toString(),
                        //         1,
                        //       );
                        //     }
                        //   },
                        //   child: const Padding(
                        //     padding: EdgeInsets.all(8.0),
                        //     child: Icon(
                        //       Icons.shopping_cart_outlined,
                        //       size: 20,
                        //     ),
                        //   ),
                        // ),
                        ),
                    Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: 4,
                      end: 4,
                      child: model.isFavLoading!
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: colors.primary,
                                  strokeWidth: 0.7,
                                ),
                              ),
                            )
                          : Selector<FavoriteProvider, List<String?>>(
                              builder: (context, data, child) {
                                return InkWell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      !data.contains(model.id)
                                          ? Icons.favorite_border
                                          : Icons.favorite,
                                      size: 20,
                                    ),
                                  ),
                                  onTap: () {
                                    if (CUR_USERID != null) {
                                      !data.contains(model.id)
                                          ? _setFav(-1, model)
                                          : _removeFav(-1, model);
                                    } else {
                                      if (!data.contains(model.id)) {
                                        model.isFavLoading = true;
                                        model.isFav = '1';
                                        context
                                            .read<FavoriteProvider>()
                                            .addFavItem(model);
                                        db.addAndRemoveFav(model.id!, true);
                                        model.isFavLoading = false;
                                        setSnackbar(
                                            getTranslated(
                                                context, 'Added to favorite')!,
                                            context);
                                      } else {
                                        model.isFavLoading = true;
                                        model.isFav = '0';
                                        context
                                            .read<FavoriteProvider>()
                                            .removeFavItem(
                                                model.prVarientList![0].id!);
                                        db.addAndRemoveFav(model.id!, false);
                                        model.isFavLoading = false;
                                        setSnackbar(
                                            getTranslated(context,
                                                'Removed from favorite')!,
                                            context);
                                      }
                                      widget.setState();
                                    }
                                  },
                                );
                              },
                              selector: (_, provider) => provider.favIdList,
                            ),
                    ),
                  ],
                );
              },
              selector: (_, provider) => provider.cartList));
    } else {
      return const SizedBox();
    }
  }
}
