import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screen/product_overview_screen.dart';
import './providers/auth.dart';
import './screen/auth_screen.dart';
import './screen/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [ChangeNotifierProvider(create: (ctx) => Auth())],
        child: Consumer<Auth>(
          builder: (context, auth, _) => MaterialApp(
            title: 'Shop App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: auth.isAuth
                ? ProductOverViewScreen()
                : FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: ((context, authResultSnapshot) =>
                        authResultSnapshot.connectionState ==
                                ConnectionState.waiting
                            ? SplashScreen()
                            : AuthScreen()),
                  ),
          ),
        ));
  }
}
