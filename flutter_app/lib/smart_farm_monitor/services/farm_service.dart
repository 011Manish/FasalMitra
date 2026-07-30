import '../models/farm.dart';

class FarmService {
  Future<List<Farm>> getFarms() async {
    return [
      Farm(
        id: 1,
        name: "Tomato Farm",
        location: "Kathmandu",
        status: "Online",
      ),
      Farm(
        id: 2,
        name: "Greenhouse A",
        location: "Pokhara",
        status: "Online",
      ),
      Farm(
        id: 3,
        name: "Corn Field",
        location: "Chitwan",
        status: "Offline",
      ),
    ];
  }
}
