import 'dart:core';
import 'package:eshop_multivendor/Screen/AddAddress/widget/saveBtn.dart';
import 'package:eshop_multivendor/Screen/Map/Map.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../Helper/Color.dart';
import '../../Helper/Constant.dart';
import '../../Helper/String.dart';
import '../../Model/User.dart';
import '../../Provider/CartProvider.dart';
import '../../Provider/addressProvider.dart';
import '../../widgets/appBar.dart';
import '../../widgets/desing.dart';
import '../Language/languageSettings.dart';
import '../../widgets/networkAvailablity.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/validation.dart';
import '../NoInterNetWidget/NoInterNet.dart';

class AddAddress extends StatefulWidget {
  final bool? update;
  final int? index;
  final bool fromProfile;

  const AddAddress(
      {Key? key, this.update, this.index, required this.fromProfile})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateAddress();
  }
}

class StateAddress extends State<AddAddress> with TickerProviderStateMixin {
  String? isDefault;
  bool onlyOneTimePress = true;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController? nameC,
      mobileC,
      addressC,
      landmarkC,
      stateC,
      countryC,
      altMobC,
      cityC,
      areaC;
  int? selectedType = 1;
  Animation? buttonSqueezeanimation;
  FocusNode? nameFocus,
      monoFocus,
      almonoFocus,
      addFocus,
      landFocus,
      locationFocus,
      cityFocus,
      areaFocus = FocusNode();
  final ScrollController _cityScrollController = ScrollController();
  final ScrollController _areaScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    context.read<AddressProvider>().buttonController = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: context.read<AddressProvider>().buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cityScrollController.addListener(_scrollListener);
        _areaScrollController.addListener(_areaScrollListener);
        callApi();
        mobileC = TextEditingController();
        nameC = TextEditingController();
        altMobC = TextEditingController();
        context.read<AddressProvider>().pincodeC = TextEditingController();
        addressC = TextEditingController();
        stateC = TextEditingController();
        countryC = TextEditingController();
        landmarkC = TextEditingController();
        cityC = TextEditingController();
        areaC = TextEditingController();

        if (widget.update!) {
          User item = context.read<CartProvider>().addressList[widget.index!];
          mobileC!.text = item.mobile!;
          nameC!.text = item.name!;
          altMobC!.text = item.altMob!;
          landmarkC!.text = item.landmark!;
          context.read<AddressProvider>().pincodeC!.text = item.pincode!;
          addressC!.text = item.address!;
          stateC!.text = item.state!;
          countryC!.text = item.country!;
          stateC!.text = item.state!;
          context.read<AddressProvider>().setLatitude(item.latitude);
          context.read<AddressProvider>().setLongitude(item.longitude);
          context.read<AddressProvider>().selectedCity = item.city!;
          context.read<AddressProvider>().selectedArea = item.area!;
          cityC!.text = item.city!;
          areaC!.text = item.area!;

          context.read<AddressProvider>().type = item.type;
          print('item cityId******${item.cityId}');
          if (item.cityId != '0') {
            /* context.read<AddressProvider>().selCityPos =
                int.parse(item.cityId!);*/
          } else {
            if (IS_SHIPROCKET_ON == '1') {
              context.read<AddressProvider>().cityEnable = true;
            }
          }
          context.read<AddressProvider>().city = item.cityId;

          if (item.areaId != '0') {
            /* context.read<AddressProvider>().selAreaPos =
                int.parse(item.areaId!);*/
          } else {
            if (IS_SHIPROCKET_ON == '1') {
              context.read<AddressProvider>().areaEnable = true;
            }
          }
          context.read<AddressProvider>().area = item.areaId;

          /* context.read<AddressProvider>().selAreaPos = int.parse(item.cityId!);
        context.read<AddressProvider>().selCityPos = int.parse(item.areaId!);
        context.read<AddressProvider>().type = item.type;
        context.read<AddressProvider>().city = item.cityId;
        context.read<AddressProvider>().area = item.areaId;*/

          if (context.read<AddressProvider>().type!.toLowerCase() ==
              HOME.toLowerCase()) {
            selectedType = 1;
          } else if (context.read<AddressProvider>().type!.toLowerCase() ==
              OFFICE.toLowerCase()) {
            selectedType = 2;
          } else {
            selectedType = 3;
          }

          context.read<AddressProvider>().checkedDefault =
              item.isDefault == '1' ? true : false;
          setState(() {});
        } else {
          context.read<AddressProvider>().selectedArea = null;
          context.read<AddressProvider>().selectedCity = null;
          context.read<AddressProvider>().selAreaPos = -1;
          context.read<AddressProvider>().selCityPos = -1;
          context.read<AddressProvider>().cityName = null;
          context.read<AddressProvider>().areaName = null;
          context.read<AddressProvider>().city = null;
          context.read<AddressProvider>().area = null;
          context.read<AddressProvider>().pincode = null;
          context.read<AddressProvider>().cityEnable = false;
          context.read<AddressProvider>().areaEnable = false;

          getCurrentLoc();
        }
      }
      setState(() {});
    });
  }

  setStateNow() {
    setState(() {});
  }

  _scrollListener() async {
    if (_cityScrollController.offset >=
            _cityScrollController.position.maxScrollExtent &&
        !_cityScrollController.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            context.read<AddressProvider>().isLoadingMoreCity = true;
            context.read<AddressProvider>().isProgress = true;
          },
        );

        /* context.read<AddressProvider>().cityState!(
          () {

          },
        );*/

        await context
            .read<AddressProvider>()
            .getCities(false, context, setState, widget.update, widget.index);
      }
    }
  }

  _areaScrollListener() async {
    if (_areaScrollController.offset >=
            _areaScrollController.position.maxScrollExtent &&
        !_areaScrollController.position.outOfRange) {
      if (mounted) {
        setState(
          () {
            context.read<AddressProvider>().isLoadingMoreArea = true;
          },
        );
        await context.read<AddressProvider>().getArea(
              context.read<AddressProvider>().city,
              false,
              false,
              context,
              setState,
              widget.update!,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: getSimpleAppBar(getTranslated(context, 'ADDRESS_LBL')!, context),
      body: isNetworkAvail
          ? _showContent()
          : NoInterNet(
              setStateNoInternate: setStateNoInternate,
              buttonSqueezeanimation: buttonSqueezeanimation,
              buttonController:
                  context.read<AddressProvider>().buttonController,
            ),
    );
  }

  setStateNoInternate() async {
    _playAnimation();

    Future.delayed(const Duration(seconds: 2)).then(
      (_) async {
        isNetworkAvail = await isNetworkAvailable();
        if (isNetworkAvail) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (BuildContext context) => super.widget),
          );
        } else {
          await context.read<AddressProvider>().buttonController!.reverse();
          if (mounted) {
            setState(
              () {},
            );
          }
        }
      },
    );
  }

  void validateAndSubmit() async {
    if (validateAndSave()) {
      checkNetwork();
    }
  }

  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();

    if (form.validate()) {
      if ((!context.read<AddressProvider>().cityEnable &&
              IS_SHIPROCKET_ON != '1') &&
          (context.read<AddressProvider>().city == null ||
              context.read<AddressProvider>().city!.isEmpty)) {
        // if (cityName == null) {
        setSnackbar(getTranslated(context, 'cityWarning')!, context);
        // }
      } else if ((IS_SHIPROCKET_ON != '1') &&
          (!context.read<AddressProvider>().areaEnable ||
              !context.read<AddressProvider>().cityEnable) &&
          (context.read<AddressProvider>().area == null ||
              context.read<AddressProvider>().area!.isEmpty)) {
        // if (areaName == null) {
        setSnackbar(getTranslated(context, 'areaWarning')!, context);
        // }
      } else if (context.read<AddressProvider>().latitude == null ||
          context.read<AddressProvider>().longitude == null) {
        setSnackbar(getTranslated(context, 'locationWarning')!, context);
      } else {
        return true;
      }
    }

    return false;
  }

/*  bool validateAndSave() {
    print(
        "validate****${context.read<AddressProvider>().cityEnable}*****${context.read<AddressProvider>().areaName}*****${context.read<AddressProvider>().area}******${!context.read<AddressProvider>().cityEnable || context.read<AddressProvider>().areaName == null || (context.read<AddressProvider>().area == null || context.read<AddressProvider>().area!.isEmpty)}");
    final form = _formkey.currentState!;

    form.save();

    if (form.validate()) {
      if (!context.read<AddressProvider>().cityEnable &&
          (context.read<AddressProvider>().city == null ||
              context.read<AddressProvider>().city!.isEmpty)) {
        // if (cityName == null) {
        setSnackbar(getTranslated(context, 'cityWarning')!, context);
        // }
      } else if ((!context.read<AddressProvider>().cityEnable &&
              !context.read<AddressProvider>().areaEnable) &&
          (context.read<AddressProvider>().area == null ||
              context.read<AddressProvider>().area!.isEmpty)) {
        // if (areaName == null) {
        print("check here");
        setSnackbar(getTranslated(context, 'areaWarning')!, context);
      } else if (context.read<AddressProvider>().latitude == null ||
          context.read<AddressProvider>().longitude == null) {
        setSnackbar(getTranslated(context, 'locationWarning')!, context);
      } else {
        print("check here2");
        return true;
      }
    }

    return false;
  }*/

/*  bool validateAndSave() {
    final form = _formkey.currentState!;

    form.save();
    if (form.validate()) {
      if ((!context.read<AddressProvider>().cityEnable &&
              IS_SHIPROCKET_ON != '1') ||
          (context.read<AddressProvider>().city == null ||
              context.read<AddressProvider>().city!.isEmpty)) {
        setSnackbar(getTranslated(context, 'cityWarning')!, context);
      } else if ((IS_SHIPROCKET_ON != '1') ||
          (!context.read<AddressProvider>().areaEnable ||
                  !context.read<AddressProvider>().cityEnable) &&
              (context.read<AddressProvider>().area == null ||
                  context.read<AddressProvider>().area!.isEmpty)) {
        setSnackbar(getTranslated(context, 'areaWarning')!, context);
      } else if (context.read<AddressProvider>().latitude == null ||
          context.read<AddressProvider>().longitude == null) {
        setSnackbar(getTranslated(context, 'locationWarning')!, context);
      } else {
        return true;
      }
    }
    return false;
  }*/

  Future<void> checkNetwork() async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      context.read<AddressProvider>().addNewAddress(context, setStateNow,
          widget.update, widget.index!, widget.fromProfile);
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
          await context.read<AddressProvider>().buttonController!.reverse();
        },
      );
    }
  }

  _fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode? nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  setUserName() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            focusNode: nameFocus,
            controller: nameC,
            textCapitalization: TextCapitalization.words,
            validator: (val) => StringValidation.validateUserName(
                val!,
                getTranslated(context, 'USER_REQUIRED'),
                getTranslated(context, 'USER_LENGTH'),
                getTranslated(context, 'INVALID_USERNAME_LBL')),
            onSaved: (String? value) {
              context.read<AddressProvider>().name = value;
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, nameFocus!, monoFocus);
            },
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            decoration: InputDecoration(
              label: Text(
                getTranslated(context, 'NAME_LBL')!,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontFamily: 'ubuntu',
                    ),
              ),
              fillColor: Theme.of(context).colorScheme.white,
              isDense: true,
              hintText: getTranslated(context, 'NAME_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  setMobileNo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller: mobileC,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            maxLength: 15,
            focusNode: monoFocus,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            validator: (val) => StringValidation.validateMob(
                val!,
                getTranslated(context, 'MOB_REQUIRED'),
                getTranslated(context, 'VALID_MOB')),
            onSaved: (String? value) {
              context.read<AddressProvider>().mobile = value;
            },
            onFieldSubmitted: (v) {
              _fieldFocusChange(context, monoFocus!, almonoFocus);
            },
            decoration: InputDecoration(
              counter: const SizedBox(),
              label: Text(
                getTranslated(context, 'MOBILEHINT_LBL')!,
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),
              fillColor: Theme.of(context).colorScheme.white,
              isDense: true,
              hintText: getTranslated(context, 'MOBILEHINT_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
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
                                        widget.update!,
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
                                controller: _areaScrollController,
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
                                      widget.update,
                                      widget.index,
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
                              controller: _cityScrollController,
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
                                              .isLoadingMoreCity!,
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
                      areaC!.clear();
                      context.read<AddressProvider>().areaName = null;

                      context.read<AddressProvider>().selArea =
                          context.read<AddressProvider>().areaSearchList[
                              context.read<AddressProvider>().selAreaPos!];
                      context.read<AddressProvider>().area =
                          context.read<AddressProvider>().selArea!.id;
                      context.read<AddressProvider>().pincodeC!.text =
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
                      context.read<AddressProvider>().pincodeC!.text = '';
                      cityC!.clear();
                      context.read<AddressProvider>().cityName = null;
                      context.read<AddressProvider>().cityEnable = false;
                      context.read<AddressProvider>().areaName = null;
                      context.read<AddressProvider>().areaEnable = false;
                      areaC!.clear();
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
                        widget.update!,
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

  setCities() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.white,
          borderRadius: BorderRadius.circular(circularBorderRadius5),
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
            color: Theme.of(context).colorScheme.white,
            borderRadius: BorderRadius.circular(circularBorderRadius5),
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

  setAddress() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                borderRadius: BorderRadius.circular(circularBorderRadius5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                ),
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(color: Theme.of(context).colorScheme.fontColor),
                  focusNode: addFocus,
                  controller: addressC,
                  validator: (val) => StringValidation.validateField(
                    val!,
                    getTranslated(context, 'FIELD_REQUIRED'),
                  ),
                  onSaved: (String? value) {
                    context.read<AddressProvider>().address = value;
                  },
                  onFieldSubmitted: (v) {
                    _fieldFocusChange(context, addFocus!, locationFocus);
                  },
                  decoration: InputDecoration(
                    label: Text(
                      getTranslated(context, 'ADDRESS_LBL')!,
                      style: const TextStyle(
                        fontFamily: 'ubuntu',
                      ),
                    ),
                    fillColor: Theme.of(context).colorScheme.white,
                    isDense: true,
                    hintText: getTranslated(context, 'ADDRESS_LBL'),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.my_location,
                        color: colors.primary,
                      ),
                      focusNode: locationFocus,
                      onPressed: () async {
                        LocationPermission permission;

                        permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }
                        Position position = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high);
                        if (onlyOneTimePress) {
                          setState(
                            () {
                              onlyOneTimePress = false;
                            },
                          );
                          await Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Map(
                                latitude:
                                    context.read<AddressProvider>().latitude ==
                                                null ||
                                            context
                                                    .read<AddressProvider>()
                                                    .latitude ==
                                                ''
                                        ? position.latitude
                                        : double.parse(context
                                            .read<AddressProvider>()
                                            .latitude!),
                                longitude:
                                    context.read<AddressProvider>().longitude ==
                                                null ||
                                            context
                                                    .read<AddressProvider>()
                                                    .longitude ==
                                                ''
                                        ? position.longitude
                                        : double.parse(context
                                            .read<AddressProvider>()
                                            .longitude!),
                                from: getTranslated(context, 'ADDADDRESS'),
                              ),
                            ),
                          ).then(
                            (value) {
                              onlyOneTimePress = true;
                            },
                          );
                          if (mounted) setState(() {});
                          List<Placemark> placemark =
                              await placemarkFromCoordinates(
                            double.parse(
                                context.read<AddressProvider>().latitude!),
                            double.parse(
                                context.read<AddressProvider>().longitude!),
                          );
                          var address;
                          address = placemark[0].name;
                          address = address + ',' + placemark[0].subLocality;
                          address = address + ',' + placemark[0].locality;
                          context.read<AddressProvider>().state =
                              placemark[0].administrativeArea;
                          context.read<AddressProvider>().country =
                              placemark[0].country;
                          if (mounted) {
                            setState(
                              () {
                                countryC!.text =
                                    context.read<AddressProvider>().country!;
                                stateC!.text =
                                    context.read<AddressProvider>().state!;
                                addressC!.text = address;
                              },
                            );
                          }
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
            horizontal: 10.0,
          ),
          child: TextFormField(
            keyboardType: TextInputType.number,
            controller: context.read<AddressProvider>().pincodeC,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSaved: (String? value) {},
            validator: (val) => StringValidation.validateField(
                val!, getTranslated(context, 'FIELD_REQUIRED')),
            decoration: InputDecoration(
              label: Text(
                getTranslated(context, 'PINCODEHINT_LBL')!,
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),
              fillColor: Theme.of(context).colorScheme.white,
              isDense: true,
              hintText: getTranslated(context, 'PINCODEHINT_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> callApi() async {
    isNetworkAvail = await isNetworkAvailable();
    if (isNetworkAvail) {
      await context.read<AddressProvider>().getCities(
            false,
            context,
            setState,
            widget.update,
            widget.index,
          );
      if (widget.update! &&
          context.read<CartProvider>().addressList[widget.index!].cityId !=
              '0') {
        context.read<AddressProvider>().getArea(
              context.read<CartProvider>().addressList[widget.index!].cityId,
              false,
              false,
              context,
              setState,
              widget.update,
            );
      }
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
        },
      );
    }
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
            horizontal: 10.0,
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
            decoration: InputDecoration(
              label: Text(
                getTranslated(context, 'STATE_LBL')!,
                style: const TextStyle(
                  fontFamily: 'ubuntu',
                ),
              ),
              fillColor: Theme.of(context).colorScheme.white,
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
            horizontal: 10.0,
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
              fillColor: Theme.of(context).colorScheme.white,
              isDense: true,
              hintText: getTranslated(context, 'COUNTRY_LBL'),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AddressProvider>().buttonController!.dispose();
        context.read<AddressProvider>().pincodeC!.dispose();
        context.read<AddressProvider>().cityController.dispose();
        context.read<AddressProvider>().areaController.dispose();
        context.read<AddressProvider>().selectedArea = null;
        context.read<AddressProvider>().selectedCity = null;
        context.read<AddressProvider>().selAreaPos = -1;
        context.read<AddressProvider>().selCityPos = -1;
        context.read<AddressProvider>().cityName = null;
        context.read<AddressProvider>().areaName = null;
        context.read<AddressProvider>().city = null;
        context.read<AddressProvider>().area = null;
        context.read<AddressProvider>().pincode = null;
      }
    });
    mobileC?.dispose();
    nameC?.dispose();
    stateC?.dispose();
    countryC?.dispose();
    altMobC?.dispose();
    landmarkC?.dispose();
    addressC!.dispose();
    cityC!.dispose();
    areaC!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await context.read<AddressProvider>().buttonController!.forward();
    } on TickerCanceled {}
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

  _showContent() {
    return Form(
      key: _formkey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: <Widget>[
                    setUserName(),
                    setMobileNo(),
                    setAddress(),
                    setCities(),
                    setCityName(),
                    setArea(),
                    setAreaName(),
                    setPincode(),
                    setStateField(),
                    setCountry(),
                    typeOfAddress(),
                    defaultAdd(),
                  ],
                ),
              ),
            ),
          ),
          SaveButtonWidget(
            title: getTranslated(context, 'SAVE_LBL')!,
            onBtnSelected: () {
              FocusScope.of(context).unfocus();
              validateAndSubmit();
            },
          ),
        ],
      ),
    );
  }

  Future<void> areaSearch(String searchText) async {
    context.read<AddressProvider>().areaSearchList.clear();
    for (int i = 0; i < context.read<AddressProvider>().areaList.length; i++) {
      User map = context.read<AddressProvider>().areaList[i];

      if (map.name!.toLowerCase().contains(searchText)) {
        context.read<AddressProvider>().areaSearchList.add(map);
      }
    }

    //if (mounted) context.read<AddressProvider>().areaState!(() {});
  }

  Future<void> getCurrentLoc() async {
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    context.read<AddressProvider>().latitude = position.latitude.toString();
    context.read<AddressProvider>().longitude = position.longitude.toString();

    List<Placemark> placemark = await placemarkFromCoordinates(
        double.parse(context.read<AddressProvider>().latitude!),
        double.parse(context.read<AddressProvider>().longitude!),
        localeIdentifier: 'en');

    context.read<AddressProvider>().state = placemark[0].administrativeArea;
    context.read<AddressProvider>().country = placemark[0].country;
    if (mounted) {
      setState(
        () {
          countryC!.text = context.read<AddressProvider>().country!;
          stateC!.text = context.read<AddressProvider>().state!;
        },
      );
    }
  }
}
