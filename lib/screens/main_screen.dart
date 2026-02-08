import 'package:flutter/material.dart';
import 'package:kmovie/screens/home_screen.dart';
import 'package:kmovie/screens/search_screen.dart';
import 'package:kmovie/screens/watch_later_screen.dart';
import 'package:kmovie/widgets/bottom_nav_widget.dart';
import 'package:kmovie/widgets/app_dialogs.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    SearchScreen(),
    WatchLaterScreen(isMainTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldExit = await AppDialogs.showExitConfirm(context);
        if (shouldExit) SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavWidget(
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
