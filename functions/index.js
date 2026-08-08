const admin = require("firebase-admin");
const {setGlobalOptions} = require("firebase-functions/v2");

// Initialize Firebase Admin once
if (!admin.apps.length) {
  admin.initializeApp();
}

setGlobalOptions({
  region: "us-central1",
  maxInstances: 20,
});
