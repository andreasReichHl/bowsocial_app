import 'package:bowsocial_app/components/app_page_header.dart';
import 'package:bowsocial_app/pages/profile_page.dart';
import 'package:bowsocial_app/pages/tournament_page.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color _navIconGreenLight = Color(0xFF6D863E);
  static const Color _navIconGreenDark = Color(0xFF8FB339);
  int _currentIndex = 2;
  final GlobalKey<TournamentPageState> _tournamentPageKey =
      GlobalKey<TournamentPageState>();

  final _items = const [
    BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(top: 6),
        child: Icon(Symbols.history, weight: 200),
      ),
      label: 'History',
    ),
    BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(top: 6),
        child: Icon(Symbols.bar_chart, weight: 200),
      ),
      label: 'Statistik',
    ),
    BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(top: 6),
        child: Icon(Symbols.trophy, weight: 200),
      ),
      label: 'Tournament',
    ),
    BottomNavigationBarItem(
      icon: Padding(
        padding: EdgeInsets.only(top: 6),
        child: Icon(Symbols.person, weight: 200),
      ),
      label: 'Profil',
    ),
  ];

  Widget _buildBody() {
    switch (_currentIndex) {
      case 1:
        return const Center(child: Text('Statistik'));
      case 2:
        return TournamentPage(key: _tournamentPageKey);
      case 3:
        return const ProfilePage();
      default:
        return const Center(child: Text('History'));
    }
  }

  String _headerTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Statistik';
      case 2:
        return 'Tournament';
      case 3:
        return 'Profil';
      default:
        return 'History';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    final navAccent = theme.brightness == Brightness.light
        ? _navIconGreenLight
        : _navIconGreenDark;
    final chromeBg = theme.brightness == Brightness.light
        ? Color.alphaBlend(
            Colors.white.withAlpha(120),
            theme.scaffoldBackgroundColor,
          )
        : Color.alphaBlend(
            Colors.white.withAlpha(18),
            theme.scaffoldBackgroundColor,
          );
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          AppPageHeader(
            title: _currentIndex == 2 ? 'TOURNAMENT' : _headerTitle(),
            centerTitle: _currentIndex == 2,
            titleColor: _currentIndex == 2 ? navAccent : null,
            trailing: _currentIndex == 2
                ? IconButton(
                    onPressed: () {
                      _tournamentPageKey.currentState?.openCreateSheet();
                    },
                    icon: Icon(
                      Symbols.add_circle,
                      size: 30,
                      color: navAccent,
                      weight: 300,
                    ),
                  )
                : null,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: chromeBg,
          border: Border(
            top: BorderSide(color: schema.secondary.withAlpha(60), width: 0.5),
          ),
        ),
        child: Theme(
          data: theme.copyWith(canvasColor: chromeBg),
          child: BottomNavigationBar(
            backgroundColor: chromeBg,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedItemColor: navAccent,
            unselectedItemColor: navAccent,
            selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w400,
            ),
            unselectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w400,
            ),
            currentIndex: _currentIndex,
            items: _items,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        ),
      ),
    );
  }
}
