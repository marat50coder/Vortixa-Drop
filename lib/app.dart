import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'data/app_store.dart';
import 'kine/kine_pilot.dart';
import 'screens/loading_screen.dart';

class VortixaApp extends StatelessWidget {
  const VortixaApp({super.key, this.helm});

  final KinePilot? helm;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppStore(),
      child: MaterialApp(
        title: 'Vortixa Drop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: VxColors.voidBlack,
          colorScheme: const ColorScheme.dark(
            primary: VxColors.cyan,
            secondary: VxColors.magenta,
            surface: VxColors.graphite,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: VxColors.deepNavy,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF1A1A30),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
          useMaterial3: true,
        ),
        home: LoadingScreen(helm: helm),
      ),
    );
  }
}
