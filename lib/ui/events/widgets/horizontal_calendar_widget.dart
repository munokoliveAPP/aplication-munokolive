import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class HorizontalCalendarWidget extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<DateTime> eventDates;

  const HorizontalCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.eventDates = const [],
  });

  @override
  State<HorizontalCalendarWidget> createState() =>
      _HorizontalCalendarWidgetState();
}

class _HorizontalCalendarWidgetState extends State<HorizontalCalendarWidget> {
  late ScrollController _scrollController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void didUpdateWidget(HorizontalCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _selectedDate = widget.selectedDate;
      _scrollToSelectedDate();
    }
  }

  void _scrollToSelectedDate() {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final daysDiff = _selectedDate.difference(startDate).inDays;
    const itemWidth = 70.0;
    final targetOffset = daysDiff * itemWidth - 100;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _generateDates() {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final dates = <DateTime>[];

    // Generate 60 days from today
    for (int i = 0; i < 60; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    return dates;
  }

  bool _hasEvent(DateTime date) {
    return widget.eventDates.any((eventDate) {
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    });
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final dates = _generateDates();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A0B2E).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final hasEvent = _hasEvent(date);
                final isToday = _isToday(date);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    widget.onDateSelected(date);
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFDF00FF), Color(0xFF800080)],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : isToday
                            ? const Color(0xFFDF00FF)
                            : Colors.white.withValues(alpha: 0.1),
                        width: isToday ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFDF00FF,
                                ).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE', 'fr_FR').format(date),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hasEvent)
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFDF00FF),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isToday && !isSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Text(
                              'Aujourd\'hui',
                              style: TextStyle(
                                color: Color(0xFFDF00FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
