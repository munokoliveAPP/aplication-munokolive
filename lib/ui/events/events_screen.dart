import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/events_provider.dart';
import '../theme/app_theme.dart';
import 'widgets/premium_event_card.dart';
import 'publish_event_page.dart';
import 'event_details_page.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/animations.dart';
import '../../services/analytics_service.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isCalendarView = false; // Toggle for Master Calendar View

  final List<String> _categories = [
    'All',
    'Concert',
    'Répétition',
    'Culte',
    'Conférence',
    'Atelier',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshEvents() async {
    // In Riverpod, refreshing a StreamProvider usually happens automatically
    // or by invalidating the container.
    // For now, we simulate a delay for UX.
    return ref.refresh(eventsStreamProvider.future).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(filteredEventsProvider);
    final currentFilter = ref.watch(eventFilterProvider);

    // Analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logScreenView(screenName: 'events');
    });

    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme Base
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Événements',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor:
            Colors.transparent, // Glassmorphism handled by body gradient
        elevation: 0,
        centerTitle: false,
        actions: [
          // Master Calendar Toggle
          IconButton(
            icon: Icon(
              _isCalendarView ? Icons.view_agenda : Icons.calendar_month,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
              });
              // Sync with native agenda logic could go here
            },
            tooltip: _isCalendarView ? 'Vue Liste' : 'Vue Calendrier',
          ),
          // Add Event Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 20),
            ),
            onPressed: () {
              context.pushWithTransition(const PublishEventPage());
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A), // Dark Grey top
              Colors.black, // Black bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Categories Filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = currentFilter.category == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(eventFilterProvider.notifier)
                              .update(
                                (state) => state.copyWith(
                                  category: selected ? category : 'All',
                                ),
                              );
                        },
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Events List with Pull-to-Refresh & Animations
              Expanded(
                child: eventsAsync.when(
                  loading: () => SkeletonList(
                    itemCount: 4,
                    itemBuilder: (context, index) => const EventCardSkeleton(),
                  ),
                  error: (error, stack) => ErrorStateWidget(
                    message: ErrorHandler.getErrorMessage(error),
                    onRetry: () => ref.invalidate(eventsStreamProvider),
                  ),
                  data: (events) {
                    if (events.isEmpty) {
                      return EmptyStates.events();
                    }

                    if (_isCalendarView) {
                      // Simple Calendar List View for now (Grouped by Month)
                      // In a real "Master Calendar", we'd use table_calendar package
                      return RefreshIndicator(
                        onRefresh: _refreshEvents,
                        color: AppTheme.primaryColor,
                        backgroundColor: Colors.black,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            // Group header logic could go here
                            return PremiumEventCard(
                              event: event,
                              onTap: () {
                                context.pushWithTransition(
                                  EventDetailsPage(event: event),
                                );
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      // Standard Card List with Animation
                      return RefreshIndicator(
                        onRefresh: _refreshEvents,
                        color: AppTheme.primaryColor,
                        backgroundColor: Colors.black,
                        child: AnimationLimiter(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: PremiumEventCard(
                                      event: event,
                                      onTap: () {
                                        context.pushWithTransition(
                                          EventDetailsPage(event: event),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
