import 'package:fast_http/fast_http.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import './Utilities/shared_preferences.dart';
import 'package:rush/rush.dart';
import 'Utilities/git_it.dart';
import 'Utilities/router_config.dart';
import 'package:provider/provider.dart';
import 'core/Font/font_provider.dart';
import 'core/Language/app_languages.dart';
import 'core/Language/locales.dart';
import 'core/Theme/theme_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  RushSetup.init(
    enableLargeScreens: true,
    enableMediumScreens: false,
    enableSmallScreens: false,
    startMediumSize: 768,
    startLargeSize: 1200,
  );

  FastHttp.initialize(
    checkStatusKey: "data",
    getErrorMessageFromResponse: (dynamic response)=> response.toString(),
    onGetResponseStatusCode: (int statusCode){
      switch (statusCode) {
        case 302: {break;} // the requested resource has been temporarily moved to the URL in the Location header
        case 403: {break;} // forbidden—you don't have permission to access this resource
        case 401: {break;} // Unauthorized
        case 503: {break;} // server is too busy or is temporarily down for maintenance.y
      }
    },
  );

  FastHttpHeader().addHeader("Accept", "*/*");
  FastHttpHeader().addHeader("content-type", "application/json");
  FastHttpHeader().addDynamicHeader("token", ()async=> SharedPref.getCurrentUser()?.token??"");

  await GitIt.initGitIt();
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppLanguage>(create: (_) => AppLanguage()),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<FontProvider>(create: (_) => FontProvider()),
        ],
        child: const EntryPoint(),
      )
  );
}


class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  static Size largeSize = const Size(1920,1080);
  static Size mediumSize = const Size(1000,780);
  static Size smallSize = const Size(375,812);

  @override
  Widget build(BuildContext context) {
    final appLan = Provider.of<AppLanguage>(context);
    final appTheme = Provider.of<ThemeProvider>(context);
    appLan.fetchLocale();
    appTheme.fetchTheme();
    return LayoutBuilder(
      builder: (context, constraints) {
        Size appSize = largeSize;
        if (constraints.maxWidth <= RushSetup.startMediumSize) {
          if(RushSetup.enableSmallScreens) appSize = smallSize;
        } else if (constraints.maxWidth <= RushSetup.startLargeSize && constraints.maxWidth > RushSetup.startMediumSize) {
          if(RushSetup.enableMediumScreens) appSize = mediumSize;
        } else {
          appSize = largeSize;
        }
        return ScreenUtilInit(
          designSize: appSize,
          builder:(_,__)=> MaterialApp.router(
            scrollBehavior: MyCustomScrollBehavior(),
            routerConfig: GoRouterConfig.router,
            debugShowCheckedModeBanner: false,
            title: 'RUSH ERP',
            locale: Locale(appLan.appLang.name),
            theme: appTheme.appThemeMode,
            supportedLocales: Languages.values.map((e) => Locale(e.name)).toList(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultMaterialLocalizations.delegate
            ],
          ),
        );
      },
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
