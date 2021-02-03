## Standards

### Chess Engine Communication Protocol
https://www.chessprogramming.org/Chess_Engine_Communication_Protocol

Noted: The majority of new chess engines don't support it

### Universal Chess Interface
Noted: While the UCI design makes it simple for engine programmers to integrate a "stateless" chess engine, it was also disputed by various chess programmers, since it subsumes engine control parameters and delegates possibly game decisive stuff to the GUI. 

## Chess Engines
* GNUChess
* Sjeng
* Amy
* Crafty
* Faile
* Phalanx
* Glaurung
* HoiChess
* Diablo
* BBChess
* Fruit
* Shredder
* Toga II
* Boo's Chess Engine

https://www.rankred.com/chess-engines/


Forsyth–Edwards Notation (FEN) is a standard notation for describing a particular board position of a chess game. The purpose of FEN is to provide all the necessary information to restart a game from a particular position. A FEN record contains six fields. The separator between fields is a space.

The fields are:

1. Piece placement on squares (A8 B8 .. G1 H1) Each piece is identified by a letter taken from the standard English names (white upper-case, black lower-case). Blank squares are noted using digits 1 through 8 (the number of blank squares), and "/" separate ranks.

2. Active color. "w" means white moves next, "b" means black.

3. Castling availability. Either - if no side can castle or a letter (K,Q,k,q) for each side and castle possibility.

4. En passant target square in algebraic notation or "-".

5. Halfmove clock: This is the number of halfmoves since the last pawn advance or capture.

6. Fullmove number: The number of the current full move.



## Castling rules
* The king and the rook may not have moved from their starting squares if you want to castle.
* All spaces between the king and the rook must be empty.
* The king cannot be in check.
* The squares that the king passes over must not be under attack, nor the square where it lands on
