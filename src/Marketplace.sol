// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ReentrancyGuard, Ownable {
    struct Listing {
        address seller;
        address token;
        uint256 amount;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    uint256 public listingCount;

    event Listed(
        address indexed seller,
        address indexed token,
        uint256 indexed listingId,
        uint256 amount,
        uint256 price
    );
    event Sold(
        address indexed seller,
        address indexed buyer,
        address indexed token,
        uint256 listingID,
        uint256 price,
        uint256 amount
    );
    event Canceled(address indexed seller, uint256 indexed listingID);

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    function list(address token, uint256 amount, uint256 price) public {
        require(amount > 0, "amount insufficent");
        require(price > 0, "price nonexistent");
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "insufficient balance"
        );
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        listingCount++;
        listings[listingCount] = Listing({
            seller: msg.sender,
            token: token,
            amount: amount,
            price: price,
            active: true
        });

        emit Listed(msg.sender, token, listingCount, amount, price);
    }

    function buy(uint256 listingID) public payable nonReentrant {
        require(listings[listingID].active, "not listed");

        Listing memory listing = listings[listingID];

        require(msg.value >= listing.price, "ins payment");

        (bool success, ) = payable(listing.seller).call{value: listing.price}(
            ""
        );
        require(success, "transfer failed");

        IERC20(listing.token).transfer(msg.sender, listing.amount);

        delete listings[listingID];

        emit Sold(
            listing.seller,
            msg.sender,
            listing.token,
            listingID,
            listing.price,
            listing.amount
        );
    }

    function cancel(uint256 listingID) public {
        require(listings[listingID].active, "not listed");
        require(listings[listingID].seller == msg.sender, "not seller");

        Listing memory listing = listings[listingID];

        IERC20(listing.token).transfer(listing.seller, listing.amount);

        delete listings[listingID];

        emit Canceled(msg.sender, listingID);
    }
}
