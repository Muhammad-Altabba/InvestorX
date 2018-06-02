pragma solidity ^0.4.21;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";

/// @title Common base for Election and ElectionFactory contracts
contract ElectionBase is Ownable {
    
    /// @dev Could be another smart contract where the logic is written instead of being controlled by a human.
    address public chairperson; 
    
    event ChairpersonChanged(address indexed previousChairperson, address indexed newChairperson);
  
    modifier onlyChairperson() {
        require(msg.sender == chairperson);
        _;
    }
    
    function ElectionBase() public Ownable()  {
        chairperson = msg.sender;
    }
    
    function changeChairperson(address _chairperson) public onlyOwner {
        require(_chairperson != address(0));
        emit ChairpersonChanged(chairperson, _chairperson);
        chairperson = _chairperson;
    }
}


/// @title Election
/// @notice Assumptions: A voter can vote for more than one guru wallet. 
/// However, the voter cannot vote for the same guru wallet more than once.
/// And the given vote cannot be undone (this can be changed easily if needed).
contract Election is ElectionBase {
    
    bool public closed = false;
    
    event GuruAdded(address indexed wallet, uint name, address indexed addedBy);
    event Voted(address indexed guruWallet, address indexed voter);
    event ElectionOpened(address indexed chairperson);
    event ElectionClosed(address indexed chairperson);
    
    modifier electionOpen() {
        require(closed == false);
        _;
    }
    
    struct  Guru {
        uint name;
        mapping(address => bool) voters;
        address[] votersList; //Save only the positive votes. So 'votersList.length' is the votes count.
        
        //'arrayIndex' is useful if delete a guru wallet is required (with the ability to iterate on all gurus wallets).
        uint arrayIndex; //Index of the address of the guru wallet inside 'gurusArray'
    }
    
    /// @dev The key of the mapping is the address (wallet) of a guru.
    mapping (address => Guru) public gurus;
    
    /// @dev An array is used to be able to iterate over all gurus.
    address[] public gurusArray;

    function Election() ElectionBase() public {
        emit ElectionOpened(msg.sender);
    }

    function close() onlyChairperson public{
        emit ElectionClosed(msg.sender);
        closed = true;
    }
    
    /// @notice Chairperson can add any guru
    function addGuru(uint _name, address _wallet) public onlyChairperson {
        require(_wallet != 0x0);
        _addGuru(_name, _wallet);
    }

    /// @notice Receiving applications to become an investment guru
    /// Anyone can add himself as an investment guru 
    function beGuru(uint _name) public {
        _addGuru(_name, msg.sender);
    }
    
    /// @notice Only doable if election is not closed.
    function _addGuru(uint _name, address _wallet) private electionOpen {
        require(_name != 0);
        require(gurus[_wallet].name == 0); //y has not been added early.
        
        emit GuruAdded(_wallet, _name, msg.sender);
        
        gurus[_wallet].name = _name;
        gurus[_wallet].arrayIndex = gurusArray.push(_wallet) -1;
    }

    function vote(address _wallet) public electionOpen {
        require(gurus[_wallet].name != 0); //guru should be exist
        require(gurus[_wallet].voters[msg.sender] == false); //The voter has not already voted
        
        emit Voted(_wallet, msg.sender);
        
        gurus[_wallet].voters[msg.sender] = true;
        gurus[_wallet].votersList.push(msg.sender);
    }
    
    function getVotesCount(address _wallet) public view returns (uint) {
        return gurus[_wallet].votersList.length;
    }

    /// @dev The other way to get the top gurus is to sort and get the top N; 
    ///  But that could consume lots of gas. However, there could be many enhancements and alternatives to the
	///	 current implementation, specially when fixing the number to 10.
    /// However, First try was to pass '_topN' variable in order to have a flexible function. 
    ///  But this limited the function from being used by another solidity function. 
    ///  Because solidity does not yet support returning an array from one function to another.
    function getTop10Preresentatives() public view returns(address[10] wallets , uint[10] names, uint[10] votes) {
        address[10] memory topWallets;
        uint[10] memory topNames;
        uint[10] memory topVotes;
        
        uint maxThreshold = uint(0 - 1); // same as and cheaper than: 'uint(0) - 1' and 'uint(2**256 - 1)';
        
        for(uint i = 0; i < 10; i++) {
            address[10] memory maxRep = getMaxRepWithTop10VotesBelowThreshold(maxThreshold);
            
            //If more than 1 guru having the same number of votes at the end of the list of top 10,
            //  the one(s) with first index will be chosen, in order to get the fixed first top 10 number.
            for(uint j = 0; i + j < 10; j++) {
                if(maxRep[j] == 0x0)
                    break;
                topWallets[i + j] = maxRep[j];
                topNames[i + j] = gurus[maxRep[j]].name;
                topVotes[i + j] = gurus[maxRep[j]].votersList.length;
            }
            i += j - 1;
            if(maxRep[0] == 0x0 || i >= 10)
                break;
            maxThreshold = gurus[maxRep[0]].votersList.length;
            if(maxThreshold == 0)
                break;
        }
        return (topWallets, topNames, topVotes);
    }
    
    /// @notice returns array because more than 1 guru wallet could have the same number of votes
    function getMaxRepWithTop10VotesBelowThreshold(uint _threshold) public view returns (address[10]) {
        address[10] memory repWithMaxVotes;
        uint maxVotes = 0;
        uint counterOfMax = 0;
        for (uint i = 0; i < gurusArray.length; i++) {
            
            uint votes = gurus[gurusArray[i]].votersList.length;
            if( votes < _threshold && counterOfMax < 10) {
                if (votes == maxVotes) {
                    repWithMaxVotes[counterOfMax++] = gurusArray[i];
                }
                else if (votes > maxVotes) {
                    maxVotes = votes;
                    delete repWithMaxVotes;
                    counterOfMax = 0;
                    repWithMaxVotes[counterOfMax++] = gurusArray[i];
                }
            }
        }
        return address[10](repWithMaxVotes);
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////////
    /// The next two function is just to show how something could be implemented in different ways.
    /////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev The other way to get the top gurus is to sort and get the top N;  
    ///  But that could consume lots of gas. However, there could be many enhancements and alternatives to the
	///	 current implementation, specially when fixing the number to 10.
    /// However, the following is the first try in which I pass '_topN' variable in order to have a flexible function. 
    ///  But this limited the function from being used by another solidity function. 
    ///  Because solidity does not yet support returning an array from one function to another.
    function getTopPreresentatives(uint _topN) public returns(address[]) {
        address[] memory topGurus = new address[](_topN);
        uint maxThreshold = uint(0 - 1); // same as and cheaper than: 'uint(0) - 1' and 'uint(2**256 - 1)';
    
        for(uint i = 0; i < _topN; i++) {
            //repWithMaxVotes could be used directly after the next line instead of maxRep. 
            // And that would be cheaper in gas.
            address[] memory maxRep = getMaxRepWithTopVotesBelowThreshold(maxThreshold);
            
            if(maxRep.length == 0) {
                break;
            }
            //If more than 1 guru wallet having the same number of votes at the end of the list of _topN,
            //  the one(s) with fist index will be chosen to get the fixed first _topN number.
            for(uint j = 0; j < maxRep.length && i + j < _topN; j++) {
                topGurus[i + j] = maxRep[j];
            }
            i += maxRep.length -1;
            maxThreshold = gurus[maxRep[0]].votersList.length;
            if(maxThreshold == 0)
                break;
        }
        return topGurus;
    }

    /// @dev I use an array in storage because it is not possible to resize memory arrays.
    /// It will be used only inside the bellow function.
    address[] repWithMaxVotes;
    
    /// @notice returns array because more than 1 guru wallet could have the same number of votes
    /// @dev It is not possible to resize memory-arrays.
    /// memory-arrays could be handled as in the function 'getMaxRepWithTopVotesBelowThreshold'. 
    /// I used the two ways to show two the possibilities (compare 'getMaxRepWithTop10VotesBelowThreshold' vs 'getMaxRepWithTopVotesBelowThreshold')
    /// However, I prefer the one that is implemented in this function (i.e. creating a memory array with fixed length)
    function getMaxRepWithTopVotesBelowThreshold(uint _threshold) public returns (address[]) {
        delete repWithMaxVotes;
        uint maxVotes = 0;
        for (uint i = 0; i < gurusArray.length; i++) {
            uint votes = gurus[gurusArray[i]].votersList.length;
            if( votes < _threshold ) {
                if (votes == maxVotes) {
                    repWithMaxVotes.push(gurusArray[i]);
                }
                else if (votes > maxVotes) {
                    maxVotes = votes;
                    delete repWithMaxVotes;
                    repWithMaxVotes.push(gurusArray[i]);
                }
            }
        }
        return repWithMaxVotes;
    }
}


/// @title Generates and keeps tracking of Elections smart contract.
contract ElectionFactory is ElectionBase {
    uint public currentBatch = 0; //Default is 0. But, setting it to 0 is just to make a clearer code
    
    mapping (uint => address) public elections;
    
    function ElectionFactory() ElectionBase() public {
    }
    
    function newElection() public onlyChairperson {
        if(currentBatch != 0)
            require(Election(elections[currentBatch]).closed()); // enforce running only one election at a time.
        currentBatch++;
        Election election = new Election();
        elections[currentBatch] = address(election);
    }
    
    //Mainly for testing (because of a bug at current remix version, I added this method to be able to link to a deplyed contract and be able to debug it)
    function addElection(address _electionContract) public onlyChairperson {
        if(currentBatch != 0)
            require(Election(elections[currentBatch]).closed()); // enforce running only one election at a time.
        currentBatch++;
        elections[currentBatch] = _electionContract;
    }
    
    function closeCurrentElection() public onlyChairperson {
        //no need to put require(currentBatch !=0) because exction will fail then in all ways.
        Election(elections[currentBatch]).close();
    }
    
    function currentTopTen() public view returns(address[10], uint[10], uint[10]) {
        Election election = Election(elections[currentBatch]);
        return election.getTop10Preresentatives();
    }
    
    function topTen(uint _batch) public view returns(address[10], uint[10], uint[10]) {
        Election election = Election(elections[_batch]);
        return election.getTop10Preresentatives();
    }
}