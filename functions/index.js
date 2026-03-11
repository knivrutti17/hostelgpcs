const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onNewMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
    const messageData = event.data.data();
    const chatId = event.params.chatId;

    const notificationPayload = {
        notification: {
            title: `${messageData.senderName} in ${chatId.replace('_', ' ')}`,
            body: messageData.messageType === 'image' ? '📷 Sent a photo' : messageData.messageText,
        },
        data: {
            chatId: chatId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
        }
    };

    // Public Chat logic
    if (chatId === 'hostel_public') {
        return admin.messaging().send({
            topic: 'hostel_public',
            ...notificationPayload
        });
    } 
    
    // Room Chat logic
    else if (chatId.startsWith('room_')) {
        const roomNo = chatId.split('_')[1];
        const studentDocs = await admin.firestore().collection('users')
            .where('roomNo', '==', roomNo)
            .get();

        const tokens = [];
        studentDocs.forEach(doc => {
            const token = doc.data().fcmToken;
            if (token && doc.id !== messageData.senderId) {
                tokens.push(token);
            }
        });

        if (tokens.length > 0) {
            return admin.messaging().sendEachForMulticast({
                tokens: tokens,
                ...notificationPayload
            });
        }
    }
    return null;
});