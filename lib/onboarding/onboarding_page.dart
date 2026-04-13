import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      gradient: [Color(0xFF2EC4B6), Color(0xFF3D8BFF)],
      icon: Icons.pets,
      title: 'Pet Tracker\'a\nHoş Geldin!',
      description:
          'Evcil hayvanlarının tüm sağlık bilgilerini\nbir arada takip et.',
    ),
    _OnboardingData(
      gradient: [Color(0xFF3D8BFF), Color(0xFFFF6B6B)],
      icon: Icons.medication_outlined,
      title: 'Sağlık Takibi',
      description:
          'Aşı takvimini, ilaçlarını ve\nveterinere gitme zamanlarını asla kaçırma.',
    ),
    _OnboardingData(
      gradient: [Color(0xFF6C63FF), Color(0xFF2EC4B6)],
      icon: Icons.monitor_weight_outlined,
      title: 'Kilo & Gelişim',
      description:
          'Kilo değişimini grafikle izle,\ngeçmiş ziyaretlerini kaydet.',
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onDone();
    }
  }

  void _skip() => widget.onDone();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _OnboardingSlide(data: _pages[i]),
          ),
          // skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: AnimatedOpacity(
              opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: _skip,
                child: const Text('Atla',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          // bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 32,
            right: 32,
            child: Column(
              children: [
                // dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_currentPage].gradient[0],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      textStyle: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Başlayalım!'
                          : 'Devam',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 160),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 48),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 17,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.description,
  });
}
