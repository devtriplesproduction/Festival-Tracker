const cron = require('node-cron');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const NotificationService = require('../services/notification.service');

// Run every day at 9 AM
cron.schedule('0 9 * * *', async () => {
    console.log('Running package expiry cron job...');
    try {
        const db = getFirestore();
        const now = new Date();
        const packagesRef = db.collection('client_packages');
        const snapshot = await packagesRef.where('packageStatus', '==', 'active').get();

        const expiringPackages = [];

        snapshot.forEach(doc => {
            const pkg = doc.data();
            if (!pkg.endDate) return;

            // Handle Firestore Timestamp or ISO string
            const endDate = pkg.endDate.toDate ? pkg.endDate.toDate() : new Date(pkg.endDate);
            
            const diffTime = endDate.getTime() - now.getTime();
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

            if (diffDays === 15) {
                // Check if we already notified within the last 20 days
                let alreadyNotified = false;
                if (pkg.renewalNotifiedAt) {
                    const notifiedAt = pkg.renewalNotifiedAt.toDate ? pkg.renewalNotifiedAt.toDate() : new Date(pkg.renewalNotifiedAt);
                    const notifiedDiff = Math.ceil((now.getTime() - notifiedAt.getTime()) / (1000 * 60 * 60 * 24));
                    if (notifiedDiff < 20) {
                        alreadyNotified = true;
                    }
                }

                if (!alreadyNotified) {
                    expiringPackages.push({ docId: doc.id, pkg, diffDays });
                }
            }
        });

        if (expiringPackages.length === 0) {
            console.log('No packages expiring in exactly 15 days.');
            return;
        }

        // Notify admins about each expiring package
        for (const { docId, pkg, diffDays } of expiringPackages) {
            const clientDoc = await db.collection('clients').doc(pkg.clientId).get();
            const clientName = clientDoc.exists ? clientDoc.data().name : 'Unknown Client';

            const data = {
                clientName,
                days: diffDays,
                assignmentId: pkg.id,
                route: '/package'
            };

            // Trigger notification process (targets 'admin')
            await NotificationService.processEvent('PACKAGE_EXPIRY', null, 'admin', data);

            // The Flutter app handles the history log natively, but since this is a backend-only cron,
            // we must create the history record manually to preserve existing behavior.
            await db.collection('notifications').add({
                assignmentId: pkg.id,
                clientName: clientName,
                festivalName: 'Package renewal',
                type: 'packageRenewal',
                message: `${clientName}'s package renews in ${diffDays} days. Collect payment or stop it.`,
                sentAt: FieldValue.serverTimestamp(),
                recipientRole: 'admin',
                read: false
            });

            // Mark the package to prevent duplicates
            await db.collection('client_packages').doc(docId).update({
                renewalNotifiedAt: FieldValue.serverTimestamp()
            });
        }
        
        console.log(`Processed ${expiringPackages.length} package expiry notifications.`);

    } catch (error) {
        console.error('Error in package expiry cron job:', error);
    }
});
