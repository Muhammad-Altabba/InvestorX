# InvestorX 

> ***Crypto in-Time Investment Collaboration ÐApp***
Website: InvestorX.io

An Ethereum decentralized application for crypto-investment with decentralized suggestions and elections.

The ÐApp aims to elect top 10 investment wallets. The elections runs continuously, one election at a time. 

Voting for the best Gurus' wallets  (technically the best investment Etheruem addresses) is **Forecasting** that is supposed to depend on technical due diligence and economical studies. And it should not be just subjective predictions. This encouraged by the DApp since the top Gurus will be the ones who really achieved the best investment strategies that are proven, by their ROIs, at the end of each election period.

# Actors

## Investment Guru

Those Guru supposed to be experienced Crypto-Investors, such that, every investor has a different collection of Ether and ERC20 tokens.  Those gurus can submit as many wallets as different strategies they have. And they may submit their wallets(s) with different or similar name(s) at each election cycle. 
The submitted wallet(s) of a guru will contain an investment advice. That is the combination of Ether and Tokens that others are advised to follow. i.e. Other people are advised to have the same suggested percentage, of Ether and tokens, similar to the suggested wallets. 

## Follower

Follower is basically a voter who votes for the best wallet(s), that contain(s) the best investment recommendations. 

## Chairperson

 This is the one who is responsible of opening and closing an election.

# Current Smart Contract Implementation handles

 - Receiving Gurus' applications (names and wallets)
 - Accepting votes from Followers
 - Running (starting & closing) the election by Chairperson 


# Execution Flow

Here is what you need to know to be able to run and test the Smart Contract:

 - The Chairperson starts an election by calling `newElection`. If this is not the first election, the previous one has to be closed first.

 - Any Guru can add his wallet, to the running election, by calling  `beGuru` of the running  `Election` contract. And he can repeat this for as many wallets as strategies he/she has.

 - A Follower can repetitively vote for an investment wallet of a Guru, during the current election period, by calling  `vote` of the in-use `Election` contract instance. 
Assumption: A voter can vote for more than one wallet. However, a voter cannot vote for the same wallet more than once. And the given vote cannot be undone (this can be changed easily if needed).

 - The Chairperson can close the current election by calling  `closeCurrentElection`. This is before a new election cycle can start.

 - Anytime during or after an election, the current/final top 10 investment wallets can be known either by calling `currentTopTen` to get the top 10 of the current running election before or after closing. Or by calling `topTen`, passing the batch number, to get the top 10 of a specific batch.
 

# Future Work

To have a complete project, some few more things has to be done like:

 - Some Oracles have to be implemented to provide the Ether and tokens' prices and overall values of each wallet during and at the end of each competition cycle. In order for the Smart Contract to be able to calculate the ROI (Return on Investment).

 - The Chairperson role can be automated or replaced by some Smart Contract as follow:
Suggestion 1: Set the Chairperson to be another smart contract where the logic of opening and closing an election cycle is for example could be triggered by anyone but verified against some rules (ex. based on time).  
Suggestion 2: remove the Chairperson logic and make the smart contract depend on time sluts and store the Gurus and votes in a mapping indexed by a number that is calculated based on time. For example, to make the period last for 3 months: 

	    batchNumber = (in seconds: timeNow - initialStratTime) / totalSecondsIn3Months

## Incentives
The following could be implemented:
 - Providing incentives for investors in order to encourage them join the completion. This can be done if a reward is given to the wallets that have the top ROI at the end of each election.

 - Followers, how votes for the top investment strategist (top ROI), has to be rewarded back also.

 - Contributors, voters and possible investors, has to pay in Ether or possibly using some specially issued ERC20 token in order to be able to participate. And the collected money will be used to reward the top investors after deducting some fees.