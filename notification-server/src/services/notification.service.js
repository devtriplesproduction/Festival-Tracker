const axios = require('axios');
const { getFirestore } = require('firebase-admin/firestore');
const env = require('../config/env');

class NotificationService {
    constructor() {
        this.appId = env.oneSignalAppId;
        this.apiKey = env.oneSignalRestApiKey;
        this.apiUrl = 'https://onesignal.com/api/v1/notifications';
    }

    get headers() {
        return {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${this.apiKey}`
        };
    }

    /**
     * Get predefined templates for events
     */
    getTemplate(eventType, data) {
        const { clientName, festivalName, assignmentId, errorMsg, days } = data;
        const templates = {
            'NEW_ASSIGNMENT': { title: 'New Assignment', body: `You have a new assignment for ${clientName} - ${festivalName}.` },
            'QC_REJECTED': { title: 'QC Rejected', body: `${clientName} - ${festivalName} poster was rejected. Please revise.` },
            'DEADLINE_REMINDER': { title: 'Upload Reminder', body: `Upload poster for ${clientName} - ${festivalName} is approaching!` },
            'OVERDUE_REMINDER': { title: 'Overdue Alert', body: `${clientName} - ${festivalName} is overdue!` },
            'QC_UPLOADED': { title: 'Poster Ready for QC', body: `${clientName} - ${festivalName} is ready for review.` },
            'QC_APPROVED': { title: 'QC Approved', body: `${clientName} - ${festivalName} has been approved.` },
            'READY_TO_SEND': { title: 'Ready to Send', body: `${clientName} - ${festivalName} is ready to be sent to the client.` },
            'POSTER_SENT': { title: 'Poster Sent', body: `${clientName} - ${festivalName} was sent to the client.` },
            'UPLOAD_FAILED': { title: 'Upload Failed', body: `An automated upload failed: ${errorMsg}` },
            'PACKAGE_EXPIRY': { title: 'Package Renewal', body: `${clientName}'s package renews in ${days} days. Collect payment or stop it.` },
            'UPCOMING_FESTIVAL': { title: 'Upcoming Festival', body: `${festivalName} is coming up ${data.daysText}!` },
        };
        return templates[eventType] || { title: 'Notification', body: 'You have a new notification.' };
    }

    /**
     * Send push notification via OneSignal API
     */
    async sendPush(targetUids, title, body, data) {
        if (!targetUids || targetUids.length === 0) return;

        const payload = {
            app_id: this.appId,
            include_external_user_ids: targetUids,
            headings: { en: title },
            contents: { en: body },
            data: data
        };

        try {
            await axios.post(this.apiUrl, payload, { headers: this.headers });
        } catch (error) {
            console.error('OneSignal Push Failed:', error?.response?.data || error.message);
            throw error;
        }
    }

    /**
     * Send push notification by Role
     */
    async sendToRole(role, title, body, data) {
        try {
            const db = getFirestore();
            const snapshot = await db.collection('users').where('role', '==', role).get();
            const targetUids = [];
            snapshot.forEach(doc => {
                const user = doc.data();
                if (user.isActive !== false) {
                    targetUids.push(doc.id);
                }
            });
            await this.sendPush(targetUids, title, body, data);
        } catch (error) {
            console.error(`Failed to send to role ${role}:`, error);
            throw error;
        }
    }

    /**
     * Primary entry point for event processing
     */
    async processEvent(eventType, targetUid, targetRole, data) {
        const template = this.getTemplate(eventType, data);
        
        // Push notification
        if (targetUid) {
            await this.sendPush([targetUid], template.title, template.body, data);
        } else if (targetRole) {
            // Some events target all users in a role (e.g. QC or Admin)
            await this.sendToRole(targetRole, template.title, template.body, data);
        }
        
        // The Flutter app continues to write history to Firestore. 
        // We do NOT write to Firestore here to avoid duplicating the history logic
        // which the Flutter app already handles via `_repo.upsertNotification`.
    }
}

module.exports = new NotificationService();
