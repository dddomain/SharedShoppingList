const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(); // service-account.json を不要にした

exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
    const { token, title, body } = req.body;

    if (!token || !title || !body) {
        return res.status(400).send("Missing required fields");
    }

    try {
        const message = {
            token: token,
            notification: {
                title: title,
                body: body,
            },
        };

        const response = await admin.messaging().send(message);
        console.log("Push notification sent:", response);
        res.status(200).send(response);
    } catch (error) {
        console.error("Error sending push notification:", error);
        res.status(500).send("Error sending notification");
    }
});