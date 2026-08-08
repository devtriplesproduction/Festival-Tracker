/// Default Indian / Maharashtra festivals for the given year.
/// Fully editable after seed — dates for lunar festivals are approximate for planning.
class DefaultFestival {
  const DefaultFestival({
    required this.name,
    required this.month,
    required this.day,
    this.category = 'Major Festival',
  });

  final String name;
  final int month;
  final int day;
  final String category;

  DateTime dateForYear(int year) => DateTime(year, month, day);
}

/// Preloaded festival calendar for Maharashtra / India agency work.
const List<DefaultFestival> kDefaultFestivals = [
  DefaultFestival(name: "New Year's Day", month: 1, day: 1, category: 'Global'),
  DefaultFestival(name: 'Makar Sankranti', month: 1, day: 14, category: 'Cultural'),
  DefaultFestival(name: 'Republic Day', month: 1, day: 26, category: 'National'),
  DefaultFestival(name: 'Maha Shivaratri', month: 2, day: 15, category: 'Religious'),
  DefaultFestival(name: 'Holi', month: 3, day: 3, category: 'Major Festival'),
  DefaultFestival(name: 'Gudi Padwa', month: 3, day: 19, category: 'Cultural'),
  DefaultFestival(name: 'Ram Navami', month: 3, day: 26, category: 'Religious'),
  DefaultFestival(name: 'Good Friday', month: 4, day: 3, category: 'Religious'),
  DefaultFestival(name: 'Maharashtra Day', month: 5, day: 1, category: 'National'),
  DefaultFestival(name: 'Eid ul-Fitr', month: 3, day: 20, category: 'Religious'),
  DefaultFestival(name: 'Independence Day', month: 8, day: 15, category: 'National'),
  DefaultFestival(name: 'Raksha Bandhan', month: 8, day: 28, category: 'Cultural'),
  DefaultFestival(name: 'Janmashtami', month: 9, day: 4, category: 'Religious'),
  DefaultFestival(name: 'Ganesh Chaturthi', month: 9, day: 14, category: 'Cultural'),
  DefaultFestival(name: 'Anant Chaturdashi', month: 9, day: 25, category: 'Religious'),
  DefaultFestival(name: 'Gandhi Jayanti', month: 10, day: 2, category: 'National'),
  DefaultFestival(name: 'Dussehra', month: 10, day: 20, category: 'Religious'),
  DefaultFestival(name: 'Diwali', month: 11, day: 8, category: 'Major Festival'),
  DefaultFestival(name: 'Bhai Dooj', month: 11, day: 10, category: 'Cultural'),
  DefaultFestival(name: 'Christmas', month: 12, day: 25, category: 'Global'),
];
