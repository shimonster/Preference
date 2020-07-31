const admin = require('firebase-admin');
const functions = require('firebase-functions');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
let gameId = '';
let uid = '';

exports.getGame = functions.database.ref('/games/' + (gameId === '' ? '{gameId}' : gameId) + '/players').onCreate((snapshot, context) => {
    snapshot.val().values.forEach((e) => {
        if(e.uid === context.auth.uid && gameId !== '') {
            gameId = context.params.gameId;
        }
    })
    if(e.uid !== context.auth.uid && gameId !== '') {
        let joinName = snapshot.child(snapshot.numChildren - 1).nickname;
        admin.messaging().sendToTopic(gameId, {notification: {title: joinName, body: '${joinName} joined the game!', }})
    }
})

exports.notifyLocationChange = functions.database.ref('/games/' + (gameId === '' ? '{gameId}' : gameId)).onUpdate((snapshot, context) => {
    // if(gameId === '') {
    //     uid = context.auth.uid;
    //     const db = snapshot.after.ref.root;
    //     const gameIdx = db.child('/games').ref.toJSON().values().findIndex((game) => {
    //         return game.players.values.findIndex((e) => {
    //             return e.uid === uid;
    //         }) !== -1;
    //     })
    //     gameId = db.child('/games').data().ref().keys()[gameIdx];
    //     console.log('game id set');
    // }
    gameId = context.params.gameId;
    uid = context.auth.uid;
    console.log('game id:', gameId);
    // console.log('players:', snapshot.after.child('/players').val());
    //     snapshot.after.child('/players').val().forEach((snap) => {
    //         console.log('snap', snap.uid);
    //         if(snap.uid === context.auth.uid) {
    //             isGame = true;
    //         }
    //     })
    return;
})