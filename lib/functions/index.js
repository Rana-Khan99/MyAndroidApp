const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deletePostCascade = functions.firestore
  .document('posts/{postId}')
  .onDelete(async (snap, context) => {
    const postId = context.params.postId;
    const postData = snap.data();

    console.log(`Deleting post: ${postId}`);

    try {
      // 1️⃣ Delete all likes
      const likesSnap = await admin.firestore().collection(`posts/${postId}/likes`).get();
      likesSnap.forEach(doc => doc.ref.delete());

      // 2️⃣ Delete all comments
      const commentsSnap = await admin.firestore().collection(`posts/${postId}/comments`).get();
      commentsSnap.forEach(doc => doc.ref.delete());

      // 3️⃣ Delete image from Storage
      if (postData.imageUrl) {
        try {
          const filePath = decodeURIComponent(postData.imageUrl.split('/o/')[1].split('?')[0]);
          await admin.storage().bucket().file(filePath).delete();
          console.log("Image deleted from Storage");
        } catch (e) {
          console.log("Image delete failed or not found:", e);
        }
      }

      console.log(`✅ Cascade delete completed for post: ${postId}`);
    } catch (error) {
      console.error("Error in cascade delete:", error);
    }
  });
