const admin = require("firebase-admin");

class FestivalDateUpdater {
  constructor() {
    this.db = admin.firestore();
    this.apiKey = process.env.CALENDARIFIC_API_KEY;
    this.country = process.env.CALENDARIFIC_COUNTRY || "IN";
  }

  /**
   * Fetches the holidays for the given year from Calendarific.
   * @param {number} year 
   * @returns {Promise<Array>} List of holidays from the API
   */
  async fetchHolidays(year) {
    if (!this.apiKey) {
      throw new Error("Calendarific API key is missing. Set CALENDARIFIC_API_KEY in environment variables.");
    }
    
    const url = `https://calendarific.com/api/v2/holidays?api_key=${this.apiKey}&country=${this.country}&year=${year}`;
    
    try {
      const response = await fetch(url);
      const data = await response.json();
      
      if (data && data.meta && data.meta.code === 200) {
        return data.response.holidays;
      } else {
        console.error("Calendarific API error:", data);
        return [];
      }
    } catch (error) {
      console.error("Error fetching holidays:", error);
      return [];
    }
  }

  /**
   * Main function to sync festival dates for the given year.
   * @param {number} targetYear 
   */
  async syncDatesForYear(targetYear) {
    console.log(`Starting festival sync for year ${targetYear}`);
    
    // 1. Fetch holidays from Calendarific
    const holidays = await this.fetchHolidays(targetYear);
    if (!holidays || holidays.length === 0) {
      console.log("No holidays fetched from API. Aborting sync.");
      return { success: false, message: "No holidays fetched from API." };
    }

    // 2. Fetch non-custom festivals from Firestore
    const festivalsSnapshot = await this.db.collection('festivals').where('isCustom', '==', false).get();
    if (festivalsSnapshot.empty) {
      console.log("No non-custom festivals found in database.");
      return { success: true, updatedCount: 0 };
    }

    let updatedCount = 0;
    const batch = this.db.batch();

    festivalsSnapshot.forEach((doc) => {
      const festivalData = doc.data();
      if (!festivalData.name) return;
      
      const festivalName = festivalData.name.toLowerCase();

      // Find matching holiday from API
      // Try exact match or partial match
      const matchingHoliday = holidays.find(h => 
        h.name.toLowerCase() === festivalName || 
        h.name.toLowerCase().includes(festivalName)
      );

      if (matchingHoliday) {
        const holidayDateStr = matchingHoliday.date.iso; // Format: "2024-11-01" or "2024-11-01T00:00:00"
        let parsedDate;
        
        try {
          parsedDate = new Date(holidayDateStr);
        } catch(e) {
          console.error(`Error parsing date for ${festivalName}: ${holidayDateStr}`);
          return;
        }

        const newDateTimestamp = admin.firestore.Timestamp.fromDate(parsedDate);
        batch.update(doc.ref, { date: newDateTimestamp });
        updatedCount++;
        console.log(`Updated ${festivalData.name} to ${parsedDate.toISOString()}`);
      } else {
        console.log(`No match found in API for ${festivalData.name}`);
      }
    });

    if (updatedCount > 0) {
      await batch.commit();
      console.log(`Successfully updated ${updatedCount} festivals.`);
    } else {
      console.log("No festival dates were updated.");
    }

    return { success: true, updatedCount };
  }
}

module.exports = new FestivalDateUpdater();
