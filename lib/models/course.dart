import 'festival.dart';

/// 코스(1박2일) 모델
class CourseItem {
  final String time;
  final CourseItemType type;
  final String name;
  final String desc;
  final int cost;
  final double lat;
  final double lng;

  const CourseItem({
    required this.time,
    required this.type,
    required this.name,
    required this.desc,
    required this.cost,
    this.lat = 0,
    this.lng = 0,
  });
}

enum CourseItemType { festival, food, spot, stay }

class CourseDay {
  final int day;
  final List<CourseItem> items;
  const CourseDay({required this.day, required this.items});

  int get total => items.fold(0, (s, i) => s + i.cost);
}

class Course {
  final String title;
  final List<CourseDay> days;
  const Course({required this.title, required this.days});

  int get total => days.fold(0, (s, d) => s + d.total);
  int get placeCount => days.fold(0, (s, d) => s + d.items.length);
}

/// 경유지 (내비게이션)
class RouteStop {
  final String id;
  final String name;
  final String sub;
  final RouteStopType type;
  final String? imageUrl;
  final Festival? festival;

  const RouteStop({
    required this.id,
    required this.name,
    required this.sub,
    required this.type,
    this.imageUrl,
    this.festival,
  });
}

enum RouteStopType { origin, festival, food, spot, stay }
