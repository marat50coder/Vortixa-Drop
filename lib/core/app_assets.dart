class AppAssets {
  AppAssets._();

  static const gameName = 'assets/branding/game_name.webp';
  static const icon = 'assets/branding/icon.png';

  static const verticalLoading = 'assets/loading/vt_boot_port.webp';
  static const horizontalLoading = 'assets/loading/vt_boot_land.webp';

  static const dropChamber = 'assets/gameplay/drop_chamber_background_asset.webp';
  static const vortexCore = 'assets/gameplay/vortex_core_background_asset.webp';
  static const vortexFunnel = 'assets/gameplay/vortex_funnel_asset.webp';
  static const neonOrbit = 'assets/gameplay/neon_orbit_background_asset.webp';
  static const resultGlow = 'assets/gameplay/result_glow_asset.webp';
  static const emptyState = 'assets/gameplay/empty_state_illustration_asset.webp';
  static const savedSetsArt = 'assets/gameplay/saved_set_illustration_asset.webp';
  static const historyArt = 'assets/gameplay/history_illustration_asset.webp';

  static const onboardingAdd = 'assets/onboarding/onboarding_add.png';
  static const onboardingDrop = 'assets/onboarding/onboarding_drop.png';
  static const onboardingResult = 'assets/onboarding/onboarding_result.png';

  static const ballCyan = 'assets/balls/ball_cyan.png';
  static const ballMagenta = 'assets/balls/ball_magenta.png';
  static const ballViolet = 'assets/balls/ball_violet.png';
  static const ballLime = 'assets/balls/ball_lime.png';
  static const ballBlue = 'assets/balls/ball_blue.png';
  static const ballOrange = 'assets/balls/ball_orange.png';
  static const ballPink = 'assets/balls/ball_pink.png';
  static const ballTurquoise = 'assets/balls/ball_turquoise.png';

  static const balls = <String>[
    ballCyan,
    ballMagenta,
    ballViolet,
    ballLime,
    ballBlue,
    ballOrange,
    ballPink,
    ballTurquoise,
  ];

  static const soundLaunch = 'sounds/vt_boot_chime.mp3';
  static const soundTap = 'sounds/vt_pad_click.mp3';
  static const soundMenuOpen = 'sounds/vt_drawer_in.mp3';
  static const soundMenuClose = 'sounds/vt_drawer_out.mp3';
  static const soundSave = 'sounds/vt_keep_ok.mp3';
  static const soundError = 'sounds/vt_warn_blip.mp3';
  static const soundBallAdd = 'sounds/vt_orb_in.mp3';
  static const soundBallRemove = 'sounds/vt_orb_out.mp3';
  static const soundDropStart = 'sounds/vt_fall_go.mp3';
  static const soundCollision = 'sounds/vt_orb_hit.mp3';
  static const soundVortex = 'sounds/vt_gyre_loop.mp3';
  static const soundResult = 'sounds/vt_pick_fanfare.mp3';
}
