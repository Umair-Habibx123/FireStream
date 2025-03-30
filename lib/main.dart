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
  // Load environment variables
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Initialize with options
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ConnectivityService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          builder: (context, child) {
            return Stack(
              children: [
                child!,
                if (!connectivityService.hasInternet)
                  ModalBarrier(
                    color: Colors.black.withOpacity(0.5),
                    dismissible: false,
                  ),
                if (!connectivityService.hasInternet)
                  Center(
                    child: NoInternetModal(
                      onRetry: connectivityService.retryConnection,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
