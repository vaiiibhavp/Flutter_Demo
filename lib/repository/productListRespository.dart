import 'dart:core';
import 'dart:developer';
import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';

class ProductListRepository {
  // get data for product list
  static Future<Map<String, dynamic>> getList({
    required var parameter,
  }) async {
    try {
      var responseData =
          await ApiBaseHelper().postAPICall(getProductApi, parameter);
      log("PARAMETER PRODUCT===${parameter}");
      log("URL===${getProductApi}");
      return responseData;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  // get data for section list
  static Future<Map<String, dynamic>> getSection({
    required var parameter,
  }) async {
    try {
      var responseData =
          await ApiBaseHelper().postAPICall(getSectionApi, parameter);

      return responseData;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }
}
