// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

interface IUSDCOracle {
    function latestAnswer() external view returns (int256);
}

contract VerdictToken {
    event Mint(address indexed by, address indexed to, string name, uint256 number, uint256 amount);
    event Burn(address indexed by, string name, uint256 number, uint256 amount, string signature);
    event Transfer(address indexed from, address indexed to, string name, uint256 number, uint256 amount);
    event Consensus(string name, uint256 number, bytes32 setId);

    address public constant owner = 0x0F6dbb5B71372aB1d77Ed67D1260083cF9f07476;
    IUSDCOracle public constant usdcOracle = IUSDCOracle(0xfe66c0da9c9f6c5d04d3f2b2cb59ab5a1b10a17e);

    struct TokenSet {
        uint256 totalSupply;
        uint256 burned;
        uint256 requiredToReach;
        bool reached;
    }

    struct TokenKey {
        string name;
        uint256 number;
    }

    mapping(bytes32 => mapping(address => uint256)) public balances;
    mapping(bytes32 => TokenSet) public tokenSets;
    mapping(bytes32 => string[]) public burnSignatures;

    TokenKey[] public tokenRegistry;
    mapping(bytes32 => bool) public registeredKeys;

    function _id(string memory name, uint256 number) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, number));
    }

    function mint(string memory name, uint256 number, uint256 amount, uint256 requiredConsensus) external payable {
        require(bytes(name).length > 0, "Name required");
        require(number >= 100000, "Number must be >= 6 digits");

        bytes32 setId = _id(name, number);
        require(!tokenSets[setId].reached, "Finalized");
        require(tokenSets[setId].totalSupply == 0, "Name+number already used");
        require(amount > 0, "Invalid amount");
        require(requiredConsensus > 0 && requiredConsensus <= amount, "Invalid consensus target");

        int256 usdcPrice = usdcOracle.latestAnswer();
        require(usdcPrice > 0, "Invalid oracle");
        uint256 requiredWei = (25 * 1e16 * 1e8) / uint256(usdcPrice);
        require(msg.value >= requiredWei, "Insufficient POL");

        TokenSet storage t = tokenSets[setId];
        t.totalSupply = amount;
        t.requiredToReach = requiredConsensus;

        balances[setId][msg.sender] += amount;
        payable(owner).transfer(msg.value);

        if (!registeredKeys[setId]) {
            tokenRegistry.push(TokenKey(name, number));
            registeredKeys[setId] = true;
        }

        emit Mint(msg.sender, msg.sender, name, number, amount);
    }

    function burn(string memory name, uint256 number, uint256 amount, string memory signature) external {
        bytes32 setId = _id(name, number);
        TokenSet storage t = tokenSets[setId];
        require(!t.reached, "Finalized");
        require(balances[setId][msg.sender] >= amount, "Insufficient balance");

        balances[setId][msg.sender] -= amount;
        t.burned += amount;
        burnSignatures[setId].push(signature);

        emit Burn(msg.sender, name, number, amount, signature);

        if (t.burned >= t.requiredToReach) {
            t.reached = true;
            emit Consensus(name, number, setId);
        }
    }

    function transfer(string memory name, uint256 number, address to, uint256 amount) external {
        bytes32 setId = _id(name, number);
        require(!tokenSets[setId].reached, "Finalized");
        require(balances[setId][msg.sender] >= amount, "Insufficient balance");

        balances[setId][msg.sender] -= amount;
        balances[setId][to] += amount;

        emit Transfer(msg.sender, to, name, number, amount);
    }

    function hasConsensus(string memory name, uint256 number) external view returns (bool) {
        return tokenSets[_id(name, number)].reached;
    }

    function balanceOf(address user, string memory name, uint256 number) external view returns (uint256) {
        return balances[_id(name, number)][user];
    }

    function totalSupply(string memory name, uint256 number) external view returns (uint256) {
        return tokenSets[_id(name, number)].totalSupply;
    }

    function burnedAmount(string memory name, uint256 number) external view returns (uint256) {
        return tokenSets[_id(name, number)].burned;
    }

    function requiredConsensus(string memory name, uint256 number) external view returns (uint256) {
        return tokenSets[_id(name, number)].requiredToReach;
    }

    function getSignatures(string memory name, uint256 number) external view returns (string[] memory) {
        return burnSignatures[_id(name, number)];
    }

    function getAllTokenKeys() external view returns (TokenKey[] memory) {
        return tokenRegistry;
    }
}
