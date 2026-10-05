import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kids_transport/core/routes/app_router.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/utils/theme_context.dart';
import 'package:kids_transport/core/widgets/primary_button.dart';
import 'package:kids_transport/features/parent/wallet/data/models/recharge_mock_pay_response_model.dart';
import 'package:kids_transport/features/parent/wallet/data/models/recharge_response_model.dart';
import 'package:kids_transport/features/parent/wallet/logic/wallet_cubit/wallet_cubit.dart';
import 'package:kids_transport/features/parent/wallet/logic/wallet_cubit/wallet_state.dart';

class RechargeConfirmationScreen extends StatelessWidget {
  final RechargeInitiateResponseModel initData;

  const RechargeConfirmationScreen({super.key, required this.initData});

  String _formatAmount(num v) {
    final s = v.toString();
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }

  void _showSuccessDialog(
    BuildContext context,
    RechargeMockPayResponseModel data,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: ctx.surfaceColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ctx.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: ctx.successColor, size: 64),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تم الدفع بنجاح',
              textAlign: TextAlign.center,
              style: AppTextStyles.style(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ctx.textPrimary,
              ),
            ),
            if (data.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.style(
                  fontSize: 13,
                  color: ctx.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _SuccessRow(
              label: 'المبلغ',
              value: '${_formatAmount(data.amount)} ${data.currency}',
            ),
            _SuccessRow(
              label: 'الرصيد الحالي',
              value:
                  '${_formatAmount(data.currentBalance)} ${data.currency}',
            ),
            if (data.invoice != null)
              _SuccessRow(
                label: 'رقم الفاتورة',
                value: data.invoice!.invoiceNumber,
              ),
            if (data.transactionRef.isNotEmpty)
              _SuccessRow(
                label: 'رقم العملية',
                value: data.transactionRef,
              ),
            if (data.invoice?.paidAt != null &&
                data.invoice!.paidAt!.isNotEmpty)
              _SuccessRow(
                label: 'تاريخ الدفع',
                value: data.invoice!.paidAt!,
              ),
            const SizedBox(height: 20),
            if (data.invoice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name == AppRoutes.parentWallet ||
                          route.isFirst,
                    );
                    Navigator.pushNamed(
                      context,
                      AppRoutes.parentInvoiceDetails,
                      arguments: data.invoice!.id,
                    );
                  },
                  child: const Text('عرض الفاتورة'),
                ),
              ),
            PrimaryButton(
              label: 'حسناً',
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil(
                  (route) =>
                      route.settings.name == AppRoutes.parentWallet ||
                      route.isFirst,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: Text(
          'تأكيد الدفع',
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
          } else if (state is WalletRechargeSuccess) {
            _showSuccessDialog(context, state.data);
          }
        },
        builder: (context, state) {
          final isConfirming = state is WalletRechargeConfirming;
          final method = initData.paymentMethod;
          final iconUrl = method?.iconUrl;
          final methodName = method?.nameAr ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.boxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppTheme.radius(16),
                    border: AppTheme.border(color: context.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _ConfirmationIcon(iconUrl: iconUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'طريقة الدفع',
                                  style: AppTextStyles.style(
                                    fontSize: 12,
                                    color: context.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  methodName,
                                  style: AppTextStyles.style(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: context.dividerColor),
                      const SizedBox(height: 12),
                      _KeyValue(
                        label: 'المبلغ',
                        value:
                            '${_formatAmount(initData.amount)} ${initData.currency}',
                      ),
                      const SizedBox(height: 10),
                      _KeyValue(
                        label: 'رقم العملية',
                        value: initData.transactionRef,
                      ),
                      if (initData.expiresInMinutes != null) ...[
                        const SizedBox(height: 10),
                        _KeyValue(
                          label: 'صالح لمدة',
                          value: '${initData.expiresInMinutes} دقيقة',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: AppTheme.boxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.06),
                    borderRadius: AppTheme.radius(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: context.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'العملية جاهزة للتأكيد. بالضغط على "تأكيد الدفع" سيتم '
                          'خصم المبلغ عبر بوابة الدفع وإيداعه في محفظتك.',
                          style: AppTextStyles.style(
                            fontSize: 13,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: isConfirming ? 'جارٍ التأكيد...' : 'تأكيد الدفع',
                  onPressed: isConfirming
                      ? null
                      : () {
                          context
                              .read<WalletCubit>()
                              .confirmRecharge(initiateData: initData);
                        },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isConfirming
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConfirmationIcon extends StatelessWidget {
  final String? iconUrl;
  const _ConfirmationIcon({required this.iconUrl});

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Icon(
          Icons.payment_rounded,
          size: 40,
          color: context.textMuted,
        );

    if (iconUrl == null || iconUrl!.isEmpty) {
      return SizedBox(width: 48, height: 48, child: fallback());
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: Image.network(
        iconUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.style(
            fontSize: 13,
            color: context.textMuted,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.style(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;
  const _SuccessRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.style(
              fontSize: 12,
              color: context.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.style(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
