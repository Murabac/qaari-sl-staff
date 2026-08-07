class DashboardCounts {
  const DashboardCounts({
    required this.reciters,
    required this.drafts,
    required this.rejected,
    required this.pendingReview,
    required this.approved,
    this.queuePending,
  });

  final int reciters;
  final int drafts;
  final int rejected;
  final int pendingReview;
  final int approved;
  final int? queuePending;

  factory DashboardCounts.fromJson(Map<String, dynamic> json) {
    return DashboardCounts(
      reciters: (json['reciters'] as num?)?.toInt() ?? 0,
      drafts: (json['drafts'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      pendingReview: (json['pending_review'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      queuePending: (json['queue_pending'] as num?)?.toInt(),
    );
  }
}
