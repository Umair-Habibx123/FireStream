import 'package:chat_app/features/services/connectivity_service.dart';
import 'package:chat_app/no_internet_modal.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:chat_app/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConnectivityService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      builder: (context, child) {
        return Consumer<ConnectivityService>(
          builder: (context, connectivity, _) {
            return Stack(
              children: [
                child!,
                if (!connectivity.hasInternet) ...[
                  // Blurred barrier
                  ModalBarrier(
                    color: Colors.black.withOpacity(0.55),
                    dismissible: false,
                  ),
                  Center(
                    child: NoInternetModal(
                      onRetry: connectivity.retryConnection,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}