import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Event state: holds the events for the currently selected day
  List<String> _selectedEvents = [];

  // 1. DUMMY EVENT DATA
  // Keys are DateTime objects stripped of time (using UTC)
  final Map<DateTime, List<String>> _events = {
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day):
        ['CSC 4330 Presentation :)', 'Sprint Retrospective'],
    DateTime.utc(2025, 10, 10): ['Adore Professor Fronchetti from afar'],
    DateTime.utc(2025, 10, 15): [
      'Rub Pibbles Belly',
      'Read One Piece Spoilers',
    ],
    DateTime.utc(2025, 10, 25): ['Goon Circle'],
  };

  @override
  void initState() {
    super.initState();
    // Initialize selected day to today and load its events
    _selectedDay = _focusedDay;
    _selectedEvents = _getEventsForDay(_focusedDay);
  }

  // Helper to get events for a given day (must normalize day to UTC stripped time)
  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // Update the list of events for the new selected day
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  // Renamed to build the event list section
  Widget _buildEventList(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    // Header showing the selected date (or a placeholder if null, though it shouldn't be null now)
    final dateText = _selectedDay == null
        ? "Select a Day"
        : "Events for ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDay!)}";

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            // Replaced .withOpacity(0.1) -> .withAlpha(26) (10% opacity)
            color: primaryColor.withAlpha(26),
            width: double.infinity,
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),

          Expanded(
            // Show a list of events using ListView.builder
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      "No scheduled events for this date.",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final eventTitle = _selectedEvents[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor.withAlpha(50)),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.circle,
                            size: 10,
                            color: primaryColor,
                          ),
                          title: Text(eventTitle),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            // Handle event tap (e.g., navigate to event details screen)
                            debugPrint('Tapped on event: $eventTitle');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar View"),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // Text/icon color
        elevation: 4,
      ),
      // The body now contains both the calendar and the event list
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,

              calendarFormat: _calendarFormat,
              onFormatChanged: _onFormatChanged,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.week: 'Week',
              },

              // Event Loader: Visually marks days with events
              eventLoader: _getEventsForDay,

              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,

              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: true,
                formatButtonShowsNext: false,
                titleTextStyle: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  // Replaced .withOpacity(0.05) -> .withAlpha(13) (5% opacity)
                  color: primaryColor.withAlpha(13),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                todayDecoration: BoxDecoration(
                  // Replaced .withOpacity(0.4) -> .withAlpha(102) (40% opacity)
                  color: primaryColor.withAlpha(102),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                // Ensure text colors are legible
                defaultTextStyle: const TextStyle(color: Colors.black87),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
                todayTextStyle: const TextStyle(color: Colors.white),
                selectedTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          // The new event list takes up the remaining vertical space
          _buildEventList(context),
        ],
      ),
      // bottomNavigationBar is removed to allow the event list to take up space
      // bottomNavigationBar: _buildSelectedDateFooter(),
    );
  }
}
