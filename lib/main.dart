import 'package:flutter/material.dart';
import 'package:ouroboros_mobile/providers/active_plan_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ouroboros_mobile/widgets/create_plan_modal.dart';
import 'package:ouroboros_mobile/providers/subject_provider.dart';
import 'package:ouroboros_mobile/widgets/study_register_modal.dart';
import 'package:ouroboros_mobile/widgets/filter_modal.dart';
import 'package:ouroboros_mobile/widgets/plan_selector.dart';
import 'package:ouroboros_mobile/widgets/floating_stopwatch_button.dart';

// Telas da BottomNavigationBar
import 'package:ouroboros_mobile/screens/plans_screen.dart';
import 'package:ouroboros_mobile/screens/planning_screen.dart';
import 'package:ouroboros_mobile/screens/revisions_screen.dart';
import 'package:ouroboros_mobile/screens/stats_screen.dart';
import 'package:ouroboros_mobile/screens/history_screen.dart';

// Telas do Drawer
import 'package:ouroboros_mobile/screens/home_screen.dart';
import 'package:ouroboros_mobile/screens/subjects_screen.dart';
import 'package:ouroboros_mobile/screens/edital_screen.dart';
import 'package:ouroboros_mobile/screens/simulados_screen.dart';
import 'package:ouroboros_mobile/screens/mentoria_screen.dart';
import 'package:ouroboros_mobile/screens/support_screen.dart';
import 'package:ouroboros_mobile/screens/backup_screen.dart';
import 'package:ouroboros_mobile/screens/simulados/add_edit_simulado_screen.dart';

import 'package:ouroboros_mobile/providers/plans_provider.dart';
import 'package:ouroboros_mobile/providers/planning_provider.dart';
import 'package:ouroboros_mobile/providers/history_provider.dart';
import 'package:ouroboros_mobile/providers/all_subjects_provider.dart';
import 'package:ouroboros_mobile/providers/review_provider.dart';
import 'package:ouroboros_mobile/providers/filter_provider.dart';
import 'package:ouroboros_mobile/providers/reminders_provider.dart';
import 'package:ouroboros_mobile/providers/simulados_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uuid/uuid.dart';
import 'package:ouroboros_mobile/models/data_models.dart';
import 'package:ouroboros_mobile/screens/login_screen.dart';
import 'package:ouroboros_mobile/providers/auth_provider.dart';


void main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await initializeDateFormatting('pt_BR', null); // Initialize date formatting for pt_BR

  // Adicionado para inicializar a plataforma do webview
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Adicionado
        ChangeNotifierProxyProvider<AuthProvider, PlansProvider>(
          create: (context) => PlansProvider(authProvider: Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => PlansProvider(authProvider: auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AllSubjectsProvider>(
          create: (context) => AllSubjectsProvider(authProvider: Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => AllSubjectsProvider(authProvider: auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ActivePlanProvider>(
          create: (context) => ActivePlanProvider(authProvider: Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => ActivePlanProvider(authProvider: auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReviewProvider>(
          create: (context) => ReviewProvider(authProvider: Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => ReviewProvider(authProvider: auth),
        ),
        ChangeNotifierProvider(create: (context) => FilterProvider()),
        ChangeNotifierProxyProvider3<AuthProvider, ReviewProvider, FilterProvider, HistoryProvider>(
          create: (context) => HistoryProvider(
            Provider.of<ReviewProvider>(context, listen: false),
            Provider.of<FilterProvider>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, reviewProvider, filterProvider, previousHistory) {
            if (previousHistory == null) {
              return HistoryProvider(reviewProvider, filterProvider, auth);
            }
            return previousHistory;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubjectProvider>(
          create: (context) => SubjectProvider(authProvider: Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => SubjectProvider(authProvider: auth),
        ),
        ChangeNotifierProvider(create: (_) => MentoriaProvider()),
        ChangeNotifierProvider(create: (_) => RemindersProvider()),
        ChangeNotifierProvider(create: (_) => SimuladosProvider()), // Adicionado SimuladosProvider aqui
        ChangeNotifierProxyProvider2<AuthProvider, ActivePlanProvider, PlanningProvider>(
          create: (context) => PlanningProvider(
            mentoriaProvider: Provider.of<MentoriaProvider>(context, listen: false),
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (_, auth, activePlan, previous) => previous!..updateForPlan(activePlan.activePlanId),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return MaterialApp(
          title: 'Ouroboros Mobile',
          theme: ThemeData(
            primarySwatch: createMaterialColor(const Color(0xFFF59E0B)), // gold-500
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF9FAFB), // gray-50
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF1F2937)), // gray-900
              bodyMedium: TextStyle(color: Color(0xFF1F2937)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF9FAFB), // gray-50
              foregroundColor: Color(0xFF1F2937), // gray-900
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            primarySwatch: createMaterialColor(const Color(0xFFF59E0B)), // gold-500
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF1F2937), // gray-900
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFF9FAFB)), // gray-50
              bodyMedium: TextStyle(color: Color(0xFFF9FAFB)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F2937), // gray-900
              foregroundColor: Color(0xFFF9FAFB), // gray-50
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: ThemeMode.system, // Pode ser alterado para ThemeMode.light ou ThemeMode.dark
          home: authProvider.isLoggedIn ? const HomePage() : const LoginScreen(),
        );
      },
    );
  }
}

MaterialColor createMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  void _handleGetRecommendation(BuildContext context) async {
    // Show loading indicator immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Get providers
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false);
    final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

    // Ensure data is loaded. Assuming fetchData methods are awaitable.
    await allSubjectsProvider.fetchData();
    await historyProvider.fetchHistory();
    await planningProvider.loadData(); // This provider has loadData instead of fetchData

    // Dismiss loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (planningProvider.studyCycle == null || planningProvider.studyCycle!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum ciclo de estudos ativo para sugerir.')),
        );
      }
      return;
    }

    final recommendation = planningProvider.getRecommendedSession(
      studyRecords: historyProvider.records,
      subjects: allSubjectsProvider.subjects,
      reviewRecords: Provider.of<ReviewProvider>(context, listen: false).allReviewRecords,
    );
    final recommendedTopic = recommendation['recommendedTopic'];
    final justification = recommendation['justification'];
    final nextSession = recommendation['nextSession'] as StudySession?;

    if (nextSession == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(justification ?? "Erro desconhecido na sugestão.")),
        );
      }
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final initialRecord = StudyRecord(
      id: Uuid().v4(),
      userId: authProvider.currentUser!.name,
      plan_id: activePlanProvider.activePlan?.id ?? '',
      date: DateTime.now().toIso8601String(),
      subject_id: nextSession.subjectId,
      topic: recommendedTopic?.topic_text ?? nextSession.subject,
      study_time: nextSession.duration * 60 * 1000,
      category: 'teoria',
      questions: {},
      review_periods: [],
      teoria_finalizada: false,
      count_in_planning: true,
      pages: [],
      videos: [],
    );

        if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => StudyRegisterModal(
          planId: initialRecord.plan_id,
          initialRecord: initialRecord, // Passa o registro inicial preenchido
          onSave: (newRecord) {
            historyProvider.addStudyRecord(newRecord);
            planningProvider.updateProgress(newRecord); // Adicionado
          },
        ),
      );
    }
  }

  int _selectedIndex = 5;

  int _bottomNavSelectedIndex = 0; // Novo índice para a BottomNavigationBar

  bool _isDrawerOpen = false;
  bool _planningScreenEditMode = false;

  late List<Widget> _allScreens;
  late List<String> _allAppBarTitles;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _allScreens = <Widget>[
      // BottomNavigationBar items
      PlansScreen(),
      PlanningScreen(isEditMode: _planningScreenEditMode, onToggleEditMode: _togglePlanningScreenEditMode, onResetCycle: () => Provider.of<PlanningProvider>(context, listen: false).resetStudyCycle()),
      RevisionsScreen(),
      StatsScreen(),
      HistoryScreen(),
      // Drawer items
      DashboardScreen(),
      SubjectsScreen(),
      EditalScreen(),
      SimuladosScreen(),
      MentoriaScreen(),
      SupportScreen(),
      BackupScreen(),
    ];

    _allAppBarTitles = <String>[
      // BottomNavigationBar titles
      'Planos',
      'Planejamento',
      'Revisões',
      'Estatísticas',
      'Histórico',
      // Drawer titles
      'Home',
      'Matérias',
      'Edital',
      'Simulados',
      'Mentoria Algorítmica',
      'Apoie o Projeto',
      'Backup',
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlanningScreenEditMode() {
    setState(() {
      _planningScreenEditMode = !_planningScreenEditMode;
      // Recria a lista de telas para que PlanningScreen seja recriada com o novo isEditMode
      _allScreens[1] = PlanningScreen(isEditMode: _planningScreenEditMode, onToggleEditMode: _togglePlanningScreenEditMode, onResetCycle: () => Provider.of<PlanningProvider>(context, listen: false).resetStudyCycle());
    });
  }

  Future<void> _showStudyRegisterModal(BuildContext context) async {
    final activePlanProvider = Provider.of<ActivePlanProvider>(context, listen: false);
    final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
    final planningProvider = Provider.of<PlanningProvider>(context, listen: false); // Adicionado

    if (activePlanProvider.activePlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crie e selecione um plano de estudos primeiro!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StudyRegisterModal(
        planId: activePlanProvider.activePlan!.id,
        onSave: (newRecord) {
          historyProvider.addStudyRecord(newRecord);
          planningProvider.updateProgress(newRecord); // Adicionado
        },
      ),
    );
  }

    void _onItemTapped(int index) {

      setState(() {

        _selectedIndex = index;

        _bottomNavSelectedIndex = index; // Atualiza o índice da BottomNavigationBar

      });

    }

  

    void _onDrawerItemTapped(int index) {

      setState(() {

        _selectedIndex = index;

        _bottomNavSelectedIndex = -1; // Nenhum item selecionado na BottomNavigationBar

      });

      Navigator.pop(context); // Fecha o Drawer

    }

  

    @override

    Widget build(BuildContext context) {
    return Consumer<PlanningProvider>(
      builder: (context, planningProvider, child) {
        final bool hasActiveCycle = planningProvider.studyCycle != null && planningProvider.studyCycle!.isNotEmpty;

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                leading: Builder(
                  builder: (context) => ScaleTransition(
                    scale: _scaleAnimation,
                    child: IconButton(
                      iconSize: 40, // Aumenta o tamanho total do botão
                      icon: Container(
                        padding: const EdgeInsets.all(2.0), // Aumenta o preenchimento
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          )
                        ),
                        child: Image.asset('logo/logo.png', height: 40, width: 40), // Aumenta o tamanho da imagem
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                title: _isDrawerOpen ? const Text('') : Text(_allAppBarTitles.elementAt(_selectedIndex)),
                actions: <Widget>[
                  if (_selectedIndex == 1 && hasActiveCycle)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow), // Novo ícone para iniciar estudo
                      label: const Text('Iniciar Estudo Sugerido'),
                      onPressed: () => _handleGetRecommendation(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  if (_selectedIndex == 1 && hasActiveCycle)
                    IconButton(
                      icon: Icon(_planningScreenEditMode ? Icons.check : Icons.edit),
                      onPressed: _togglePlanningScreenEditMode,
                      tooltip: _planningScreenEditMode ? 'Concluir Edição' : 'Editar Ciclo',
                    ),
                  if (_selectedIndex == 1 && hasActiveCycle)
                    IconButton(
                      icon: const Icon(Icons.delete), // Ícone de lixeira
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Apagar Ciclo de Estudo'),
                              content: const Text('Tem certeza de que deseja apagar o ciclo de estudo atual? Esta ação é irreversível.'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Provider.of<PlanningProvider>(context, listen: false).resetStudyCycle();
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Apagar', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      tooltip: 'Apagar Ciclo',
                    ),
                  if (_selectedIndex == 0) // PlansScreen index
                    Builder(
                      builder: (context) => ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Novo Plano'),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return const CreatePlanModal();
                            },
                          );
                        },
                      ),
                    ),
                  if (_selectedIndex == 5) // DashboardScreen index
                    Builder(
                      builder: (context) => ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle),
                        label: const Text('Adicionar Estudo'),
                        onPressed: () => _showStudyRegisterModal(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  if (_selectedIndex == 4) // HistoryScreen index
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showStudyRegisterModal(context),
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Adicionar Estudo'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                                final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
                                return FilterModal(
                                  screen: FilterScreen.history,
                                  availableCategories: historyProvider.availableCategories,
                                  availableSubjects: allSubjectsProvider.subjects,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filtros'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Add some spacing
                      ],
                    ),
                  if (_selectedIndex == 8) // SimuladosScreen index
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const AddEditSimuladoScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Novo Simulado'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  if (_selectedIndex == 3) // StatsScreen index
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showStudyRegisterModal(context),
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Adicionar Estudo'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
                                final allSubjectsProvider = Provider.of<AllSubjectsProvider>(context, listen: false);
                                return FilterModal(
                                  screen: FilterScreen.stats,
                                  availableCategories: historyProvider.availableCategories,
                                  availableSubjects: allSubjectsProvider.subjects,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filtros'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Add some spacing
                      ],
                    ),
                  if (_selectedIndex == 7) // EditalScreen index
                    ElevatedButton.icon(
                      onPressed: () { /* TODO: Implementar modal de registro de estudo */ },
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Adicionar Estudo'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  if (_selectedIndex == 2) // RevisionsScreen index
                    ElevatedButton.icon(
                      onPressed: () => _showStudyRegisterModal(context),
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Adicionar Estudo'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  if (_selectedIndex == 9) // SupportScreen index
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () { /* TODO: Implementar compartilhamento */ },
                      tooltip: 'Compartilhar',
                    ),
                ],
              ),
              body: _allScreens.elementAt(_selectedIndex),
              onDrawerChanged: (isOpened) {
                setState(() {
                  _isDrawerOpen = isOpened;
                });
              },
              drawer: Drawer(
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                          Container(
                            height: 120, // Altura menor
                            color: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.all(16.0),
                            child: Image.asset('logo/logo-marca.png'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.home),
                            title: const Text('Home'),
                            onTap: () => _onDrawerItemTapped(5), // Index da HomeScreen em _allScreens
                          ),
                          ListTile(
                            leading: const Icon(Icons.book),
                            title: const Text('Matérias'),
                            onTap: () => _onDrawerItemTapped(6), // Index da SubjectsScreen em _allScreens
                          ),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Edital'),
                            onTap: () => _onDrawerItemTapped(7), // Index da EditalScreen em _allScreens
                          ),
                          ListTile(
                            leading: const Icon(Icons.quiz),
                            title: const Text('Simulados'),
                            onTap: () => _onDrawerItemTapped(8), // Index da SimuladosScreen em _allScreens
                          ),
                          ListTile(
                            leading: const Icon(Icons.psychology),
                            title: const Text('Mentoria Algorítmica'),
                            onTap: () => _onDrawerItemTapped(9), // Index da MentoriaScreen em _allScreens
                          ),
                          ListTile(
                            leading: const Icon(Icons.favorite),
                            title: const Text('Apoie o Projeto'),
                            onTap: () => _onDrawerItemTapped(10), // Index da SupportScreen em _allScreens
                          ),
                          ListTile(
                            leading: const Icon(Icons.backup),
                            title: const Text('Backup'),
                            onTap: () => _onDrawerItemTapped(11), // Index da BackupScreen em _allScreens
                          ),
                          const Divider(),
                          Consumer<AuthProvider>(
                            builder: (context, auth, child) {
                              final userName = auth.currentUser?.name ?? '';
                              return ListTile(
                                leading: const Icon(Icons.logout),
                                title: Text('Sair ($userName)'),
                                onTap: () {
                                  auth.logout();
                                  Navigator.pop(context); // Fecha o Drawer
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const ListTile(
                      leading: Icon(Icons.folder_open),
                      title: PlanSelector(),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment),
                    label: 'Planos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_today),
                    label: 'Planejamento',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.rate_review),
                    label: 'Revisões',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'Estatísticas',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history),
                    label: 'Histórico',
                  ),
                ],
                currentIndex: _selectedIndex < 5 ? _selectedIndex : 0,
                selectedItemColor: _selectedIndex < 5 ? Theme.of(context).primaryColor : Colors.grey,
                unselectedItemColor: Colors.grey,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
              ),
            ),
            const FloatingStopwatchButton(),
          ],
        );
      },
    );
  }
}