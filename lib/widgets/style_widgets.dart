import 'package:flutter/material.dart';
import '../theme/registre/app_theme.dart';
import '../theme/registre/register_styles.dart';


class StyledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? Function(String?) validator;
  final IconData? icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? hint;
  final Widget? suffixIcon;
  final VoidCallback? onChanged;

  const StyledTextField({
    Key? key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.validator,
    this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.textInputAction,
    this.onFieldSubmitted,
    this.hint,
    this.suffixIcon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: RegisterStyles.defaultMargin(context), // 👈 corregido
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(label, style: RegisterStyles.labelStyle(context)),
              ),
              Text(' *', style: RegisterStyles.requiredLabelStyle(context)),
            ],
          ),
          SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            onChanged: (value) {
              if (onChanged != null) onChanged!();
            },
            style: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 16)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 14)),
              prefixIcon: icon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: RegisterStyles.getResponsiveSize(context, 16),
                        right: RegisterStyles.getResponsiveSize(context, 12),
                      ),
                      child: Icon(
                        icon,
                        color: AppTheme.textTertiary,
                        size: RegisterStyles.mediumIcon(context),
                      ),
                    )
                  : null,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText 
                            ? Icons.visibility_off_rounded 
                            : Icons.visibility_rounded,
                        color: AppTheme.textTertiary,
                        size: RegisterStyles.mediumIcon(context),
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : suffixIcon ?? (controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: RegisterStyles.mediumIcon(context),
                          ),
                          onPressed: () {
                            controller.clear();
                            if (onChanged != null) onChanged!();
                          },
                          color: AppTheme.textTertiary,
                        )
                      : null),
            ),
          ),
        ],
      ),
    );
  }
}

class StyledSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const StyledSectionHeader({
    Key? key,
    required this.title,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: RegisterStyles.sectionHeaderMargin(context), // 👈 corregido
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(RegisterStyles.getResponsiveSize(context, 8)),
            decoration: RegisterStyles.sectionIconDecoration(context),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: RegisterStyles.mediumIcon(context),
            ),
          ),
          SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
          Expanded(
            child: Text(title, style: RegisterStyles.sectionHeaderStyle(context)),
          ),
          SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StyledProgressIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const StyledProgressIndicator({
    Key? key,
    required this.currentPage,
    required this.totalPages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: RegisterStyles.getResponsiveSize(context, 24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso ${currentPage + 1} de $totalPages',
                style: RegisterStyles.progressTextStyle(context),
              ),
              Text(
                '${((currentPage + 1) / totalPages * 100).toInt()}%',
                style: RegisterStyles.progressPercentStyle(context),
              ),
            ],
          ),
          SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
          Row(
            children: List.generate(totalPages, (index) {
              final isActive = index <= currentPage;
              final isCurrent = index == currentPage;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: RegisterStyles.getResponsiveSize(context, 6),
                  margin: EdgeInsets.only(
                    right: index < totalPages - 1 ? RegisterStyles.getResponsiveSize(context, 8) : 0
                  ),
                  decoration: RegisterStyles.progressIndicatorDecoration(isActive, isCurrent),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class StyledPasswordValidation extends StatelessWidget {
  final String password;
  final bool validLength;
  final bool hasUpperOrDigit;
  final bool hasSpecial;

  const StyledPasswordValidation({
    Key? key,
    required this.password,
    required this.validLength,
    required this.hasUpperOrDigit,
    required this.hasSpecial,
  }) : super(key: key);

  double get passwordStrength {
    int score = 0;
    if (validLength) score++;
    if (hasUpperOrDigit) score += 2;
    if (hasSpecial) score++;
    return score / 4.0;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strengthColor = RegisterStyles.getStrengthColor(passwordStrength);
    final strengthText = RegisterStyles.getStrengthText(passwordStrength);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(top: RegisterStyles.getResponsiveSize(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                size: RegisterStyles.smallIcon(context),
                color: strengthColor,
              ),
              SizedBox(width: RegisterStyles.getResponsiveSize(context, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strengthText,
                          style: RegisterStyles.strengthTextStyle(context, strengthColor),
                        ),
                        Text(
                          '${(passwordStrength * 100).toInt()}%',
                          style: RegisterStyles.strengthPercentStyle(context),
                        ),
                      ],
                    ),
                    SizedBox(height: RegisterStyles.getResponsiveSize(context, 4)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: passwordStrength,
                        backgroundColor: AppTheme.borderColor,
                        valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                        minHeight: RegisterStyles.getResponsiveSize(context, 3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: RegisterStyles.getResponsiveSize(context, 10)),
          Wrap(
            spacing: RegisterStyles.getResponsiveSize(context, 6),
            runSpacing: RegisterStyles.getResponsiveSize(context, 6),
            children: [
              _ValidationChip(text: '8+ caracteres', isValid: validLength),
              _ValidationChip(text: 'Mayús + número', isValid: hasUpperOrDigit),
              _ValidationChip(text: 'Símbolo especial', isValid: hasSpecial),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationChip extends StatelessWidget {
  final String text;
  final bool isValid;

  const _ValidationChip({
    required this.text,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: RegisterStyles.getResponsiveSize(context, 8),
        vertical: RegisterStyles.getResponsiveSize(context, 4),
      ),
      decoration: RegisterStyles.chipDecoration(isValid),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isValid ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(isValid),
              size: RegisterStyles.getResponsiveSize(context, 14),
              color: isValid 
                  ? AppTheme.secondaryColor 
                  : AppTheme.textTertiary,
            ),
          ),
          SizedBox(width: RegisterStyles.getResponsiveSize(context, 4)),
          Text(text, style: RegisterStyles.chipTextStyle(context, isValid)),
        ],
      ),
    );
  }
}

class StyledStepHeader extends StatelessWidget {
  final int currentPage;
  final List<String> titles;
  final List<String> subtitles;
  final List<IconData> icons;

  const StyledStepHeader({
    Key? key,
    required this.currentPage,
    required this.titles,
    required this.subtitles,
    required this.icons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: RegisterStyles.getResponsiveSize(context, 80),
          height: RegisterStyles.getResponsiveSize(context, 80),
          decoration: RegisterStyles.iconContainerDecoration(context),
          child: Icon(
            icons[currentPage],
            color: AppTheme.primaryColor,
            size: RegisterStyles.largeIcon(context),
          ),
        ),
        SizedBox(height: RegisterStyles.getResponsiveSize(context, 20)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            titles[currentPage],
            key: ValueKey(currentPage),
            style: RegisterStyles.titleStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: RegisterStyles.getResponsiveSize(context, 12)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            subtitles[currentPage],
            key: ValueKey('subtitle_$currentPage'),
            style: RegisterStyles.subtitleStyle(context),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class StyledSummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const StyledSummaryItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: RegisterStyles.summaryItemMargin(context), // 👈 corregido
      padding: RegisterStyles.defaultPadding(context),
      decoration: RegisterStyles.summaryItemDecoration(),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(RegisterStyles.getResponsiveSize(context, 8)),
            decoration: RegisterStyles.summaryItemIconDecoration(context),
            child: Icon(
              icon,
              size: RegisterStyles.mediumIcon(context),
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: RegisterStyles.getResponsiveSize(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: RegisterStyles.getResponsiveSize(context, 12),
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: RegisterStyles.getResponsiveSize(context, 2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: RegisterStyles.getResponsiveSize(context, 16),
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
