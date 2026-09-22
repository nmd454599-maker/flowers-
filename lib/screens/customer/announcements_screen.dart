import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import 'home/home_campaigns.dart';
import 'home/home_occasions.dart';
import 'search_screen.dart';

class AnnouncementsScreen extends StatelessWidget {
  final AppState state;
  const AnnouncementsScreen({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    void search(String query) => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SearchScreen(state: state, initialQuery: query)));
    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      body: ListView(children: [
        Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 36),
                const SizedBox(height: 16),
                Text('أفكار تُزهر بالفرح',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('اكتشف مجموعات الورد والهدايا لمناسباتك القادمة.'),
              ],
            )),
        HomeCampaigns(onSearch: search),
        const Padding(
            padding: EdgeInsets.all(24),
            child: Text('لكل مناسبة هدية',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
        HomeOccasions(onSearch: search),
        const SizedBox(height: 32),
      ]),
    );
  }
}
