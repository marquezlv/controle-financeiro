import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../screens/home_screen.dart';
import '../screens/expense_screen.dart';
import '../widgets/dialogs/add_transaction_sheet.dart';
import '../screens/income_screen.dart';
import '../screens/organization_screen.dart';
import 'suspense_menu.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<ExpenseScreenState> expenseKey =
      GlobalKey<ExpenseScreenState>();
  final GlobalKey<IncomeScreenState> incomeKey = GlobalKey<IncomeScreenState>();
    final GlobalKey<OrganizationScreenState> organizationKey =
      GlobalKey<OrganizationScreenState>();

  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(key: homeKey),
    ExpenseScreen(key: expenseKey),
    IncomeScreen(key: incomeKey),
    OrganizationScreen(key: organizationKey),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onProjectSelected(ProjectModel project) {
    // When a project is selected from the menu, reload screens context
    setState(() {
      _currentIndex = 0; // Go to home screen
    });
    // Trigger reload of screens to show new project data
    homeKey.currentState?.loadTransactions();
    expenseKey.currentState?.reload();
    incomeKey.currentState?.reload();
    organizationKey.currentState?.reload();
  }

  void _openAddTransactionModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return AddTransactionSheet(
              scrollController: scrollController,
              onSaved: () {
                if (_currentIndex == 0) {
                  homeKey.currentState?.loadTransactions();
                } else if (_currentIndex == 1) {
                  expenseKey.currentState?.reload();
                } else if (_currentIndex == 2) {
                  incomeKey.currentState?.reload();
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SuspenseMenuDrawer(
        onProjectSelected: _onProjectSelected,
      ),
      body: Stack(
        children: [
          _screens[_currentIndex],
          Positioned(
            top: 0,
            right: 0,
            child: Builder(
              builder: (context) => SuspenseMenuButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF2F6BFF),
        onPressed: _openAddTransactionModal,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () => _changePage(0),
              ),
              IconButton(
                icon: Icon(Icons.trending_down),
                onPressed: () => _changePage(1),
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(Icons.trending_up),
                onPressed: () => _changePage(2),
              ),
              IconButton(
                icon: Icon(Icons.folder),
                onPressed: () => _changePage(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
