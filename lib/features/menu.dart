import 'package:flutter/material.dart';
import './books/pages/home_page.dart';

class Menu extends StatefulWidget {
  final String userId;
  const Menu({super.key, required this.userId});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  int _currentTabIndex = 0;
  late final List<Widget> _appScreens;

  @override
  void initState() {
    super.initState();

    _appScreens = [
      HomePage(userId: widget.userId),
      const Scaffold(
        backgroundColor: Color(0xFFF4F4F0),
        body: Center(child: Text('Minha estante')),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFFF4F4F0);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: IndexedStack(index: _currentTabIndex, children: _appScreens),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black, width: 3))),
      padding: EdgeInsets.only(top: 12, bottom: MediaQuery.of(context).padding.bottom+12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Início'
          ),
          _buildTabItem(
            index: 1,
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Minhas leituras'
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label
}) {
    final bool isSelected = _currentTabIndex == index;
    const Color focalColor = Color(0xFFFFE800);

    return GestureDetector(
      onTap: () {
        setState(() { _currentTabIndex = index; });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? focalColor: Colors.transparent,
          border: isSelected ? Border.all(color: Colors.black, width: 2)
                             : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isSelected ? const [BoxShadow(color: Colors.black, offset: Offset(3, 3))] : null,
        ),
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: Colors.black, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }
}
