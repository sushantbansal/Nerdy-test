import 'package:get/get.dart';

import '../modules/achievements/achievements_binding.dart';
import '../modules/achievements/achievements_view.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/leaderboard/leaderboard_binding.dart';
import '../modules/leaderboard/leaderboard_view.dart';
import '../modules/lobby/lobby_binding.dart';
import '../modules/lobby/lobby_view.dart';
import '../modules/match/match_binding.dart';
import '../modules/match/match_view.dart';
import '../modules/practice/practice_binding.dart';
import '../modules/practice/practice_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_edit_binding.dart';
import '../modules/profile/profile_edit_view.dart';
import '../modules/profile/profile_view.dart';
import '../modules/progress/progress_binding.dart';
import '../modules/progress/progress_view.dart';
import '../modules/rooms/create_room_binding.dart';
import '../modules/rooms/create_room_view.dart';
import '../modules/rooms/join_room_binding.dart';
import '../modules/rooms/join_room_view.dart';
import '../modules/rooms/room_browser_binding.dart';
import '../modules/rooms/room_browser_view.dart';
import '../modules/settings/settings_binding.dart';
import '../modules/settings/settings_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/tutorial/tutorial_binding.dart';
import '../modules/tutorial/tutorial_view.dart';
import '../modules/welcome/welcome_binding.dart';
import '../modules/welcome/welcome_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomeView(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.browseRooms,
      page: () => const RoomBrowserView(),
      binding: RoomBrowserBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.createRoom,
      page: () => const CreateRoomView(),
      binding: CreateRoomBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.joinRoom,
      page: () => const JoinRoomView(),
      binding: JoinRoomBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.lobby,
      page: () => const LobbyView(),
      binding: LobbyBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.match,
      page: () => const MatchView(),
      binding: MatchBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const ProfileEditView(),
      binding: ProfileEditBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.publicProfile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.progress,
      page: () => const ProgressView(),
      binding: ProgressBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.achievements,
      page: () => const AchievementsView(),
      binding: AchievementsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.leaderboards,
      page: () => const LeaderboardView(),
      binding: LeaderboardBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.practice,
      page: () => const PracticeView(),
      binding: PracticeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.tutorial,
      page: () => const TutorialView(),
      binding: TutorialBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
