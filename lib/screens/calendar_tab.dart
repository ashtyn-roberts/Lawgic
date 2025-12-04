import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  // State variables for the calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Event state: holds the events for the currently selected day
  List<String> _selectedEvents = [];

  // 1. DUMMY EVENT DATA
  // Keys are DateTime objects stripped of time (using UTC)
  // This map should be managed by a state management solution in a real app.
  final Map<DateTime, List<String>> _events = {
    DateTime.utc(2025, 12, 9): [
      'S.B. 1007: The Digital Privacy Restoration Act',
    ],
    DateTime.utc(2025, 12, 16): ['H.R. 452: The National Infrastructure Bond'],
    DateTime.utc(2025, 12, 21): [
      'S.J. Res. 3: The Term Limits Amendment',
      'H.R. 611: The Winter Relief Economic Stimulus',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Initialize selected day to today and load its events
    // Ensure _focusedDay is normalized for comparison/lookup if using _getEventsForDay later.
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

  // --- New: Handler for Add Event Button ---
  void _addEvent() {
    // In a real application, you would navigate to an "Add Event" screen
    // or show a dialog here.
    final selectedDate = _selectedDay;
    if (selectedDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Adding event for ${DateFormat.yMd().format(selectedDate)}",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      debugPrint('Add event dialog/screen opened for ${selectedDate}');
    } else {
      // Should not happen since _selectedDay is initialized to DateTime.now()
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a day first."),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
  // ----------------------------------------

  // Renamed to build the event list section
  Widget _buildEventList(BuildContext context) {
    // Use theme colors
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onSurfaceColor = colorScheme.onSurface;

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
fixprofile
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
                      style: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
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
                          // Use a light border color from the theme
                          border: Border.all(
                            color: onSurfaceColor.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.circle,
                            size: 10,
                            color: primaryColor,
                          ),
                          title: Text(
                            eventTitle,
                            style: TextStyle(color: onSurfaceColor),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: onSurfaceColor.withOpacity(0.4),
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
    // Get the color scheme from the theme
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final onPrimaryColor = colorScheme.onPrimary;
    final secondaryColor = colorScheme.secondary; // Useful for the event marker
    final onSurfaceColor = colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar View"),
        centerTitle: true,
        // Use primary and onPrimary colors from the theme
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor, // Text/icon color
        elevation: 4,
      ),
      // --- New: Floating Action Button for Add Event ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEvent,
        label: const Text('Add Event'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        // Ensure the button is only visible when a day is selected
        tooltip: 'Add a new event',
      ),
      // ------------------------------------------------

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
                  // Use primary color with opacity
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                // Use primary color for the format button text
                formatButtonTextStyle: TextStyle(color: onPrimaryColor),
                // Use primary color for the format button border/background
                formatButtonDecoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                // Use accent/secondary color for today's decoration
                todayDecoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                // Use primary color for the selected day
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                // Use primary color for the event marker
                markerDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  // Reduce marker size
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
fixprofile
                // Ensure text colors are legible
                defaultTextStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                  ? Color(0xFFB48CFB)   // neon purple
                  : Colors.black87,
                ),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
                todayTextStyle: const TextStyle(color: Colors.white),
                selectedTextStyle: const TextStyle(color: Colors.white),

              ),
            ),
          ),

          const Divider(height: 1),

          // The event list takes up the remaining vertical space
          _buildEventList(context),
        ],
      ),
    );
  }
}