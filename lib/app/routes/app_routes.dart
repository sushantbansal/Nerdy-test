abstract class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const auth = '/auth';
  static const home = '/home';

  static const browseRooms = '/rooms';
  static const createRoom = '/rooms/create';
  static const joinRoom = '/rooms/join';
  static const lobby = '/lobby';
  static const match = '/match';

  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const publicProfile = '/players';

  static const progress = '/progress';
  static const achievements = '/achievements';
  static const leaderboards = '/leaderboards';
  static const practice = '/practice';
  static const tutorial = '/tutorial';
  static const settings = '/settings';

  static String lobbyFor(String roomId) => '/room/$roomId';
  static String matchFor(String roomId) => '/room/$roomId/play';
  static String profileFor(String playerId) => '/players?playerId=$playerId';
}
