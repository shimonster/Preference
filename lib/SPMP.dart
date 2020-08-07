class SPMP {
  // methods
  static const bid = 'BID';
  static const place = 'PLACE';
  static const dispose = 'DISPOSE';
  static const collectWidow = 'COLLECTWIDOW';
  static const acceptPlay = 'ACCEPTPLAY';
  static const startPlaying = 'STARTPLAYING';
  static const finishBidding = 'FINNISHBIDDING';
  static const playerJoin = 'PLAYERJOIN';
  static const playerLeave = 'PLAYERLEAVE';
  static const trickCollected = 'TRICKCOLLECTED';

  // cards
  static const spade = 0;
  static const clubs = 1;
  static const diamonds = 2;
  static const hearts = 3;
  static const noSuit = 4;

  static const seven = 0;
  static const eight = 1;
  static const nine = 2;
  static const ten = 3;
  static const jack = 4;
  static const queen = 5;
  static const king = 6;
  static const ace = 7;

  static const player1 = 0;
  static const player2 = 1;
  static const player3 = 2;
  static const widow = 4;
  static const disposed = 5;
  static const center1 = 6;
  static const center2 = 7;
  static const center3 = 8;
  static const trick1 = 9;
  static const trick2 = 10;
  static const trick3 = 11;

  // game stages
  static const bidding = 'BIDDING';
  static const playing = 'PLAYING';
  static const notStarted = 'NOTSTARTED';
}
