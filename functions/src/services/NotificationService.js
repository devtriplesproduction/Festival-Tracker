const admin = require("firebase-admin");

class NotificationService {
  /**
   * Dispatches a notification via Firestore (which can later trigger FCM).
   */
  async notify(targetRole, title, body, assignmentId) {
    const db = admin.firestore();
    
    const notification = {
      targetRole,
      title,
      body,
      assignmentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    };

    try {
      await db.collection("notifications").add(notification);
    } catch (error) {
      console.error("Failed to send notification:", error);
    }
  }

  async notifyUploadSuccess(assignmentId, festivalName, clientName) {
    await this.notify(
      "qc", // Notify QC that it's ready for review
      "Poster Ready for QC",
      `${clientName} - ${festivalName} has been uploaded and is ready for review.`,
      assignmentId
    );
  }

  async notifyUploadFailed(assignmentId, errorMsg) {
    await this.notify(
      "admin",
      "Upload Failed",
      `An automated upload failed: ${errorMsg}`,
      assignmentId
    );
    await this.notify(
      "designer", // or whoever triggered it
      "Upload Failed",
      `Your upload failed: ${errorMsg}`,
      assignmentId
    );
  }
}

module.exports = new NotificationService();
