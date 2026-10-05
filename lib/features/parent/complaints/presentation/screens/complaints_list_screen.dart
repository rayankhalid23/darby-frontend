import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_transport/core/di/dependency_injection.dart';
import 'package:kids_transport/core/theme/app_colors.dart';
import 'package:kids_transport/core/theme/text_styles.dart';
import '../../logic/complaints_cubit.dart';
import '../../logic/complaints_state.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaint_empty_widget.dart';
import '../widgets/complaint_loading_widget.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/driver_trip_model.dart';
import '../../data/repositories/complaints_repository.dart';
import '../widgets/complaint_trip_dropdown.dart';
import 'complaint_details_screen.dart';

class ComplaintsListScreen extends StatefulWidget {
  const ComplaintsListScreen({super.key});

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<ComplaintsCubit>(
      create: (context) => getIt<ComplaintsCubit>()..fetchComplaints(type: 'all'),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
          appBar: AppBar(
            title: Text(
              'سجل الشكاوى والمتابعة',
              style: AppTextStyles.style(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.textDark,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
            foregroundColor: isDark ? AppColors.white : AppColors.textDark,
            surfaceTintColor: Colors.transparent,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: isDark ? AppColors.grey400 : AppColors.textMuted,
              labelStyle: AppTextStyles.style(fontSize: 13.sp, fontWeight: FontWeight.bold),
              unselectedLabelStyle: AppTextStyles.style(fontSize: 13.sp),
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'قيد الانتظار'),
                Tab(text: 'تمت المعالجة'),
                Tab(text: 'مغلقة'),
              ],
            ),
          ),
          body: Builder(
            builder: (blocCtx) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _ComplaintsTabList(type: 'all', blocContext: blocCtx),
                  _ComplaintsTabList(type: 'pending', blocContext: blocCtx),
                  _ComplaintsTabList(type: 'completed', blocContext: blocCtx),
                  _ComplaintsTabList(type: 'dismissed', blocContext: blocCtx),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ComplaintsTabList extends StatefulWidget {
  final String type;
  final BuildContext blocContext;

  const _ComplaintsTabList({
    required this.type,
    required this.blocContext,
  });

  @override
  State<_ComplaintsTabList> createState() => _ComplaintsTabListState();
}

class _ComplaintsTabListState extends State<_ComplaintsTabList> {
  @override
  void initState() {
    super.initState();
    widget.blocContext.read<ComplaintsCubit>().fetchComplaints(type: widget.type);
  }

  void _showDeleteDialog(BuildContext context, int id, ComplaintsCubit cubit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          title: Text(
            'حذف الشكوى',
            style: AppTextStyles.style(
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في إلغاء وحذف هذه الشكوى نهائياً؟',
            style: AppTextStyles.style(
              fontSize: 13.sp,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('إلغاء', style: AppTextStyles.style(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dCtx);
                await cubit.deleteComplaint(id);
              },
              child: Text('نعم، حذف', style: AppTextStyles.style(color: AppColors.error, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, ComplaintModel complaint, ComplaintsCubit cubit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      builder: (bCtx) => _EditComplaintBottomSheet(
        complaint: complaint,
        cubit: cubit,
      ),
    ).then((changed) {
      if (changed == true && mounted) {
        cubit.fetchComplaints(type: widget.type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ComplaintsCubit, ComplaintsState>(
      bloc: widget.blocContext.read<ComplaintsCubit>(),
      listener: (context, state) {
        if (state is ComplaintsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: AppTextStyles.style(color: AppColors.white)),
              backgroundColor: AppColors.error,
            ),
          );
        } else if (state is ComplaintSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: AppTextStyles.style(color: AppColors.white)),
              backgroundColor: AppColors.success,
            ),
          );
          if (mounted) {
            widget.blocContext.read<ComplaintsCubit>().fetchComplaints(type: widget.type);
          }
        }
      },
      builder: (context, state) {
        if (state is ComplaintsLoading && state is! ComplaintsLoaded) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: const ComplaintLoadingWidget(),
          );
        }

        if (state is ComplaintsLoaded) {
          final complaints = state.complaints;
          if (complaints.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => widget.blocContext.read<ComplaintsCubit>().fetchComplaints(type: widget.type),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  ComplaintEmptyWidget(),
                ],
              ),
            );
          }

          final cubit = widget.blocContext.read<ComplaintsCubit>();
          return RefreshIndicator(
            onRefresh: () => cubit.fetchComplaints(type: widget.type),
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                return ComplaintCard(
                  complaint: complaint,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintDetailsScreen(complaintId: complaint.id),
                      ),
                    ).then((changed) {
                      if (changed == true && mounted) {
                        cubit.fetchComplaints(type: widget.type);
                      }
                    });
                  },
                  onEdit: () => _showEditSheet(context, complaint, cubit),
                  onDelete: () => _showDeleteDialog(context, complaint.id, cubit),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => widget.blocContext.read<ComplaintsCubit>().fetchComplaints(type: widget.type),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              ComplaintEmptyWidget(),
            ],
          ),
        );
      },
    );
  }
}

class _EditComplaintBottomSheet extends StatefulWidget {
  final ComplaintModel complaint;
  final ComplaintsCubit cubit;

  const _EditComplaintBottomSheet({
    required this.complaint,
    required this.cubit,
  });

  @override
  State<_EditComplaintBottomSheet> createState() => _EditComplaintBottomSheetState();
}

class _EditComplaintBottomSheetState extends State<_EditComplaintBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  int? _selectedTripId;
  List<DriverTripModel> _trips = [];
  bool _isLoadingTrips = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.complaint.description);
    _selectedTripId = widget.complaint.tripId;
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final repo = getIt<ComplaintsRepository>();
      final trips = await repo.getDriverTrips(widget.complaint.driverId);
      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoadingTrips = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTrips = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.w,
          right: 20.w,
          top: 20.h,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey700 : AppColors.grey300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'تعديل الشكوى',
                  style: AppTextStyles.style(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'اختر الرحلة المعنية بالشكوى',
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ),
                SizedBox(height: 8.h),
                ComplaintTripDropdown(
                  trips: _trips,
                  selectedTripId: _selectedTripId,
                  isLoading: _isLoadingTrips,
                  onChanged: (val) {
                    setState(() {
                      _selectedTripId = val;
                    });
                  },
                ),
                SizedBox(height: 16.h),
                Text(
                  'تفاصيل الشكوى',
                  style: AppTextStyles.style(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: AppTextStyles.style(
                    fontSize: 13.sp,
                    color: isDark ? AppColors.white : AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب الشكوى بالتفصيل هنا لمتابعتها مع الإدارة...',
                    hintStyle: AppTextStyles.style(
                      fontSize: 11.5.sp,
                      color: isDark ? AppColors.grey500 : AppColors.textMuted,
                    ),
                    contentPadding: EdgeInsets.all(12.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: isDark ? AppColors.grey800 : AppColors.grey300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'يرجى كتابة نص الشكوى';
                    }
                    if (val.trim().length < 10) {
                      return 'يرجى إدخال 10 حروف على الأقل لوصف الشكوى بشكل كامل';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isSubmitting = true);
                              try {
                                await widget.cubit.updateComplaint(
                                  id: widget.complaint.id,
                                  description: _descriptionController.text.trim(),
                                  tripId: _selectedTripId,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            }
                          },
                    child: _isSubmitting
                        ? SizedBox(
                            width: 18.w,
                            height: 18.h,
                            child: const CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : Text(
                            'حفظ التعديلات',
                            style: AppTextStyles.style(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
