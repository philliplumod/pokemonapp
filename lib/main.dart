import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/landing_page.dart';
import 'utils/dark_mode.dart';
import 'bloc/progress_bloc.dart';
import 'bloc/pokedex_bloc.dart';
import 'repositories/pokemon_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize HydratedBloc storage for persistence
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    );
  } catch (e) {
    // If storage fails, continue without persistence
    debugPrint('Failed to initialize storage: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final retroPrimary = const Color(0xFFB71C1C); // deep red
  final retroAccent = const Color(0xFFFFD54F); // warm yellow
  final retroBg = const Color(0xFFF3E9D2); // parchment

  @override
  void initState() {
    super.initState();
    // Nothing else to init; the DarkModeController holds the notifier.
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProgressBloc()),
        BlocProvider(
          create: (_) =>
              PokedexBloc(repository: PokemonRepository())
                ..add(LoadPokedex(limit: 151)),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: DarkModeController.instance.mode,
        builder: (context, mode, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pokémon Battle Arena',
            themeMode: mode,
            theme: ThemeData(
              brightness: Brightness.light,
              useMaterial3: false,
              primaryColor: retroPrimary,
              scaffoldBackgroundColor: retroBg,
              appBarTheme: AppBarTheme(
                backgroundColor: retroPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              // Use cardColor for broader compatibility across Flutter versions
              cardColor: const Color(0xFFF7F3E8),
              textTheme: GoogleFonts.pressStart2pTextTheme(
                const TextTheme(
                  titleLarge: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  bodyLarge: TextStyle(),
                  bodyMedium: TextStyle(),
                ),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: retroPrimary,
                primary: retroPrimary,
                secondary: retroAccent,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              useMaterial3: false,
              primaryColor: Colors.grey.shade900,
              scaffoldBackgroundColor: const Color.fromARGB(255, 65, 65, 65),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey.shade900,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardColor: Colors.grey.shade800,
              textTheme: GoogleFonts.pressStart2pTextTheme(
                ThemeData(brightness: Brightness.dark).textTheme,
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.grey.shade900,
                brightness: Brightness.dark,
              ),
            ),
            home: const LandingPage(),
          );
        },
      ),
    );
  }
}
