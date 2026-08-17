const cron = require('node-cron');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const NotificationService = require('../services/notification.service');

// Run every day at 4:30 PM (16:30 IST) for testing
cron.schedule('30 16 * * *', async () => {
    console.log('Running upcoming festivals cron job...');
    try {
        const db = getFirestore();
        const now = new Date();
        const festivalsRef = db.collection('festivals');
        
        // We fetch all festivals and filter in code, as we need to process dates carefully
        // Alternatively, could query for date >= now, but festivals collection is likely small.
        const snapshot = await festivalsRef.get();

        const upcomingFestivals = [];

        // Midnight today for accurate day calculation
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        snapshot.forEach(doc => {
            const festival = doc.data();
            if (!festival.date) return;

            // Handle Firestore Timestamp or ISO string
            const festivalDateRaw = festival.date.toDate ? festival.date.toDate() : new Date(festival.date);
            
            // Normalize to midnight
            const festivalDate = new Date(festivalDateRaw.getFullYear(), festivalDateRaw.getMonth(), festivalDateRaw.getDate());
            
            const diffTime = festivalDate.getTime() - today.getTime();
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

            // Notify from 7 days before until the day of the festival
            if (diffDays <= 7 && diffDays >= 0) {
                upcomingFestivals.push({ docId: doc.id, festival, diffDays });
            }
        });

        if (upcomingFestivals.length === 0) {
            console.log('No upcoming festivals in the next 7 days.');
            return;
        }

        // Notify admins about each upcoming festival
        for (const { docId, festival, diffDays } of upcomingFestivals) {
            let dayText = 'today';
            if (diffDays === 1) dayText = 'tomorrow';
            else if (diffDays > 1) dayText = `in ${diffDays} days`;

            const data = {
                festivalName: festival.name || 'A Festival',
                daysText: dayText,
                route: '/festivals' // Assuming a route exists, or it just opens the app
            };

            // Trigger notification process (targets 'all')
            await NotificationService.processEvent('UPCOMING_FESTIVAL', null, 'all', data);

            // Create the history record manually to preserve existing behavior.
            await db.collection('notifications').add({
                festivalName: data.festivalName,
                type: 'UPCOMING_FESTIVAL',
                message: `${data.festivalName} is coming up ${dayText}!`,
                sentAt: FieldValue.serverTimestamp(),
                recipientRole: 'all',
                read: false
            });
        }
        
        console.log(`Processed ${upcomingFestivals.length} upcoming festival notifications.`);

    } catch (error) {
        console.error('Error in upcoming festivals cron job:', error);
    }
}, {
    timezone: "Asia/Kolkata"
});
