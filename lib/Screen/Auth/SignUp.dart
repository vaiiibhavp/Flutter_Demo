  // ignore: file_names
import 'dart:async';
import 'dart:developer';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Provider/SettingProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Provider/addressProvider.dart';
import 'package:eshop_multivendor/Provider/authenticationProvider.dart';
import 'package:eshop_multivendor/Screen/NoInterNetWidget/NoInterNet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../Helper/Constant.dart';
import '../../Helper/String.dart';
import '../../Helper/routes.dart';
import '../../widgets/ButtonDesing.dart';
import '../../widgets/desing.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/systemChromeSettings.dart';
import '../Language/languageSettings.dart';
import '../../widgets/networkAvailablity.dart';
import '../../widgets/validation.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUp> with TickerProviderStateMixin {
  bool? _showPassword = true;
  bool visible = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final ccodeController = TextEditingController();
  final passwordController = TextEditingController();
  final referController = TextEditingController();
  final businessNameController = TextEditingController();
  final businessAddressController = TextEditingController();
  final gstNumberController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final areaC = TextEditingController();
  final cityC = TextEditingController();
  final landmarkC = TextEditingController();
  final countryC = TextEditingController();
  final stateC = TextEditingController();
  FocusNode? nameFocus,
      monoFocus,
      almonoFocus,
      addFocus,
      landFocus,
      locationFocus,
      cityFocus,
      areaFocus = FocusNode();
  int? selectedType = 1;

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  String? name,
      email,
      password,
      mobile,
      id,
      countrycode,
      city,
      area,
      pincode,
      address,
      latitude,
      longitude,
      referCode,
      friendCode;
  FocusNode?
      emailFocus,
      passFocus = FocusNode(),
      referFocus = FocusNode();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;

  void validateAndSubmit() async {
    if (validateAndSave()) {
      _playAnimation();
      checkNetwork();
    }
  }

  getUserDetails() async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    context
        .read<AuthenticationProvider>()
        .setMobileNumber(await settingsProvider.getPrefrence(MOBILE));
    context
        .read<AuthenticationProvider>()
        .setcountrycode(await settingsProvider.getPrefrence(COUNTRY_CODE));

    if (mounted) setState(() {});
  }

  setStateNow() {
    setState(() {});
  }

  Future<void> getCurrentLoc() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    context.read<AddressProvider>().latitude = position.latitude.toString();
    context.read<AddressProvider>().longitude = position.longitude.toString();
    await context
        .read<AddressProvider>()
        .getCities(false, context, setState, false, 0);
    List<Placemark> placemark = await placemarkFromCoordinates(
        double.parse(context.read<AddressProvider>().latitude!),
        double.parse(context.read<AddressProvider>().longitude!),
        localeIdentifier: 'en');

    context.read<AddressProvider>().state = placemark[0].administrativeArea;
    context.read<AddressProvider>().country = placemark[0].country;
    if (mounted) {
      setState(
            () {
          countryC.text = context.read<AddressProvider>().country!;
          stateC.text = context.read<AddressProvider>().state!;
        },
      );
    }
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> checkNetwork() async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      Future.delayed(Duration.zero).then(
        (value) => context.read<AuthenticationProvider>().getSingUPData().then(
          (
            value,
          ) async {

            log('SignUp ===${value}');
            bool error = value['error'] ?? false;
            String? msg = value['message'];
            await buttonController!.reverse();
            if (!error) {
              setSnackbar(
                  getTranslated(context, 'REGISTER_SUCCESS_MSG')!, context);
              var i = value['data'][0];
              log('REGISTER DATA===${value['data'][0]}');

              id = i[ID];
              name = i[USERNAME];
              email = i[EMAIL];
              mobile = i[MOBILE];
              CUR_USERID = id;
              UserProvider userProvider = context.read<UserProvider>();
              userProvider.setName(name ?? '');
              SettingProvider settingProvider = context.read<SettingProvider>();
              settingProvider.saveUserDetail(
                  id!,
                  name,
                  email,
                  phoneNumberController.text,
                  city,
                  area,
                  address,
                  pincode,
                  latitude,
                  longitude,
                  '',
                  i[TYPE],
                  context,
                  businessNameController.text,
                  businessAddressController.text,
                  gstNumberController.text);
              context.read<AddressProvider>().mobile = phoneNumberController.text;
              context.read<AddressProvider>().address = businessAddressController.text;
              context.read<AddressProvider>().name = name;
              context.read<AddressProvider>().addNewAddress(context, setStateNow,
                  false,0, false);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
            } else {
              setSnackbar(msg!, context);
            }
          },
        ),
      );
    } else {
      Future.delayed(const Duration(seconds: 2)).then(
        (_) async {
          if (mounted) {
            setState(
              () {
                isNetworkAvail = false;
              },
            );
          }
          await buttonController!.reverse();
        },
      );
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;
    form.save();
    if (form.validate()) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    SystemChromeSettings.setSystemButtomNavigationBarithTopAndButtom();
    SystemChromeSettings.setSystemUIOverlayStyleWithNoSpecification();

    buttonController!.dispose();
    super.dispose();
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  setStateNoInternate() async {
    _playAnimation();
    Future.delayed(const Duration(seconds: 2)).then(
      (_) async {
        isNetworkAvail = await isNetworkAvailable();
        if (isNetworkAvail) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (BuildContext context) => super.widget,
            ),
          );
        } else {
          await buttonController!.reverse();
          if (mounted) setState(() {});
        }
      },
    );
  }

  Widget registerTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 60.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          getTranslated(context, 'Create a new account')!,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.fontColor,
                fontWeight: FontWeight.bold,
                fontSize: textFontSize23,
                fontFamily: 'ubuntu',
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }

  signUpSubTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 13.0,
      ),
      child: Text(
        getTranslated(context, 'INFO_FOR_NEW_ACCOUNT')!,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.38),
              fontWeight: FontWeight.bold,
              fontFamily: 'ubuntu',
            ),
      ),
    );
  }

  setUserName() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        controller: nameController,
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp('[ ]')),
        ],
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'NAMEHINT_LBL'),
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: textFontSize13),
            filled: true,
            fillColor: Theme.of(context).colorScheme.lightWhite,
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            border: InputBorder.none),
        validator: (val) => StringValidation.validateUserName(
            val!,
            getTranslated(context, 'USER_REQUIRED'),
            getTranslated(context, 'USER_LENGTH'),
            getTranslated(context, 'INVALID_USERNAME_LBL')),
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setUserName(value);
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus!, emailFocus);
        },
      ),
    );
  }

  setBusinessName() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        controller: businessNameController,
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z\s]+$')),
        ],
        decoration: InputDecoration(

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'Business Name'),
            filled: true,
            fillColor: Theme.of(context).colorScheme.lightWhite,
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: textFontSize13),

            border: InputBorder.none),
        validator: (val) => StringValidation.validatePincode(
          val!,
          getTranslated(context, 'Business Name'),
        ),
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setBusinessName(value);
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus!, emailFocus);
        },
      ),
    );
  }

  setBusinessAddress() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        controller: businessAddressController,
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        // inputFormatters: [
        //   FilteringTextInputFormatter.deny(RegExp('[ ]')),
        // ],
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'Business Address'),
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: textFontSize13),
            filled: true,
            fillColor: Theme.of(context).colorScheme.lightWhite,
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            border: InputBorder.none),
        validator: (val) => StringValidation.validatePincode(
          val!,
          getTranslated(context, 'Business Address'),
        ),
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setBusinessAddress(value);
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus!, emailFocus);
        },
      ),
    );
  }

  setGSTNumber() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        controller: gstNumberController,
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp('[ ]')),
          CapitalCaseTextFormatter(),
          LengthLimitingTextInputFormatter(15)
        ],
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'GST Number'),
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: textFontSize13),
            filled: true,
            fillColor: Theme.of(context).colorScheme.lightWhite,
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            border: InputBorder.none),
        validator: (val) {
          RegExp gstRegex = RegExp(
              r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

          if (val!.isEmpty) {
            return 'GST Number';
          } else if (!gstRegex.hasMatch(val)) {
            return 'Enter Valid GST Number';
          }
          return null;
        },
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setGstNumber(value);
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus!, emailFocus);
        },
      ),
    );
  }

  setPhoneNumber() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
        controller: phoneNumberController,
        focusNode: nameFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10)
        ],
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'Phone Number'),
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: textFontSize13),
            filled: true,
            fillColor: Theme.of(context).colorScheme.lightWhite,
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            border: InputBorder.none),
        validator: (val) => StringValidation.validatePincode(
          val!,
          getTranslated(context, 'Phone Number'),
        ),
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setMobileNumber(value);
          context
              .read<SettingProvider>()
              .setPrefrence(MOBILE, value.toString());
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, nameFocus!, emailFocus);
        },
      ),
    );
  }

  setEmail() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.emailAddress,
        focusNode: emailFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp('[ ]')),
        ],
        controller: emailController,
        decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'EMAILHINT_LBL'),
            hintStyle: TextStyle(
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                fontSize: textFontSize13),
            filled: true,
            fillColor: Theme.of(context).colorScheme.lightWhite,
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            enabledBorder:  OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            errorBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.circular(circularBorderRadius10)
            ),
            border: InputBorder.none),
        validator: (val) => StringValidation.validateEmail(
          val!,
          getTranslated(context, 'EMAIL_REQUIRED'),
          getTranslated(context, 'VALID_EMAIL'),
        ),
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setSingUp(value);
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(
            context,
            emailFocus!,
            passFocus,
          );
        },
      ),
    );
  }

  setCities() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.lightWhite,
          borderRadius: BorderRadius.circular(circularBorderRadius10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: GestureDetector(
            child: InputDecorator(
              decoration: InputDecoration(
                fillColor: Theme.of(context).colorScheme.white,
                isDense: true,
                border: InputBorder.none,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          getTranslated(context, 'CITYSELECT_LBL')!,
                          style:
                          Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontFamily: 'ubuntu',
                          ),
                        ),
                        Text(
                          context.read<AddressProvider>().selCityPos != null &&
                              context.read<AddressProvider>().selCityPos !=
                                  -1
                              ? context.read<AddressProvider>().selectedCity!
                              : context.read<AddressProvider>().cityEnable &&
                              IS_SHIPROCKET_ON == '1'
                              ? getTranslated(context, 'OTHER_CITY_LBL')!
                              : '',
                          style: TextStyle(
                            color: context.read<AddressProvider>().selCityPos !=
                                null
                                ? Theme.of(context).colorScheme.fontColor
                                : Colors.grey,
                            fontFamily: 'ubuntu',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_right,
                  )
                ],
              ),
            ),
            onTap: () {
              cityDialog();
            },
          ),
        ),
      ),
    );
  }

  setArea() {
    if (!context.read<AddressProvider>().cityEnable) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.lightWhite,
            borderRadius: BorderRadius.circular(circularBorderRadius10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
            ),
            child: GestureDetector(
              child: InputDecorator(
                decoration: InputDecoration(
                    fillColor: Theme.of(context).colorScheme.white,
                    isDense: true,
                    border: InputBorder.none),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            getTranslated(context, 'AREASELECT_LBL')!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            context.read<AddressProvider>().selAreaPos !=
                                null &&
                                context
                                    .read<AddressProvider>()
                                    .selAreaPos !=
                                    -1
                                ? context.read<AddressProvider>().selectedArea!
                                : context.read<AddressProvider>().areaEnable &&
                                IS_SHIPROCKET_ON == '1'
                                ? getTranslated(context, 'OTHER_AREA_LBL')!
                                : '',
                            style: TextStyle(
                              color:
                              context.read<AddressProvider>().selAreaPos !=
                                  null
                                  ? Theme.of(context).colorScheme.fontColor
                                  : Colors.grey,
                              fontFamily: 'ubuntu',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right),
                  ],
                ),
              ),
              onTap: () {
                if (context.read<AddressProvider>().selCityPos != null &&
                    context.read<AddressProvider>().selCityPos != -1) {
                  areaDialog();
                }
              },
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  areaDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            //context.read<AddressProvider>().areaState = setStater;
            return WillPopScope(
              onWillPop: () async {
                // setStater() {
                context.read<AddressProvider>().areaOffset = 0;
                context.read<AddressProvider>().areaController.clear();
                //}
                setStater(() {});
                return true;
              },
              child: AlertDialog(
                contentPadding: const EdgeInsets.all(0.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(circularBorderRadius5),
                  ),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                      child: Text(
                        getTranslated(context, 'AREASELECT_LBL')!,
                        style: Theme.of(this.context)
                            .textTheme
                            .titleMedium!
                            .copyWith(
                          fontFamily: 'ubuntu',
                          color: Theme.of(context).colorScheme.fontColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                            child: TextField(
                              controller: context
                                  .read<AddressProvider>()
                                  .areaController,
                              autofocus: false,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                              ),
                              decoration: InputDecoration(
                                contentPadding:
                                const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                                hintText: getTranslated(context, 'SEARCH_LBL'),
                                hintStyle: TextStyle(
                                    color: colors.primary.withOpacity(0.5)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: IconButton(
                            onPressed: () async {
                              setStater(
                                    () async {
                                  context
                                      .read<AddressProvider>()
                                      .isLoadingMoreArea = true;
                                  await context.read<AddressProvider>().getArea(
                                    context.read<AddressProvider>().city,
                                    true,
                                    true,
                                    context,
                                    setStater,
                                    false,
                                  );
                                },
                              );
                              FocusScope.of(context).unfocus();
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.search,
                              size: 20,
                            ),
                          ),
                        )
                      ],
                    ),
                    Divider(color: Theme.of(context).colorScheme.lightBlack),
                    context.read<AddressProvider>().areaLoading
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 50.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                        : Flexible(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (IS_SHIPROCKET_ON == '1')
                                InkWell(
                                  onTap: () {
                                    setStater(() {
                                      context
                                          .read<AddressProvider>()
                                          .selAreaPos = -1;

                                      context
                                          .read<AddressProvider>()
                                          .selArea = null;

                                      context
                                          .read<AddressProvider>()
                                          .pincodeC!
                                          .clear();
                                      context
                                          .read<AddressProvider>()
                                          .selectedArea = null;

                                      context
                                          .read<AddressProvider>()
                                          .areaEnable = true;
                                      Navigator.of(context).pop();
                                      setState(() {});
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        getTranslated(
                                            context, 'OTHER_AREA_LBL')!,
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                    ),
                                  ),
                                ),
                              (context
                                  .read<AddressProvider>()
                                  .areaSearchList
                                  .isNotEmpty)
                                  ? Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: getAreaList(setStater),
                              )
                                  : Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 20.0),
                                child:
                                DesignConfiguration.getNoItem(
                                    context),
                              ),
                              DesignConfiguration.showCircularProgress(
                                context
                                    .read<AddressProvider>()
                                    .isLoadingMoreArea!,
                                colors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  getAreaList(StateSetter stateSetter) {
    return context
        .read<AddressProvider>()
        .areaSearchList
        .asMap()
        .map(
          (index, element) => MapEntry(
        index,
        InkWell(
          onTap: () {
            if (mounted) {
              context.read<AddressProvider>().areaOffset = 0;
              context.read<AddressProvider>().areaController.clear();

              stateSetter(
                    () {
                  context.read<AddressProvider>().selAreaPos = index;
                  context.read<AddressProvider>().areaEnable = false;
                  areaC.clear();
                  context.read<AddressProvider>().areaName = null;

                  context.read<AddressProvider>().selArea =
                  context.read<AddressProvider>().areaSearchList[
                  context.read<AddressProvider>().selAreaPos!];
                  context.read<AddressProvider>().area =
                      context.read<AddressProvider>().selArea!.id;
                  context.read<AddressProvider>().pincodeC?.text =
                  context.read<AddressProvider>().selArea!.pincode!;
                  context.read<AddressProvider>().selectedArea = context
                      .read<AddressProvider>()
                      .areaSearchList[
                  context.read<AddressProvider>().selAreaPos!]
                      .name!;
                },
              );
              Navigator.of(context).pop();
              setState(() {});
              /*context.read<AddressProvider>().getArea(
                        context.read<AddressProvider>().city,
                        false,
                        true,
                        context,
                        setStateNow,
                        widget.update!,
                      );*/
            }
          },
          child: SizedBox(
            width: double.maxFinite,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.read<AddressProvider>().areaSearchList[index].name!,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontFamily: 'ubuntu',
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .values
        .toList();
  }

  cityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStater) {
            // context.read<AddressProvider>().cityState = setStater;

            return AlertDialog(
              contentPadding: const EdgeInsets.all(0.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(circularBorderRadius5),
                ),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 0, 0),
                    child: Text(
                      getTranslated(context, 'CITYSELECT_LBL')!,
                      style: Theme.of(this.context)
                          .textTheme
                          .titleMedium!
                          .copyWith(
                          fontFamily: 'ubuntu',
                          color: Theme.of(context).colorScheme.fontColor),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: TextField(
                            controller:
                            context.read<AddressProvider>().cityController,
                            autofocus: false,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                            ),
                            decoration: InputDecoration(
                              contentPadding:
                              const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
                              hintText: getTranslated(context, 'SEARCH_LBL'),
                              hintStyle: TextStyle(
                                  color: colors.primary.withOpacity(0.5)),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: IconButton(
                          onPressed: () async {
                            setStater(
                                  () async {
                                context
                                    .read<AddressProvider>()
                                    .isLoadingMoreCity = true;
                                await context.read<AddressProvider>().getCities(
                                  true,
                                  context,
                                  setStater,
                                  false,
                                  0,
                                );
                              },
                            );

                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.search,
                            size: 20,
                          ),
                        ),
                      )
                    ],
                  ),
                  context.read<AddressProvider>().cityLoading
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 50.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: SingleChildScrollView(
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                if (IS_SHIPROCKET_ON == '1')
                                  InkWell(
                                    onTap: () {
                                      setStater(() {
                                        context
                                            .read<AddressProvider>()
                                            .isArea = false;
                                        context
                                            .read<AddressProvider>()
                                            .selAreaPos = null;
                                        context
                                            .read<AddressProvider>()
                                            .selArea = null;
                                        context
                                            .read<AddressProvider>()
                                            .pincodeC!
                                            .text = '';
                                        context
                                            .read<AddressProvider>()
                                            .cityEnable = true;
                                        context
                                            .read<AddressProvider>()
                                            .selCityPos = -1;
                                        Navigator.of(context).pop();
                                      });
                                      setState(() {});
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          getTranslated(
                                              context, 'OTHER_CITY_LBL')!,
                                          textAlign: TextAlign.start,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                (context
                                    .read<AddressProvider>()
                                    .citySearchLIst
                                    .isNotEmpty)
                                    ? Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: getCityList(setStater),
                                )
                                    : Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  child:
                                  DesignConfiguration.getNoItem(
                                      context),
                                ),
                                Center(
                                  child: DesignConfiguration
                                      .showCircularProgress(
                                    context
                                        .read<AddressProvider>()
                                        .isLoadingMoreCity??false,
                                    colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            DesignConfiguration.showCircularProgress(
                              context.read<AddressProvider>().isProgress,
                              colors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  getCityList(StateSetter setStater) {
    return context
        .read<AddressProvider>()
        .citySearchLIst
        .asMap()
        .map(
          (index, element) => MapEntry(
        index,
        InkWell(
          onTap: () {
            if (mounted) {
              setStater(
                    () {
                  context.read<AddressProvider>().isArea = false;
                  context.read<AddressProvider>().area = null;
                  context.read<AddressProvider>().selCityPos = index;
                  context.read<AddressProvider>().selectedArea = null;
                  context.read<AddressProvider>().selAreaPos = -1;
                  context.read<AddressProvider>().selAreaPos = null;
                  context.read<AddressProvider>().selArea = null;
                  context.read<AddressProvider>().pincodeC?.text = '';
                  cityC.clear();
                  context.read<AddressProvider>().cityName = null;
                  context.read<AddressProvider>().cityEnable = false;
                  context.read<AddressProvider>().areaName = null;
                  context.read<AddressProvider>().areaEnable = false;
                  areaC.clear();
                  Navigator.of(context).pop();
                },
              );

              context.read<AddressProvider>().city = context
                  .read<AddressProvider>()
                  .citySearchLIst[
              context.read<AddressProvider>().selCityPos!]
                  .id;

              context.read<AddressProvider>().selectedCity = context
                  .read<AddressProvider>()
                  .citySearchLIst[
              context.read<AddressProvider>().selCityPos!]
                  .name;
              context.read<AddressProvider>().areaSearchList.clear();
              context.read<AddressProvider>().getArea(
                context.read<AddressProvider>().city,
                true,
                true,
                context,
                setState,
                false
              );
              setState(() {});
            }
          },
          child: SizedBox(
            width: double.maxFinite,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.read<AddressProvider>().citySearchLIst[index].name!,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontFamily: 'ubuntu',
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .values
        .toList();
  }

  Widget setCityName() {
    if (context.read<AddressProvider>().cityEnable && IS_SHIPROCKET_ON == '1') {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                    focusNode: cityFocus,
                    controller: cityC,
                    validator: (val) => StringValidation.validateField(
                        val!, getTranslated(context, 'FIELD_REQUIRED')),
                    onSaved: (String? value) {
                      context.read<AddressProvider>().cityName = value;
                    },
                    decoration: InputDecoration(
                      label: Text(getTranslated(context, 'CITY_NAME_LBL')!),
                      fillColor: Theme.of(context).colorScheme.white,
                      isDense: true,
                      hintText: getTranslated(context, 'CITY_NAME_LBL')!,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget setAreaName() {
    if (IS_SHIPROCKET_ON == '1' && context.read<AddressProvider>().areaEnable ||
        context.read<AddressProvider>().cityEnable) {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                  ),
                  child: TextFormField(
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.fontColor),
                    focusNode: areaFocus,
                    controller: areaC,
                    validator: (val) => StringValidation.validateField(
                        val!, getTranslated(context, 'FIELD_REQUIRED')),
                    onSaved: (String? value) {
                      context.read<AddressProvider>().areaName = value;
                    },
                    decoration: InputDecoration(
                      label: Text(getTranslated(context, 'AREA_NAME_LBL')!),
                      hintStyle:
                      Theme.of(context).textTheme.titleSmall!.copyWith(),
                      fillColor: Theme.of(context).colorScheme.white,
                      isDense: true,
                      hintText: getTranslated(context, 'AREA_NAME_LBL')!,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  setPincode() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller: context.read<AddressProvider>().pincodeC,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSaved: (String? value) {
              context.read<AddressProvider>().pincode = value.toString();
              context.read<AddressProvider>().pincodeC = TextEditingController(text: value.toString());

            },
            validator: (val) => StringValidation.validateField(
                val!, getTranslated(context, 'FIELD_REQUIRED')),
            decoration: InputDecoration(
              label: Text(
                getTranslated(context, 'PINCODEHINT_LBL')!,
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),

              filled: true,
              fillColor: Theme.of(context).colorScheme.lightWhite,
              focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              enabledBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              isDense: true,
              hintText: getTranslated(context, 'PINCODEHINT_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  setLandmark() {
    return TextFormField(
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      focusNode: landFocus,
      controller: landmarkC,
      style: Theme.of(context)
          .textTheme
          .titleSmall!
          .copyWith(color: Theme.of(context).colorScheme.fontColor),
      validator: (val) => StringValidation.validateField(
          val!, getTranslated(context, 'FIELD_REQUIRED')),
      onSaved: (String? value) {
        context.read<AddressProvider>().landmark = value;
      },
      decoration: const InputDecoration(
        hintText: LANDMARK,
      ),
    );
  }

  setStateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: stateC,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            readOnly: false,
            onChanged: (v) => setState(
                  () {
                context.read<AddressProvider>().state = v;
              },
            ),
            onSaved: (String? value) {
              context.read<AddressProvider>().state = value;
            },
            validator: (val) => StringValidation.validateField(
              val!,
              getTranslated(context, 'FIELD_REQUIRED'),
            ),
            decoration: InputDecoration(

              label: Text(
                getTranslated(context, 'STATE_LBL')!,
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.lightWhite,
              focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              enabledBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              isDense: true,
              hintText: getTranslated(context, 'STATE_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  setCountry() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            controller: countryC,
            readOnly: false,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            onSaved: (String? value) {
              context.read<AddressProvider>().country = value;
            },
            validator: (val) => StringValidation.validateField(
              val!,
              getTranslated(context, 'FIELD_REQUIRED'),
            ),
            decoration: InputDecoration(
              label: Text(
                getTranslated(context, 'COUNTRY_LBL')!,
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.lightWhite,
              focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              enabledBorder:  OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(circularBorderRadius10)
              ),
              isDense: true,
              hintText: getTranslated(context, 'COUNTRY_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  typeOfAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
        borderRadius: BorderRadius.circular(circularBorderRadius5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: InkWell(
              child: Row(
                children: [
                  Radio(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    groupValue: selectedType,
                    activeColor: Theme.of(context).colorScheme.fontColor,
                    value: 1,
                    onChanged: (dynamic val) {
                      if (mounted) {
                        setState(
                              () {
                            selectedType = val;
                            context.read<AddressProvider>().type = HOME;
                          },
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      getTranslated(context, 'HOME_LBL')!,
                      style: const TextStyle(
                        fontFamily: 'ubuntu',
                      ),
                    ),
                  )
                ],
              ),
              onTap: () {
                if (mounted) {
                  setState(
                        () {
                      selectedType = 1;
                      context.read<AddressProvider>().type = HOME;
                    },
                  );
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: InkWell(
              child: Row(
                children: [
                  Radio(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    groupValue: selectedType,
                    activeColor: Theme.of(context).colorScheme.fontColor,
                    value: 2,
                    onChanged: (dynamic val) {
                      if (mounted) {
                        setState(
                              () {
                            selectedType = val;
                            context.read<AddressProvider>().type = OFFICE;
                          },
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      getTranslated(context, 'OFFICE_LBL')!,
                      style: const TextStyle(
                        fontFamily: 'ubuntu',
                      ),
                    ),
                  )
                ],
              ),
              onTap: () {
                if (mounted) {
                  setState(
                        () {
                      selectedType = 2;
                      context.read<AddressProvider>().type = OFFICE;
                    },
                  );
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: InkWell(
              child: Row(
                children: [
                  Radio(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    groupValue: selectedType,
                    activeColor: Theme.of(context).colorScheme.fontColor,
                    value: 3,
                    onChanged: (dynamic val) {
                      if (mounted) {
                        setState(
                              () {
                            selectedType = val;
                            context.read<AddressProvider>().type = OTHER;
                          },
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: Text(
                      getTranslated(context, 'OTHER_LBL')!,
                      style: const TextStyle(
                        fontFamily: 'ubuntu',
                      ),
                    ),
                  )
                ],
              ),
              onTap: () {
                if (mounted) {
                  setState(
                        () {
                      selectedType = 3;
                      context.read<AddressProvider>().type = OTHER;
                    },
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }

  defaultAdd() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.white,
        borderRadius: BorderRadius.circular(circularBorderRadius5),
      ),
      child: SwitchListTile(
        value: context.read<AddressProvider>().checkedDefault,
        activeColor: Theme.of(context).colorScheme.secondary,
        dense: true,
        onChanged: (newValue) {
          if (mounted) {
            setState(
                  () {
                context.read<AddressProvider>().checkedDefault = newValue;
              },
            );
          }
        },
        title: Text(
          getTranslated(context, 'DEFAULT_ADD')!,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            color: Theme.of(context).colorScheme.lightBlack,
            fontWeight: FontWeight.bold,
            fontFamily: 'ubuntu',
          ),
        ),
      ),
    );
  }


  setRefer() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Container(
        height: 53,
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.lightWhite,
          borderRadius: BorderRadius.circular(circularBorderRadius10),
        ),
        alignment: Alignment.center,
        child: TextFormField(
          style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
              fontWeight: FontWeight.bold,
              fontSize: textFontSize13),
          keyboardType: TextInputType.text,
          focusNode: referFocus,
          controller: referController,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp('[ ]')),
          ],
          onSaved: (String? value) {
            context.read<AuthenticationProvider>().setfriendCode(value);
          },
          onFieldSubmitted: (v) {
            referFocus!.unfocus();
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 5,
            ),
            hintText: getTranslated(context, 'REFER'),
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              fontSize: textFontSize13,
            ),
            fillColor: Theme.of(context).colorScheme.lightWhite,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  setPass() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        style: TextStyle(
            color: Theme.of(context).colorScheme.fontColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            fontSize: textFontSize13),
        keyboardType: TextInputType.text,
        obscureText: _showPassword!,
        controller: passwordController,
        focusNode: passFocus,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp('[ ]')),
        ],
        validator: (val) => StringValidation.validatePass(
            val!,
            getTranslated(context, 'PWD_REQUIRED'),
            getTranslated(context, 'PASSWORD_VALIDATION'),
            onlyRequired: false),
        onSaved: (String? value) {
          context.read<AuthenticationProvider>().setsinUpPassword(value);
        },
        onFieldSubmitted: (v) {
          _fieldFocusChange(context, passFocus!, referFocus);
        },
        decoration: InputDecoration(
          errorMaxLines: 4,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 5,
          ),
          suffixIcon: InkWell(
            onTap: () {
              setState(() {
                _showPassword = !_showPassword!;
              });
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 10.0),
              child: Icon(
                !_showPassword! ? Icons.visibility : Icons.visibility_off,
                color:
                    Theme.of(context).colorScheme.fontColor.withOpacity(0.4),
                size: 22,
              ),
            ),
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 40, maxHeight: 20),
          hintText: getTranslated(context, 'PASSHINT_LBL')!,
          hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.fontColor.withOpacity(0.3),
              fontWeight: FontWeight.bold,
              fontSize: textFontSize13),
          filled: true,
          fillColor: Theme.of(context).colorScheme.lightWhite,
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(circularBorderRadius10)
          ),
          enabledBorder:  OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(circularBorderRadius10)
          ),
          errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: BorderRadius.circular(circularBorderRadius10)
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  verifyBtn() {
    return Center(
      child: AppBtn(
        title: getTranslated(context, 'SAVE_LBL'),
        btnAnim: buttonSqueezeanimation,
        btnCntrl: buttonController,
        onBtnSelected: () async {
          validateAndSubmit();
        },
      ),
    );
  }

  loginTxt() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 25.0, bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            getTranslated(context, 'ALREADY_A_CUSTOMER')!,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.fontColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ubuntu',
                ),
          ),
          InkWell(
            onTap: () {
              Routes.navigateToLoginScreen(context);
            },
            child: Text(
              getTranslated(context, 'LOG_IN_LBL')!,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ubuntu',
                  ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    SystemChromeSettings.setSystemButtomNavigationBarithTopAndButtom();
    SystemChromeSettings.setSystemUIOverlayStyleWithNoSpecification();

    super.initState();
    getUserDetails();
    getCurrentLoc();
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

    context.read<AuthenticationProvider>().generateReferral(
          context,
          setStateNow,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.white,
      key: _scaffoldKey,
      body: isNetworkAvail
          ? SingleChildScrollView(
              padding: EdgeInsets.only(
                  top: 23,
                  left: 23,
                  right: 23,
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Form(
                key: _formkey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    getLogo(),
                    registerTxt(),
                    signUpSubTxt(),
                    setBusinessName(),
                    setBusinessAddress(),
                    setGSTNumber(),
                    setPhoneNumber(),
                    setUserName(),
                    setEmail(),
                    setPass(),
                    const SizedBox(height: 10),
                    setCities(),
                    setCityName(),
                    const SizedBox(height: 10),
                    setArea(),
                    setAreaName(),
                    const SizedBox(height: 10),
                    setPincode(),
                    const SizedBox(height: 10),
                    setStateField(),
                    const SizedBox(height: 10),
                    setCountry(),
                    typeOfAddress(),
                    defaultAdd(),

                    // setRefer(),
                    verifyBtn(),
                    loginTxt(),
                  ],
                ),
              ),
            )
          : NoInterNet(
              setStateNoInternate: setStateNoInternate,
              buttonSqueezeanimation: buttonSqueezeanimation,
              buttonController: buttonController,
            ),
    );
  }

  Widget getLogo() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 60),
      child: SvgPicture.asset(
        DesignConfiguration.setSvgPath('homelogo'),
        alignment: Alignment.center,
        height: 90,
        width: 90,
        fit: BoxFit.contain,
      ),
    );
  }
}

class CapitalCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
