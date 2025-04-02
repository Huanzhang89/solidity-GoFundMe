// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate() > MINIMUM_USD,
            "didn't send enough Eth"
        ); // 1e18 =  1 ETH = 1 * 10 ** 18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] =
            addressToAmountFunded[msg.sender] +
            msg.value;
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF
        );
        return priceFeed.version();
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset array
        funders = new address[](0);
        // actually withdraw the funds
        // payable(msg.sender).transfer(address(this).balance);
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // this allows us to use the code in the modifier without having to add a parameter
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
