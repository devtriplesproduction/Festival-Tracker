const NotificationService = require('../services/notification.service');

const sendNotification = async (req, res) => {
    try {
        const { eventType, targetUid, targetRole, data } = req.body;

        if (!eventType) {
            return res.status(400).json({ error: 'eventType is required' });
        }

        if (!targetUid && !targetRole) {
            return res.status(400).json({ error: 'Either targetUid or targetRole is required' });
        }

        await NotificationService.processEvent(eventType, targetUid, targetRole, data || {});

        return res.status(200).json({ success: true, message: 'Notification event processed successfully.' });
    } catch (error) {
        console.error('Error in sendNotification controller:', error);
        return res.status(500).json({ error: 'Internal Server Error' });
    }
};

module.exports = {
    sendNotification
};
