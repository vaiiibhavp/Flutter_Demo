import 'package:eshop_multivendor/Helper/ApiBaseHelper.dart';

//Your application name
const String appName = 'Pratham Enterprises';

//Your package name
const String packageName = 'pratham.enterprises.customer';
const String iosPackage = 'eShop.multivendor.customer';

//Playstore link of your application
const String androidLink = 'https://play.google.com/store/apps/details?id=';

//Appstore link of your application
const String iosLink = 'your ios link here';

//Appstore id
const String appStoreId = '123456789';

//Link for share product (get From Firebase)
const String deepLinkUrlPrefix = 'https://prathamjelliesai.page.link';
const String deepLinkName = 'pratham.jelliesai.com';

//Set labguage
String defaultLanguage = 'en';

//Set country code
String defaultCountryCode = 'IN';

//Time settings
const int timeOut = 50;
const int perPage = 10;

//FontSize
const double textFontSize7 = 7;
const double textFontSize8 = 8;
const double textFontSize9 = 9;
const double textFontSize10 = 10;
const double textFontSize11 = 11;
const double textFontSize12 = 12;
const double textFontSize13 = 13;
const double textFontSize14 = 14;
const double textFontSize15 = 15;
const double textFontSize16 = 16;
const double textFontSize18 = 18;
const double textFontSize20 = 20;
const double textFontSize23 = 23;
const double textFontSize30 = 30;
//Radius
const double circularBorderRadius1 = 1;
const double circularBorderRadius3 = 3;
const double circularBorderRadius4 = 4;
const double circularBorderRadius5 = 5;
const double circularBorderRadius7 = 7;
const double circularBorderRadius8 = 8;
const double circularBorderRadius10 = 10;
const double circularBorderRadius20 = 20;
const double circularBorderRadius25 = 25;
const double circularBorderRadius30 = 30;
const double circularBorderRadius40 = 40;
const double circularBorderRadius50 = 50;
const double circularBorderRadius100 = 100;
//Token ExpireTime in minutes & issuer name
const int tokenExpireTime = 5;

const String issuerName = 'eshop';

//General Error Message
const String errorMesaage = 'Something went wrong, Error : ';

//Bank detail hint text
const String bankDetail =
    'Bank Details:\nAccount No :123XXXXX\nIFSC Code: 123XXX \nName: Abc Bank';

//Api class instance
ApiBaseHelper apiBaseHelper = ApiBaseHelper();

const String baseUrl = 'https://pratham.jelliesai.com/app/v1/api/';
const String jwtKey = 'f765ffd9ed39488ca05c3ff596e3f0f6ba7e248b';
