// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title  EscrowCore — DispatchPay v1
/// @notice Fixed-price escrow with location-based pricing and OTP delivery confirmation.
/// @dev    Seller registers zone prices on-chain in USDC units (6 decimals).
///         e.g. 15_000_000 = $15.00 USDC.
///         Buyer approves the contract to spend USDC, then calls createOrder().
///
///         Zone labels are bytes32 for gas efficiency.
///         Frontend should use ethers.encodeBytes32String("lekki") before calling.
///
///         Delivery confirmation flow:
///           1. Seller delivers and generates an OTP off-chain.
///           2. Seller calls markDelivered(), storing keccak256(otp) on-chain.
///           3. Seller sends the raw OTP to the buyer out-of-band (SMS / app notification).
///           4. Buyer calls confirmDelivery() with the raw OTP.
///           5. Status moves to Completed and a 2-hour dispute window starts.
///           6a. If buyer disputes within 2 hours → owner investigates via resolveDispute().
///           6b. If no dispute after 2 hours → anyone calls releaseFunds() to pay the seller.
///               The frontend should call this automatically on the seller's behalf.

contract EscrowCore is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The USDC token contract used for all payments.
    IERC20 public immutable usdc;

    enum Status {
        Funded,
        Delivered,
        Completed,
        Released,
        Refunded,
        Disputed
    }

    struct Order {
        address payable buyer;
        address payable seller;
        bytes32 zone;
        bytes32 otpHash;
        uint256 usdcAmount;   // amount in USDC (6 decimals) locked in escrow
        uint256 createdAt;
        uint256 deliveredAt;
        uint256 confirmedAt;
        Status status;
    }

    uint256 public orderCount;

    /// @dev orderId → Order
    mapping(uint256 => Order) public orders;

    /// @dev seller → zone (bytes32) → price in USDC units (6 decimals)
    ///      e.g. 15_000_000 = $15.00
    mapping(address => mapping(bytes32 => uint256)) public sellerPrices;

    /// @dev seller → true if accepting new orders.
    ///      Defaults to false — seller must explicitly go online before orders can be placed.
    mapping(address => bool) public sellerAvailable;

    /// @dev orderId → number of failed OTP attempts by buyer
    mapping(uint256 => uint8) public otpAttempts;

    uint8 public constant MAX_OTP_ATTEMPTS = 4;

    
    uint256 public constant DISPUTE_WINDOW = 2 hours;

    uint256 public constant REFUND_TIMEOUT = 7 days;

    event OrderCreated(
        uint256 indexed orderId,
        address indexed buyer,
        address indexed seller,
        bytes32 zone,
        uint256 usdcAmount
    );
    event OrderDelivered(uint256 indexed orderId, bytes32 otpHash);
    event OrderCompleted(uint256 indexed orderId, uint256 confirmedAt);
    event OrderReleased(uint256 indexed orderId, uint256 usdcAmount);
    event OrderRefunded(uint256 indexed orderId);
    event OrderDisputed(uint256 indexed orderId);
    event DisputeResolved(
        uint256 indexed orderId,
        address recipient,
        uint256 usdcAmount
    );
    event PriceSet(address indexed seller, bytes32 zone, uint256 usdcAmount);
    event PriceRemoved(address indexed seller, bytes32 zone);
    event AvailabilityChanged(address indexed seller, bool available);
    event OTPFailed(
        uint256 indexed orderId,
        uint8 attemptNumber,
        uint8 attemptsLeft
    );


    error EscrowCore__NotBuyer();
    error EscrowCore__NotSeller();
    error EscrowCore__WrongStatus(Status expected, Status actual);
    error EscrowCore__ZeroPayment();
    error EscrowCore__ZeroPrice();
    error EscrowCore__ZeroAddress();
    error EscrowCore__ZoneNotFound();
    error EscrowCore__InvalidZone();
    error EscrowCore__SellerUnavailable();
    error EscrowCore__InvalidOTP();
    error EscrowCore__InvalidOTPHash();
    error EscrowCore__SelfTrade();
    error EscrowCore__TransferFailed();
    error EscrowCore__MaxAttemptsReached();
    error EscrowCore__TimeoutNotReached();
    error EscrowCore__DisputeWindowOpen();
    error EscrowCore__DisputeWindowClosed();

    modifier onlyBuyer(uint256 orderId) {
        if (msg.sender != orders[orderId].buyer) revert EscrowCore__NotBuyer();
        _;
    }

    modifier onlySeller(uint256 orderId) {
        if (msg.sender != orders[orderId].seller) revert EscrowCore__NotSeller();
        _;
    }

    modifier inStatus(uint256 orderId, Status expected) {
        Status actual = orders[orderId].status;
        if (actual != expected) revert EscrowCore__WrongStatus(expected, actual);
        _;
    }

    constructor(address _usdc) Ownable(msg.sender) ReentrancyGuard() {
        if (_usdc == address(0)) revert EscrowCore__ZeroAddress();
        usdc = IERC20(_usdc);
    }


    /// @notice Seller toggles their availability to accept new orders.
    /// @dev    Sellers default to unavailable (false). Must call setAvailability(true)
    ///         before buyers can place orders against them.
    /// @param available  true = open for orders, false = not accepting orders
    function setAvailability(bool available) external {
        sellerAvailable[msg.sender] = available;
        emit AvailabilityChanged(msg.sender, available);
    }

    /// @notice Seller sets or updates a delivery price for a location zone.
    /// @param  zone       bytes32 zone label e.g. ethers.encodeBytes32String("lekki")
    /// @param  usdcAmount Price in USDC units (6 decimals) e.g. 15_000_000 = $15.00
    function setPrice(bytes32 zone, uint256 usdcAmount) external {
        if (zone == bytes32(0)) revert EscrowCore__InvalidZone();
        if (usdcAmount == 0) revert EscrowCore__ZeroPrice();
        sellerPrices[msg.sender][zone] = usdcAmount;
        emit PriceSet(msg.sender, zone, usdcAmount);
    }

    function removePrice(bytes32 zone) external {
        if (zone == bytes32(0)) revert EscrowCore__InvalidZone();
        delete sellerPrices[msg.sender][zone];
        emit PriceRemoved(msg.sender, zone);
    }

    /// @notice Returns the USDC price a seller has set for a zone.
    function getPrice(
        address seller,
        bytes32 zone
    ) external view returns (uint256 usdcAmount) {
        return sellerPrices[seller][zone];
    }

    function isSellerReady(
        address seller,
        bytes32 zone
    ) external view returns (bool) {
        return sellerAvailable[seller] && sellerPrices[seller][zone] > 0;
    }


    function createOrder(
        address payable seller,
        bytes32 zone
    ) external nonReentrant returns (uint256 orderId) {
        if (seller == address(0)) {
            revert EscrowCore__ZeroAddress();
        }
        if (seller == msg.sender) {
            revert EscrowCore__SelfTrade();
        }
        if (zone == bytes32(0)) {
            revert EscrowCore__InvalidZone();
        }
        if (!sellerAvailable[seller]) {
            revert EscrowCore__SellerUnavailable();
        }

        uint256 usdcAmount = sellerPrices[seller][zone];
        if (usdcAmount == 0) {
            revert EscrowCore__ZoneNotFound();
        }

        orderId = ++orderCount;

        orders[orderId] = Order({
            buyer: payable(msg.sender),
            seller: seller,
            zone: zone,
            otpHash: bytes32(0),
            usdcAmount: usdcAmount,
            createdAt: block.timestamp,
            deliveredAt: 0,
            confirmedAt: 0,
            status: Status.Funded
        });

        usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);

        emit OrderCreated(orderId, msg.sender, seller, zone, usdcAmount);
    }

    /// @notice Seller marks an order as delivered and stores the hashed OTP.
    /// @param  orderId  The order to mark delivered
    /// @param  otpHash  keccak256(abi.encodePacked(otp)) — generated off-chain by seller.
    ///                  Raw OTP shared with buyer out-of-band (SMS / app notification).
    function markDelivered(
        uint256 orderId,
        bytes32 otpHash
    ) external onlySeller(orderId) inStatus(orderId, Status.Funded) {
        if (otpHash == bytes32(0)) revert EscrowCore__InvalidOTPHash();

        Order storage order = orders[orderId];
        order.otpHash = otpHash;
        order.status = Status.Delivered;
        order.deliveredAt = block.timestamp;

        emit OrderDelivered(orderId, otpHash);
    }

    /// @notice Buyer submits the OTP to confirm receipt. Starts the 2-hour dispute window.
    /// @dev    Funds stay locked until releaseFunds() is called after the window elapses.
    /// @param  orderId  The order to confirm
    /// @param  otp      The raw OTP string shared by the seller out-of-band
    function confirmDelivery(
        uint256 orderId,
        string calldata otp
    ) external nonReentrant onlyBuyer(orderId) inStatus(orderId, Status.Delivered) {
        Order storage order = orders[orderId];
        otpAttempts[orderId]++;

        if (keccak256(abi.encodePacked(otp)) != order.otpHash) {
            uint8 used = otpAttempts[orderId];

            emit OTPFailed(orderId, used, MAX_OTP_ATTEMPTS - used);

            if (used >= MAX_OTP_ATTEMPTS) {
                order.status = Status.Disputed;
                emit OrderDisputed(orderId);
            }

            return;
        }

        order.status = Status.Completed;
        order.confirmedAt = block.timestamp;

        emit OrderCompleted(orderId, block.timestamp);
    }
    /// @notice Releases funds to the seller after the dispute window has passed with no dispute.
    /// @param  orderId  A Completed order whose dispute window has passed
    function releaseFunds(
        uint256 orderId
    ) external nonReentrant inStatus(orderId, Status.Completed) {
        Order storage order = orders[orderId];
        if (block.timestamp < order.confirmedAt + DISPUTE_WINDOW) {
            revert EscrowCore__DisputeWindowOpen();
        }

        order.status = Status.Released;
        uint256 amount = order.usdcAmount;
        order.usdcAmount = 0;

        usdc.safeTransfer(order.seller, amount);

        emit OrderReleased(orderId, amount);
    }

    /// @notice Buyer disputes a completed order within the 2-hour window.
    /// @param  orderId  A Completed order still within the dispute window
    function disputeOrder(
        uint256 orderId
    ) external onlyBuyer(orderId) inStatus(orderId, Status.Completed) {
        Order storage order = orders[orderId];
        if (block.timestamp >= order.confirmedAt + DISPUTE_WINDOW) {
            revert EscrowCore__DisputeWindowClosed();
        }

        order.status = Status.Disputed;
        emit OrderDisputed(orderId);
    }

    /// @notice Owner resolves a disputed order, sending USDC to either buyer or seller.
    /// @param  orderId     The disputed order to resolve
    /// @param  refundBuyer true = refund buyer, false = release to seller
    function resolveDispute(
        uint256 orderId,
        bool refundBuyer
    ) external nonReentrant onlyOwner inStatus(orderId, Status.Disputed) {
        Order storage order = orders[orderId];

        order.status = refundBuyer ? Status.Refunded : Status.Released;
        uint256 amount = order.usdcAmount;
        order.usdcAmount = 0;

        address recipient = refundBuyer ? order.buyer : order.seller;
        usdc.safeTransfer(recipient, amount);

        emit DisputeResolved(orderId, recipient, amount);
    }

    function claimRefund(
        uint256 orderId
    ) external nonReentrant onlyBuyer(orderId) inStatus(orderId, Status.Funded) {
        Order storage order = orders[orderId];
        if (block.timestamp < order.createdAt + REFUND_TIMEOUT) {
            revert EscrowCore__TimeoutNotReached();
        }

        order.status = Status.Refunded;
        uint256 amount = order.usdcAmount;
        order.usdcAmount = 0;

        usdc.safeTransfer(order.buyer, amount);

        emit OrderRefunded(orderId);
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    function getStatus(uint256 orderId) external view returns (Status) {
        return orders[orderId].status;
    }

    /// @notice Returns seconds remaining in the dispute window, 0 if elapsed or not Completed.
    function disputeTimeLeft(uint256 orderId) external view returns (uint256) {
        Order storage order = orders[orderId];
        if (order.status != Status.Completed) return 0;
        uint256 deadline = order.confirmedAt + DISPUTE_WINDOW;
        if (block.timestamp >= deadline) return 0;
        return deadline - block.timestamp;
    }
}

