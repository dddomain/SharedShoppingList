const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendPushNotification = functions.https.onRequest(async (req, res) =>{
  const {token, title, body} = req.body;

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
  };

  try {
    await admin.messaging().send(message);
    res.status(200).send("通知が送信されました");
  } catch (error) {
    console.error("通知送信エラー:", error);
    res.status(500).send("通知の送信に失敗しました");
  }
});

