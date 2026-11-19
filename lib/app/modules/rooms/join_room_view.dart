import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import 'join_room_controller.dart';

class JoinRoomView extends GetView<JoinRoomController> {
  const JoinRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Join with code',
      subtitle: 'Private and public rooms both use codes.',
      background: CandyBackgroundStyle.purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: AppColors.yellow,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellowDark.withValues(alpha: 0.35),
                    offset: const Offset(0, 8),
                    blurRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                '🔑',
                style: TextStyle(fontSize: 46, height: 1),
              ),
            ),
          ),
          const SizedBox(height: 22),
          CandyCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter the room code',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'The host can share it from their lobby.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller.codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.visiblePassword,
                  maxLength: 6,
                  autofocus: true,
                  onChanged: controller.onCodeChanged,
                  onSubmitted: (_) => controller.join(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp('[A-HJ-NP-Z2-9a-hj-np-z]'),
                    ),
                    LengthLimitingTextInputFormatter(6),
                    _UpperCaseFormatter(),
                  ],
                  style: theme.textTheme.displaySmall?.copyWith(
                    letterSpacing: 12,
                    fontSize: 34,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'ABC123',
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 12,
                    ),
                  ),
                ),
                Obx(
                  () => controller.error.value.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: InlineBanner(
                            message: controller.error.value,
                            icon: Icons.error_outline_rounded,
                            color: AppColors.errorDark,
                            background: AppColors.errorSoft,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => ArcadeButton(
                    label: 'Join room',
                    icon: Icons.login_rounded,
                    size: ArcadeButtonSize.large,
                    expand: true,
                    loading: controller.isJoining.value,
                    onPressed: controller.join,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: controller.browseRooms,
                  child: const Text('Or browse public rooms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SafetyNote(),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.inkSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Codes are randomly generated — no guessing games. Only people with '
            'the code can enter a private room.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
