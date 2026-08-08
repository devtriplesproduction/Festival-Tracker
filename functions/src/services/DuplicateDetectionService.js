const crypto = require("crypto");
const fs = require("fs");
const admin = require("firebase-admin");

class DuplicateDetectionService {
  /**
   * Computes SHA-256 hash of a file.
   */
  async computeHash(filePath) {
    return new Promise((resolve, reject) => {
      const hash = crypto.createHash("sha256");
      const stream = fs.createReadStream(filePath);
      stream.on("error", (err) => reject(err));
      stream.on("data", (chunk) => hash.update(chunk));
      stream.on("end", () => resolve(hash.digest("hex")));
    });
  }

  /**
   * Checks if an assignment already has a poster with the exact same hash.
   * If true, throws an error to halt the upload process.
   */
  async checkDuplicate(assignmentId, filePath) {
    const fileHash = await this.computeHash(filePath);

    const db = admin.firestore();
    const doc = await db.collection("assignments").doc(assignmentId).get();
    
    if (doc.exists) {
      const data = doc.data();
      if (data.posterFileHash === fileHash && data.posterUploadStatus === "success") {
        throw new Error("Duplicate upload detected: This exact file has already been uploaded for this assignment.");
      }
    }

    return fileHash;
  }
}

module.exports = new DuplicateDetectionService();
