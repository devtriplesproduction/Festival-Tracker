const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { verifyFirebaseToken } = require('../middleware/auth.middleware');

// Protected route
router.post('/send', verifyFirebaseToken, notificationController.sendNotification);

module.exports = router;
