const functions = require('firebase-functions');
const { database } = require('firebase-functions/lib/providers/firestore');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.notifyLocationChange = functions.database.ref('/games/{gameId}')
    .onUpdate((snapshot, context) => {
        if(snapshot.after.child('/players').hasChild({
                'nickname': String,
                'uid': context.auth.uid,
            },
        )) {
            console.log(context.params.gameId)
        }
    });
