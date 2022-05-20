// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20_Token.sol";
import "./Ownable.sol";

contract Vesting is ERC20, Ownable{
    using SafeMath for uint256;
    IERC20 public token;
    uint256 public firstRelease; //after 1 year, investor can claim token
    uint256 public totalPeriods;    //8
    uint256 public timePerPeriods;  // 1 month
    uint256 public clif;            //2 months
    uint256 public totalVestingToken = 1000000000;
    address public ADMIN = address(this);

    event claim(address sender, address receiver, uint256 token_out);

    struct BuyerInfor{
        uint256 claimedPeriods;     //số period đã claim
        uint256 currentTimeClaim;   //thời gian laim
        uint256 amount;             //tổng sô token investor có thể claim
        uint256 claimableToken;     //số token có thể claim
        bool claimedInCliff;        //đã claim trong đợt cliff?
        uint256 totalClaimedPeriods;//số chu kì đã claim
    }
    mapping(address => BuyerInfor) public buyerInfor;
    constructor(
        uint256 _firstRelease, 
        uint256 _clif,      
        uint256 _totalPeriod,   
        uint256 _timePerPeriods
    
    ) ERC20("Tung Bo", "TBC", 10000000000){}
    modifier onlyAdmin(){
        require(msg.sender == 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        _;
    }
    function addWhiteList(address whiteListAdress) public{
        buyerInfor[whiteListAdress].amount = 10000;
        buyerInfor[whiteListAdress].claimableToken = 0;
        buyerInfor[whiteListAdress].currentTimeClaim = 0;
        buyerInfor[whiteListAdress].totalClaimedPeriods = 0;
        buyerInfor[whiteListAdress].claimedInCliff = false;
        buyerInfor[whiteListAdress].claimedPeriods = 0;
    }
    function fundVesting() onlyAdmin payable public{
        // approve(msg.sender, totalVestingToken);
        // allowance(ADMIN, msg.sender);
        approve(address(this), totalVestingToken);
        transfer(msg.sender, totalVestingToken);
}
    function claimToken() public{
        require(buyerInfor[msg.sender].currentTimeClaim < block.timestamp && 
        buyerInfor[msg.sender].claimedPeriods <8, "NOT TIME NO CLAIM YOUR TOKEN");//Kiểm tra đẫ đến thời gian claim hay chưa?
        if(buyerInfor[msg.sender].currentTimeClaim <= firstRelease + clif){     //và sô chu kì phải nhỏ hơn 8
            transferFrom(ADMIN, msg.sender, buyerInfor[msg.sender].amount * clif);      //Nếu pass require thì check tiếp thời gian
            BuyerInfor memory buyerInfor1;                                      //có trong khoảng cliff thì cho claim 20%
            buyerInfor[msg.sender] = buyerInfor1;                           
            emit claim(ADMIN, msg.sender, buyerInfor[msg.sender].amount);
            buyerInfor[msg.sender].claimedInCliff = true;
        }
        else{                               //còn lại sẽ là thời gian claim của 8 periods
            uint256 token20 = 0;
            if(buyerInfor[msg.sender].claimedInCliff == false){         //nếu đã claim 20% ở giai đoạn cliff thì sẽ là true
                token20 = totalVestingToken / 20;                       
            }
            uint256 tokenPerPeriod = totalVestingToken / 10; //10% token của investor
            uint256 checkPeriod = (((buyerInfor[msg.sender].currentTimeClaim - clif - firstRelease) / 2629743) - 
            buyerInfor[msg.sender].claimedPeriods);     //check period = số chu kì - số chu kì đã claim
            transferFrom(ADMIN, msg.sender, (tokenPerPeriod * checkPeriod) + token20); 
            BuyerInfor memory buyerInfor1;
            buyerInfor[msg.sender] = buyerInfor1;
            emit claim(ADMIN, msg.sender, buyerInfor[msg.sender].amount);
            buyerInfor[msg.sender].claimedPeriods += checkPeriod;   //số lần đã claim tăng theo số chu kì đã claim
        }
    }
}