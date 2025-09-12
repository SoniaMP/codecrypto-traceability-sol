// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Traceability} from "../src/Traceability.sol";

contract TraceabilityTest is Test {
    Traceability traceability;

    function setUp() public {
        traceability = new Traceability();
    }

    function testRegisterOrganization() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        string memory name = traceability.getOrganizationName(address(this));
        assertEq(name, "OrgA");
        assertEq(
            uint256(traceability.roles(address(this))),
            uint256(Traceability.Role.Producer)
        );
    }

    function testRegisterOrganizationEmptyName() public {
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "registerOrganization(string,uint8)",
                "",
                uint8(Traceability.Role.Producer)
            )
        );
        assertTrue(!success);
    }

    function testRegisterOrganizationTwice() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "registerOrganization(string,uint8)",
                "OrgA",
                uint8(Traceability.Role.Producer)
            )
        );
        assertTrue(!success);
    }

    function testProducerCreatesFirstEvent() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        traceability.addEvent("PROD1", "Created", 12345, -54321);
        Traceability.Event[] memory events = traceability.getHistory("PROD1");
        assertEq(events.length, 1);
        assertEq(events[0].organization, address(this));
        assertEq(events[0].details, "Created");
        assertEq(events[0].latitude, 12345);
        assertEq(events[0].longitude, -54321);
    }

    function testNonProducerCannotCreateFirstEvent() public {
        traceability.registerOrganization(
            "OrgA",
            Traceability.Role.Distributor
        );
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "addEvent(string,string,int32,int32)",
                "PROD1",
                "Created",
                int32(12345),
                int32(-54321)
            )
        );
        assertTrue(!success);
    }

    function testProducerCannotCreateSecondEvent() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        traceability.addEvent("PROD1", "Created", 12345, -54321);
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "addEvent(string,string,int32,int32)",
                "PROD1",
                "Second",
                int32(12345),
                int32(-54321)
            )
        );
        assertTrue(!success);
    }

    function testDistributorCreatesSecondEvent() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        traceability.addEvent("PROD1", "Created", 12345, -54321);
        vm.prank(address(0xBEEF));
        traceability.registerOrganization(
            "OrgB",
            Traceability.Role.Distributor
        );
        vm.prank(address(0xBEEF));
        traceability.addEvent("PROD1", "Received", 22222, -22222);
        Traceability.Event[] memory events = traceability.getHistory("PROD1");
        assertEq(events.length, 2);
        assertEq(events[1].organization, address(0xBEEF));
        assertEq(events[1].details, "Received");
        assertEq(events[1].latitude, 22222);
        assertEq(events[1].longitude, -22222);
    }

    function testAddEventEmptyDetails() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "addEvent(string,string,int32,int32)",
                "PROD1",
                "",
                int32(12345),
                int32(-54321)
            )
        );
        assertTrue(!success);
    }

    function testAddEventWithoutRegistration() public {
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "addEvent(string,string,int32,int32)",
                "PROD1",
                "Created",
                int32(12345),
                int32(-54321)
            )
        );
        assertTrue(!success);
    }

    function testAddEventsBatch() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        string[] memory codes = new string[](2);
        codes[0] = "PROD1";
        codes[1] = "PROD2";
        traceability.addEventsBatch(codes, "BatchInfo", 111, -222);
        for (uint256 i = 0; i < codes.length; i++) {
            Traceability.Event[] memory events = traceability.getHistory(
                codes[i]
            );
            assertEq(events.length, 1);
            assertEq(events[0].details, "BatchInfo");
            assertEq(events[0].organization, address(this));
            assertEq(events[0].latitude, 111);
            assertEq(events[0].longitude, -222);
        }
    }

    function testAddEventsBatchEmptyArray() public {
        traceability.registerOrganization("OrgA", Traceability.Role.Producer);
        string[] memory codes = new string[](0);
        (bool success, ) = address(traceability).call(
            abi.encodeWithSignature(
                "addEventsBatch(string[],string,int32,int32)",
                codes,
                "BatchInfo",
                int32(111),
                int32(-222)
            )
        );
        assertTrue(!success);
    }
}
