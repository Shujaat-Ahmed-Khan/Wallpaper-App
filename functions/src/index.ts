import { onDocumentUpdated, onDocumentWritten } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();

/**
 * 1. onWallpaperStatusUpdate: Triggered when Wallpapers/{id}.status changes.
 * - If APPROVED: Moves storage files from /pending/ to /live/, updates document URLs, and increments total_uploads.
 * - If REJECTED: Deletes files from /pending/.
 */
export const onWallpaperStatusUpdate = onDocumentUpdated("Wallpapers/{id}", async (event) => {
  const beforeData = event.data?.before.data();
  const afterData = event.data?.after.data();

  if (!beforeData || !afterData) return;

  const prevStatus = beforeData.status;
  const newStatus = afterData.status;

  if (prevStatus === newStatus) return;

  const wallpaperId = event.params.id;
  const uploaderId = afterData.uploader_id;
  const bucket = storage.bucket();

  if (newStatus === "APPROVED") {
    const updates: Record<string, any> = {};

    // Helper to move file from /pending/ to /live/
    const moveFile = async (urlField: string) => {
      const fileUrl = afterData[urlField];
      if (fileUrl && typeof fileUrl === "string" && fileUrl.includes("/pending/")) {
        try {
          // Extract storage path from tokenized URL or path
          const regex = /\/o\/([^?]+)/;
          const match = fileUrl.match(regex);
          const encodedPath = match ? match[1] : null;
          const decodedPath = encodedPath ? decodeURIComponent(encodedPath) : null;

          if (decodedPath && decodedPath.startsWith("pending/")) {
            const destPath = decodedPath.replace("pending/", "live/");
            const sourceFile = bucket.file(decodedPath);
            const destFile = bucket.file(destPath);

            await sourceFile.move(destFile);
            await destFile.makePublic();

            updates[urlField] = `https://storage.googleapis.com/${bucket.name}/${destPath}`;
          }
        } catch (err) {
          console.error(`Error migrating ${urlField} for wallpaper ${wallpaperId}:`, err);
        }
      }
    };

    await moveFile("image_url");
    await moveFile("thumbnail_url");
    await moveFile("video_url");
    await moveFile("background_url");
    await moveFile("foreground_url");

    // Update wallpaper document if URLs moved
    if (Object.keys(updates).length > 0) {
      await event.data?.after.ref.update(updates);
    }

    // Atomically increment creator's total uploads
    if (uploaderId) {
      const userRef = db.collection("Users").doc(uploaderId);
      await userRef.set(
        {
          stats: {
            total_uploads: admin.firestore.FieldValue.increment(1),
          },
        },
        { merge: true }
      );
    }
  } else if (newStatus === "REJECTED") {
    // Delete files in /pending/
    const deletePendingFile = async (urlField: string) => {
      const fileUrl = afterData[urlField];
      if (fileUrl && typeof fileUrl === "string" && fileUrl.includes("/pending/")) {
        try {
          const match = fileUrl.match(/\/o\/([^?]+)/);
          const path = match ? decodeURIComponent(match[1]) : null;
          if (path && path.startsWith("pending/")) {
            await bucket.file(path).delete({ ignoreNotFound: true });
          }
        } catch (err) {
          console.error(`Error deleting rejected ${urlField}:`, err);
        }
      }
    };

    await deletePendingFile("image_url");
    await deletePendingFile("video_url");
    await deletePendingFile("background_url");
    await deletePendingFile("foreground_url");
  }
});

/**
 * 2. onFollowerWrite: Triggered on create or delete in Followers/{docId}.
 * Atomically increments/decrements creator's stats.total_followers.
 */
export const onFollowerWrite = onDocumentWritten("Followers/{docId}", async (event) => {
  const beforeExists = event.data?.before.exists;
  const afterExists = event.data?.after.exists;

  // No change
  if (beforeExists && afterExists) return;

  const data = afterExists ? event.data?.after.data() : event.data?.before.data();
  const creatorUid = data?.creator_uid;
  if (!creatorUid) return;

  const creatorRef = db.collection("Users").doc(creatorUid);

  if (!beforeExists && afterExists) {
    // New follower: +1
    await creatorRef.set(
      {
        stats: {
          total_followers: admin.firestore.FieldValue.increment(1),
        },
      },
      { merge: true }
    );
  } else if (beforeExists && !afterExists) {
    // Unfollowed: -1
    await creatorRef.set(
      {
        stats: {
          total_followers: admin.firestore.FieldValue.increment(-1),
        },
      },
      { merge: true }
    );
  }
});

/**
 * 3. onRatingWrite: Triggered on write in Ratings/{docId}.
 * Recalculates rolling average_rating and rating_count for wallpaper and creator.
 */
export const onRatingWrite = onDocumentWritten("Ratings/{docId}", async (event) => {
  const data = event.data?.after.data() || event.data?.before.data();
  if (!data) return;

  const wallpaperId = data.wallpaper_id;
  const creatorUid = data.creator_uid;

  if (!wallpaperId) return;

  // 1. Recalculate Wallpaper rating
  const ratingsSnap = await db
    .collection("Ratings")
    .where("wallpaper_id", "==", wallpaperId)
    .get();

  const count = ratingsSnap.size;
  let sum = 0;
  ratingsSnap.forEach((doc) => {
    sum += Number(doc.data().rating || 0);
  });
  const avg = count > 0 ? Number((sum / count).toFixed(2)) : 0.0;

  await db.collection("Wallpapers").doc(wallpaperId).update({
    average_rating: avg,
    rating_count: count,
  });

  // 2. Recalculate Creator rolling average across all wallpapers
  if (creatorUid) {
    const creatorRatingsSnap = await db
      .collection("Ratings")
      .where("creator_uid", "==", creatorUid)
      .get();

    const creatorCount = creatorRatingsSnap.size;
    let creatorSum = 0;
    creatorRatingsSnap.forEach((doc) => {
      creatorSum += Number(doc.data().rating || 0);
    });
    const creatorAvg = creatorCount > 0 ? Number((creatorSum / creatorCount).toFixed(2)) : 0.0;

    await db.collection("Users").doc(creatorUid).set(
      {
        stats: {
          average_rating: creatorAvg,
          rating_count: creatorCount,
        },
      },
      { merge: true }
    );
  }
});
