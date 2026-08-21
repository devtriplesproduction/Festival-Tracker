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

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const festivalDateUpdater = require("./src/services/FestivalDateUpdater");

/**
 * Scheduled function to automatically sync festival dates on January 1st every year.
 */
exports.scheduledFestivalSync = onSchedule("0 0 1 1 *", async (event) => {
  const currentYear = new Date().getFullYear();
  await festivalDateUpdater.syncDatesForYear(currentYear);
});

/**
 * HTTP callable function to manually trigger a sync from the app/dashboard.
 */
exports.manualFestivalSync = onCall(async (request) => {
  const targetYear = request.data.year || new Date().getFullYear();
  const result = await festivalDateUpdater.syncDatesForYear(targetYear);
  return result;
});

/**
 * Scheduled function to automatically check for expired and expiring packages.
 */
exports.scheduledPackageCheck = onSchedule("0 0 * * *", async (event) => {
  const db = admin.firestore();
  
  // Fetch active packages
  const packagesSnap = await db.collection("client_packages")
    .where("packageStatus", "==", "active")
    .get();
    
  if (packagesSnap.empty) return;
  
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const notificationsToSend = [];
  const batch = db.batch();

  const clientsMap = new Map();
  async function getClient(clientId) {
    if (clientsMap.has(clientId)) return clientsMap.get(clientId);
    const snap = await db.collection("clients").doc(clientId).get();
    const data = snap.exists ? snap.data() : null;
    clientsMap.set(clientId, data);
    return data;
  }

  for (const doc of packagesSnap.docs) {
    const pkg = doc.data();
    if (!pkg.endDate) continue;
    
    const end = pkg.endDate.toDate ? pkg.endDate.toDate() : new Date(pkg.endDate);
    const endDate = new Date(end.getFullYear(), end.getMonth(), end.getDate());
    
    const diffTime = endDate.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    const client = await getClient(pkg.clientId);
    const clientName = client ? client.name : "Unknown Client";

    if (diffDays < 0) {
      // Expired
      batch.update(doc.ref, { packageStatus: "stopped" });
      
      const logRef = db.collection("notifications").doc();
      batch.set(logRef, {
        assignmentId: "",
        clientName: clientName,
        clientId: pkg.clientId || "",
        festivalName: "",
        type: "PACKAGE_EXPIRY",
        message: `Package for ${clientName} expired! Service stopped.`,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        recipientRole: "all",
        readBy: [],
      });

      notificationsToSend.push({
        eventType: "PACKAGE_EXPIRY",
        targetRole: "all",
      });

    } else if (diffDays <= 15) {
      // Within 15 days
      const lastNotified = pkg.renewalNotifiedAt ? (pkg.renewalNotifiedAt.toDate ? pkg.renewalNotifiedAt.toDate() : new Date(pkg.renewalNotifiedAt)) : null;
      let shouldNotify = false;
      if (!lastNotified) {
        shouldNotify = true;
      } else {
        const notifyDiff = today.getTime() - lastNotified.getTime();
        const notifyDays = Math.floor(notifyDiff / (1000 * 60 * 60 * 24));
        if (notifyDays > 20) {
           shouldNotify = true;
        }
      }

      if (shouldNotify) {
        batch.update(doc.ref, { renewalNotifiedAt: admin.firestore.FieldValue.serverTimestamp() });
        
        const logRef = db.collection("notifications").doc();
        batch.set(logRef, {
          assignmentId: "",
          clientName: clientName,
          clientId: pkg.clientId || "",
          festivalName: "",
          type: "package_renewal",
          message: `Package for ${clientName} expires in ${diffDays} day(s). Please renew.`,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          recipientRole: "all",
          readBy: [],
        });

        notificationsToSend.push({
          eventType: "PACKAGE_EXPIRY",
          targetRole: "all",
        });
      }
    }
  }

  if (notificationsToSend.length > 0 || packagesSnap.docs.length > 0) {
    await batch.commit();
  }

  // Send push notifications
  for (const notif of notificationsToSend) {
    try {
      await globalThis.fetch("https://notification-server-asep.onrender.com/api/notifications/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(notif)
      });
    } catch (e) {
      console.error("Failed to send push notification:", e);
    }
  }
});
