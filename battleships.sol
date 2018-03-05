pragma solidity ^0.4.18;

contract Field {
    bytes13 private field;
    bytes13 private shots;
    uint8 private cellsLeft;

    function Field() public {
        cellsLeft = 20;
    }

    function setField(bytes13 newField) public {
        field = newField;
    }

    function getField() view public returns (bytes13) {
        return field;
    }

    function getShots() view public returns (bytes13) {
        return shots;
    }

    function getLeftCount() view public returns (uint8) {
        return cellsLeft;
    }

    function shiftLeft(bytes13 a, uint8 x) pure private returns (bytes13) {
        return bytes13(uint104(a) * uint104(2) ** x);
    }

    function getCell(bytes13 someField, uint8 x) pure private returns (bool) {
        return someField & shiftLeft(0x01, x) != 0;
    }

    function shotCell(uint8 x) public returns (bool) {
        require(x < 100 && !getCell(shots, x));
        shots = shots | shiftLeft(0x01, x);

        if (!getCell(field, x)) {
            return false;
        }

        cellsLeft -= 1;
        return true;
    }
}

contract Battleships {
    struct Player {
        address addr;
        uint8 cellsLeft;
        bool inited;
        Field field;
    }

    Player[2] private players;
    uint private turn;

    function Battleships() public {
        players[0].addr = msg.sender;
        players[0].field = new Field();
        players[1].field = new Field();
    }

    function getPlayersStatus() view public returns(bool[2] inited) {
        uint playerId = whois();
        uint foeId = (playerId + 1) % 2;

        bool[2] memory inits;
        inits[0] = players[playerId].inited;
        inits[1] = players[foeId].inited;

        return inits;
    }

    function join() public returns (bool) {
        if (players[1].addr != 0 || whois() != 2) {
            return false;
        }

        players[1].addr = msg.sender;
        return true;
    }

    function whois() view public returns (uint) {
        if (players[0].addr == msg.sender) {
            return 0;
        } else if (players[1].addr == msg.sender) {
            return 1;
        }

        return 2;
    }

    modifier playerOnly() {
        require(msg.sender == players[0].addr || msg.sender == players[1].addr);
        _;
    }

    modifier gameAction() {
        require(players[0].inited && players[1].inited);
        require(players[0].field.getLeftCount() != 0);
        require(players[1].field.getLeftCount() != 0);
        _;
    }

    function turnPlayer() view private playerOnly returns (uint) {
        return turn % 2;
    }

    function myTurn() view public playerOnly returns (bool) {
        if (players[turnPlayer()].addr == msg.sender) {
            return true;
        } else {
            return false;
        }
    }

    function getFields() view public playerOnly returns(bytes13, bytes13, bytes13, bytes13) {
        uint playerId = whois();
        uint foeId = (whois() + 1) % 2;

        return (
            players[playerId].field.getField(),
            players[playerId].field.getShots(),
            players[foeId].field.getField() & players[foeId].field.getShots(),
            players[foeId].field.getShots()
        );
    }

    function setField(bytes13 field) public playerOnly {
        uint playerId = whois();
        require(!players[playerId].inited);

        players[playerId].inited = true;
        players[playerId].field.setField(field);
    }

    function makeShot(uint8 x) public playerOnly gameAction returns (bool) {
        uint playerId = whois();
        require(playerId == turnPlayer());

        uint foeId = (playerId + 1) % 2;

        bool res = players[foeId].field.shotCell(x);
        turn++;

        return res;
    }
}