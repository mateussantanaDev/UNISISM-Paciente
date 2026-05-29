import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Input controlado — label uppercase em cima, input quadrado, mono opcional.
/// Adaptado pra paciente: input grande (60dp), label legível (não micro).
class FormFieldX extends StatefulWidget {
  const FormFieldX({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.readOnly = false,
    this.mono = false,
    this.maxLength,
    this.helpText,
    this.errorText,
    this.suffix,
    this.prefix,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool readOnly;
  final bool mono;
  final int? maxLength;
  final String? helpText;
  final String? errorText;
  final Widget? suffix;
  final Widget? prefix;
  final bool autofocus;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  State<FormFieldX> createState() => _FormFieldXState();
}

class _FormFieldXState extends State<FormFieldX> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.obscureText;
    final inputStyle = widget.mono
        ? AppTypography.data.copyWith(fontSize: 17, color: AppColors.slate900)
        : AppTypography.bodyLarge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.sm),
          child: Text(
            widget.label.toUpperCase(),
            style: AppTypography.labelInstitucional,
          ),
        ),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          obscureText: _obscure,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: inputStyle,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helpText,
            helperStyle: AppTypography.bodySmall,
            counterText: '',
            fillColor: widget.readOnly ? AppColors.slate50 : AppColors.white,
            prefixIcon: widget.prefix,
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.slate600,
                    ),
                    tooltip: _obscure ? 'Mostrar senha' : 'Esconder senha',
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
