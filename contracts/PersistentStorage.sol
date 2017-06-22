pragma solidity ^0.4.11;

// 0xff1e6f10cded258f34d288a1ff93740287cc8a6b

contract PersistentStorage {

    mapping (bytes32 => uint) uintStorage;
    mapping (bytes32 => address) addressStorage;
    mapping (bytes32 => string) stringStorage;
    mapping (bytes32 => bytes32) bytes32Storage;

    function setUintValue(bytes32 key, uint value) {
        uintStorage[key] = value;
    }

    function setAddressValue(bytes32 key, address value) {
        addressStorage[key] = value;
    }

    function setStringValue(bytes32 key, string value) {
        stringStorage[key] = value;
    }

    function setBytes32Value(bytes32 key, bytes32 value) {
        bytes32Storage[key] = value;
    }

    function getUintValue(bytes32 key) constant returns (uint) {
        return uintStorage[key];
    }

    function getAddressValue(bytes32 key) constant returns (address) {
        return addressStorage[key];
    }

    function getStringValue(bytes32 key) constant returns (string) {
        return stringStorage[key];
    }

    function getBytes32Value(bytes32 key) constant returns (bytes32) {
        return bytes32Storage[key];
    }
}