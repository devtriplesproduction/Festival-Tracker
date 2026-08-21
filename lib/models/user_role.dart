/// TSP internal roles.
enum UserRole {
  admin('admin', 'Admin'),
  designer('designer', 'Designer'),
  manager('manager', 'Manager');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? v) {
    return UserRole.values.firstWhere(
      (r) => r.value == v,
      orElse: () => UserRole.designer,
    );
  }

  bool get canManageTeam => this == UserRole.admin;
  /// Admins and managers can add/edit festival dates (lunar dates need yearly fixes).
  bool get canManageFestivals =>
      this == UserRole.admin || this == UserRole.manager;
  bool get canManageClients =>
      this == UserRole.admin || this == UserRole.manager;
  bool get canCreateAssignments =>
      this == UserRole.admin || this == UserRole.manager;
  bool get canDeleteAssignments => this == UserRole.admin;
  bool get canViewFestivals => true;
  bool get canViewClients =>
      this == UserRole.admin || this == UserRole.manager;
  bool get canViewPipeline => true;
  bool get canUploadPoster =>
      this == UserRole.admin || this == UserRole.designer;
  bool get canSendWhatsApp =>
      this == UserRole.admin || this == UserRole.manager;
  bool get canQcReview => this == UserRole.admin;
  bool get canManageSettings => this == UserRole.admin;
  bool get canViewAlerts => true;

  /// Admin creates packages and edits prices.
  bool get canManagePackages => this == UserRole.admin;

  /// Admin + manager can view packages, progress, and price history.
  bool get canViewPackages =>
      this == UserRole.admin || this == UserRole.manager;

  /// Which statuses this role may set on an assignment.
  bool canSetStatus(String statusValue) {
    switch (this) {
      case UserRole.admin:
        return true;
      case UserRole.designer:
        return statusValue == 'not_started' ||
            statusValue == 'design' ||
            statusValue == 'qc' ||
            statusValue == 'ready';
      case UserRole.manager:
        return statusValue == 'ready' ||
            statusValue == 'sent' ||
            statusValue == 'qc';
    }
  }
}
