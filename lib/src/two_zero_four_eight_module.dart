import 'package:flutter/material.dart';
import 'package:game_module/game_module.dart';

import 'two_zero_four_eight_page.dart';

GameModule get twoZeroFourEightModule => const _TwoZeroFourEightModule();

class _TwoZeroFourEightModule implements GameModule {
  const _TwoZeroFourEightModule();

  @override
  GameDescriptor get descriptor => const GameDescriptor(
        id: '2048',
        name: '2048',
        description: 'Combine matching tiles to reach 2048.',
        icon: Icons.view_module_outlined,
        color: Color(0xFFEDC22E),
        build: _buildPage,
      );

  static Widget _buildPage(BuildContext context) =>
      const TwoZeroFourEightPage();
}
