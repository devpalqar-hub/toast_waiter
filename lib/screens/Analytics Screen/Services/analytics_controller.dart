
// import 'package:savorya_staff/models/restuarent.dart';
// import 'package:savorya_staff/services/apiservice.dart';


// class AnalyticsController extends GetxController {
//   var restaurants = <RestaurantModel>[].obs;
//   var selectedRestaurant = Rxn<RestaurantModel>();
//   var isLoading = false.obs;

//   @override
//   void onInit() {
//     fetchRestaurants();
//     super.onInit();
//   }

//   Future<void> fetchRestaurants() async {
//     isLoading.value = true;

//     final res = await ApiService.getRestaurants();

//     if (res.ok) {
//       restaurants.value = res.data!;
//       if (restaurants.isNotEmpty) {
//         selectedRestaurant.value = restaurants.first;
//       }
//     }

//     isLoading.value = false;
//   }

//   void changeRestaurant(RestaurantModel r) {
//     selectedRestaurant.value = r;

//     // 👉 later call analytics API using r.id
//   }
// }