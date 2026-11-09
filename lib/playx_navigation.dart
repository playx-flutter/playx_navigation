library;

export 'package:go_router/go_router.dart';

export 'src/binding/playx_binding.dart';
export 'src/binding/playx_page_state.dart';
export 'src/controller/playx_page_lifecycle.dart';
export 'src/controller/playx_route_controller.dart' show PlayxControllerBuilder;
export 'src/controller/playx_view.dart';
export 'src/models/playx_page_config.dart'
    show
        PlayxControllerFinder,
        PlayxControllerRegistrar,
        PlayxErrorWidgetBuilder,
        PlayxPageConfig,
        PlayxRouteWidgetBuilder,
        PlayxShellWidgetBuilder;

export 'src/extensions/go_router_state_extensions.dart';
export 'src/guards/playx_guard.dart';
export 'src/models/playx_page_configuration.dart';
export 'src/models/playx_page_transition.dart';
export 'src/playx_navigation.dart';
export 'src/router/playx_router.dart';
export 'src/routes/playx_page.dart' show PlayxScope, PlayxScopeProvider;
export 'src/routes/playx_route.dart';
export 'src/routes/playx_shell_branch.dart';
export 'src/widgets/playx_back_button.dart';
export 'src/widgets/playx_navigation_builder.dart';
