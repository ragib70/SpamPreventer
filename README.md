# SpamPreventer

// Variables

// 1. Mapping of address with the spam count.
// 2. Base money amount variable which could be changeable. Keeping it 0.01 base token payable. Depending on the network it is deployed it becomes matic or eth.
// 3. mapping => mapping => {amount deposited, spam, timeStamp}.

// Functions

// 1. Login() - Returns true or false, Executed when the receiver logins the dapp. It will result in checking whether the user is already present in the mapping.


// 2. CreateUser() - Returns void, Must be called after login if the user is not present in the mapping then it means it is a new user and the user will be added in the mapping and the spam count will be 0.

// Functions 1 and 2 are never required to be created as by default the mapping has an address with value = 0, on query.

// 3. DepositSPAmount() - Returns void, linked with + button of new chat, it will take the address of the receiver mentioned in the input field as input and then deposit SP amount calculated based on formula F , into the contract and also will update the mapping of mapping amount deposited.

// 4. ReleaseAmount() - Returns void, linked with the approve button, it will go and search in the mapping of mapping that what is the amount deposited and then the contract will release that amount back to the sender, by depositing it, the mapping of mapping will be updated. Can also be called if CheckTimeElapsed function returns true.

// 5. SpamDeclared() -  Returns void, linked with the spam button beside approve, Once pressed by the receiver, it will increment the spam count and update the mapping of mapping, and will move the chat from requests to block.

// 6. CheckTimeDurationElapsed() - Returns true or false, it will check. whether the timestamp at which the amount deposited has elapsed 24 hrs or not.