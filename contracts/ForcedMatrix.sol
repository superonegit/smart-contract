pragma solidity ^0.4.15;

import './Ownable.sol';
import './SafeMath.sol';

contract ForcedMatrix is Ownable {
    using SafeMath for uint256;

    struct Spot {
        uint256 parentId; // id of parent in tree
        address owner;
        address parentAddress; // may differ from parentId owner
        uint256 commissionTierId; // current comission tier
    }

    struct Participant {
        bool isBlackListed;
        uint256 spotsCount;
        uint256 weiAmount;
        uint256 totalEarned;
    }

    address public ethWallet;

    uint256 public spotCost; // price for 1 place
    uint256 public matrixWidth;
    uint256 public matrixHeight;

    uint256 public totalBalance;
    uint256 private constant spotsCount = 900000; // number we never get

    uint256[] public commissionTiers; // tier in % (0, 2, 4, 8)

    mapping(uint256 => Spot) public spots; // id => spot
    mapping(address => Participant) public participants;

    event ComissionPaid(uint256 spotId, address spotOwner, uint256 amount);

    function ForcedMatrix(uint256 _matrixWidth,
        uint256 _matrixHeight, uint256 _spotCost, uint256[] _commissionTiers,
        address _rootAddress, address _ethWallet) public {

        require(_matrixWidth > 1);
        require(_matrixHeight > 1);

        require(_spotCost > 0);
        require(_commissionTiers.length > 0);

        matrixWidth = _matrixWidth;
        matrixHeight = _matrixHeight;
        spotCost = _spotCost;
        commissionTiers = _commissionTiers;

        ethWallet = _ethWallet;

        spots[0].parentId = spotsCount;
        spots[0].owner = _rootAddress;
        participants[_rootAddress].spotsCount = 1;
    }

    // @param spotId  New spot id
    // @param owner Address of nwe spot owner
    // @param parentId Parent id in root
    // @param parent Referral parent address
    // @param addId parent id if he isn't on referral chain
    // @param addCommissionTierId
    function submitCommission(uint256 spotId, address owner, uint256 parentId,
        address parent, uint256 addId, uint256 addCommissionTierId) public onlyOwner {

        participants[owner].spotsCount = participants[owner].spotsCount.add(1);
        if(participants[owner].weiAmount < spotCost) {
            participants[owner].weiAmount = 0;
        } else {
            participants[owner].weiAmount = participants[owner].weiAmount.sub(spotCost);
        }

        // reserve new spot
        spots[spotId].parentId = parentId;
        spots[spotId].owner = owner;
        spots[spotId].parentAddress = parent;
        spots[spotId].commissionTierId = 0;

        spots[parentId].commissionTierId = incrementCommissionTier(spots[parentId].commissionTierId);

        // additional comission if parent is not in chain
        if(addId > 0) {
            uint256 addTier = commissionTiers[addCommissionTierId];
            uint256 addComission = calculateComission(addTier);

            spots[addId].owner.transfer(addComission);
            spots[addId].commissionTierId = addCommissionTierId;

            participants[spots[addId].owner].totalEarned =
                participants[spots[addId].owner].totalEarned.add(addComission);
            ComissionPaid(addId, spots[addId].owner, addComission);
        }

        // up chain transfer
        Spot memory currentSpot = spots[parentId];

        while(currentSpot.owner != 0) {
            if(!participants[currentSpot.owner].isBlackListed) {
                uint256 commissionTier = commissionTiers[currentSpot.commissionTierId];
                uint256 comission = calculateComission(commissionTier);
                currentSpot.owner.transfer(comission);

                participants[currentSpot.owner].totalEarned =
                    participants[currentSpot.owner].totalEarned.add(comission);
                ComissionPaid(parentId, currentSpot.owner, comission);
            }
            currentSpot = spots[currentSpot.parentId];
            parentId = currentSpot.parentId;
        }
    }

    function incrementCommissionTier(uint256 tierId) public constant returns(uint256)  {
        uint256 tiersLength = commissionTiers.length;

        if(tierId == tiersLength.sub(1)) {
            return tiersLength.sub(1);
        }

        tierId = tierId.add(1);
        return tierId;
    }

    function blackListParticipant(address participant) public onlyOwner {
        participants[participant].isBlackListed = true;
    }

    function buySpot() public payable {
        totalBalance = totalBalance.add(msg.value);
        participants[msg.sender].weiAmount =
            participants[msg.sender].weiAmount.add(msg.value);
    }

    function() public payable {
        buySpot();
    }

    function calculateComission(uint256 tierValue) internal constant returns(uint256) {
        return spotCost.mul(tierValue).div(100);
    }
}
