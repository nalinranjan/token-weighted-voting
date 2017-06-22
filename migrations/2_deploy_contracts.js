// var PToken = artifacts.require("./PToken.sol");
var Organization = artifacts.require("./Organization.sol");
// var PersistentStorage = artifacts.require("./PersistentStorage.sol");

module.exports = function(deployer) {
  // deployer.deploy(PToken, 100);
  deployer.deploy(Organization, '0x16063c97f4183b183d936206a39ceb84cd839131', '0xff1e6f10cded258f34d288a1ff93740287cc8a6b');
  // deployer.deploy(PersistentStorage);
};
