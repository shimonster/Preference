class SPMP {
  // methods
  static const bid = 'BID';
  static const pass = 'PASS';
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
  static const widow = 3;
  static const disposed = 4;
  static const center1 = 5;
  static const center2 = 6;
  static const center3 = 7;
  static const trick1 = 8;
  static const trick2 = 9;
  static const trick3 = 10;
  static const disposing = 11;

  // game stages
  static const bidding = 'BIDDING';
  static const discarding = 'DISCARDING';
  static const playing = 'PLAYING';
  static const showingScore = 'SHOWINGSCORE';
  static const notStarted = 'NOTSTARTED';
}
