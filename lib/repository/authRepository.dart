import '../Helper/ApiBaseHelper.dart';
import '../Helper/Constant.dart';
import '../Helper/String.dart';

class AuthRepository {
  //
  //This method is used to fetch System policies {e.g. Privacy Policy, T&C etc..}
  static Future<Map<String, dynamic>> fetchLoginData({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var loginDetail =
          await ApiBaseHelper().postAPICall(getUserLoginApi, parameter);

      return loginDetail;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchSocialLoginData({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var loginDetail =
          await ApiBaseHelper().postAPICall(signUpUserApi, parameter);

      return loginDetail;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  //validate referl code
  static Future<Map<String, dynamic>> validateReferal({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var result =
          await ApiBaseHelper().postAPICall(validateReferalApi, parameter);

      return result;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchverificationData({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      print('verify param*****$parameter');
      var loginDetail =
          await ApiBaseHelper().postAPICall(getVerifyUserApi, parameter);
      print('login detail****$loginDetail');

      return loginDetail;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchSingUpData({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var loginDetail =
          await ApiBaseHelper().postAPICall(getUserSignUpApi, parameter);

      return loginDetail;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> fetchFetchReset({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var loginDetail =
          await ApiBaseHelper().postAPICall(getResetPassApi, parameter);

      print("login details reset****$loginDetail");

      return loginDetail;
    } on Exception catch (e) {
      throw ApiException('$errorMesaage${e.toString()}');
    }
  }
}
