import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_transport/core/routes/app_router.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/custom_text_field.dart';
import 'package:kids_transport/core/widgets/primary_button.dart';
import 'package:kids_transport/features/parent/wallet/data/models/payment_method_model.dart';
import 'package:kids_transport/features/parent/wallet/logic/wallet_cubit/wallet_cubit.dart';
import 'package:kids_transport/features/parent/wallet/logic/wallet_cubit/wallet_state.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int? _selectedMethodId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatLimit(num v) {
    final s = v.toString();
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: Text(
          'شحن المحفظة',
          style: AppTextStyles.style(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.surfaceColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletRechargeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.errorColor,
              ),
            );
          } else if (state is WalletRechargeInitiated) {
            Navigator.pushNamed(
              context,
              AppRoutes.parentRechargeConfirmation,
              arguments: {
                'cubit': context.read<WalletCubit>(),
                'initData': state.data,
              },
            );
          }
        },
        builder: (context, state) {
          final isInitiating = state is WalletRechargeInitiating;

          if (state is WalletLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final loaded = _extractLoaded(state);
          if (loaded == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final methods = loaded.paymentMethods;
          if (methods.isEmpty) {
            return Center(
              child: Text(
                'لا توجد طرق دفع متاحة حالياً.',
                style: AppTextStyles.style(color: context.textMuted),
              ),
            );
          }

          PaymentMethodModel selectedMethod;
          if (_selectedMethodId != null &&
              methods.any((m) => m.id == _selectedMethodId)) {
            selectedMethod =
                methods.firstWhere((m) => m.id == _selectedMethodId);
          } else {
            selectedMethod = methods.first;
            _selectedMethodId = selectedMethod.id;
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المبلغ',
                    style: AppTextStyles.style(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _amountController,
                    hintText: 'أدخل المبلغ',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    prefixIcon: Icons.attach_money_rounded,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'يرجى إدخال المبلغ';
                      }
                      final parsed = double.tryParse(val);
                      if (parsed == null || parsed <= 0) {
                        return 'يرجى إدخال مبلغ صحيح';
                      }
                      if (parsed < selectedMethod.minAmount) {
                        return 'الحد الأدنى للمبلغ: ${_formatLimit(selectedMethod.minAmount)}';
                      }
                      if (parsed > selectedMethod.maxAmount) {
                        return 'الحد الأقصى للمبلغ: ${_formatLimit(selectedMethod.maxAmount)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الحد: ${_formatLimit(selectedMethod.minAmount)} - ${_formatLimit(selectedMethod.maxAmount)}',
                    style: AppTextStyles.style(
                      fontSize: 12,
                      color: context.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'اختر طريقة الدفع',
                    style: AppTextStyles.style(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...methods.map((method) {
                    final isSelected = _selectedMethodId == method.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: isInitiating
                            ? null
                            : () {
                                setState(() {
                                  _selectedMethodId = method.id;
                                });
                                _formKey.currentState?.validate();
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: AppTheme.boxDecoration(
                            color: isSelected
                                ? context.primaryColor.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: AppTheme.radius(12),
                            border: AppTheme.border(
                              color: isSelected
                                  ? context.primaryColor
                                  : context.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? context.primaryColor
                                        : context.dividerColor,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? context.primaryColor
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              _PaymentMethodIcon(iconUrl: method.iconUrl),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  method.nameAr,
                                  style: AppTextStyles.style(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: isInitiating ? 'جارٍ المتابعة...' : 'متابعة',
                    onPressed: isInitiating
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              final amount =
                                  double.parse(_amountController.text);
                              context.read<WalletCubit>().initiateRecharge(
                                    amount: amount,
                                    paymentMethodId: selectedMethod.id,
                                  );
                            }
                          },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  WalletLoaded? _extractLoaded(WalletState state) {
    if (state is WalletLoaded) return state;
    return context.read<WalletCubit>().cachedLoaded;
  }
}

class _PaymentMethodIcon extends StatelessWidget {
  final String? iconUrl;
  const _PaymentMethodIcon({required this.iconUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Icon(
          Icons.payment_rounded,
          size: 28,
          color: context.textMuted,
        );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return SizedBox(width: 32, height: 32, child: fallback());
    }
    return SizedBox(
      width: 32,
      height: 32,
      child: Image.network(
        iconUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}
