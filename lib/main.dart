import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SuiviSalleApp());
}

// ============================================================
// APPLICATION
// ============================================================

class SuiviSalleApp extends StatelessWidget {
  const SuiviSalleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suivi Salle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF15151C),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A22),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const AppLoader(),
    );
  }
}

// ============================================================
// CHARGEMENT
// ============================================================

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  late Future<AppState> future;

  @override
  void initState() {
    super.initState();
    future = AppState.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erreur de chargement : ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return MainScreen(
          state: snapshot.data!,
        );
      },
    );
  }
}

// ============================================================
// MODELES
// ============================================================

class ExerciseSet {
  double weight;
  int reps;

  ExerciseSet({
    this.weight = 0,
    this.reps = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
    };
  }

  factory ExerciseSet.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExerciseSet(
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
    );
  }
}

class Exercise {
  final String name;
  final String muscle;
  final int defaultSets;

  List<ExerciseSet> sets;

  Exercise({
    required this.name,
    required this.muscle,
    this.defaultSets = 3,
    List<ExerciseSet>? sets,
  }) : sets = sets ??
            List.generate(
              defaultSets,
              (_) => ExerciseSet(),
            );

  Exercise copy() {
    return Exercise(
      name: name,
      muscle: muscle,
      defaultSets: defaultSets,
      sets: sets
          .map(
            (set) => ExerciseSet(
              weight: set.weight,
              reps: set.reps,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'muscle': muscle,
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSets =
        json['sets'] as List<dynamic>? ?? [];

    return Exercise(
      name: json['name'] as String? ?? '',
      muscle: json['muscle'] as String? ?? '',
      defaultSets:
          rawSets.isEmpty ? 3 : rawSets.length,
      sets: rawSets
          .map(
            (set) => ExerciseSet.fromJson(
              Map<String, dynamic>.from(
                set as Map,
              ),
            ),
          )
          .toList(),
    );
  }
}

class Workout {
  final String name;
  final String description;
  final List<Exercise> exercises;

  Workout({
    required this.name,
    required this.description,
    required this.exercises,
  });

  Workout copy() {
    return Workout(
      name: name,
      description: description,
      exercises:
          exercises.map((e) => e.copy()).toList(),
    );
  }
}

class WorkoutRecord {
  final String id;
  final String workoutName;
  final DateTime date;
  final List<Exercise> exercises;

  WorkoutRecord({
    required this.id,
    required this.workoutName,
    required this.date,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutName': workoutName,
      'date': date.toIso8601String(),
      'exercises':
          exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawExercises =
        json['exercises'] as List<dynamic>? ?? [];

    return WorkoutRecord(
      id: json['id'] as String? ?? '',
      workoutName:
          json['workoutName'] as String? ?? '',
      date: DateTime.tryParse(
            json['date'] as String? ?? '',
          ) ??
          DateTime.now(),
      exercises: rawExercises
          .map(
            (exercise) => Exercise.fromJson(
              Map<String, dynamic>.from(
                exercise as Map,
              ),
            ),
          )
          .toList(),
    );
  }
}

class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;

  WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
    };
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeightEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(
            json['date'] as String? ?? '',
          ) ??
          DateTime.now(),
      weight:
          (json['weight'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ============================================================
// DONNEES DE PROGRESSION
// ============================================================

class ExerciseProgress {
  final DateTime date;
  final double maxWeight;
  final int maxReps;
  final double volume;

  ExerciseProgress({
    required this.date,
    required this.maxWeight,
    required this.maxReps,
    required this.volume,
  });
}

// ============================================================
// PROGRAMMES
// ============================================================

List<Workout> defaultWorkouts() {
  return [
    Workout(
      name: 'Pectoraux / Triceps',
      description:
          'Développer les pectoraux et les triceps',
      exercises: [
        Exercise(
          name: 'Développé couché',
          muscle: 'Pectoraux',
          defaultSets: 4,
        ),
        Exercise(
          name: 'Développé incliné',
          muscle: 'Pectoraux',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Écarté haltères',
          muscle: 'Pectoraux',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Dips',
          muscle: 'Triceps',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Extension triceps',
          muscle: 'Triceps',
          defaultSets: 3,
        ),
      ],
    ),
    Workout(
      name: 'Dos / Biceps',
      description:
          'Développer le dos et les biceps',
      exercises: [
        Exercise(
          name: 'Tractions',
          muscle: 'Dos',
          defaultSets: 4,
        ),
        Exercise(
          name: 'Tirage vertical',
          muscle: 'Dos',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Rowing',
          muscle: 'Dos',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Curl haltères',
          muscle: 'Biceps',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Curl barre',
          muscle: 'Biceps',
          defaultSets: 3,
        ),
      ],
    ),
    Workout(
      name: 'Jambes / Abdos',
      description:
          'Jambes complètes et abdominaux',
      exercises: [
        Exercise(
          name: 'Squat',
          muscle: 'Quadriceps',
          defaultSets: 4,
        ),
        Exercise(
          name: 'Presse à cuisses',
          muscle: 'Jambes',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Leg curl',
          muscle: 'Ischio-jambiers',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Mollets',
          muscle: 'Mollets',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Crunch',
          muscle: 'Abdominaux',
          defaultSets: 3,
        ),
      ],
    ),
    Workout(
      name: 'Épaules / Haut du corps',
      description:
          'Épaules et renforcement du haut du corps',
      exercises: [
        Exercise(
          name: 'Développé militaire',
          muscle: 'Épaules',
          defaultSets: 4,
        ),
        Exercise(
          name: 'Élévations latérales',
          muscle: 'Épaules',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Oiseau',
          muscle: 'Arrière épaules',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Shrugs',
          muscle: 'Trapèzes',
          defaultSets: 3,
        ),
      ],
    ),
    Workout(
      name: 'Full Body',
      description:
          'Séance complète du corps',
      exercises: [
        Exercise(
          name: 'Squat',
          muscle: 'Jambes',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Développé couché',
          muscle: 'Pectoraux',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Tirage horizontal',
          muscle: 'Dos',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Développé épaules',
          muscle: 'Épaules',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Curl biceps',
          muscle: 'Biceps',
          defaultSets: 3,
        ),
        Exercise(
          name: 'Extension triceps',
          muscle: 'Triceps',
          defaultSets: 3,
        ),
      ],
    ),
  ];
}

// ============================================================
// ETAT GLOBAL
// ============================================================

class AppState extends ChangeNotifier {
  static const String workoutHistoryKey =
      'workout_history_v3';

  static const String weightHistoryKey =
      'weight_history_v3';

  final List<WorkoutRecord> history;
  final List<WeightEntry> weights;

  AppState({
    required this.history,
    required this.weights,
  });

  static Future<AppState> load() async {
    final prefs =
        await SharedPreferences.getInstance();

    final workoutString =
        prefs.getString(workoutHistoryKey);

    final weightString =
        prefs.getString(weightHistoryKey);

    List<WorkoutRecord> history = [];
    List<WeightEntry> weights = [];

    if (workoutString != null &&
        workoutString.isNotEmpty) {
      try {
        final data =
            jsonDecode(workoutString)
                as List<dynamic>;

        history = data
            .map(
              (item) => WorkoutRecord.fromJson(
                Map<String, dynamic>.from(
                  item as Map,
                ),
              ),
            )
            .toList();
      } catch (_) {
        history = [];
      }
    }

    if (weightString != null &&
        weightString.isNotEmpty) {
      try {
        final data =
            jsonDecode(weightString)
                as List<dynamic>;

        weights = data
            .map(
              (item) => WeightEntry.fromJson(
                Map<String, dynamic>.from(
                  item as Map,
                ),
              ),
            )
            .toList();
      } catch (_) {
        weights = [];
      }
    }

    history.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    weights.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return AppState(
      history: history,
      weights: weights,
    );
  }

  int get sessionCount => history.length;

  WeightEntry? get latestWeight {
    if (weights.isEmpty) {
      return null;
    }

    return weights.last;
  }

  WorkoutRecord? get latestWorkout {
    if (history.isEmpty) {
      return null;
    }

    return history.first;
  }

  Future<void> addWorkout(
    Workout workout,
  ) async {
    final record = WorkoutRecord(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      workoutName: workout.name,
      date: DateTime.now(),
      exercises: workout.exercises
          .map((exercise) => exercise.copy())
          .toList(),
    );

    history.insert(0, record);

    await saveWorkouts();

    notifyListeners();
  }

  Future<void> addWeight(
    double weight,
  ) async {
    final entry = WeightEntry(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      date: DateTime.now(),
      weight: weight,
    );

    weights.add(entry);

    weights.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    await saveWeights();

    notifyListeners();
  }

  Future<void> deleteWorkout(
    String id,
  ) async {
    history.removeWhere(
      (item) => item.id == id,
    );

    await saveWorkouts();

    notifyListeners();
  }

  Future<void> deleteWeight(
    String id,
  ) async {
    weights.removeWhere(
      (item) => item.id == id,
    );

    await saveWeights();

    notifyListeners();
  }

  Future<void> clearAllData() async {
    history.clear();
    weights.clear();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      workoutHistoryKey,
    );

    await prefs.remove(
      weightHistoryKey,
    );

    notifyListeners();
  }

  Future<void> saveWorkouts() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      workoutHistoryKey,
      jsonEncode(
        history
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }

  Future<void> saveWeights() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      weightHistoryKey,
      jsonEncode(
        weights
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }

  List<WorkoutRecord> historyForExercise(
    String exerciseName,
  ) {
    return history
        .where(
          (workout) => workout.exercises.any(
            (exercise) =>
                exercise.name == exerciseName,
          ),
        )
        .toList();
  }

  List<ExerciseProgress> progressForExercise(
    String exerciseName,
  ) {
    final records =
        historyForExercise(exerciseName);

    final result =
        <ExerciseProgress>[];

    for (final record in records.reversed) {
      final matching =
          record.exercises.where(
        (exercise) =>
            exercise.name == exerciseName,
      );

      if (matching.isEmpty) {
        continue;
      }

      final exercise = matching.first;

      final validSets = exercise.sets
          .where(
            (set) =>
                set.weight > 0 &&
                set.reps > 0,
          )
          .toList();

      if (validSets.isEmpty) {
        continue;
      }

      double maxWeight = 0;
      int maxReps = 0;
      double volume = 0;

      for (final set in validSets) {
        if (set.weight > maxWeight) {
          maxWeight = set.weight;
        }

        if (set.reps > maxReps) {
          maxReps = set.reps;
        }

        volume +=
            set.weight * set.reps;
      }

      result.add(
        ExerciseProgress(
          date: record.date,
          maxWeight: maxWeight,
          maxReps: maxReps,
          volume: volume,
        ),
      );
    }

    return result;
  }

  double? latestWeightForExercise(
    String exerciseName,
  ) {
    final data =
        progressForExercise(exerciseName);

    if (data.isEmpty) {
      return null;
    }

    return data.last.maxWeight;
  }

  double? previousWeightForExercise(
    String exerciseName,
  ) {
    final data =
        progressForExercise(exerciseName);

    if (data.length < 2) {
      return null;
    }

    return data[data.length - 2].maxWeight;
  }
}

// ============================================================
// ECRAN PRINCIPAL
// ============================================================

class MainScreen extends StatefulWidget {
  final AppState state;

  const MainScreen({
    super.key,
    required this.state,
  });

  @override
  State<MainScreen> createState() =>
      _MainScreenState();
}

class _MainScreenState
    extends State<MainScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(refresh);
  }

  @override
  void dispose() {
    widget.state.removeListener(refresh);
    super.dispose();
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        state: widget.state,
        onNavigate: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      SessionsPage(
        state: widget.state,
      ),
      ProgressPage(
        state: widget.state,
      ),
      WeightPage(
        state: widget.state,
      ),
      SettingsPage(
        state: widget.state,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[currentIndex],
      ),
      bottomNavigationBar:
          NavigationBar(
        backgroundColor: const Color(0xFF14141B),
        selectedIndex: currentIndex,
        onDestinationSelected:
            (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(
              Icons
                  .fitness_center_outlined,
            ),
            selectedIcon: Icon(
              Icons.fitness_center,
            ),
            label: 'Séances',
          ),
          NavigationDestination(
            icon: Icon(
              Icons
                  .show_chart_outlined,
            ),
            selectedIcon: Icon(
              Icons.show_chart,
            ),
            label: 'Progression',
          ),
          NavigationDestination(
            icon: Icon(
              Icons
                  .monitor_weight_outlined,
            ),
            selectedIcon: Icon(
              Icons.monitor_weight,
            ),
            label: 'Poids',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACCUEIL
// ============================================================

class HomePage extends StatelessWidget {
  final AppState state;
  final ValueChanged<int> onNavigate;

  const HomePage({
    super.key,
    required this.state,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final latestWeight =
        state.latestWeight;

    final latestWorkout =
        state.latestWorkout;

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Suivi Salle',
            style: TextStyle(
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Ton suivi sportif',
            style: TextStyle(
              color:
                  Colors.grey.shade400,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon:
                      Icons.fitness_center,
                  title: 'Séances',
                  value:
                      '${state.sessionCount}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon:
                      Icons.monitor_weight,
                  title: 'Poids',
                  value:
                      latestWeight == null
                          ? '--'
                          : '${latestWeight.weight.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          const Text(
            'Nouvelle séance',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child:
                FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutSelectionPage(
                      state: state,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.play_arrow,
              ),
              label: const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 15,
                ),
                child: Text(
                  'Commencer une séance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Dernière séance',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (latestWorkout == null)
            const EmptyCard(
              icon: Icons.history,
              title:
                  'Aucune séance enregistrée',
              subtitle:
                  'Tes séances terminées apparaîtront ici.',
            )
          else
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 27,
                      child: Icon(
                        Icons
                            .fitness_center,
                      ),
                    ),
                    const SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            latestWorkout
                                .workoutName,
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            formatDateTime(
                              latestWorkout
                                  .date,
                            ),
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade400,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${latestWorkout.exercises.length} exercices',
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 25),

          const Text(
            'Accès rapides',
            style: TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: QuickAction(
                  icon:
                      Icons.show_chart,
                  label:
                      'Progression',
                  onTap: () =>
                      onNavigate(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickAction(
                  icon:
                      Icons.monitor_weight,
                  label: 'Poids',
                  onTap: () =>
                      onNavigate(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CHOIX SEANCE
// ============================================================

class WorkoutSelectionPage
    extends StatelessWidget {
  final AppState state;

  const WorkoutSelectionPage({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final workouts =
        defaultWorkouts();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choisir une séance',
        ),
      ),
      body:
          ListView.builder(
        padding:
            const EdgeInsets.all(20),
        itemCount: workouts.length,
        itemBuilder:
            (context, index) {
          final workout =
              workouts[index];

          return Card(
            margin:
                const EdgeInsets.only(
              bottom: 14,
            ),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutDetailPage(
                      state: state,
                      workout:
                          workout.copy(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(
                        Icons
                            .fitness_center,
                      ),
                    ),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            workout.name,
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            workout
                                .description,
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade400,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            '${workout.exercises.length} exercices',
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons
                          .chevron_right,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// SEANCE EN COURS
// ============================================================

class WorkoutDetailPage
    extends StatefulWidget {
  final AppState state;
  final Workout workout;

  const WorkoutDetailPage({
    super.key,
    required this.state,
    required this.workout,
  });

  @override
  State<WorkoutDetailPage>
      createState() =>
          _WorkoutDetailPageState();
}

class _WorkoutDetailPageState
    extends State<WorkoutDetailPage> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.workout.name),
      ),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          120,
        ),
        children: [
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .timer_outlined,
                    size: 28,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Text(
                      'Séance en cours',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.workout.exercises.length} exercices',
                    style: TextStyle(
                      color: Colors
                          .grey
                          .shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          ...widget.workout.exercises
              .asMap()
              .entries
              .map(
            (entry) {
              return ExerciseCard(
                index: entry.key,
                exercise:
                    entry.value,
                state: widget.state,
                onChanged: () {
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,
      floatingActionButton:
          SizedBox(
        width:
            MediaQuery.of(context)
                    .size
                    .width -
                32,
        child:
            FilledButton.icon(
          onPressed: saving
              ? null
              : finishWorkout,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.check,
                ),
          label: Text(
            saving
                ? 'Enregistrement...'
                : 'Terminer la séance',
          ),
        ),
      ),
    );
  }

  Future<void> finishWorkout() async {
    final hasData =
        widget.workout.exercises.any(
      (exercise) =>
          exercise.sets.any(
        (set) =>
            set.weight > 0 ||
            set.reps > 0,
      ),
    );

    if (!hasData) {
      final result =
          await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Séance vide',
            ),
            content: const Text(
              'Aucune charge ou répétition n’a été renseignée. '
              'Veux-tu tout de même enregistrer cette séance ?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child:
                    const Text(
                  'Annuler',
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child:
                    const Text(
                  'Enregistrer',
                ),
              ),
            ],
          );
        },
      );

      if (result != true) {
        return;
      }
    }

    setState(() {
      saving = true;
    });

    await widget.state.addWorkout(
      widget.workout,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Séance enregistrée avec succès',
        ),
      ),
    );
  }
}

// ============================================================
// CARTE EXERCICE
// ============================================================

class ExerciseCard
    extends StatefulWidget {
  final int index;
  final Exercise exercise;
  final AppState state;
  final VoidCallback onChanged;

  const ExerciseCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.state,
    required this.onChanged,
  });

  @override
  State<ExerciseCard>
      createState() =>
          _ExerciseCardState();
}

class _ExerciseCardState
    extends State<ExerciseCard> {
  @override
  Widget build(BuildContext context) {
    final exercise =
        widget.exercise;

    final previous =
        widget.state
            .latestWeightForExercise(
      exercise.name,
    );

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    '${widget.index + 1}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        exercise.name,
                        style:
                            const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        exercise.muscle,
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade400,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    setState(() {
                      exercise.sets.add(
                        ExerciseSet(),
                      );
                    });

                    widget.onChanged();
                  },
                  icon: const Icon(
                    Icons.add,
                  ),
                ),
              ],
            ),

            if (previous != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                  color: Theme.of(
                    context,
                  )
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .history,
                      size: 17,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Dernière charge : '
                      '${formatNumber(previous)} kg',
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 15,
            ),

            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '#',
                    style:
                        TextStyle(
                      color: Colors
                          .grey
                          .shade500,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Charge',
                    style:
                        TextStyle(
                      color: Colors
                          .grey
                          .shade500,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Reps',
                    style:
                        TextStyle(
                      color: Colors
                          .grey
                          .shade500,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 42,
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            ...exercise.sets
                .asMap()
                .entries
                .map(
              (entry) {
                return SetRow(
                  number:
                      entry.key + 1,
                  set: entry.value,
                  onChanged: () {
                    setState(() {});
                    widget.onChanged();
                  },
                  onDelete:
                      exercise.sets
                                  .length <=
                              1
                          ? null
                          : () {
                              setState(() {
                                exercise
                                    .sets
                                    .removeAt(
                                  entry.key,
                                );
                              });

                              widget.onChanged();
                            },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LIGNE SERIE
// ============================================================

class SetRow extends StatefulWidget {
  final int number;
  final ExerciseSet set;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  const SetRow({
    super.key,
    required this.number,
    required this.set,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<SetRow> createState() =>
      _SetRowState();
}

class _SetRowState
    extends State<SetRow> {
  late final TextEditingController
      weightController;

  late final TextEditingController
      repsController;

  @override
  void initState() {
    super.initState();

    weightController =
        TextEditingController(
      text: widget.set.weight == 0
          ? ''
          : formatNumber(
              widget.set.weight,
            ),
    );

    repsController =
        TextEditingController(
      text: widget.set.reps == 0
          ? ''
          : '${widget.set.reps}',
    );
  }

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${widget.number}',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: TextField(
              controller:
                  weightController,
              keyboardType:
                  const TextInputType
                      .numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                widget.set.weight =
                    double.tryParse(
                          value.replaceAll(
                            ',',
                            '.',
                          ),
                        ) ??
                        0.0;

                widget.onChanged();
              },
              decoration:
                  InputDecoration(
                isDense: false,
                suffixText: 'kg',
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: TextField(
              controller:
                  repsController,
              keyboardType:
                  TextInputType.number,
              onChanged: (value) {
                widget.set.reps =
                    int.tryParse(
                          value,
                        ) ??
                        0;

                widget.onChanged();
              },
              decoration:
                  InputDecoration(
                isDense: false,
                suffixText: 'reps',
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),
              ),
            ),
          ),

          IconButton(
            onPressed:
                widget.onDelete,
            icon: const Icon(
              Icons
                  .delete_outline,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HISTORIQUE SEANCES
// ============================================================

class SessionsPage
    extends StatelessWidget {
  final AppState state;

  const SessionsPage({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text(
            'Séances',
          ),
          automaticallyImplyLeading:
              false,
        ),

        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: SizedBox(
            width: double.infinity,
            child:
                FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutSelectionPage(
                      state: state,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Nouvelle séance',
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        Expanded(
          child: state.history.isEmpty
              ? const Center(
                  child: EmptyCard(
                    icon:
                        Icons.history,
                    title:
                        'Aucune séance',
                    subtitle:
                        'Commence ta première séance pour créer ton historique.',
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    0,
                    16,
                    20,
                  ),
                  itemCount:
                      state.history.length,
                  itemBuilder:
                      (context, index) {
                    final record =
                        state.history[
                            index];

                    return Card(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 7,
                        ),
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons
                                .fitness_center,
                          ),
                        ),
                        title: Text(
                          record
                              .workoutName,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        subtitle: Text(
                          '${formatDateTime(record.date)}\n'
                          '${record.exercises.length} exercices',
                        ),
                        isThreeLine:
                            true,
                        trailing:
                            IconButton(
                          icon:
                              const Icon(
                            Icons
                                .delete_outline,
                          ),
                          onPressed: () {
                            confirmDeleteWorkout(
                              context,
                              state,
                              record.id,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Future<void>
    confirmDeleteWorkout(
  BuildContext context,
  AppState state,
  String id,
) async {
  final confirm =
      await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Supprimer la séance ?',
        ),
        content: const Text(
          'Cette séance sera définitivement supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text(
              'Annuler',
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text(
              'Supprimer',
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await state.deleteWorkout(id);
  }
}

// ============================================================
// PROGRESSION
// ============================================================

class ProgressPage
    extends StatefulWidget {
  final AppState state;

  const ProgressPage({
    super.key,
    required this.state,
  });

  @override
  State<ProgressPage> createState() =>
      _ProgressPageState();
}

class _ProgressPageState
    extends State<ProgressPage> {
  String? selectedExercise;

  @override
  Widget build(BuildContext context) {
    final names = <String>{};

    for (final workout
        in widget.state.history) {
      for (final exercise
          in workout.exercises) {
        names.add(
          exercise.name,
        );
      }
    }

    final exercises =
        names.toList()..sort();

    if (selectedExercise ==
            null &&
        exercises.isNotEmpty) {
      selectedExercise =
          exercises.first;
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression',
            style: TextStyle(
              fontSize: 30,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Évolution de tes performances',
            style: TextStyle(
              color:
                  Colors.grey.shade400,
            ),
          ),

          const SizedBox(height: 22),

          if (exercises.isEmpty)
            const EmptyCard(
              icon:
                  Icons.show_chart,
              title:
                  'Pas encore de données',
              subtitle:
                  'Termine une séance avec des charges pour voir ta progression.',
            )
          else ...[
            DropdownButtonFormField<
                String>(
              initialValue:
                  selectedExercise,
              decoration:
                  const InputDecoration(
                labelText:
                    'Exercice',
                border:
                    OutlineInputBorder(),
              ),
              items: exercises
                  .map(
                    (exercise) =>
                        DropdownMenuItem<
                            String>(
                      value:
                          exercise,
                      child:
                          Text(
                        exercise,
                      ),
                    ),
                  )
                  .toList(),
              onChanged:
                  (value) {
                setState(() {
                  selectedExercise =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 18,
            ),

            ProgressSummary(
              state:
                  widget.state,
              exerciseName:
                  selectedExercise!,
            ),

            const SizedBox(
              height: 18,
            ),

            ProgressChart(
              state:
                  widget.state,
              exerciseName:
                  selectedExercise!,
            ),

            const SizedBox(
              height: 18,
            ),

            ProgressHistory(
              state:
                  widget.state,
              exerciseName:
                  selectedExercise!,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// RESUME
// ============================================================

class ProgressSummary
    extends StatelessWidget {
  final AppState state;
  final String exerciseName;

  const ProgressSummary({
    super.key,
    required this.state,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final data =
        state.progressForExercise(
      exerciseName,
    );

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest =
        data.last.maxWeight;

    double best = 0;

    for (final item in data) {
      if (item.maxWeight > best) {
        best = item.maxWeight;
      }
    }

    double? previous;

    if (data.length >= 2) {
      previous =
          data[data.length - 2]
              .maxWeight;
    }

    final difference =
        previous == null
            ? null
            : latest - previous;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon:
                    Icons.emoji_events_outlined,
                title:
                    'Meilleure charge',
                value:
                    '${formatNumber(best)} kg',
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: StatCard(
                icon:
                    Icons.trending_up,
                title:
                    'Dernière charge',
                value:
                    '${formatNumber(latest)} kg',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        PerformanceIndicator(
          difference:
              difference,
        ),
      ],
    );
  }
}

// ============================================================
// INDICATEUR
// ============================================================

class PerformanceIndicator extends StatelessWidget {
  final double? difference;

  const PerformanceIndicator({
    super.key,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    final double? delta = difference;

    String title;
    String subtitle;
    IconData icon;

    if (delta == null) {
      title = 'Première mesure';
      subtitle =
          'Continue pour commencer à comparer tes performances.';
      icon = Icons.flag_outlined;
    } else if (delta > 0) {
      title = 'Progression';
      subtitle =
          '+${formatNumber(delta)} kg depuis la dernière séance';
      icon = Icons.trending_up;
    } else if (delta < 0) {
      title = 'Régression';
      subtitle =
          '${formatNumber(delta)} kg depuis la dernière séance';
      icon = Icons.trending_down;
    } else {
      title = 'Maintien';
      subtitle =
          'Même charge maximale que lors de la dernière séance';
      icon = Icons.trending_flat;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// GRAPHIQUE
// ============================================================

class ProgressChart
    extends StatelessWidget {
  final AppState state;
  final String exerciseName;

  const ProgressChart({
    super.key,
    required this.state,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final data =
        state.progressForExercise(
      exerciseName,
    );

    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];

    for (int i = 0;
        i < data.length;
        i++) {
      spots.add(
        FlSpot(
          i.toDouble(),
          data[i].maxWeight,
        ),
      );
    }

    double maxY = data
        .map((e) => e.maxWeight)
        .reduce(
          (a, b) => a > b ? a : b,
        );

    if (maxY <= 0) {
      maxY = 10;
    }

    maxY += maxY * 0.15;

    if (maxY < 10) {
      maxY = 10;
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          18,
          20,
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution de la charge',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              exerciseName,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade400,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              height: 250,
              child:
                  LineChart(
                LineChartData(
                  minX: 0,
                  maxX:
                      (data.length - 1)
                          .toDouble() <
                          1
                      ? 1
                      : (data.length - 1)
                          .toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData:
                      const FlGridData(
                    show: true,
                  ),
                  borderData:
                      FlBorderData(
                    show: false,
                  ),
                  titlesData:
                      FlTitlesData(
                    topTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),
                    rightTitles:
                        const AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            false,
                      ),
                    ),
                    bottomTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,
                        reservedSize:
                            35,
                        interval:
                            data.length <=
                                    5
                                ? 1
                                : (data.length /
                                        5)
                                    .ceil()
                                    .toDouble(),
                        getTitlesWidget:
                            (value, meta) {
                          final index =
                              value
                                  .round();

                          if (index <
                                  0 ||
                              index >=
                                  data.length) {
                            return const SizedBox
                                .shrink();
                          }

                          return Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 8,
                            ),
                            child:
                                Text(
                              '${index + 1}',
                              style:
                                  TextStyle(
                                color: Colors
                                    .grey
                                    .shade500,
                                fontSize:
                                    11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles:
                        AxisTitles(
                      sideTitles:
                          SideTitles(
                        showTitles:
                            true,
                        reservedSize:
                            45,
                        getTitlesWidget:
                            (value, meta) {
                          return Text(
                            formatNumber(
                              value,
                            ),
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade500,
                              fontSize:
                                  10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData:
                      LineTouchData(
                    enabled: true,
                    touchTooltipData:
                        LineTouchTooltipData(
                      getTooltipItems:
                          (spots) {
                        return spots
                            .map(
                          (spot) {
                            final index =
                                spot.x
                                    .round();

                            if (index <
                                    0 ||
                                index >=
                                    data.length) {
                              return null;
                            }

                            return LineTooltipItem(
                              '${formatNumber(data[index].maxWeight)} kg',
                              const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            );
                          },
                        ).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 4,
                      isStrokeCapRound:
                          true,
                      dotData:
                          const FlDotData(
                        show: true,
                      ),
                      belowBarData:
                          BarAreaData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HISTORIQUE PROGRESSION
// ============================================================

class ProgressHistory
    extends StatelessWidget {
  final AppState state;
  final String exerciseName;

  const ProgressHistory({
    super.key,
    required this.state,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final data =
        state.progressForExercise(
      exerciseName,
    );

    final reversed =
        data.reversed.toList();

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style:
                  TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            if (reversed.isEmpty)
              Text(
                'Aucune donnée.',
                style: TextStyle(
                  color:
                      Colors.grey.shade400,
                ),
              )
            else
              ...reversed.take(10).map(
                (item) {
                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      bottom: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDate(
                              item.date,
                            ),
                          ),
                        ),
                        Text(
                          '${formatNumber(item.maxWeight)} kg',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          '${item.maxReps} reps',
                          style:
                              TextStyle(
                            color: Colors
                                .grey
                                .shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// POIDS
// ============================================================

class WeightPage
    extends StatelessWidget {
  final AppState state;

  const WeightPage({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final latest =
        state.latestWeight;

    return Column(
      children: [
        AppBar(
          title:
              const Text('Poids'),
          automaticallyImplyLeading:
              false,
        ),

        Expanded(
          child: ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              10,
              20,
              30,
            ),
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets
                          .all(22),
                  child: Column(
                    children: [
                      Icon(
                        Icons
                            .monitor_weight_outlined,
                        size: 45,
                        color: Theme.of(
                          context,
                        )
                            .colorScheme
                            .primary,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        latest == null
                            ? '--'
                            : '${latest.weight.toStringAsFixed(1)} kg',
                        style:
                            const TextStyle(
                          fontSize: 34,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        latest == null
                            ? 'Aucun poids enregistré'
                            : 'Dernière mesure : ${formatDate(latest.date)}',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color: Colors
                              .grey
                              .shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton.icon(
                  onPressed: () =>
                      addWeightDialog(
                    context,
                    state,
                  ),
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Ajouter une mesure',
                  ),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              const Text(
                'Historique',
                style:
                    TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              if (state.weights.isEmpty)
                const EmptyCard(
                  icon: Icons
                      .monitor_weight,
                  title:
                      'Aucune mesure',
                  subtitle:
                      'Ajoute ton premier poids pour commencer le suivi.',
                )
              else
                ...state.weights
                    .reversed
                    .map(
                  (entry) {
                    return Card(
                      margin:
                          const EdgeInsets
                              .only(
                        bottom: 8,
                      ),
                      child: ListTile(
                        leading:
                            const CircleAvatar(
                          child: Icon(
                            Icons
                                .monitor_weight,
                          ),
                        ),
                        title:
                            Text(
                          '${entry.weight.toStringAsFixed(1)} kg',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        subtitle:
                            Text(
                          formatDateTime(
                            entry.date,
                          ),
                        ),
                        trailing:
                            IconButton(
                          icon:
                              const Icon(
                            Icons
                                .delete_outline,
                          ),
                          onPressed:
                              () async {
                            await state
                                .deleteWeight(
                              entry.id,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> addWeightDialog(
  BuildContext context,
  AppState state,
) async {
  final controller =
      TextEditingController();

  final double? value =
      await showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Ajouter ton poids',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType
                  .numberWithOptions(
            decimal: true,
          ),
          decoration:
              const InputDecoration(
            labelText: 'Poids',
            suffixText: 'kg',
            border:
                OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child: const Text(
              'Annuler',
            ),
          ),
          FilledButton(
            onPressed: () {
              final double? weight =
                  double.tryParse(
                controller.text
                    .replaceAll(
                  ',',
                  '.',
                ),
              );

              if (weight != null &&
                  weight > 0) {
                Navigator.pop(
                  context,
                  weight,
                );
              }
            },
            child: const Text(
              'Enregistrer',
            ),
          ),
        ],
      );
    },
  );

  controller.dispose();

  if (value != null) {
    await state.addWeight(value);
  }
}

// ============================================================
// PARAMETRES
// ============================================================

class SettingsPage
    extends StatelessWidget {
  final AppState state;

  const SettingsPage({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        30,
      ),
      children: [
        const Text(
          'Profil',
          style:
              TextStyle(
            fontSize: 30,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        Card(
          child: ListTile(
            leading:
                const CircleAvatar(
              radius: 27,
              child: Icon(
                Icons.person,
              ),
            ),
            title: const Text(
              'Mon profil',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${state.sessionCount} séances enregistrées',
            ),
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons
                      .fitness_center,
                ),
                title: const Text(
                  'Séances',
                ),
                subtitle:
                    const Text(
                  'Séances enregistrées',
                ),
                trailing: Text(
                  '${state.sessionCount}',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),

              const Divider(
                height: 1,
              ),

              ListTile(
                leading: const Icon(
                  Icons
                      .monitor_weight,
                ),
                title: const Text(
                  'Mesures',
                ),
                subtitle:
                    const Text(
                  'Poids enregistrés',
                ),
                trailing: Text(
                  '${state.weights.length}',
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons
                  .delete_forever_outlined,
            ),
            title: const Text(
              'Effacer toutes les données',
            ),
            subtitle:
                const Text(
              'Supprimer les séances et les mesures',
            ),
            onTap: () =>
                clearAllDataDialog(
              context,
              state,
            ),
          ),
        ),

        const SizedBox(
          height: 25,
        ),

        Center(
          child: Text(
            'Suivi Salle • V5 iPhone',
            style:
                TextStyle(
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> clearAllDataDialog(
  BuildContext context,
  AppState state,
) async {
  final confirm =
      await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Effacer toutes les données ?',
        ),
        content: const Text(
          'Toutes les séances et toutes les mesures de poids '
          'seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                false,
              );
            },
            child: const Text(
              'Annuler',
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                true,
              );
            },
            child: const Text(
              'Tout supprimer',
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await state.clearAllData();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Toutes les données ont été supprimées.',
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS GENERIQUES
// ============================================================

class StatCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(
              height: 12,
            ),
            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              title,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickAction
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 20,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                label,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(25),
        child: Column(
          children: [
            Icon(
              icon,
              size: 45,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              subtitle,
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// UTILITAIRES
// ============================================================

String formatNumber(
  double value,
) {
  if (value ==
      value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}

String formatDate(
  DateTime date,
) {
  final day =
      date.day.toString().padLeft(
            2,
            '0',
          );

  final month =
      date.month.toString().padLeft(
            2,
            '0',
          );

  final year =
      date.year.toString();

  return '$day/$month/$year';
}

String formatDateTime(
  DateTime date,
) {
  final day =
      date.day.toString().padLeft(
            2,
            '0',
          );

  final month =
      date.month.toString().padLeft(
            2,
            '0',
          );

  final year =
      date.year.toString();

  final hour =
      date.hour.toString().padLeft(
            2,
            '0',
          );

  final minute =
      date.minute.toString().padLeft(
            2,
            '0',
          );

  return '$day/$month/$year à $hour:$minute';
}