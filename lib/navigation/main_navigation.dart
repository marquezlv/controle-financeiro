import 'package:flutter/material.dart';
import '../screens/home_sreen.dart';
import '../screens/expense_screen.dart';
import '../screens/add_transaction_sheet.dart';
import '../screens/income_screen.dart';
import '../screens/organization_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();

  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(key: homeKey),
    ExpenseScreen(),
    IncomeScreen(),
    OrganizationScreen(),
  ];

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddTransactionModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return AddTransactionSheet();
      },
    );

    // Atualiza a home
    homeKey.currentState?.loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

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
