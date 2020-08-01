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
let nickname = '';

exports.getGame = functions.database.ref('/games/'/*  + (gameId === '') ? '{gameId}' : gameId + '/players' */).onCreate((snapshot, context) => {
    console.log('get game was run');
    snapshot.forEach((e) => {
        console.log(e.val());
    })
    snapshot.val().values.forEach((e) => {
        if(e.uid === context.auth.uid && gameId === '') {
            gameId = context.params.gameId;
            uid = context.auth.uid;
            nickname = e.nickname;
        }
    })
    console.log('game id:', gameId, 'uid:', uid, 'nickname:', nickname)
    if(e.uid !== context.auth.uid && gameId !== '') {
        const joinName = snapshot.child(snapshot.numChildren - 1).nickname;
        return admin.messaging().sendToTopic(gameId, {notification: {title: joinName, body: joinName + ' joined the game!', }})
    } else {
        return Promise.resolve();
    }
})

exports.notifyCardLocationChange = functions.database.ref('/games/' + gameId + '/cards/{cardNum}').onUpdate((snapshot, context) => {
    const rankI = snapshot.after.val().rankI;
    const suitI = snapshot.after.val().suitI;
    const placeI = snapshot.after.val().placeI;
    const prevPlaceI = snapshot.before.val().placeI;
    let message = '';
    const suit = ['hearts', 'diamonds', 'clubs', 'spades'][suitI];
    const rank = ['7', '8', '9', '10', 'jack', 'queen', 'king'][rankI];
    if(placeI >= 5 && placeI <= 7) {
        message = nickname + ' placed the ' + rank + ' of ' + suit + '.'
    } else if(prevPlaceI === 3 && placeI <= 2) {
        message = nickname + ' collected the widow.';
    } else if(prevPlaceI >= 5 && prevPlaceI <= 7 && placeI >= 8 && placeI <= 10) {
        message = nickname + ' collected the trick.'
    }

    if(message !== '') {
        return admin.messaging().sendToTopic(gameId, {notification: {title: nickname, body: message}});
    } else {
        return Promise.resolve();
    }
})