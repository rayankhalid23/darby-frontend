import 'package:flutter/material.dart';
import 'package:kids_transport/features/parent/search/data/models/driver_search_model.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import 'package:kids_transport/core/theme/app_theme.dart';
import 'driver_search_card_widget.dart';
import 'empty_state_widget.dart';
import 'search_loading_widget.dart';
import 'warning_card.dart';

class NameOrNumberSearchWidget extends StatefulWidget {
  final List<DriverSearchModel> filteredDrivers;
  final bool isLoading;
  final ValueChanged<String> onSearch;
  final Function(DriverSearchModel) onDriverTapped;
  final VoidCallback onBack;

  const NameOrNumberSearchWidget({
    super.key,
    required this.filteredDrivers,
    this.isLoading = false,
    required this.onSearch,
    required this.onDriverTapped,
    required this.onBack,
  });

  @override
  State<NameOrNumberSearchWidget> createState() =>
      _NameOrNumberSearchWidgetState();
}

class _NameOrNumberSearchWidgetState extends State<NameOrNumberSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    widget.onSearch(_controller.text);
    setState(() {
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // حقل البحث (SearchBar)
          TextField(
            controller: _controller,
            textDirection: TextDirection.rtl,
            decoration: AppTheme.inputDecoration(
              context,
              hintText: 'البحث باسم السائق أو رقم الهاتف',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? AppColors.grey400 : AppColors.grey500,
              ),
            ),
            onSubmitted: (_) => _handleSearch(),
          ),
          const SizedBox(height: 12),

          // زر البحث (Search Button)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _handleSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: isDark
                    ? AppColors.grey800
                    : AppColors.grey200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      'بحث',
                      style: AppTextStyles.style(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // النتائج (Results)
          if (widget.isLoading && _hasSearched)
            const SearchLoadingWidget(itemCount: 3)
          else if (_hasSearched)
            _buildDriversList(context),
        ],
      ),
    );
  }

  Widget _buildDriversList(BuildContext context) {
    if (widget.filteredDrivers.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          icon: Icons.person_search_rounded,
          title: 'لم يتم العثور على نتائج.',
          description:
              'تأكد من كتابة الاسم أو رقم الهاتف بشكل صحيح وحاول مرة أخرى.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WarningCard(
          icon: Icons.info_outline_rounded,
          color: Theme.of(context).colorScheme.primary,
          message:
              "يمكنك إرسال طلبات اشتراك لأكثر من سائق في نفس الوقت. بمجرد قبول أحد السائقين لطلبك، سيتم إلغاء بقية الطلبات تلقائيًا تفاديًا للازدواجية.",
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.filteredDrivers.length,
          itemBuilder: (context, index) {
            final driver = widget.filteredDrivers[index];
            return DriverSearchCardWidget(
              driver: driver,
              isSelected: false,
              showPricing:
                  false, // لا تظهر الأسعار لأن الأطفال لم يتم تحديدهم بعد
              isSubscriptionSearch: false,
              showCheckbox: false,
              onTap: () => widget.onDriverTapped(driver),
            );
          },
        ),
      ],
    );
  }
}
