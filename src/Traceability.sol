// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Traceability {
    enum Role {
        None,
        Producer,
        Distributor,
        Retailer
    }

    struct Event {
        uint256 timestamp;
        address organization;
        string details;
        int32 latitude;
        int32 longitude;
    }

    mapping(string => Event[]) private histories;
    mapping(address => string) public organizationNames;
    mapping(address => Role) public roles;

    function registerOrganization(string memory name, Role role) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(
            bytes(organizationNames[msg.sender]).length == 0,
            "Organization already registered"
        );
        organizationNames[msg.sender] = name;
        roles[msg.sender] = role;
    }

    function unregisterOrganization() public {
        require(
            bytes(organizationNames[msg.sender]).length != 0,
            "Organization not registered"
        );
        delete organizationNames[msg.sender];
        delete roles[msg.sender];
    }

    function addEvent(
        string memory code,
        string memory details,
        int32 latitude,
        int32 longitude
    ) public {
        require(
            bytes(organizationNames[msg.sender]).length != 0,
            "Organization not registered"
        );
        require(bytes(details).length > 0, "Details cannot be empty");

        Event[] storage events = histories[code];
        Role senderRole = roles[msg.sender];

        if (senderRole == Role.Producer) {
            require(
                events.length == 0,
                "A producer can only create the first event"
            );
        } else {
            require(
                events.length > 0,
                "Only a producer can create the first event"
            );
        }

        Event memory newEvent = Event(
            block.timestamp,
            msg.sender,
            details,
            latitude,
            longitude
        );
        histories[code].push(newEvent);
    }

    function getHistory(
        string memory code
    ) public view returns (Event[] memory) {
        return histories[code];
    }

    function addEventsBatch(
        string[] memory codes,
        string memory info,
        int32 latitude,
        int32 longitude
    ) public {
        require(codes.length > 0, "Codes array cannot be empty");
        for (uint256 i = 0; i < codes.length; i++) {
            addEvent(codes[i], info, latitude, longitude);
        }
    }

    function getOrganizationName(
        address org
    ) public view returns (string memory) {
        return organizationNames[org];
    }
}
