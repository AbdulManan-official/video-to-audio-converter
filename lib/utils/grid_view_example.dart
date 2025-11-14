// import 'package:flutter/material.dart';
//
// class GridViewExample extends StatelessWidget {
//   const GridViewExample({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // Define the list of items to display
//     final List<String> list = ['One', 'Two', 'Three'];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Grid View Example'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0), // Add padding around the grid
//         child: Column(
//           children: [
//             Flexible(
//               child: GridView.builder(
//                 itemCount: 100,
//                 gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
//                   maxCrossAxisExtent: 200, // Maximum width of each grid item
//                   crossAxisSpacing: 10, // Horizontal spacing between grid items
//                   mainAxisSpacing: 10, // Vertical spacing between grid items
//                 ),
//                 itemBuilder: (context, index) {
//                   final String listName = list[index]; // Item text
//                   return Container(
//                     decoration: BoxDecoration(
//                       color: Colors.green, // Background color
//                       borderRadius:
//                           BorderRadius.circular(10), // Rounded corners
//                     ),
//                     alignment:
//                         Alignment.center, // Center content in the container
//                     child: Text(
//                       listName,
//                       style: const TextStyle(
//                         fontSize: 24, // Font size
//                         color: Colors.white, // Text color
//                         fontWeight: FontWeight.bold, // Text weight
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
