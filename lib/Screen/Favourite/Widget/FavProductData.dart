import 'dart:async';
import 'dart:developer';
import 'package:eshop_multivendor/Helper/routes.dart';
import 'package:eshop_multivendor/Provider/explore_provider.dart';
import 'package:eshop_multivendor/Provider/productDetailProvider.dart';
import 'package:eshop_multivendor/Screen/ProductDetail/Widget/commanFiledsofProduct.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Helper/Color.dart';
import '../../../Helper/Constant.dart';
import '../../../Helper/String.dart';
import '../../SQLiteData/SqliteData.dart';
import '../../../Model/Section_Model.dart';
import '../../../Provider/CartProvider.dart';
import '../../../Provider/Favourite/FavoriteProvider.dart';
import '../../../Provider/Favourite/UpdateFavProvider.dart';
import '../../../Provider/UserProvider.dart';
import '../../../widgets/desing.dart';
import '../../Language/languageSettings.dart';
import '../../../widgets/networkAvailablity.dart';
import '../../../widgets/snackbar.dart';
import '../../../widgets/star_rating.dart';
import '../../ProductDetail/productDetail.dart';
import 'package:collection/src/iterable_extensions.dart';

class FavProductData extends StatefulWidget {
  int? index;
  List<Product> favList = [];
  Function updateNow;
  TextEditingController? controller;

  FavProductData({
    Key? key,
    required this.index,
    this.controller,
    required this.updateNow,
    required this.favList,
  }) : super(key: key);

  @override
  State<FavProductData> createState() => _FavProductDataState();
}

class _FavProductDataState extends State<FavProductData> {
  var db = DatabaseHelper();

  int selectedPos = 0;
  int _oldSelVarient = 0;
  bool? available, outOfStock;
  int? selectIndex = 0;
  // final List<TextEditingController> controllerText = [];
  final List<int?> _selectedIndex = [];
  Widget? choiceContainer;
  bool isProgress = false;

  newRemoveCart(int index, List<Product> productList, Product? model,
      int varietIndex, int qty) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.updateNow();
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
          }
          else {

            setSnackbar(msg!, context);
          }

          if (mounted) {
            context.read<CartProvider>().setProgress(false);
            widget.updateNow();
          }
        }, onError: (error) {
          log("ERROR QUANTITY======${error.toString()}");
          setSnackbar(error.toString(), context);
          context.read<CartProvider>().setProgress(false);
          widget.updateNow();
        });
      }
      else {
        context.read<CartProvider>().setProgress(true);
        widget.updateNow();

        int qty;

        qty = (int.parse(widget.controller?.text??'') -
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
        widget.updateNow();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
      }
    }
  }

  removeCart(int index, List<Product> productList) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.updateNow();
        }

        int qty;

        qty = (int.parse(widget.controller?.text??'') -
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
            widget.updateNow();
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
          context.read<CartProvider>().setProgress(false);
          widget.updateNow();
        });
      } else {
        context.read<CartProvider>().setProgress(true);
        widget.updateNow();

        int qty;

        qty = (int.parse(widget.controller?.text??'') -
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
        widget.updateNow();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.updateNow();
      }
    }
  }

  Future<void> addNewCart(int index, String qty, int from) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.updateNow();
        }

        if (int.parse(qty) <
            widget.favList[index]
                .minOrderQuntity!) {
          qty = widget.favList[index]
              .minOrderQuntity
              .toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: widget.favList[index]
              .prVarientList![widget.favList[index]
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
              widget.favList[index]
                  .prVarientList![widget.favList[index]
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
              widget.updateNow();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.updateNow();
            }
          },
        );
      } else {
        context.read<CartProvider>().setProgress(true);
        widget.updateNow();

        if (singleSellerOrderSystem) {
          if (CurrentSellerID == '' ||
              CurrentSellerID ==
                  widget.favList[index]
                      .seller_id) {
            CurrentSellerID =
            widget.favList[index].seller_id!;
            if (from == 1) {
              List<Product>? prList = [];
              prList.add(widget.favList[index]);
              context.read<CartProvider>().addCartItem(
                    SectionModel(
                      qty: qty,
                      productList: prList,
                      varientId: widget.favList[index]
                          .prVarientList![widget.favList[index]
                              .selVarient!]
                          .id!,
                      id: widget.favList[index].id,
                      sellerId: widget.favList[index]
                          .seller_id,
                    ),
                  );
              db.insertCart(
                widget.favList[index].id!,
                widget.favList[index]
                    .prVarientList![widget.favList[index]
                        .selVarient!]
                    .id!,
                qty,
                context,
              );
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                  context);
            } else {
              if (int.parse(qty) >
                  int.parse(widget.favList[index]
                      .itemsCounter!
                      .last)) {
                setSnackbar(
                    "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                    context);
              } else {
                context.read<CartProvider>().updateCartItem(
                    widget.favList[index].id!,
                    qty,
                    widget.favList[index]
                        .selVarient!,
                    widget.favList[index]
                        .prVarientList![widget.favList[index]
                            .selVarient!]
                        .id!);
                db.updateCart(
                  widget.favList[index].id!,
                  widget.favList[index]
                      .prVarientList![widget.favList[index]
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
            prList.add(widget.favList[index]);
            context.read<CartProvider>().addCartItem(
                  SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: widget.favList[index]
                        .prVarientList![widget.favList[index]
                            .selVarient!]
                        .id!,
                    id: widget.favList[index].id,
                    sellerId: widget.favList[index]
                        .seller_id,
                  ),
                );
            db.insertCart(
              widget.favList[index].id!,
              widget.favList[index]
                  .prVarientList![widget.favList[index]
                      .selVarient!]
                  .id!,
              qty,
              context,
            );
            setSnackbar(
                "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                context);
          } else {
            if (int.parse(qty) >
                int.parse(widget.favList[index]
                    .itemsCounter!
                    .last)) {
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                  context);
            } else {
              context.read<CartProvider>().updateCartItem(
                  widget.favList[index].id!,
                  qty,
                  widget.favList[index]
                      .selVarient!,
                  widget.favList[index]
                      .prVarientList![widget.favList[index]
                          .selVarient!]
                      .id!);
              db.updateCart(
                widget.favList[index].id!,
                widget.favList[index]
                    .prVarientList![widget.favList[index]
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
        widget.updateNow();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
      }
    }
  }

  Future<void> addCart(int index, String qty, int from) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        if (mounted) {
          context.read<CartProvider>().setProgress(true);
          widget.updateNow();
        }

        if (int.parse(qty) <
            widget.favList[index]
                .minOrderQuntity!) {
          qty = widget.favList[index]
              .minOrderQuntity
              .toString();

          setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
        }

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_VARIENT_ID: widget.favList[index]
              .prVarientList![widget.favList[index]
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
              widget.favList[index]
                  .prVarientList![widget.favList[index]
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
              widget.updateNow();
            }
          },
          onError: (error) {
            setSnackbar(error.toString(), context);
            if (mounted) {
              context.read<CartProvider>().setProgress(false);
              widget.updateNow();
            }
          },
        );
      } else {
        context.read<CartProvider>().setProgress(true);
        widget.updateNow();

        if (singleSellerOrderSystem) {
          if (CurrentSellerID == '' ||
              CurrentSellerID ==
                  widget.favList[index]
                      .seller_id) {
            CurrentSellerID =
            widget.favList[index].seller_id!;
            if (from == 1) {
              List<Product>? prList = [];
              prList.add(widget.favList[index]);
              context.read<CartProvider>().addCartItem(
                    SectionModel(
                      qty: qty,
                      productList: prList,
                      varientId: widget.favList[index]
                          .prVarientList![widget.favList[index]
                              .selVarient!]
                          .id!,
                      id: widget.favList[index].id,
                      sellerId: widget.favList[index]
                          .seller_id,
                    ),
                  );
              db.insertCart(
                widget.favList[index].id!,
                widget.favList[index]
                    .prVarientList![widget.favList[index]
                        .selVarient!]
                    .id!,
                qty,
                context,
              );
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                  context);
            } else {
              if (int.parse(qty) >
                  int.parse(widget.favList[index]
                      .itemsCounter!
                      .last)) {
                setSnackbar(
                    "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                    context);
              } else {
                context.read<CartProvider>().updateCartItem(
                    widget.favList[index].id!,
                    qty,
                    widget.favList[index]
                        .selVarient!,
                    widget.favList[index]
                        .prVarientList![widget.favList[index]
                            .selVarient!]
                        .id!);
                db.updateCart(
                  widget.favList[index].id!,
                  widget.favList[index]
                      .prVarientList![widget.favList[index]
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
            prList.add(widget.favList[index]);
            context.read<CartProvider>().addCartItem(
                  SectionModel(
                    qty: qty,
                    productList: prList,
                    varientId: widget.favList[index]
                        .prVarientList![widget.favList[index]
                            .selVarient!]
                        .id!,
                    id: widget.favList[index].id,
                    sellerId: widget.favList[index]
                        .seller_id,
                  ),
                );
            db.insertCart(
              widget.favList[index].id!,
              widget.favList[index]
                  .prVarientList![widget.favList[index]
                      .selVarient!]
                  .id!,
              qty,
              context,
            );
            setSnackbar(
                "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                context);
          } else {
            if (int.parse(qty) >
                int.parse(widget.favList[index]
                    .itemsCounter!
                    .last)) {
              setSnackbar(
                  "${getTranslated(context, 'MAXQTY')!} ${widget.favList[index].itemsCounter!.last}",
                  context);
            } else {
              context.read<CartProvider>().updateCartItem(
                  widget.favList[index].id!,
                  qty,
                  widget.favList[index]
                      .selVarient!,
                  widget.favList[index]
                      .prVarientList![widget.favList[index]
                          .selVarient!]
                      .id!);
              db.updateCart(
                widget.favList[index].id!,
                widget.favList[index]
                    .prVarientList![widget.favList[index]
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
        widget.updateNow();
      }
    } else {
      if (mounted) {
        isNetworkAvail = false;
        widget.updateNow();
      }
    }
  }
  //
  // removeFromCart(
  //   int index,
  //   List<Product> favList,
  //   BuildContext context,
  // ) async {
  //   isNetworkAvail = await isNetworkAvailable();
  //   if (isNetworkAvail) {
  //     if (CUR_USERID != null) {
  //       if (mounted) {
  //         context
  //             .read<UpdateFavProvider>()
  //             .changeStatus(UpdateFavStatus.inProgress);
  //       }
  //       int qty;
  //       qty = (int.parse(
  //               context.read<FavoriteProvider>().controllerText[index].text) -
  //           int.parse(favList[index].qtyStepSize!));
  //
  //       if (qty < favList[index].minOrderQuntity!) {
  //         qty = 0;
  //       }
  //
  //       var parameter = {
  //         PRODUCT_VARIENT_ID:
  //             favList[index].prVarientList![favList[index].selVarient!].id,
  //         USER_ID: CUR_USERID,
  //         QTY: qty.toString()
  //       };
  //
  //       apiBaseHelper.postAPICall(manageCartApi, parameter).then(
  //         (getdata) {
  //           bool error = getdata['error'];
  //           String? msg = getdata['message'];
  //           if (!error) {
  //             var data = getdata['data'];
  //
  //             String? qty = data['total_quantity'];
  //
  //             context.read<UserProvider>().setCartCount(data['cart_count']);
  //             favList[index]
  //                 .prVarientList![favList[index].selVarient!]
  //                 .cartCount = qty.toString();
  //
  //             var cart = getdata['cart'];
  //             List<SectionModel> cartList = (cart as List)
  //                 .map((cart) => SectionModel.fromCart(cart))
  //                 .toList();
  //             context.read<CartProvider>().setCartlist(cartList);
  //           } else {
  //             setSnackbar(msg!, context);
  //           }
  //
  //           if (mounted) {
  //             context
  //                 .read<UpdateFavProvider>()
  //                 .changeStatus(UpdateFavStatus.isSuccsess);
  //             widget.updateNow();
  //           }
  //         },
  //         onError: (error) {
  //           setSnackbar(error.toString(), context);
  //           context
  //               .read<UpdateFavProvider>()
  //               .changeStatus(UpdateFavStatus.isSuccsess);
  //           widget.updateNow();
  //         },
  //       );
  //     } else {
  //       context
  //           .read<UpdateFavProvider>()
  //           .changeStatus(UpdateFavStatus.inProgress);
  //       int qty;
  //
  //       qty = (int.parse(
  //               context.read<FavoriteProvider>().controllerText[index].text) -
  //           int.parse(favList[index].qtyStepSize!));
  //
  //       if (qty < favList[index].minOrderQuntity!) {
  //         qty = 0;
  //
  //         db.removeCart(
  //             favList[index].prVarientList![favList[index].selVarient!].id!,
  //             favList[index].id!,
  //             context);
  //       } else {
  //         db.updateCart(
  //           favList[index].id!,
  //           favList[index].prVarientList![favList[index].selVarient!].id!,
  //           qty.toString(),
  //         );
  //       }
  //       context
  //           .read<UpdateFavProvider>()
  //           .changeStatus(UpdateFavStatus.isSuccsess);
  //       widget.updateNow();
  //     }
  //   } else {
  //     if (mounted) {
  //       isNetworkAvail = false;
  //       widget.updateNow();
  //     }
  //   }
  // }

  Future<void> addToCart(
    String qty,
    int from,
    List<Product> favList,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      if (CUR_USERID != null) {
        try {
          if (mounted) {
            context
                .read<UpdateFavProvider>()
                .changeStatus(UpdateFavStatus.inProgress);
          }

          String qty =
              (int.parse(favList[widget.index!].prVarientList![0].cartCount!) +
                      int.parse(favList[widget.index!].qtyStepSize!))
                  .toString();

          if (int.parse(qty) < favList[widget.index!].minOrderQuntity!) {
            qty = favList[widget.index!].minOrderQuntity.toString();
            setSnackbar("${getTranslated(context, 'MIN_MSG')}$qty", context);
          }

          var parameter = {
            PRODUCT_VARIENT_ID: favList[widget.index!]
                .prVarientList![favList[widget.index!].selVarient!]
                .id,
            USER_ID: CUR_USERID,
            QTY: qty,
          };
          apiBaseHelper.postAPICall(manageCartApi, parameter).then(
            (getdata) {
              bool error = getdata['error'];
              String? msg = getdata['message'];
              if (!error) {
                var data = getdata['data'];

                String? qty = data['total_quantity'];
                context.read<UserProvider>().setCartCount(data['cart_count']);

                favList[widget.index!]
                    .prVarientList![favList[widget.index!].selVarient!]
                    .cartCount = qty.toString();

                favList[widget.index!].prVarientList![0].cartCount =
                    qty.toString();
                context
                    .read<FavoriteProvider>()
                    .controllerText[widget.index!]
                    .text = qty.toString();
                var cart = getdata['cart'];
                List<SectionModel> cartList = (cart as List)
                    .map((cart) => SectionModel.fromCart(cart))
                    .toList();
                context.read<CartProvider>().setCartlist(cartList);
              } else {
                setSnackbar(msg!, context);
              }

              if (mounted) {
                context
                    .read<UpdateFavProvider>()
                    .changeStatus(UpdateFavStatus.isSuccsess);
              }
            },
            onError: (error) {
              setSnackbar(error.toString(), context);
            },
          );
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, 'somethingMSg')!, context);
          context.read<FavoriteProvider>().changeStatus(FavStatus.isSuccsess);
          widget.updateNow();
        }
      } else {
        if (singleSellerOrderSystem) {
          if (CurrentSellerID == '' ||
              CurrentSellerID == widget.favList[widget.index!].seller_id!) {
            CurrentSellerID = widget.favList[widget.index!].seller_id!;

            context
                .read<UpdateFavProvider>()
                .changeStatus(UpdateFavStatus.inProgress);
            if (from == 1) {
              db.insertCart(
                widget.favList[widget.index!].id!,
                widget
                    .favList[widget.index!]
                    .prVarientList![widget.favList[widget.index!].selVarient!]
                    .id!,
                qty,
                context,
              );
              context
                  .read<FavoriteProvider>()
                  .controllerText[widget.index!]
                  .text = qty.toString();
              widget.updateNow();
              setSnackbar(getTranslated(context, 'Product Added Successfully')!,
                  context);
            } else {
              if (int.parse(qty) >
                  widget.favList[widget.index!].itemsCounter!.length) {
                setSnackbar(
                    '${getTranslated(context, "Max Quantity is")!}-${int.parse(qty) - 1}',
                    context);
              } else {
                db.updateCart(
                  widget.favList[widget.index!].id!,
                  widget
                      .favList[widget.index!]
                      .prVarientList![widget.favList[widget.index!].selVarient!]
                      .id!,
                  qty,
                );
              }
              context
                  .read<FavoriteProvider>()
                  .controllerText[widget.index!]
                  .text = qty.toString();
              setSnackbar(
                  getTranslated(context, 'Cart Update Successfully')!, context);
            }
          } else {
            setSnackbar(
                getTranslated(context, 'only Single Seller Product Allow')!,
                context);
          }
        } else {
          context
              .read<UpdateFavProvider>()
              .changeStatus(UpdateFavStatus.inProgress);
          if (from == 1) {
            db.insertCart(
              widget.favList[widget.index!].id!,
              widget
                  .favList[widget.index!]
                  .prVarientList![widget.favList[widget.index!].selVarient!]
                  .id!,
              qty,
              context,
            );
            context
                .read<FavoriteProvider>()
                .controllerText[widget.index!]
                .text = qty.toString();
            widget.updateNow();
            setSnackbar(
                getTranslated(context, 'Product Added Successfully')!, context);
          } else {
            if (int.parse(qty) >
                widget.favList[widget.index!].itemsCounter!.length) {
              setSnackbar(
                  '${getTranslated(context, "Max Quantity is")!}-${int.parse(qty) - 1}',
                  context);
            } else {
              db.updateCart(
                widget.favList[widget.index!].id!,
                widget
                    .favList[widget.index!]
                    .prVarientList![widget.favList[widget.index!].selVarient!]
                    .id!,
                qty,
              );
            }
            context
                .read<FavoriteProvider>()
                .controllerText[widget.index!]
                .text = qty.toString();
            setSnackbar(
                getTranslated(context, 'Cart Update Successfully')!, context);
          }
        }
        context
            .read<UpdateFavProvider>()
            .changeStatus(UpdateFavStatus.isSuccsess);
        widget.updateNow();
      }
    } else {
      isNetworkAvail = false;

      widget.updateNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index! < widget.favList.length && widget.favList.isNotEmpty) {
      if (context.read<FavoriteProvider>().controllerText.length <
          widget.index! + 1) {
        context
            .read<FavoriteProvider>()
            .controllerText
            .add(TextEditingController());
      }
      return Selector<CartProvider, List<SectionModel>>(
          builder: (context, data, child) {
            double price = double.parse(widget
                .favList[widget.index!]
                .prVarientList![widget.favList[widget.index!].selVarient!]
                .disPrice!);
            if (price == 0) {
              price = double.parse(widget
                  .favList[widget.index!]
                  .prVarientList![widget.favList[widget.index!].selVarient!]
                  .price!);
            }
            double off = 0;
            if (widget
                    .favList[widget.index!]
                    .prVarientList![widget.favList[widget.index!].selVarient!]
                    .disPrice !=
                '0') {
              off = (double.parse(widget
                          .favList[widget.index!]
                          .prVarientList![
                              widget.favList[widget.index!].selVarient!]
                          .price!) -
                      double.parse(
                        widget
                            .favList[widget.index!]
                            .prVarientList![
                                widget.favList[widget.index!].selVarient!]
                            .disPrice!,
                      ))
                  .toDouble();
              off = off *
                  100 /
                  double.parse(widget
                      .favList[widget.index!]
                      .prVarientList![widget.favList[widget.index!].selVarient!]
                      .price!);
            }

            SectionModel? tempId = data.firstWhereOrNull((cp) =>
                cp.id == widget.favList[widget.index!].id &&
                cp.varientId ==
                    widget
                        .favList[widget.index!]
                        .prVarientList![
                            widget.favList[widget.index!].selVarient!]
                        .id!);
            if (tempId != null) {
              context
                  .read<FavoriteProvider>()
                  .controllerText[widget.index!]
                  .text = tempId.qty!.toString();
            } else {
              if (CUR_USERID != null) {
                context
                        .read<FavoriteProvider>()
                        .controllerText[widget.index!]
                        .text =
                    widget
                        .favList[widget.index!]
                        .prVarientList![
                            widget.favList[widget.index!].selVarient!]
                        .cartCount!;
              } else {
                context
                    .read<FavoriteProvider>()
                    .controllerText[widget.index!]
                    .text = '0';
              }
            }
            return Padding(
              padding: const EdgeInsetsDirectional.only(
                end: 10,
                start: 10,
                top: 5.0,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Card(
                    elevation: 0.1,
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(circularBorderRadius10),
                      splashColor: colors.primary.withOpacity(0.2),
                      onTap: () {
                        Product model = widget.favList[widget.index!];
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => ProductDetail(
                              model: model,
                              secPos: 0,
                              index: widget.index!,
                              list: true,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Hero(
                            tag:
                                '$heroTagUniqueString${widget.index}!${widget.favList[widget.index!].id}${widget.index} ${widget.favList[widget.index!].name}',
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(circularBorderRadius4),
                                bottomLeft:
                                    Radius.circular(circularBorderRadius4),
                              ),
                              child: Stack(
                                children: [
                                  DesignConfiguration.getCacheNotworkImage(
                                    context: context,
                                    boxFit: BoxFit.cover,
                                    heightvalue: 100.0,
                                    widthvalue: 100.0,
                                    placeHolderSize: 125,
                                    imageurlString:
                                        widget.favList[widget.index!].image!,
                                  ),
                                  Positioned.fill(
                                    child: widget.favList[widget.index!]
                                                .availability ==
                                            '0'
                                        ? Container(
                                            height: 55,
                                            color: colors.white70,
                                            padding: const EdgeInsets.all(2),
                                            child: Center(
                                              child: Text(
                                                getTranslated(context,
                                                    'OUT_OF_STOCK_LBL')!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                      fontFamily: 'ubuntu',
                                                      color: colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(),
                                  ),
                                  off != 0
                                      ? GetDicountLabel(discount: off)
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        top: 15.0,
                                        start: 15.0,
                                      ),
                                      child: Text(
                                        widget.favList[widget.index!].name!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .fontColor,
                                              fontFamily: 'ubuntu',
                                              fontWeight: FontWeight.w400,
                                              fontStyle: FontStyle.normal,
                                              fontSize: textFontSize12,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    (widget.favList[widget.index!].brandName
                                                ?.isNotEmpty ??
                                            false)
                                        ? Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(top: 10.0, start: 15.0),
                                            child: Text(
                                              (widget
                                                          .favList[
                                                              widget.index!]
                                                          .brandName
                                                          ?.isNotEmpty ??
                                                      false)
                                                  ? 'Brand : ${widget.favList[widget.index!].brandName}'
                                                  : '${widget.favList[widget.index!].brandName}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall!
                                                  .copyWith(
                                                      fontFamily: 'ubuntu',
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .fontColor,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      fontStyle:
                                                          FontStyle.normal,
                                                      fontSize: textFontSize12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        : const SizedBox(),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 15.0,
                                        top: 8.0,
                                      ),
                                      child: CUR_USERID != null
                                          ? Row(
                                              children: [
                                                Text(
                                                  DesignConfiguration
                                                      .getPriceFormat(
                                                          context, price)!,
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
                                                  double.parse(widget
                                                              .favList[
                                                                  widget.index!]
                                                              .prVarientList![0]
                                                              .disPrice!) !=
                                                          0
                                                      ? DesignConfiguration
                                                          .getPriceFormat(
                                                          context,
                                                          double.parse(
                                                            widget
                                                                .favList[widget
                                                                    .index!]
                                                                .prVarientList![
                                                                    0]
                                                                .price!,
                                                          ),
                                                        )!
                                                      : '',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall!
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .lightBlack,
                                                        fontFamily: 'ubuntu',
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        decorationColor:
                                                            colors.darkColor3,
                                                        decorationStyle:
                                                            TextDecorationStyle
                                                                .solid,
                                                        decorationThickness: 2,
                                                        letterSpacing: 0,
                                                      ),
                                                ),
                                              ],
                                            )
                                          : InkWell(
                                              onTap: () {
                                                Routes.navigateToLoginScreen(
                                                    context);
                                              },
                                              child: Text(
                                                'Login To See Price',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .blue,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'ubuntu',
                                                ),
                                              ),
                                            ),
                                    ),
                                    widget.favList[widget.index!].rating! !=
                                            '0.00'
                                        ? Padding(
                                            padding: const EdgeInsetsDirectional
                                                .only(
                                              top: 8.0,
                                              start: 15.0,
                                            ),
                                            child: StarRating(
                                              noOfRatings: widget
                                                  .favList[widget.index!]
                                                  .noOfRating!,
                                              totalRating: widget
                                                  .favList[widget.index!]
                                                  .rating!,
                                              needToShowNoOfRatings: true,
                                            ),
                                          )
                                        : const SizedBox(),
                                    widget.favList[widget.index!].attributeList!
                                            .isNotEmpty
                                        ? Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 5.0, left: 10.0),
                                              child: ListView.builder(
                                                  padding:
                                                      const EdgeInsets.all(0),
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: widget
                                                      .favList[widget.index!]
                                                      .attributeList!
                                                      .length,
                                                  itemBuilder:
                                                      (context, indexAT) {
                                                    return Text(
                                                      '${widget.favList[widget.index!].attributeList!.first.value!.split(",").first} ${widget.favList[widget.index!].attributeList![indexAT].name!}',
                                                      style: const TextStyle(
                                                        fontFamily: 'ubuntu',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    );
                                                  }),
                                            ),
                                          )
                                        : const SizedBox(),
                                    SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.04),
                                  ],
                                ),
                                Positioned.directional(
                                  textDirection: Directionality.of(context),
                                  // bottom: 15,
                                  end: 4,
                                  top: 45,
                                  child: Row(
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
                                              10.0,
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          if (isProgress == false &&
                                              (int.parse(widget.controller?.text??'') >
                                                  0)) {
                                            if ((widget
                                                .favList[widget.index!]
                                                .prVarientList
                                                ?.length ??
                                                1) >
                                                1) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  List<String> selList = widget
                                                      .favList[widget.index!]
                                                      .prVarientList![
                                                  _oldSelVarient]
                                                      .attribute_value_ids!
                                                      .split(',');
                                                  _selectedIndex.clear();
                                                  for (int i = 0;
                                                  i <
                                                      widget
                                                          .favList[
                                                      widget.index!]
                                                          .attributeList!
                                                          .length;
                                                  i++) {
                                                    List<String> sinList =
                                                    widget
                                                        .favList[
                                                    widget.index!]
                                                        .attributeList![i]
                                                        .id!
                                                        .split(',');

                                                    for (int j = 0;
                                                    j < sinList.length;
                                                    j++) {
                                                      if (selList.contains(
                                                          sinList[j])) {
                                                        _selectedIndex.insert(
                                                            i, j);
                                                      }
                                                    }

                                                    if (_selectedIndex.length ==
                                                        i) {
                                                      _selectedIndex.insert(
                                                          i, null);
                                                    }
                                                  }
                                                  return StatefulBuilder(
                                                    builder: (BuildContext
                                                    context,
                                                        StateSetter setStater) {
                                                      return AlertDialog(
                                                        contentPadding:
                                                        const EdgeInsets
                                                            .all(0.0),
                                                        shape:
                                                        const RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.all(
                                                            Radius.circular(
                                                                circularBorderRadius5),
                                                          ),
                                                        ),
                                                        content: SizedBox(
                                                          height: MediaQuery.of(
                                                              context)
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
                                                                  height: MediaQuery.of(
                                                                      context)
                                                                      .size
                                                                      .height *
                                                                      0.47,
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    color: Theme.of(
                                                                        context)
                                                                        .colorScheme
                                                                        .white,
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        circularBorderRadius10),
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      InkWell(
                                                                        child: Stack(
                                                                          children: [
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                              children: [
                                                                                Flexible(
                                                                                  flex:
                                                                                  1,
                                                                                  child:
                                                                                  ClipRRect(
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
                                                                                      imageurlString: widget.favList[widget.index!].image!,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Column(
                                                                                  crossAxisAlignment:
                                                                                  CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    widget.favList[widget.index!].brandName != '' && widget.favList[widget.index!].brandName != null
                                                                                        ? Padding(
                                                                                      padding: const EdgeInsets.only(
                                                                                        left: 15.0,
                                                                                        right: 15.0,
                                                                                        top: 16.0,
                                                                                      ),
                                                                                      child: Text(
                                                                                        widget.favList[widget.index!].brandName ?? '',
                                                                                        style: TextStyle(
                                                                                          fontWeight: FontWeight.bold,
                                                                                          color: Theme.of(context).colorScheme.lightBlack,
                                                                                          fontSize: textFontSize14,
                                                                                        ),
                                                                                      ),
                                                                                    )
                                                                                        : const SizedBox(),
                                                                                    GetTitleWidget(
                                                                                      title: widget.favList[widget.index!].name ?? '',
                                                                                    ),
                                                                                    available ?? false || (outOfStock ?? false)
                                                                                        ? GetPrice(pos: selectIndex, from: true, model: widget.favList[widget.index!])
                                                                                        : GetPrice(
                                                                                      pos: widget.favList[widget.index!].selVarient,
                                                                                      from: false,
                                                                                      model: widget.favList[widget.index!],
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
                                                                              height: MediaQuery.of(context).size.height *
                                                                                  0.28,
                                                                              width: MediaQuery.of(context).size.height *
                                                                                  0.6,
                                                                              color: Theme.of(context)
                                                                                  .colorScheme
                                                                                  .white,
                                                                              child:
                                                                              Padding(
                                                                                padding:
                                                                                const EdgeInsets.only(top: 15.0),
                                                                                child:
                                                                                ListView.builder(
                                                                                  scrollDirection:
                                                                                  Axis.vertical,
                                                                                  physics:
                                                                                  const BouncingScrollPhysics(),
                                                                                  itemCount:
                                                                                  widget.favList[widget.index!].attributeList!.length,
                                                                                  itemBuilder:
                                                                                      (context, indexAt) {
                                                                                    List<Widget?> chips = [];
                                                                                    List<String> att = widget.favList[widget.index!].attributeList![indexAt].value!.split(',');
                                                                                    List<String> attId = widget.favList[widget.index!].attributeList![indexAt].id!.split(',');
                                                                                    List<String> attSType = widget.favList[widget.index!].attributeList![indexAt].sType!.split(',');
                                                                                    List<String> attSValue = widget.favList[widget.index!].attributeList![indexAt].sValue!.split(',');
                                                                                    int? varSelected;
                                                                                    List<String> wholeAtt = widget.favList[widget.index!].attrIds!.split(',');
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
                                                                                              '${att[i]} ${widget.favList[widget.index!].attributeList![indexAt].name}',
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
                                                                                                      widget.favList[widget.index!].selVarient = i;
                                                                                                      available = false;
                                                                                                      _selectedIndex[indexAt] = i;
                                                                                                      List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                      List<bool> check = [];
                                                                                                      for (int i = 0; i < widget.favList[widget.index!].attributeList!.length; i++) {
                                                                                                        List<String> attId = widget.favList[widget.index!].attributeList![i].id!.split(',');
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
                                                                                                      for (int i = 0; i < widget.favList[widget.index!].prVarientList!.length; i++) {
                                                                                                        sinId = widget.favList[widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                        if (widget.favList[widget.index!].stockType == '0' || widget.favList[widget.index!].stockType == '1') {
                                                                                                          if (widget.favList[widget.index!].availability == '1') {
                                                                                                            available = true;
                                                                                                            outOfStock = false;
                                                                                                            _oldSelVarient = varSelected!;
                                                                                                          } else {
                                                                                                            available = false;
                                                                                                            outOfStock = true;
                                                                                                          }
                                                                                                        } else if (widget.favList[widget.index!].stockType == '') {
                                                                                                          available = true;
                                                                                                          outOfStock = false;
                                                                                                          _oldSelVarient = varSelected!;
                                                                                                        } else if (widget.favList[widget.index!].stockType == '2') {
                                                                                                          if (widget.favList[widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                      if (widget.favList[widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                        int oldVarTotal = 0;
                                                                                                        if (_oldSelVarient > 0) {
                                                                                                          for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                            oldVarTotal = oldVarTotal + widget.favList[widget.index!].prVarientList![i].images!.length;
                                                                                                          }
                                                                                                        }
                                                                                                        int p = widget.favList[widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                      }
                                                                                                    },
                                                                                                  );
                                                                                                }
                                                                                                if (available!) {
                                                                                                  if (CUR_USERID != null) {
                                                                                                    if (widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                      qtyController.text = widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                      context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                    } else {
                                                                                                      qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                      context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                    }
                                                                                                  } else {
                                                                                                    String qty = (await db.checkCartItemExists(widget.favList[widget.index!].id!, widget.favList[widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                    if (qty == '0') {
                                                                                                      qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                      context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                    } else {
                                                                                                      widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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
                                                                                                '${widget.favList[widget.index!].attributeList![indexAt].name!} : $value',
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
                                                                                                        widget.favList[widget.index!].type == 'digital_product'
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
                                                                                                                if (widget.favList[widget.index!].prVarientList![chipIndex].quantity >= 1) {
                                                                                                                  setStater(() {
                                                                                                                    context.read<ExploreProvider>().variantDecrement(widget.index!, chipIndex, (int.parse(context.read<ExploreProvider>().productList[widget.index!].qtyStepSize.toString())));
                                                                                                                  });
                                                                                                                }
                                                                                                                else {
                                                                                                                  setSnackbar('${getTranslated(context, 'MIN_MSG')}${widget.favList[widget.index!].quantity.toString()}', context);
                                                                                                                }

                                                                                                                if (widget.favList[widget.index!].prVarientList![chipIndex].quantity != 0) {
                                                                                                                  var finalQuantity = widget.favList[widget.index!].prVarientList![chipIndex].quantity - int.parse(context.read<ExploreProvider>().productList[widget.index!].qtyStepSize.toString());
                                                                                                                  setStater(() {
                                                                                                                    widget.favList[widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                  });
                                                                                                                  newRemoveCart(widget.index!, widget.favList, widget.favList[widget.index!], chipIndex, widget.favList[widget.index!].prVarientList![chipIndex].quantity);
                                                                                                                }
                                                                                                              }
                                                                                                            }
                                                                                                          },
                                                                                                        ),
                                                                                                        context.read<ExploreProvider>().productList[widget.index!].type == 'digital_product'
                                                                                                            ? const SizedBox()
                                                                                                            : Padding(
                                                                                                          padding: const EdgeInsets.only(left: 10),
                                                                                                          child: SizedBox(
                                                                                                              width: 20,
                                                                                                              child: Text(
                                                                                                                '${widget.favList[widget.index!].prVarientList![chipIndex].quantity}',
                                                                                                                style: TextStyle(
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
                                                                                                        widget.favList[widget.index!].type == 'digital_product'
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
                                                                                                                    widget.favList[widget.index!].selVarient = chipIndex;
                                                                                                                    available = false;
                                                                                                                    _selectedIndex[indexAt] = chipIndex;
                                                                                                                    List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                    List<bool> check = [];
                                                                                                                    for (int i = 0; i < widget.favList[widget.index!].attributeList!.length; i++) {
                                                                                                                      List<String> attId = widget.favList[widget.index!].attributeList![i].id!.split(',');
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
                                                                                                                    for (int i = 0; i < widget.favList[widget.index!].prVarientList!.length; i++) {
                                                                                                                      sinId = widget.favList[widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                                      if (widget.favList[widget.index!].stockType == '0' || context.read<ExploreProvider>().productList[widget.index!].stockType == '1') {
                                                                                                                        if (widget.favList[widget.index!].availability == '1') {
                                                                                                                          available = true;
                                                                                                                          outOfStock = false;
                                                                                                                          _oldSelVarient = varSelected!;
                                                                                                                        } else {
                                                                                                                          available = false;
                                                                                                                          outOfStock = true;
                                                                                                                        }
                                                                                                                      } else if (widget.favList[widget.index!].stockType == '') {
                                                                                                                        available = true;
                                                                                                                        outOfStock = false;
                                                                                                                        _oldSelVarient = varSelected!;
                                                                                                                      } else if (widget.favList[widget.index!].stockType == '2') {
                                                                                                                        if (widget.favList[widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                                    if (widget.favList[widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                      int oldVarTotal = 0;
                                                                                                                      if (_oldSelVarient > 0) {
                                                                                                                        for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                          oldVarTotal = oldVarTotal + widget.favList[widget.index!].prVarientList![i].images!.length;
                                                                                                                        }
                                                                                                                      }
                                                                                                                      int p = widget.favList[widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                                    }
                                                                                                                  },
                                                                                                                );
                                                                                                              }
                                                                                                              if (available!) {
                                                                                                                if (CUR_USERID != null) {
                                                                                                                  if (widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                    qtyController.text = widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  } else {
                                                                                                                    qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  }
                                                                                                                } else {
                                                                                                                  String qty = (await db.checkCartItemExists(widget.favList[widget.index!].id!, context.read<ExploreProvider>().productList[widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                                  if (qty == '0') {
                                                                                                                    qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                                    context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                  } else {
                                                                                                                    widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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
                                                                                                                var finalQuantity = widget.favList[widget.index!].prVarientList![chipIndex].quantity + int.parse(context.read<ExploreProvider>().productList[widget.index!].qtyStepSize.toString());
                                                                                                                setStater(() {
                                                                                                                  widget.favList[widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                });
                                                                                                                // context.read<ExploreProvider>().variantIncrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                addNewCart(widget.index!, widget.favList[widget.index!].prVarientList![chipIndex].quantity.toString(), 2);
                                                                                                                widget.updateNow;
                                                                                                              }
                                                                                                              // else {
                                                                                                              //   log('Vijay 2');
                                                                                                              //   context
                                                                                                              //       .read<
                                                                                                              //       CartProvider>()
                                                                                                              //       .addQuantity(
                                                                                                              //     productList: context
                                                                                                              //         .read<
                                                                                                              //         ExploreProvider>()
                                                                                                              //         .productList[index],
                                                                                                              //     qty: context
                                                                                                              //         .read<
                                                                                                              //         ExploreProvider>()
                                                                                                              //         .productList[
                                                                                                              //     index].quantity.toString(),
                                                                                                              //     from: 1,
                                                                                                              //     totalLen: context
                                                                                                              //         .read<
                                                                                                              //         ExploreProvider>()
                                                                                                              //         .productList[
                                                                                                              //     index]
                                                                                                              //         .itemsCounter!
                                                                                                              //         .length *
                                                                                                              //         int.parse(context
                                                                                                              //             .read<ExploreProvider>()
                                                                                                              //             .productList[index]
                                                                                                              //             .qtyStepSize!),
                                                                                                              //     index:
                                                                                                              //     index,
                                                                                                              //     price:
                                                                                                              //     price,
                                                                                                              //     selectedPos:
                                                                                                              //     selectedPos,
                                                                                                              //     total:
                                                                                                              //     total,
                                                                                                              //     pid: context
                                                                                                              //         .read<
                                                                                                              //         ExploreProvider>()
                                                                                                              //         .productList[
                                                                                                              //     0]
                                                                                                              //         .id
                                                                                                              //         .toString(),
                                                                                                              //     vid: context
                                                                                                              //         .read<ExploreProvider>()
                                                                                                              //         .productList[0]
                                                                                                              //         .prVarientList?[selectedPos]
                                                                                                              //         .id
                                                                                                              //         .toString() ??
                                                                                                              //         '',
                                                                                                              //     itemCounter: int.parse(context
                                                                                                              //         .read<
                                                                                                              //         ExploreProvider>()
                                                                                                              //         .productList[
                                                                                                              //     index]
                                                                                                              //         .qtyStepSize!),
                                                                                                              //     context:
                                                                                                              //     context,
                                                                                                              //     update:
                                                                                                              //     setStateNow,
                                                                                                              //   );
                                                                                                              // }
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
                                                  widget.index!,
                                                  widget.favList);
                                            }

                                          }
                                        },
                                      ),
                                      SizedBox(
                                        width: 37,
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
                                              controller:widget.controller,
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
                                              itemBuilder:
                                                  (BuildContext context) {
                                                return widget
                                                    .favList[widget.index!]
                                                    .itemsCounter!
                                                    .map<PopupMenuItem<String>>(
                                                  (String value) {
                                                    return PopupMenuItem(
                                                        value: value,
                                                        child: Text(value,
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
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
                                            padding: EdgeInsets.all(10.0),
                                            child: Icon(
                                              Icons.add,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          if (isProgress == false) {
                                            if ((widget
                                                        .favList[widget.index!]
                                                        .prVarientList
                                                        ?.length ??
                                                    1) >
                                                1) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  List<String> selList = widget
                                                      .favList[widget.index!]
                                                      .prVarientList![
                                                          _oldSelVarient]
                                                      .attribute_value_ids!
                                                      .split(',');
                                                  _selectedIndex.clear();
                                                  for (int i = 0;
                                                      i <
                                                          widget
                                                              .favList[
                                                                  widget.index!]
                                                              .attributeList!
                                                              .length;
                                                      i++) {
                                                    List<String> sinList =
                                                        widget
                                                            .favList[
                                                                widget.index!]
                                                            .attributeList![i]
                                                            .id!
                                                            .split(',');

                                                    for (int j = 0;
                                                        j < sinList.length;
                                                        j++) {
                                                      if (selList.contains(
                                                          sinList[j])) {
                                                        _selectedIndex.insert(
                                                            i, j);
                                                      }
                                                    }

                                                    if (_selectedIndex.length ==
                                                        i) {
                                                      _selectedIndex.insert(
                                                          i, null);
                                                    }
                                                  }
                                                  return StatefulBuilder(
                                                    builder: (BuildContext
                                                            context,
                                                        StateSetter setStater) {
                                                      return AlertDialog(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .all(0.0),
                                                        shape:
                                                            const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                            Radius.circular(
                                                                circularBorderRadius5),
                                                          ),
                                                        ),
                                                        content: SizedBox(
                                                          height: MediaQuery.of(
                                                              context)
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
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height *
                                                                      0.47,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .white,
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                                circularBorderRadius10),
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      InkWell(
                                                                        child: Stack(
                                                                          children: [
                                                                            Row(
                                                                              crossAxisAlignment:
                                                                                  CrossAxisAlignment.start,
                                                                              children: [
                                                                                Flexible(
                                                                                  flex:
                                                                                      1,
                                                                                  child:
                                                                                      ClipRRect(
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
                                                                                      imageurlString: widget.favList[widget.index!].image!,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                Column(
                                                                                  crossAxisAlignment:
                                                                                      CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    widget.favList[widget.index!].brandName != '' && widget.favList[widget.index!].brandName != null
                                                                                        ? Padding(
                                                                                            padding: const EdgeInsets.only(
                                                                                              left: 15.0,
                                                                                              right: 15.0,
                                                                                              top: 16.0,
                                                                                            ),
                                                                                            child: Text(
                                                                                              widget.favList[widget.index!].brandName ?? '',
                                                                                              style: TextStyle(
                                                                                                fontWeight: FontWeight.bold,
                                                                                                color: Theme.of(context).colorScheme.lightBlack,
                                                                                                fontSize: textFontSize14,
                                                                                              ),
                                                                                            ),
                                                                                          )
                                                                                        : const SizedBox(),
                                                                                    GetTitleWidget(
                                                                                      title: widget.favList[widget.index!].name ?? '',
                                                                                    ),
                                                                                    available ?? false || (outOfStock ?? false)
                                                                                        ? GetPrice(pos: selectIndex, from: true, model: widget.favList[widget.index!])
                                                                                        : GetPrice(
                                                                                            pos: widget.favList[widget.index!].selVarient,
                                                                                            from: false,
                                                                                            model: widget.favList[widget.index!],
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
                                                                              height: MediaQuery.of(context).size.height *
                                                                                  0.28,
                                                                              width: MediaQuery.of(context).size.height *
                                                                                  0.6,
                                                                              color: Theme.of(context)
                                                                                  .colorScheme
                                                                                  .white,
                                                                              child:
                                                                                  Padding(
                                                                                padding:
                                                                                    const EdgeInsets.only(top: 15.0),
                                                                                child:
                                                                                    ListView.builder(
                                                                                  scrollDirection:
                                                                                      Axis.vertical,
                                                                                  physics:
                                                                                      const BouncingScrollPhysics(),
                                                                                  itemCount:
                                                                                      widget.favList[widget.index!].attributeList!.length,
                                                                                  itemBuilder:
                                                                                      (context, indexAt) {
                                                                                    List<Widget?> chips = [];
                                                                                    List<String> att = widget.favList[widget.index!].attributeList![indexAt].value!.split(',');
                                                                                    List<String> attId = widget.favList[widget.index!].attributeList![indexAt].id!.split(',');
                                                                                    List<String> attSType = widget.favList[widget.index!].attributeList![indexAt].sType!.split(',');
                                                                                    List<String> attSValue = widget.favList[widget.index!].attributeList![indexAt].sValue!.split(',');
                                                                                    int? varSelected;
                                                                                    List<String> wholeAtt = widget.favList[widget.index!].attrIds!.split(',');
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
                                                                                              '${att[i]} ${widget.favList[widget.index!].attributeList![indexAt].name}',
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
                                                                                                      widget.favList[widget.index!].selVarient = i;
                                                                                                      available = false;
                                                                                                      _selectedIndex[indexAt] = i;
                                                                                                      List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                      List<bool> check = [];
                                                                                                      for (int i = 0; i < widget.favList[widget.index!].attributeList!.length; i++) {
                                                                                                        List<String> attId = widget.favList[widget.index!].attributeList![i].id!.split(',');
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
                                                                                                      for (int i = 0; i < widget.favList[widget.index!].prVarientList!.length; i++) {
                                                                                                        sinId = widget.favList[widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                        if (widget.favList[widget.index!].stockType == '0' || widget.favList[widget.index!].stockType == '1') {
                                                                                                          if (widget.favList[widget.index!].availability == '1') {
                                                                                                            available = true;
                                                                                                            outOfStock = false;
                                                                                                            _oldSelVarient = varSelected!;
                                                                                                          } else {
                                                                                                            available = false;
                                                                                                            outOfStock = true;
                                                                                                          }
                                                                                                        } else if (widget.favList[widget.index!].stockType == '') {
                                                                                                          available = true;
                                                                                                          outOfStock = false;
                                                                                                          _oldSelVarient = varSelected!;
                                                                                                        } else if (widget.favList[widget.index!].stockType == '2') {
                                                                                                          if (widget.favList[widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                      if (widget.favList[widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                        int oldVarTotal = 0;
                                                                                                        if (_oldSelVarient > 0) {
                                                                                                          for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                            oldVarTotal = oldVarTotal + widget.favList[widget.index!].prVarientList![i].images!.length;
                                                                                                          }
                                                                                                        }
                                                                                                        int p = widget.favList[widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                      }
                                                                                                    },
                                                                                                  );
                                                                                                }
                                                                                                if (available!) {
                                                                                                  if (CUR_USERID != null) {
                                                                                                    if (widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                      qtyController.text = widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                      context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                    } else {
                                                                                                      qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                      context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                    }
                                                                                                  } else {
                                                                                                    String qty = (await db.checkCartItemExists(widget.favList[widget.index!].id!, widget.favList[widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                    if (qty == '0') {
                                                                                                      qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                      context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                    } else {
                                                                                                      widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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
                                                                                                      '${widget.favList[widget.index!].attributeList![indexAt].name!} : $value',
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
                                                                                                              widget.favList[widget.index!].type == 'digital_product'
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
                                                                                                                            if (widget.favList[widget.index!].prVarientList![chipIndex].quantity >= 1) {
                                                                                                                              setStater(() {
                                                                                                                                context.read<ExploreProvider>().variantDecrement(widget.index!, chipIndex, (int.parse(context.read<ExploreProvider>().productList[widget.index!].qtyStepSize.toString())));
                                                                                                                              });
                                                                                                                            } else {
                                                                                                                              setSnackbar('${getTranslated(context, 'MIN_MSG')}${widget.favList[widget.index!].quantity.toString()}', context);
                                                                                                                            }

                                                                                                                            if (widget.favList[widget.index!].prVarientList![chipIndex].quantity != 0) {
                                                                                                                              var finalQuantity = widget.favList[widget.index!].prVarientList![chipIndex].quantity - int.parse(context.read<ExploreProvider>().productList[widget.index!].qtyStepSize.toString());
                                                                                                                              setStater(() {
                                                                                                                                widget.favList[widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                              });
                                                                                                                              newRemoveCart(widget.index!, widget.favList, widget.favList[widget.index!], chipIndex, widget.favList[widget.index!].prVarientList![chipIndex].quantity);
                                                                                                                            }
                                                                                                                          }
                                                                                                                        }
                                                                                                                      },
                                                                                                                    ),
                                                                                                              context.read<ExploreProvider>().productList[widget.index!].type == 'digital_product'
                                                                                                                  ? const SizedBox()
                                                                                                                  : Padding(
                                                                                                                      padding: const EdgeInsets.only(left: 10),
                                                                                                                      child: SizedBox(
                                                                                                                          width: 20,
                                                                                                                          child: Text(
                                                                                                                            '${widget.favList[widget.index!].prVarientList![chipIndex].quantity}',
                                                                                                                            style: TextStyle(
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
                                                                                                              widget.favList[widget.index!].type == 'digital_product'
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
                                                                                                                                widget.favList[widget.index!].selVarient = chipIndex;
                                                                                                                                available = false;
                                                                                                                                _selectedIndex[indexAt] = chipIndex;
                                                                                                                                List<int> selectedId = []; //list where user choosen item id is stored
                                                                                                                                List<bool> check = [];
                                                                                                                                for (int i = 0; i < widget.favList[widget.index!].attributeList!.length; i++) {
                                                                                                                                  List<String> attId = widget.favList[widget.index!].attributeList![i].id!.split(',');
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
                                                                                                                                for (int i = 0; i < widget.favList[widget.index!].prVarientList!.length; i++) {
                                                                                                                                  sinId = widget.favList[widget.index!].prVarientList![i].attribute_value_ids!.split(',');

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
                                                                                                                                  if (widget.favList[widget.index!].stockType == '0' || context.read<ExploreProvider>().productList[widget.index!].stockType == '1') {
                                                                                                                                    if (widget.favList[widget.index!].availability == '1') {
                                                                                                                                      available = true;
                                                                                                                                      outOfStock = false;
                                                                                                                                      _oldSelVarient = varSelected!;
                                                                                                                                    } else {
                                                                                                                                      available = false;
                                                                                                                                      outOfStock = true;
                                                                                                                                    }
                                                                                                                                  } else if (widget.favList[widget.index!].stockType == '') {
                                                                                                                                    available = true;
                                                                                                                                    outOfStock = false;
                                                                                                                                    _oldSelVarient = varSelected!;
                                                                                                                                  } else if (widget.favList[widget.index!].stockType == '2') {
                                                                                                                                    if (widget.favList[widget.index!].prVarientList![varSelected!].availability == '1') {
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
                                                                                                                                if (widget.favList[widget.index!].prVarientList![_oldSelVarient].images!.isNotEmpty) {
                                                                                                                                  int oldVarTotal = 0;
                                                                                                                                  if (_oldSelVarient > 0) {
                                                                                                                                    for (int i = 0; i < _oldSelVarient; i++) {
                                                                                                                                      oldVarTotal = oldVarTotal + widget.favList[widget.index!].prVarientList![i].images!.length;
                                                                                                                                    }
                                                                                                                                  }
                                                                                                                                  int p = widget.favList[widget.index!].otherImage!.length + 1 + oldVarTotal;
                                                                                                                                }
                                                                                                                              },
                                                                                                                            );
                                                                                                                          }
                                                                                                                          if (available!) {
                                                                                                                            if (CUR_USERID != null) {
                                                                                                                              if (widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount! != '0') {
                                                                                                                                qtyController.text = widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount!;
                                                                                                                                context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                              } else {
                                                                                                                                qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                                                context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                              }
                                                                                                                            } else {
                                                                                                                              String qty = (await db.checkCartItemExists(widget.favList[widget.index!].id!, context.read<ExploreProvider>().productList[widget.index!].prVarientList![_oldSelVarient].id!))!;
                                                                                                                              if (qty == '0') {
                                                                                                                                qtyController.text = widget.favList[widget.index!].minOrderQuntity.toString();
                                                                                                                                context.read<ProductDetailProvider>().qtyChange = true;
                                                                                                                              } else {
                                                                                                                                widget.favList[widget.index!].prVarientList![_oldSelVarient].cartCount = qty;
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
                                                                                                                            var finalQuantity = widget.favList[widget.index!].prVarientList![chipIndex].quantity + int.parse(context.read<ExploreProvider>().productList[widget.index!].qtyStepSize.toString());
                                                                                                                            setStater(() {
                                                                                                                              widget.favList[widget.index!].prVarientList![chipIndex].quantity = finalQuantity;
                                                                                                                            });
                                                                                                                            // context.read<ExploreProvider>().variantIncrement(index, chipIndex, (int.parse(context.read<ExploreProvider>().productList[index].qtyStepSize.toString())));
                                                                                                                            addNewCart(widget.index!, widget.favList[widget.index!].prVarientList![chipIndex].quantity.toString(), 2);
                                                                                                                            widget.updateNow;
                                                                                                                          }
                                                                                                                          // else {
                                                                                                                          //   log('Vijay 2');
                                                                                                                          //   context
                                                                                                                          //       .read<
                                                                                                                          //       CartProvider>()
                                                                                                                          //       .addQuantity(
                                                                                                                          //     productList: context
                                                                                                                          //         .read<
                                                                                                                          //         ExploreProvider>()
                                                                                                                          //         .productList[index],
                                                                                                                          //     qty: context
                                                                                                                          //         .read<
                                                                                                                          //         ExploreProvider>()
                                                                                                                          //         .productList[
                                                                                                                          //     index].quantity.toString(),
                                                                                                                          //     from: 1,
                                                                                                                          //     totalLen: context
                                                                                                                          //         .read<
                                                                                                                          //         ExploreProvider>()
                                                                                                                          //         .productList[
                                                                                                                          //     index]
                                                                                                                          //         .itemsCounter!
                                                                                                                          //         .length *
                                                                                                                          //         int.parse(context
                                                                                                                          //             .read<ExploreProvider>()
                                                                                                                          //             .productList[index]
                                                                                                                          //             .qtyStepSize!),
                                                                                                                          //     index:
                                                                                                                          //     index,
                                                                                                                          //     price:
                                                                                                                          //     price,
                                                                                                                          //     selectedPos:
                                                                                                                          //     selectedPos,
                                                                                                                          //     total:
                                                                                                                          //     total,
                                                                                                                          //     pid: context
                                                                                                                          //         .read<
                                                                                                                          //         ExploreProvider>()
                                                                                                                          //         .productList[
                                                                                                                          //     0]
                                                                                                                          //         .id
                                                                                                                          //         .toString(),
                                                                                                                          //     vid: context
                                                                                                                          //         .read<ExploreProvider>()
                                                                                                                          //         .productList[0]
                                                                                                                          //         .prVarientList?[selectedPos]
                                                                                                                          //         .id
                                                                                                                          //         .toString() ??
                                                                                                                          //         '',
                                                                                                                          //     itemCounter: int.parse(context
                                                                                                                          //         .read<
                                                                                                                          //         ExploreProvider>()
                                                                                                                          //         .productList[
                                                                                                                          //     index]
                                                                                                                          //         .qtyStepSize!),
                                                                                                                          //     context:
                                                                                                                          //     context,
                                                                                                                          //     update:
                                                                                                                          //     setStateNow,
                                                                                                                          //   );
                                                                                                                          // }
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
                                                  widget.index!,
                                                  (int.parse(widget.controller?.text??'') +
                                                          int.parse(context
                                                              .read<
                                                                  ExploreProvider>()
                                                              .productList[
                                                                  widget.index!]
                                                              .qtyStepSize!))
                                                      .toString(),
                                                  2);
                                            }
                                          }
                                        },
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Positioned.directional(
                  //   textDirection: Directionality.of(context),
                  //   bottom: 4,
                  //   end: 4,
                  //   child: InkWell(
                  //     child: Container(
                  //       padding: const EdgeInsets.all(8.0),
                  //       alignment: Alignment.center,
                  //       decoration: BoxDecoration(
                  //         borderRadius:
                  //             BorderRadius.circular(circularBorderRadius40),
                  //         color: Theme.of(context).colorScheme.white,
                  //         boxShadow: const [
                  //           BoxShadow(
                  //             offset: Offset(2, 2),
                  //             blurRadius: 12,
                  //             color: Color.fromRGBO(0, 0, 0, 0.13),
                  //             spreadRadius: 0.4,
                  //           )
                  //         ],
                  //       ),
                  //       child: const Icon(
                  //         Icons.shopping_cart_outlined,
                  //         size: 20,
                  //       ),
                  //     ),
                  //     onTap: () async {
                  //       await addToCart(
                  //         '1',
                  //         1,
                  //         widget.favList,
                  //       ).then(
                  //         (value) {
                  //           Future.delayed(const Duration(seconds: 3)).then(
                  //             (_) async {
                  //               /* context
                  //                             .read<UserProvider>()
                  //                             .setCartCount(context
                  //                                     .read<UpdateFavProvider>()
                  //                                     .cartCount ??
                  //                                 '0');*/
                  //
                  //               widget.updateNow();
                  //             },
                  //           );
                  //         },
                  //       );
                  //     },
                  //   ),
                  // )
                  // widget.favList[widget.index!].availability == '0'
                  //     ? const SizedBox()
                  //     : context
                  //                 .read<FavoriteProvider>()
                  //                 .controllerText[widget.index!]
                  //                 .text ==
                  //             '0'
                  //         ? Positioned.directional(
                  //             textDirection: Directionality.of(context),
                  //             bottom: 4,
                  //             end: 4,
                  //             child: InkWell(
                  //               child: Container(
                  //                 padding: const EdgeInsets.all(8.0),
                  //                 alignment: Alignment.center,
                  //                 decoration: BoxDecoration(
                  //                   borderRadius: BorderRadius.circular(
                  //                       circularBorderRadius40),
                  //                   color: Theme.of(context).colorScheme.white,
                  //                   boxShadow: const [
                  //                     BoxShadow(
                  //                       offset: Offset(2, 2),
                  //                       blurRadius: 12,
                  //                       color: Color.fromRGBO(0, 0, 0, 0.13),
                  //                       spreadRadius: 0.4,
                  //                     )
                  //                   ],
                  //                 ),
                  //                 child: const Icon(
                  //                   Icons.shopping_cart_outlined,
                  //                   size: 20,
                  //                 ),
                  //               ),
                  //               onTap: () async {
                  //                 await addToCart(
                  //                   '1',
                  //                   1,
                  //                   widget.favList,
                  //                 ).then(
                  //                   (value) {
                  //                     Future.delayed(const Duration(seconds: 3))
                  //                         .then(
                  //                       (_) async {
                  //                         /* context
                  //                             .read<UserProvider>()
                  //                             .setCartCount(context
                  //                                     .read<UpdateFavProvider>()
                  //                                     .cartCount ??
                  //                                 '0');*/
                  //
                  //                         widget.updateNow();
                  //                       },
                  //                     );
                  //                   },
                  //                 );
                  //               },
                  //             ),
                  //           )
                  //         : const SizedBox()
                ],
              ),
            );
          },
          selector: (_, provider) => provider.cartList);
    } else {
      return const SizedBox();
    }
  }
}
