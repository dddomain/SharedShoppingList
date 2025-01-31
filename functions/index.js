const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { google } = require("googleapis");

admin.initializeApp();

// Firebase のプロジェクトID
const PROJECT_ID = "sharedshoppinglist-feecd";
const MESSAGING_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const SCOPES = [MESSAGING_SCOPE];

// Google 認証用のJWTを取得
async function getAccessToken() {
    const key = require("./service-account.json");  // ここでダウンロードした JSON を参照
    const jwtClient = new google.auth.JWT(
        key.client_email,
        null,
        key.private_key,
        SCOPES,
        null
    );
    const tokens = await jwtClient.authorize();
    return tokens.access_token;
}

// プッシュ通知を送信するHTTP関数
exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
    const { token, title, body } = req.body;

    if (!token || !title || !body) {
        return res.status(400).send("Missing required fields");
    }

    try {
        const accessToken = await getAccessToken();
        const message = {
            message: {
                token: token,
                notification: {
                    title: title,
                    body: body
                }
            }
        };

        const response = await fetch(`https://fcm.googleapis.com/v1/projects/sharedshoppinglist-feecd/messages:send`, {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${accessToken}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify(message)
        });

        const data = await response.json();
        console.log("Push notification sent:", data);
        res.status(200).send(data);
    } catch (error) {
        console.error("Error sending push notification:", error);
        res.status(500).send("Error sending notification");
    }
});