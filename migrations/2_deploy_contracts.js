// var PersistentStorage = artifacts.require("./PersistentStorage.sol");
// var PToken = artifacts.require("./PToken.sol");
var Organization = artifacts.require("./Organization.sol");

module.exports = function(deployer) {
  // deployer.deploy(PersistentStorage);
  // deployer.deploy(PToken, 100, '0x2efbbc1399f79e405a62ecd38928e8b70eee7c14');
  deployer.deploy(Organization, '0x710a257a58747569215c81972de0c7c0c187b23d', '0x2efbbc1399f79e405a62ecd38928e8b70eee7c14');
};
