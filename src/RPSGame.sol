// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RPSGame is ReentrancyGuard, Ownable {
    enum Move {
        None,
        Rock,
        Paper,
        Scissors
    }

    struct Game {
        address player1;
        address player2;
        bytes32 commit1;
        bytes32 commit2;
        Move move1;
        Move move2;
        uint256 entryFee;
        bool player1Committed;
        bool player2Committed;
        bool player1Revealed;
        bool player2Revealed;
        bool finished;
    }

    mapping(uint256 => Game) public games;
    uint256 public gameCounter;
    uint256 public entryFee = 0.01 ether;
    uint256 public houseFee = 5;

    event GameCreated(
        uint256 indexed gameId,
        address indexed player1,
        uint256 entryFee
    );
    event PlayerJoined(uint256 indexed gameId, address indexed player2);
    event MoveCommitted(uint256 indexed gameId, address indexed player);
    event MoveRevealed(
        uint256 indexed gameId,
        address indexed player,
        Move move
    );
    event GameFinished(
        uint256 indexed gameId,
        address indexed winner,
        uint256 prize
    );

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    function createGame() public payable nonReentrant {
        require(msg.value >= entryFee, "insufficient entry fee");

        gameCounter++;
        games[gameCounter] = Game({
            player1: msg.sender,
            player2: address(0),
            commit1: bytes32(0),
            commit2: bytes32(0),
            move1: Move.None,
            move2: Move.None,
            entryFee: msg.value,
            player1Committed: false,
            player2Committed: false,
            player1Revealed: false,
            player2Revealed: false,
            finished: false
        });

        emit GameCreated(gameCounter, msg.sender, msg.value);
    }

    function joinGame(uint256 gameId) public payable nonReentrant {
        Game storage game = games[gameId];
        require(game.player1 != address(0), "game does not exist");
        require(game.player2 == address(0), "game already full");
        require(msg.sender != game.player1, "cannot join own game");
        require(msg.value >= game.entryFee, "Insuficient entry fee");
        require(!game.finished, "game finished");

        game.player2 = msg.sender;
        emit PlayerJoined(gameId, msg.sender);
    }

    function commitMove(uint256 gameId, bytes32 commit) public {
        Game storage game = games[gameId];
        require(
            msg.sender == game.player1 || msg.sender == game.player2,
            "not a player"
        );
        require(!game.finished, "game finished");
        require(game.player2 != address(0), "game not full");

        if (msg.sender == game.player1) {
            require(!game.player1Committed, "already committed");
            game.commit1 = commit;
            game.player1Committed = true;
        } else {
            require(!game.player2Committed, "already committed");
            game.commit2 = commit;
            game.player2Committed = true;
        }

        emit MoveCommitted(gameId, msg.sender);
    }

    function revealMove(uint256 gameId, Move move, bytes32 secret) public {
        Game storage game = games[gameId];
        require(
            msg.sender == game.player1 || msg.sender == game.player2,
            "not a player"
        );
        require(
            game.player1Committed && game.player2Committed,
            "both must commit first"
        );
        require(!game.finished, "game finished");
        require(move != Move.None, "invalid move");

        bytes32 hash = keccak256(abi.encodePacked(move, secret, msg.sender));

        if (msg.sender == game.player1) {
            require(!game.player1Revealed, "already revealed");
            require(hash == game.commit1, "invalid commit");
            game.move1 = move;
            game.player1Revealed = true;
        } else {
            require(!game.player2Revealed, "already revealed");
            require(hash == game.commit2, "invalid commit");
            game.move2 = move;
            game.player2Revealed = true;
        }

        emit MoveRevealed(gameId, msg.sender, move);

        if (game.player1Revealed && game.player2Revealed) {
            _finishGame(gameId);
        }
    }

    function _finishGame(uint256 gameId) internal {
        Game storage game = games[gameId];
        require(!game.finished, "already finished");

        game.finished = true;

        address winner = _determineWinner(
            game.move1,
            game.move2,
            game.player1,
            game.player2
        );
        uint256 totalPrize = game.entryFee * 2;
        uint256 fee = (totalPrize * houseFee) / 100;
        uint256 prize = totalPrize - fee;

        if (winner != address(0)) {
            payable(winner).transfer(prize);
            emit GameFinished(gameId, winner, prize);
        } else {
            payable(game.player1).transfer(game.entryFee);
            payable(game.player2).transfer(game.entryFee);
            emit GameFinished(gameId, address(0), 0);
        }
    }

    function _determineWinner(
        Move move1,
        Move move2,
        address player1,
        address player2
    ) internal pure returns (address) {
        if (move1 == move2) return address(0);

        if (
            (move1 == Move.Rock && move2 == Move.Scissors) ||
            (move1 == Move.Paper && move2 == Move.Rock) ||
            (move1 == Move.Scissors && move2 == Move.Paper)
        ) {
            return player1;
        }
        return player2;
    }

    function getGame(
        uint256 gameId
    )
        public
        view
        returns (
            address _player1,
            address _player2,
            uint256 _entryFee,
            bool _player1Committed,
            bool _player2Committed,
            bool _player1Revealed,
            bool _player2Revealed,
            bool _finished
        )
    {
        Game memory game = games[gameId];
        return (
            game.player1,
            game.player2,
            game.entryFee,
            game.player1Committed,
            game.player2Committed,
            game.player1Revealed,
            game.player2Revealed,
            game.finished
        );
    }

    function setEntryFee(uint256 _entryFee) public onlyOwner {
        entryFee = _entryFee;
    }

    function setHouseFee(uint256 _houseFee) public onlyOwner {
        require(_houseFee <= 10, "fee too high");
        houseFee = _houseFee;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
