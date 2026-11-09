import 'package:flutter/material.dart';
import 'package:playx_navigation/playx_navigation.dart';
import 'package:playx_navigation_example/explore/explore_details_controller.dart';
import 'package:playx_navigation_example/explore/widgets/explore_details_info.dart';

/// Explore Details page — gets its controller with [PlayxView], like GetX's
/// `GetView`, but scoped to this page.
class ExploreDetailsPage extends PlayxView<ExploreDetailsController> {
  const ExploreDetailsPage({super.key});

  @override
  Widget buildView(BuildContext context, ExploreDetailsController controller) {
    return Scaffold(
      appBar: AppBar(title: Text('Explore Details #${controller.id}')),
      // A child view in a separate file resolves the same controller.
      body: const Center(child: ExploreDetailsInfo()),
    );
  }
}
