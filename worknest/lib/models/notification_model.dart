class NotificationModel {
  final String  id;
  final String  userId;
  final String  companyId;
  final String  type;       // leave_approved / leave_rejected / claim_approved / claim_rejected
  final String  title;
  final String  body;
  final bool    isRead;
  final String? refId;      // leave/claim record id
  final String? refType;    // "leave" | "claim"
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.refId,
    this.refType,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> m) {
    return NotificationModel(
      id:        (m['Id']        ?? m['id']        ?? '').toString(),
      userId:    (m['UserId']    ?? m['user_id']    ?? '').toString(),
      companyId: (m['CompanyId'] ?? m['company_id'] ?? '').toString(),
      type:      (m['Type']      ?? m['type']       ?? '').toString(),
      title:     (m['Title']     ?? m['title']      ?? '').toString(),
      body:      (m['Body']      ?? m['body']       ?? '').toString(),
      isRead:    (m['IsRead']    ?? m['is_read']    ?? false) as bool,
      refId:     (m['RefId']     ?? m['ref_id'])?.toString(),
      refType:   (m['RefType']   ?? m['ref_type'])?.toString(),
      createdAt: DateTime.parse(
          (m['CreatedAt'] ?? m['created_at'] ?? DateTime.now().toIso8601String())
              .toString()),
    );
  }
}
