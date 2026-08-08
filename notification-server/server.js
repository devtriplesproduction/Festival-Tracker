const express = require('express');
const cors = require('cors');
const { initializeApp, getApps, cert } = require('firebase-admin/app');
const env = require('./src/config/env');

// Initialize Firebase Admin (Modular API)
if (getApps().length === 0) {
    try {
        let privateKey = env.firebasePrivateKey;
        
        // Strip wrapping quotes if dotenv didn't remove them
        if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
            privateKey = privateKey.slice(1, -1);
        }
        if (privateKey.startsWith("'") && privateKey.endsWith("'")) {
            privateKey = privateKey.slice(1, -1);
        }
        
        // Convert literal '\n' strings to actual newlines and remove \r and whitespace
        privateKey = privateKey.replace(/\\n/g, '\n').replace(/\r/g, '').trim();

        initializeApp({
            credential: cert({
                projectId: env.firebaseProjectId,
                clientEmail: env.firebaseClientEmail,
                privateKey: privateKey,
            })
        });
        console.log('✓ Firebase initialized');
    } catch (e) {
        console.error('ERROR: Failed to initialize Firebase Admin.');
        console.error(e);
        process.exit(1);
    }
}

const app = express();

app.use(cors());
app.use(express.json());

// Routes
const notificationRoutes = require('./src/routes/notification.routes');
app.use('/api/notifications', notificationRoutes);

// Health check
app.get('/health', async (req, res) => {
    let firebaseStatus = false;
    let onesignalStatus = false;

    // Firebase check
    if (getApps().length > 0) {
        firebaseStatus = true;
    }

    // OneSignal check (Lightweight API call to check if credentials are valid)
    try {
        const axios = require('axios');
        const response = await axios.get(`https://onesignal.com/api/v1/apps/${env.oneSignalAppId}`, {
            headers: { 'Authorization': `Basic ${env.oneSignalRestApiKey}` }
        });
        if (response.status === 200) {
            onesignalStatus = true;
        }
    } catch (error) {
        // Validation failed or timeout
        console.warn('OneSignal validation failed during health check:', error?.response?.data || error.message);
    }

    res.status(200).json({ 
        status: 'ok',
        firebase: firebaseStatus,
        onesignal: onesignalStatus,
        serverTime: new Date().toISOString()
    });
});

// Version
app.get('/version', (req, res) => {
    res.status(200).json({ version: '1.0.0' });
});

// Initialize Cron Jobs
require('./src/cron/packageExpiry');
require('./src/cron/upcomingFestival');

console.log('✓ OneSignal configured');

const PORT = env.port;
app.listen(PORT, () => {
    console.log(`✓ Server listening on PORT ${PORT}`);
});
