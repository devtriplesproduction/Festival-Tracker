require('dotenv').config();

const port = process.env.PORT || 3000;
const oneSignalAppId = process.env.ONESIGNAL_APP_ID;
const oneSignalRestApiKey = process.env.ONESIGNAL_REST_API_KEY;
const firebaseProjectId = process.env.FIREBASE_PROJECT_ID;
const firebaseClientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const firebasePrivateKey = process.env.FIREBASE_PRIVATE_KEY;

const requiredEnvVars = [
    { key: 'ONESIGNAL_APP_ID', value: oneSignalAppId },
    { key: 'ONESIGNAL_REST_API_KEY', value: oneSignalRestApiKey },
    { key: 'FIREBASE_PROJECT_ID', value: firebaseProjectId },
    { key: 'FIREBASE_CLIENT_EMAIL', value: firebaseClientEmail },
    { key: 'FIREBASE_PRIVATE_KEY', value: firebasePrivateKey },
];

const missingEnvVars = requiredEnvVars.filter(env => !env.value);

if (missingEnvVars.length > 0) {
    const missingKeys = missingEnvVars.map(env => env.key).join(', ');
    console.error(`ERROR: Missing required environment variables: ${missingKeys}`);
    process.exit(1);
}

console.log('✓ Environment loaded');

module.exports = {
    port,
    oneSignalAppId,
    oneSignalRestApiKey,
    firebaseProjectId,
    firebaseClientEmail,
    firebasePrivateKey
};
