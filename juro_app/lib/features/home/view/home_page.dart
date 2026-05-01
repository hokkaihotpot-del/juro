import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/models/daily_menu.dart';
import '../cubit/menu_cubit.dart';
import '../repository/menu_repository.dart';
import 'widgets/daily_signal_bar.dart';
import 'widgets/meal_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MenuCubit(MenuRepository()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy年M月d日（E）', 'ja').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の献立'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: BlocBuilder<MenuCubit, MenuState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<MenuCubit>().proposeMenu(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      today,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ),
                if (state is MenuInitial)
                  SliverFillRemaining(
                    child: _InitialView(
                      onTap: () =>
                          context.read<MenuCubit>().proposeMenu(),
                    ),
                  )
                else if (state is MenuLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state is MenuError)
                  SliverFillRemaining(
                    child: _ErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<MenuCubit>().proposeMenu(),
                    ),
                  )
                else if (state is MenuLoaded) ...[
                  _buildLoaded(context, state.proposal),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<MenuCubit, MenuState>(
        builder: (context, state) {
          if (state is MenuLoaded || state is MenuInitial) {
            return FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).pushNamed('/nutrition'),
              icon: const Icon(Icons.mic),
              label: const Text('料理を確認'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, DailyMenuProposal proposal) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // フォールバック通知
        if (proposal.isFallback)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '献立の候補が少なくなっています。似た献立になる場合があります。',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        // 1日合計の信号色バー
        DailySignalBar(
          phosphorusSignal: proposal.dailyPhosphorusSignal,
          potassiumSignal: proposal.dailyPotassiumSignal,
          sodiumSignal: proposal.dailySodiumSignal,
          waterSignal: proposal.dailyWaterSignal,
        ),
        if (proposal.allDailyGreen)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '🟢 今日の献立は1日を通して安心です',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF388E3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
          ),
        if (proposal.breakfast != null)
          MealCard(
            meal: proposal.breakfast!,
            title: '朝食',
            icon: Icons.wb_sunny_outlined,
          ),
        if (proposal.lunch != null)
          MealCard(
            meal: proposal.lunch!,
            title: '昼食',
            icon: Icons.wb_cloudy_outlined,
          ),
        if (proposal.dinner != null)
          MealCard(
            meal: proposal.dinner!,
            title: '夕食',
            icon: Icons.nights_stay_outlined,
          ),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu,
                size: 80,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            const Text(
              '今日の献立を取得しましょう',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.refresh),
              label: const Text('献立を提案してもらう'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: onRetry,
                child: const Text('再試行')),
          ],
        ),
      ),
    );
  }
}
