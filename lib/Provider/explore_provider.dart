import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../repository/FavoriteRepository.dart';
import '../Screen/Language/languageSettings.dart';
import '../widgets/networkAvailablity.dart';
import '../widgets/security.dart';
import '../widgets/snackbar.dart';

class ExploreProvider extends ChangeNotifier {
  String view = 'ListView'; //GridView
  String totalProducts = '0';
  List<Product> productList = [];
  bool isFilter = false;
  String filterCategoryName = '';
  int selectedIndex = 0;

  get getCurrentView => view;

  changeViewTo(String view) {
    this.view = view;
    notifyListeners();
  }

  increment(int index)
  {
    productList[index].quantity ++;
    notifyListeners();
  }

  selectedFilter(int index)
  {
    selectedIndex = index;
    notifyListeners();
  }

  filterAdd(String filterName)
  {
    filterCategoryName = filterName;
    notifyListeners();
  }

  isFilterAdd(bool isFilterAdd)
  {
    isFilter = isFilterAdd;
    notifyListeners();
  }

  decrement(int index)
  {
    productList[index].quantity --;
    notifyListeners();
  }

  variantIncrement(int index,int indexAT,int stepSize)
  {
    if(productList[index].prVarientList![indexAT].quantity=="0")
    {
      productList[index].prVarientList![indexAT].quantity =stepSize;
      notifyListeners();
    }
    else
    {
      var qty = productList[index].prVarientList![indexAT].quantity + stepSize;
      productList[index].prVarientList![indexAT].quantity =qty;
      notifyListeners();
    }


  }

  variantDecrement(int index,int indexAT,int stepSize)
  {
    productList[index].prVarientList?[indexAT].quantity??0 -stepSize;
    notifyListeners();
  }

  get getTotalProducts => totalProducts;

  setProductTotal(String total) {
    totalProducts = total;
    notifyListeners();
  }

  Future<void> setFavorateNow({
    required Function update,
    required BuildContext context,
    required int index,
    required Product model,
    required Function showSanckBarNow,
  }) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        index == -1
            ? model.isFavLoading = true
            : productList[index].isFavLoading = true;
        update();
        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_ID: model.id,
        };
        Map<String, dynamic> result = await FavRepository.setFavorate(
          parameter: parameter,
        );

        showSanckBarNow(
          result,
          model,
          index,
        );
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      isNetworkAvail = false;
      update();
    }
  }

  removeFav(
    int index,
    Product model,
    BuildContext context,
    Function updateNow,
    List<Product>? productList,
    Function showSanckBarNowForRemove,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        index == -1
            ? model.isFavLoading = true
            : productList![index].isFavLoading = true;
        updateNow();

        var parameter = {
          USER_ID: CUR_USERID,
          PRODUCT_ID: model.id,
        };
        Response response =
            await post(removeFavApi, body: parameter, headers: headers).timeout(
          const Duration(seconds: timeOut),
        );
        showSanckBarNowForRemove(
          response,
          index,
          model,
        );
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      isNetworkAvail = false;
      updateNow();
    }
  }

  setFav(
    int index,
    Product model,
    Function updateNow,
    BuildContext context,
    Function showSanckBarNowForAdd,
  ) async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      try {
        index == -1
            ? model.isFavLoading = true
            : productList[index].isFavLoading = true;

        updateNow();

        var parameter = {USER_ID: CUR_USERID, PRODUCT_ID: model.id};
        Response response =
            await post(setFavoriteApi, body: parameter, headers: headers)
                .timeout(const Duration(seconds: timeOut));

        showSanckBarNowForAdd(
          response,
          model,
          index,
        );
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      isNetworkAvail = false;

      updateNow();
    }
  }
}
