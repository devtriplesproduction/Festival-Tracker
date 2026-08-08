const admin = require("firebase-admin");

class ActivityLogService {
  /**
   * Records an activity log.
   * Actions: 'upload', 'update', 'approval', 'rejection', 'delete', 'send'
   */
  async log(action, assignmentId, userId, details = {}) {
    const db = admin.firestore();
    
    const logEntry = {
      action,
      assignmentId,
      userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details,
    };

    try {
      await db.collection("activity_logs").add(logEntry);
    } catch (error) {
      console.error("Failed to write activity log:", error);
      // We typically don't throw here to avoid failing the main workflow just because logging failed.
    }
  }
}

module.exports = new ActivityLogService();
