// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../shared/BasicUpgradeableAccessControl.sol";
import "../shared/Freezable.sol";
import "./EmotiCoinCurve.sol";

interface IImplementationApprovalRegistry {
    function approvedImplementation(
        address _implementation
    ) external view returns (bool);
}

contract EmotiCoin is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    UUPSUpgradeable,
    BasicUpgradeableAccessControl,
    Freezable
{
    /**
     * Events:
     * Friends
     * Follower
     */
    enum FriendRequest {
        NONE,
        REQUEST,
        FRIEND,
        UNFRIEND
    }

    enum FollowRequest {
        NONE,
        FOLLOW,
        UNFOLLOW
    }

    event Request(
        FriendRequest request,
        address friend,
        address owner,
        uint256 amount
    );
    event Follow(address friend, address owner, uint256 amount);

    uint256 public constant MAX_SUPPLY = 100_000_000 * 1e18;
    uint256 public constant OWNER_SHARE = (MAX_SUPPLY * 20) / 100; // 20%
    uint256 public constant BONDING_CURVE_SHARE = (MAX_SUPPLY * 60) / 100; // 60%

    address public constant DEV_ADDRESS =
        0xB2e3e82a95f5c4c47E30A5b420Ac4f99d32EF61f;

    mapping(address => FriendRequest) public friendRequests;
    mapping(address => FollowRequest) public followRequests;

    mapping(address => bool) public blockList;
    mapping(address => bool) public isFriend;
    mapping(address => bool) public isFollower;
    mapping(address => bool) public isReferral;

    uint256 public constant FRIEND_AMOUNT = MAX_SUPPLY / 100_000; // 0.001%
    uint256 public constant FOLLOWER_AMOUNT = MAX_SUPPLY / 10_000_000; // 0.00001%
    uint256 public constant REFERRAL_AMOUNT = MAX_SUPPLY / 10_000; // 0.01%

    uint256 public constant FRIEND_MAX = 5_000;
    uint256 public constant FOLLOWER_MAX = 500_000;
    uint256 public constant REFERRAL_MAX = 500;

    uint256 public friendCount;
    uint256 public followerCount;
    uint256 public referralCount;

    EmotiCoinCurve public pumpfun;
    IImplementationApprovalRegistry public implementationApprovalRegistry;

    mapping(address => uint256) public followTimestamps;

    // CAUTION: Always put new variables above construtor to avoid changes to existing global variables.

    constructor() {
        _disableInitializers(); // Required for upgradeable contracts
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _implementationApprovalRegistry,
        address _router,
        address _lpLocker,
        uint256 _lpLockSeconds
    ) public payable initializer {
        __ERC20_init(_name, _symbol);
        __UUPSUpgradeable_init();
        __Ownable_init();
        __ERC20Burnable_init();

        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), _owner, OWNER_SHARE);

        //Initialize Bonding Cuver here
        //TODO: Have to set it 250 PC for prod
        uint256 GRADUATION_PC = 250 ether; // 0.1 PC
        uint256 INITIAL_PC_RESERVES = 25 ether; // 10% of the goal

        //TODO: Set it to 0 also check why its there in the first place
        uint256 TOKENS_TO_BURN = 930233 ether; // A more proportional burn amount

        pumpfun = new EmotiCoinCurve(
            _owner,
            _owner,
            address(this),
            DEV_ADDRESS,
            MAX_SUPPLY,
            GRADUATION_PC, // Using the clear constant for 0.1 PC
            TOKENS_TO_BURN, // Using a clear constant
            300, // feeBps
            BONDING_CURVE_SHARE, // Correct: Matches the actual curve supply
            INITIAL_PC_RESERVES, // Using the clear constant for 0.01 PC
            _router,
            _lpLocker,
            _lpLockSeconds
        );

        _transfer(address(this), address(pumpfun), BONDING_CURVE_SHARE);
        // if (msg.value == 0) {
        //     _transfer(address(this), DEV_ADDRESS, DEV_SHARE);
        // }
        transferOwnership(_owner);
        implementationApprovalRegistry = IImplementationApprovalRegistry(
            _implementationApprovalRegistry
        );
    }

    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {
        require(
            implementationApprovalRegistry.approvedImplementation(
                _newImplementation
            ),
            "Implementation not allowed"
        );
    }

    function requestFriend() external {
        require(
            msg.sender != address(0),
            "Cannot send friend request to null address"
        );
        require(!blockList[msg.sender], "You are block by user");

        require(
            friendRequests[msg.sender] == FriendRequest.NONE ||
                friendRequests[msg.sender] == FriendRequest.UNFRIEND,
            "Invalid request type"
        );
        require(msg.sender != owner(), "Cannot send friend request to ownself");

        if (friendRequests[msg.sender] == FriendRequest.UNFRIEND) {
            friendRequests[msg.sender] = FriendRequest.UNFRIEND;
        } else if (friendRequests[msg.sender] == FriendRequest.NONE) {
            friendRequests[msg.sender] = FriendRequest.REQUEST;
        }
        emit Request(friendRequests[msg.sender], msg.sender, owner(), 0);
    }

    function acceptFriend(address _friend) external onlyOwner {
        require(!blockList[_friend], "You have blocked the user");

        require(
            friendRequests[_friend] == FriendRequest.REQUEST ||
                friendRequests[_friend] == FriendRequest.UNFRIEND,
            "Invalid request type"
        );
        require(!isFriend[_friend], "Already a friend");
        require(friendCount < FRIEND_MAX, "Friend cap reached");

        if (friendRequests[_friend] == FriendRequest.REQUEST) {
            friendCount++;
            if (balanceOf(address(this)) >= FRIEND_AMOUNT) {
                _transfer(address(this), _friend, FRIEND_AMOUNT);
            }
            emit Request(
                FriendRequest.FRIEND,
                _friend,
                msg.sender,
                FRIEND_AMOUNT
            );
        } else if (friendRequests[_friend] == FriendRequest.UNFRIEND) {
            emit Request(FriendRequest.FRIEND, _friend, msg.sender, 0);
        }
        isFriend[_friend] = true;
        friendRequests[_friend] = FriendRequest.FRIEND;
    }

    function unFriend(address _friend) external onlyOwner {
        require(
            !blockList[_friend],
            "You have blocked the user, unfriended already"
        );

        require(
            friendRequests[_friend] == FriendRequest.FRIEND ||
                friendRequests[_friend] == FriendRequest.REQUEST,
            "Invalid request type"
        );
        require(isFriend[_friend], "Not a friend");

        isFriend[_friend] = false;
        friendRequests[_friend] = FriendRequest.UNFRIEND;
        emit Request(FriendRequest.UNFRIEND, _friend, msg.sender, 0);
    }

    function blockUser(address _friend) external onlyOwner {
        if (friendRequests[_friend] == FriendRequest.NONE) {
            friendRequests[_friend] = FriendRequest.NONE;
        } else {
            friendRequests[_friend] = FriendRequest.UNFRIEND;
        }

        if (followRequests[_friend] == FollowRequest.NONE) {
            followRequests[_friend] = FollowRequest.NONE;
        } else {
            followRequests[_friend] = FollowRequest.UNFOLLOW;
        }

        isFriend[_friend] = false;
        blockList[_friend] = true;
        isFollower[_friend] = false;
        emit Request(friendRequests[_friend], _friend, msg.sender, 0);
    }

    function unBlockUser(address _friend) external onlyOwner {
        blockList[_friend] = false;
        emit Request(friendRequests[_friend], _friend, msg.sender, 0);
    }

    function followUser() external {
        require(!blockList[msg.sender], "You are block by user");

        require(
            followRequests[msg.sender] == FollowRequest.NONE ||
                followRequests[msg.sender] == FollowRequest.UNFOLLOW,
            "Invalid request type"
        );

        require(!isFollower[msg.sender], "Already a follower");
        require(msg.sender != owner(), "Cannot follow to ownself");
        require(followerCount < FOLLOWER_MAX, "Follower cap reached");

        if (followRequests[msg.sender] == FollowRequest.NONE) {
            followerCount++;
            _transfer(address(this), msg.sender, FOLLOWER_AMOUNT);
            emit Follow(msg.sender, owner(), FOLLOWER_AMOUNT);
        } else if (followRequests[msg.sender] == FollowRequest.UNFOLLOW) {
            emit Follow(msg.sender, owner(), 0);
        }
        isFollower[msg.sender] = true;
        followRequests[msg.sender] = FollowRequest.FOLLOW;
        followTimestamps[msg.sender] = block.timestamp;
    }

    function unFollowUser() external {
        require(!blockList[msg.sender], "You are block by user");

        require(
            followRequests[msg.sender] == FollowRequest.FOLLOW,
            "Invalid request type"
        );

        require(isFollower[msg.sender], "Not a follower");
        require(msg.sender != owner(), "Cannot unfollow to ownself");

        uint256 followedAt = followTimestamps[msg.sender];
        require(
            block.timestamp >= followedAt + 7 days,
            "Cannot unfollow within 7 days of following"
        );

        isFollower[msg.sender] = false;
        // token.disperse(msg.sender, FOLLOWER_AMOUNT);
        emit Follow(msg.sender, owner(), 0);
    }

    function getRemaining()
        external
        view
        returns (
            uint256 friendsLeft,
            uint256 followersLeft,
            uint256 referralsLeft
        )
    {
        return (
            FRIEND_MAX - friendCount,
            FOLLOWER_MAX - followerCount,
            REFERRAL_MAX - referralCount
        );
    }
}
