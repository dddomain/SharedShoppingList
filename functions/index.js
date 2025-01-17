    
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.firestore
    .document("groups/{groupId}/items/{itemId}")
    .onUpdate((change, context) => {
      const after = change.after.data();

      if (after.purchased) {
        const payload = {
          notification: {
            title: "購入完了",
            body: `${after.name}が購入されました。`,
            sound: "default",
          },
        };

        // トピックごとに通知を送信
        return admin.messaging().sendToTopic(context.params.groupId, payload);
      }
      return null;
    });
