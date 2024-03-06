import 'dart:async';
import 'dart:developer';
import 'package:eshop_multivendor/Helper/Color.dart';
import 'package:eshop_multivendor/Provider/SettingProvider.dart';
import 'package:eshop_multivendor/Provider/UserProvider.dart';
import 'package:eshop_multivendor/Provider/authenticationProvider.dart';
import 'package:eshop_multivendor/Provider/homePageProvider.dart';
import 'package:eshop_multivendor/Screen/Auth/SignInUpAcc.dart';
import 'package:eshop_multivendor/Screen/IntroSlider/Intro_Slider.dart';
import 'package:eshop_multivendor/widgets/networkAvailablity.dart';
import 'package:eshop_multivendor/widgets/snackbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Helper/String.dart';
import '../../Provider/pushNotificationProvider.dart';
import '../../widgets/desing.dart';
import '../../widgets/systemChromeSettings.dart';

//splash screen of app
class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<Splash> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool from = false;
  late AnimationController navigationContainerAnimationController =
      AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    SystemChromeSettings.setSystemButtomNavigationBarithTopAndButtom();
    SystemChromeSettings.setSystemUIOverlayStyleWithNoSpecification();
    setToken();
    initializeAnimationController();
    startTime();
    super.initState();
  }

  void setToken() async {
    FirebaseMessaging.instance.getToken().then(
      (token) async {
        SettingProvider settingsProvider =
            Provider.of<SettingProvider>(context, listen: false);

        String getToken = await settingsProvider.getPrefrence(FCMTOKEN) ?? '';

        if (token != getToken && token != null) {
          context
              .read<PushNotificationProvider>()
              .registerToken(token, context);
        }
      },
    );
  }

  void initializeAnimationController() {
    Future.delayed(
      Duration.zero,
      () {
        context.read<HomePageProvider>()
          ..setAnimationController(navigationContainerAnimationController)
          ..setBottomBarOffsetToAnimateController(
              navigationContainerAnimationController)
          ..setAppBarOffsetToAnimateController(
              navigationContainerAnimationController);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: Center(
              child: Image.asset(
                "assets/images/png/splash.jpg",
                fit: BoxFit.contain,
                width: 180,
                height: 180,
              ),
            ),
          ),
          Image.asset(
            DesignConfiguration.setPngPath('doodle'),
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      ),
    );
  }

  startTime() async {
    var duration = const Duration(seconds: 2);
    return Timer(duration, navigationPage);
  }

  Future<void> navigationPage() async {
    SharedPreferences _sharedPreferences = await SharedPreferences.getInstance();
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    bool isFirstTime = await settingsProvider.getPrefrenceBool(ISFIRSTTIME);
    bool isDashboard = await settingsProvider.getDashboard("Dashboard");
    log("FIRST TIME===+${isFirstTime}");
    log("DASHBOArD======${isDashboard}");
    bool isNetworkAvail = await isNetworkAvailable();

    if (isFirstTime) {
      setState(
        () {
          from = true;
        },
      );
      if(isDashboard)
      {
        if (isNetworkAvail) {
          String mobileNumber  = _sharedPreferences.getString(MOBILE)??'';
          String password  = _sharedPreferences.getString('password')??'';
          context.read<AuthenticationProvider>().setMobileNumber(mobileNumber);
          context.read<AuthenticationProvider>().setPassword(password);
          UserProvider userProvider =
          Provider.of<UserProvider>(context, listen: false);
          Future.delayed(Duration.zero).then(
                (value) => context.read<AuthenticationProvider>().getLoginData().then(
                  (
                  value,
                  ) async {
                bool error = value['error']??false;
                String? errorMessage = value['message'];
                if (!error) {
                  var getdata = value['data'][0];


                  userProvider.setName(getdata[USERNAME] ?? '');
                  userProvider.setEmail(getdata[EMAIL] ?? '');
                  userProvider.setProfilePic(getdata[IMAGE] ?? '');
                  userProvider.setLoginType(getdata[TYPE] ?? '');
                  userProvider.setBusinessName(getdata[BUSINESS_NAME] ?? '');
                  userProvider.setBusinessAddress(getdata[BUSINESS_ADDRESS] ?? '');
                  userProvider.setGstNumber(getdata[GST_NUMBER] ?? '');
                  userProvider.setMobile(getdata[MOBILE] ?? '');

                  SettingProvider settingProvider =
                  Provider.of<SettingProvider>(context, listen: false);
                  settingProvider.saveUserDetail(
                    getdata[ID],
                    getdata[USERNAME],
                    getdata[EMAIL],
                    getdata[MOBILE],
                    getdata[CITY],
                    getdata[AREA],
                    getdata[ADDRESS],
                    getdata[PINCODE],
                    getdata[LATITUDE],
                    getdata[LONGITUDE],
                    getdata[IMAGE],
                    getdata[TYPE],
                    context,
                    getdata[BUSINESS_NAME],
                    getdata[BUSINESS_ADDRESS],
                    getdata[GST_NUMBER],
                  );
                  setToken();
                } else {
                  setSnackbar(errorMessage!, context);
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
            },
          );
        }
        Navigator.pushReplacementNamed(context, '/home');
      }
      else
      {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
              builder: (context) => const SignInUpAcc()),
        );
      }

    } else {
      setState(
        () {
          from = false;
        },
      );
      if(isDashboard)
      {
        Navigator.pushReplacementNamed(context, '/home');
      }
      else
      {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => const IntroSlider(),
          ),
        );
      }

    }
  }

  @override
  void dispose() {
    if (from) {
      SystemChromeSettings.setSystemButtomNavigationBarithTopAndButtom();
    }
    super.dispose();
  }
}
