/**
 *Submitted for verification at BscScan.com on 2021-06-18
*/

// File: Egoras/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.7.0;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Libraries



// https://docs.synthetix.io/contracts/SafeDecimalMath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

interface EgorasLendingInterface {
    struct Loan{
        string title;
        string story;
        string branchName;
        string loan_category;
        uint amount;
        uint finalLoanAmount;
        uint length;
        string image_url;
        uint totalPayment;
        bool isApproved;
        uint loanFee;
        address creator;
        bool isConfirmed;
    }
event LoanCreated(uint newLoanID, string _title, string _story, string _branchName, string _loan_category, uint _amount, uint _dueAmount, uint _length, 
string _image_url, address _creator);

 event Rewarded(
        address voter, 
        uint share, 
        uint currentVotingPeriod, 
        uint time
        );

    event VotedForRequest(
        address _voter,
        uint _requestID,
        uint _positiveVote,
        uint _negativeVote,
        bool _accept
    );
    event RequestCreated(
      address _creator,
      uint _requestType,
      uint _changeTo,
      uint _votersCut,
      uint _uploaderCut,
      string _reason,
      uint _positiveVote,
      uint _negativeVote,
      bool _stale,
      uint _votingPeriod,
      uint _requestID
      );
  
  
  
    event ApproveLoan(uint _loanID, bool state, address initiator, uint time);
    event ApproveRequest(uint _requestID, bool _state, address _initiator);    
    event LoanRepayment(
        uint loanID,
        uint amount,
        address remitter,
        uint time
    );
    event Confirmed(uint _loanID, uint _loanFee, uint _countDown);
   
    event Refunded(uint amount, address voterAddress, uint _loanID, uint time);

    event Voted(address voter,  uint loanID, uint _positiveVote, uint _negativeVote, bool _accept);
    event Repay(uint _amount, uint _time, uint _loanID);

    function applyForLoan(
        string calldata _title,
        string calldata _story,
        string calldata _branch_name,
         string calldata _loan_category,
        uint _amount,
        uint _length,
        string calldata _image_url
        ) external;

    function getLoanByID(uint _loanID) external view returns(string memory _title, string memory _story, string memory _branchName, uint _amount,
        uint _length,  string memory _image_url,
          uint _totalPayment, bool isApproved, address  _creator);
    function isDue(uint _loanID) external view returns (bool);
    function getVotesByLoanID(uint _loanID) external view returns(uint _accepted, uint _declined);
    function repayLoan(uint _loanID, uint _amount) external;
    function approveLoan(uint _loanID) external;
    function vote(uint _loanID, uint _votePower, bool _accept) external;
    function createRequest(uint _requestType, uint _changeTo, uint _votersCut, uint _uploaderCut, string calldata _reason) external;
    function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) external;
    function validateRequest(uint _requestID) external;
    
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





interface IERC20 {
    function totalSupply() external view  returns (uint256);
    function balanceOf(address account) external view  returns (uint256);
    function transfer(address recipient, uint256 amount) external  returns (bool);
    function allowance(address owner, address spender) external  view returns (uint256);
    function approve(address spender, uint256 amount) external  returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external  returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external;
}




contract EgorasLending is EgorasLendingInterface, Ownable{
    using SafeDecimalMath for uint;
    mapping(uint => bool) activeRequest;
    mapping(uint => mapping(address => uint)) requestPower;
  
    struct Votters{
      address payable voter;
    }
    
     struct Requests{
      address creator;
      uint requestType;
      uint changeTo;
      uint votersCut;
      uint uploaderCut;
      string reason;
      uint positiveVote;
      uint negativeVote;
      bool stale;
      uint votingPeriod;
    }
    
    Requests[] requests;
    mapping(uint => Requests[]) listOfrequests;
    mapping(uint => Votters[]) listOfvoters;
    mapping(uint => Votters[]) activeVoters;
    mapping(uint => Votters[]) activeRequestVoters;
   
    mapping(uint => mapping(address => bool)) hasVoted;
    mapping(uint => mapping(address => bool)) manageRequestVoters;
    mapping(uint => bool) stale;
    mapping(uint => mapping(address => uint)) votePower;
    mapping(uint => uint) totalVotePower;
    mapping(address => address) uploaderRewardAddress;
    
    mapping(uint => uint) positiveVote;
    mapping(uint => uint) voteCountDown;
    mapping(uint => uint) negativeVote;
    mapping (uint => bool) isLoanApproved;
    mapping(uint => uint) votersReward;
    mapping(uint => uint) ownersReward;
    mapping(uint => uint) uploadersReward;
    mapping(address => bool)  uploader;
    Loan[] loans;
    Votters[] voters;
    using SafeMath for uint256;
    address private egorasEUSD;
    address private egorasEGR;
    uint private loanFee;
    uint private systemFeeBalance;
    uint private requestCreationPower;
    uint public ownerCut;
    uint public votersCut;
    uint public uploaderCut;
    constructor(address _egorasEusd, address _egorasEgr, uint _initialLoanFee
    , uint _ownerCut, uint _votersCut, uint _uploaderCut)  public {
        require(address(0) != _egorasEusd, "Invalid address");
        require(address(0) != _egorasEgr, "Invalid address");
        egorasEGR = _egorasEgr;
        egorasEUSD = _egorasEusd;
        loanFee = _initialLoanFee;
        ownerCut = _ownerCut;
        votersCut = _votersCut;
        uploaderCut = _uploaderCut;
    
    }
    
    function addUploader(address _uploader, address _uploaderRewardAddress) external onlyOwner returns(bool){
        uploader[_uploader] = true;
        uploaderRewardAddress[_uploader] = _uploaderRewardAddress;
        return true;
    }
    
   function suspendUploader(address _uploader) external onlyOwner returns(bool) {
       uploader[_uploader] = false;
       return true;
   }

      /*** Restrict access to Uploader role*/    
      modifier onlyUploader() {        
        require(uploader[msg.sender] == true, "Address is not allowed to upload a loan!");       
        _;}

/// Request
function createRequest(uint _requestType, uint _changeTo, uint _votersCut, uint _uploaderCut, string memory _reason) public onlyOwner override{
    require(_requestType >= 0 && _requestType <  2,  "Invalid request type!");
    require(!activeRequest[_requestType], "Another request is still active");
    Requests memory _request = Requests({
      creator: msg.sender,
      requestType: _requestType,
      changeTo: _changeTo,
      votersCut: _votersCut,
      uploaderCut: _uploaderCut,
      reason: _reason,
      positiveVote: 0,
      negativeVote: 0,
      stale: false,
      votingPeriod: block.timestamp.add(1 days)
    });
    
    requests.push(_request);
    uint256 newRequestID = requests.length - 1;
     Requests memory request = requests[newRequestID];
    emit RequestCreated(
      request.creator,
      request.requestType,
      request.changeTo,
      request.votersCut,
      request.uploaderCut,
      request.reason,
      request.positiveVote,
      request.negativeVote,
      request.stale,
      request.votingPeriod,
      newRequestID
      );
}

function governanceVote(uint _requestType, uint _requestID, uint _votePower, bool _accept) public override{
    Requests storage request = requests[_requestID];
    require(request.votingPeriod >= block.timestamp, "Voting period ended");
    require(_votePower > 0, "Power must be greater than zero!");
    require(_requestType == 0 || _requestType == 1 || _requestType == 2,  "Invalid request type!");
    IERC20 iERC20 = IERC20(egorasEGR);
    require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
    require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error");
    requestPower[_requestType][msg.sender] = requestPower[_requestType][msg.sender].add(_votePower);
     
     
       if(_accept){
            request.positiveVote = request.positiveVote.add(_votePower);
        }else{
            request.negativeVote = request.negativeVote.add(_votePower);  
        }
        
        if(manageRequestVoters[_requestID][msg.sender] == false){
            manageRequestVoters[_requestID][msg.sender] = true;
            activeRequestVoters[_requestID].push(Votters(msg.sender));
        }
            
           emit VotedForRequest(msg.sender, _requestID, request.positiveVote, request.negativeVote, _accept);
    
}

function validateRequest(uint _requestID) public override{
    Requests storage request = requests[_requestID];
    require(block.timestamp >= request.votingPeriod, "Voting period still active");
    require(!request.stale, "This has already been validated");
    
    IERC20 egr = IERC20(egorasEGR);
    if(request.requestType == 0){
        if(request.positiveVote >= request.negativeVote){
            loanFee = request.changeTo;
            request.stale = true;
        }
        
    }else if(request.requestType == 1){
        if(request.positiveVote >= request.negativeVote){
            ownerCut = request.changeTo;
            votersCut = request.votersCut;
            uploaderCut = request.uploaderCut;
            request.stale = true;
        }
        
    }
    
    for (uint256 i = 0; i < activeRequestVoters[_requestID].length; i++) {
           address voterAddress = activeRequestVoters[_requestID][i].voter;
           uint amount = requestPower[request.requestType][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           requestPower[request.requestType][voterAddress] = 0;
           emit Refunded(amount, voterAddress, _requestID, now);
    }
    
   
    emit ApproveRequest(_requestID, request.positiveVote >= request.negativeVote, msg.sender);
}
  // Loan

    function applyForLoan(
        string memory _title,
        string memory _story,
        string memory _branch_name,
        string memory _loan_category,
        uint _amount,
        uint _length,
        string memory _image_url
        ) external onlyUploader override {
        require(_amount > 0, "Loan amount should be greater than zero");
        require(_length > 0, "Loan duration should be greater than zero");
        require(bytes(_title).length > 3, "Loan title should more than three characters long");
        uint currentLoanFee = loanFee.mul(_length);
        
        uint reward = uint(uint(_amount).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(currentLoanFee)));
        uint dueAmount = _amount.sub(reward);
        require(votersCut.add(uploaderCut.add(ownerCut)) == 10000, "Invalid percent");
         Loan memory _loan = Loan({
         title: _title,
         story: _story,
         branchName: _branch_name,
         loan_category: _loan_category,
         amount: _amount,
         finalLoanAmount: dueAmount,
         length: _length,
         image_url: _image_url,
         totalPayment: 0,
         isApproved: false,
         loanFee: loanFee,
         creator: msg.sender,
         isConfirmed: false
        });
             loans.push(_loan);
             uint256 newLoanID = loans.length - 1;
             
             votersReward[newLoanID] = votersReward[newLoanID].add(uint(uint(reward).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(votersCut))));
             ownersReward[newLoanID] = ownersReward[newLoanID].add(uint(uint(reward).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(ownerCut))));
             uploadersReward[newLoanID] = uploadersReward[newLoanID].add(uint(uint(reward).divideDecimalRound(uint(10000)).multiplyDecimalRound(uint(uploaderCut))));
             
             emit LoanCreated(newLoanID, _title, _story, _branch_name, _loan_category, _amount, dueAmount, _length,_image_url, msg.sender);
        }

    function getLoanByID(uint _loanID) external override view returns(
        string memory _title, string memory _story, string memory _branchName, uint _amount,
        uint _length, string memory _image_url,
        uint _totalPayment, bool isApproved, address  _creator
        ){
         Loan memory loan = loans[_loanID];
         return (loan.title, loan.story,loan.branchName, loan.amount, 
         loan.length,  loan.image_url, loan.totalPayment,
          isApproved, loan.creator);
     }
     
  
      
     
     function getVotesByLoanID(uint _loanID) external override view returns(uint _accepted, uint _declined){
        return (positiveVote[_loanID], negativeVote[_loanID]);
    }

    function vote(uint _loanID, uint _votePower, bool _accept) external override{
            require(!stale[_loanID], "The loan is either approve/declined");
            require(!hasVoted[_loanID][msg.sender], "You cannot vote twice");
            Loan memory loan = loans[_loanID];
            require(loan.isConfirmed, "Can't vote at the moment!");
            require(_votePower > 0, "Power must be greater than zero!");
            IERC20 iERC20 = IERC20(egorasEGR);
            require(iERC20.allowance(msg.sender, address(this)) >= _votePower, "Insufficient EGR allowance for vote!");
            require(iERC20.transferFrom(msg.sender, address(this), _votePower), "Error!");
            if(_accept){
                positiveVote[_loanID] = positiveVote[_loanID].add(_votePower);
            }else{
              negativeVote[_loanID] = negativeVote[_loanID].add(_votePower);  
            }
             votePower[_loanID][msg.sender] = votePower[_loanID][msg.sender].add(_votePower);
             totalVotePower[_loanID] = totalVotePower[_loanID].add(_votePower);
           
            if(!hasVoted[_loanID][msg.sender]){
                 hasVoted[_loanID][msg.sender] = true;
                listOfvoters[_loanID].push(Votters(msg.sender));
            }
            
            emit Voted(msg.sender, _loanID,  positiveVote[_loanID],negativeVote[_loanID], _accept);
    } 
       
function repayLoan(uint _loanID, uint _amount) external override{
   Loan storage loan = loans[_loanID];
   require(loan.isApproved, "This loan is not approved yet.");
   require(loan.creator == msg.sender, "Unauthorized.");
   require(loan.finalLoanAmount >= (loan.totalPayment.add(_amount)), "You canno over pay for this loan.");
   IERC20 iERC20 = IERC20(egorasEUSD);
   require(iERC20.allowance(msg.sender, address(this)) >= _amount, "Insufficient EUSD allowance for repayment!");
   iERC20.burnFrom(msg.sender, _amount);
   loan.totalPayment = loan.totalPayment.add(_amount);
  
   emit Repay(_amount, now, _loanID);  
}

function approveLoan(uint _loanID) external override{
    Loan storage loan = loans[_loanID];
    require(loan.isConfirmed, "Can't vote at the moment!");
     require(isDue(_loanID), "Voting is not over yet!");
     require(!stale[_loanID], "The loan is either approve/declined");
     
     IERC20 EUSD = IERC20(egorasEUSD);
     IERC20 egr = IERC20(egorasEGR);
     if(positiveVote[_loanID] > negativeVote[_loanID]){
     require(EUSD.mint(loan.creator, loan.finalLoanAmount), "Fail to transfer fund");
     require(EUSD.mint(owner(), ownersReward[_loanID]), "Fail to transfer fund");
     require(EUSD.mint(uploaderRewardAddress[loan.creator], uploadersReward[_loanID]), "Fail to transfer fund");
    for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;


            // Start of reward calc
            uint totalUserVotePower = votePower[_loanID][voterAddress].mul(1000);
            uint currentTotalPower = totalVotePower[_loanID];
            uint percentage = totalUserVotePower.div(currentTotalPower);
            uint share = percentage.mul(votersReward[_loanID]).div(1000);
            // End of reward calc
            
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           votePower[_loanID][voterAddress] = votePower[_loanID][voterAddress].sub(amount);
           require(EUSD.mint(voterAddress, share), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, now);
    }
     loan.isApproved = true;
     stale[_loanID] = true;
     
     emit ApproveLoan(_loanID, true, msg.sender, now);
     }else{
        for (uint256 i = 0; i < listOfvoters[_loanID].length; i++) {
           address voterAddress = listOfvoters[_loanID][i].voter;
           uint amount = votePower[_loanID][voterAddress];
           require(egr.transfer(voterAddress, amount), "Fail to refund voter");
           emit Refunded(amount, voterAddress, _loanID, now);
    } 
     stale[_loanID] = true;
     emit ApproveLoan(_loanID, false, msg.sender, now);
     }
}

function isDue(uint _loanID) public override view returns (bool) {
        if (block.timestamp >= voteCountDown[_loanID])
            return true;
        else
            return false;
    }


function confirmLoan(uint _loanID)  external  onlyOwner returns(bool){
    Loan storage loan = loans[_loanID];
    loan.isConfirmed = true;
    emit Confirmed(_loanID, loan.loanFee, block.timestamp.add(1 days));
}

function getLoanInfo(uint _loanID) view external returns (bool _validate, bool _staleVoting, bool _state, uint _finalLoanAmount){
     Loan memory loan = loans[_loanID];
    return(stale[_loanID], isDue(_loanID), loan.isApproved, loan.finalLoanAmount);
}

function systemInfo() external view  returns(uint _requestpower, uint _loanFee, uint _ownerCut, uint _uploaderCut, uint _votersCut){
    return(requestCreationPower, loanFee, ownerCut, uploaderCut, votersCut);
}

}