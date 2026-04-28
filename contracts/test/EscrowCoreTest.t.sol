// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {EscrowCore} from "../src/EscrowCore.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Minimal mock USDC — 6 decimals, freely mintable in tests
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract EscrowCoreTest is Test {
    EscrowCore public escrow;
    MockUSDC public usdc;

    address public owner;
    address public seller;
    address public buyer;
    address public other;

    bytes32 public constant ZONE_LEKKI = keccak256("lekki");
    bytes32 public constant ZONE_IKEJA = keccak256("ikeja");
    bytes32 public constant ZONE_INVALID = bytes32(0);

    /// @dev $15.00 in USDC units (6 decimals)
    uint256 public constant USDC_PRICE = 15_000_000;

    string public constant VALID_OTP = "123456";
    bytes32 public VALID_OTP_HASH;

    // ─────────────────────────────────────────────────────────────
    // Setup
    // ─────────────────────────────────────────────────────────────

    function setUp() public {
        owner = address(this);
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");
        other = makeAddr("other");

        usdc = new MockUSDC();
        escrow = new EscrowCore(address(usdc));

        VALID_OTP_HASH = keccak256(abi.encodePacked(VALID_OTP));

        // Mint USDC to buyer and other so they can fund orders
        usdc.mint(buyer, 10_000 * 1e6);
        usdc.mint(other, 10_000 * 1e6);

        // Seller sets up
        vm.startPrank(seller);
        escrow.setAvailability(true);
        escrow.setPrice(ZONE_LEKKI, USDC_PRICE);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────

    /// @dev Approve escrow and create an order as buyer
    function _createOrder() internal returns (uint256 orderId) {
        vm.startPrank(buyer);
        usdc.approve(address(escrow), USDC_PRICE);
        orderId = escrow.createOrder(payable(seller), ZONE_LEKKI);
        vm.stopPrank();
    }

    function _createAndDeliver() internal returns (uint256 orderId) {
        orderId = _createOrder();
        vm.prank(seller);
        escrow.markDelivered(orderId, VALID_OTP_HASH);
    }

    function _createDeliverAndConfirm() internal returns (uint256 orderId) {
        orderId = _createAndDeliver();
        vm.prank(buyer);
        escrow.confirmDelivery(orderId, VALID_OTP);
    }

    // ─────────────────────────────────────────────────────────────
    // Constructor
    // ─────────────────────────────────────────────────────────────

    function test_Constructor_SetsUSDC() public view {
        assertEq(address(escrow.usdc()), address(usdc));
    }

    function test_Constructor_RevertsOnZeroAddress() public {
        vm.expectRevert(EscrowCore.EscrowCore__ZeroAddress.selector);
        new EscrowCore(address(0));
    }

    // ─────────────────────────────────────────────────────────────
    // Seller availability & pricing
    // ─────────────────────────────────────────────────────────────

    function test_SetAvailability_OnAndOff() public {
        vm.startPrank(seller);

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.AvailabilityChanged(seller, false);
        escrow.setAvailability(false);
        assertFalse(escrow.sellerAvailable(seller));

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.AvailabilityChanged(seller, true);
        escrow.setAvailability(true);
        assertTrue(escrow.sellerAvailable(seller));

        vm.stopPrank();
    }

    function test_SetPrice_StoresCorrectly() public {
        vm.prank(seller);
        escrow.setPrice(ZONE_IKEJA, 20_000_000);
        assertEq(escrow.sellerPrices(seller, ZONE_IKEJA), 20_000_000);
    }

    function test_SetPrice_RevertsOnZeroZone() public {
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__InvalidZone.selector);
        escrow.setPrice(ZONE_INVALID, USDC_PRICE);
    }

    function test_SetPrice_RevertsOnZeroPrice() public {
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__ZeroPrice.selector);
        escrow.setPrice(ZONE_LEKKI, 0);
    }

    function test_RemovePrice() public {
        vm.prank(seller);
        escrow.removePrice(ZONE_LEKKI);
        assertEq(escrow.sellerPrices(seller, ZONE_LEKKI), 0);
    }

    function test_RemovePrice_RevertsOnZeroZone() public {
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__InvalidZone.selector);
        escrow.removePrice(ZONE_INVALID);
    }

    function test_IsSellerReady_TrueWhenAvailableAndPriced() public view {
        assertTrue(escrow.isSellerReady(seller, ZONE_LEKKI));
    }

    function test_IsSellerReady_FalseWhenUnavailable() public {
        vm.prank(seller);
        escrow.setAvailability(false);
        assertFalse(escrow.isSellerReady(seller, ZONE_LEKKI));
    }

    function test_IsSellerReady_FalseWhenZoneNotPriced() public view {
        assertFalse(escrow.isSellerReady(seller, ZONE_IKEJA));
    }

    // ─────────────────────────────────────────────────────────────
    // createOrder
    // ─────────────────────────────────────────────────────────────

    function test_CreateOrder_Success() public {
        vm.startPrank(buyer);
        usdc.approve(address(escrow), USDC_PRICE);

        vm.expectEmit(true, true, true, true);
        emit EscrowCore.OrderCreated(1, buyer, seller, ZONE_LEKKI, USDC_PRICE);

        uint256 orderId = escrow.createOrder(payable(seller), ZONE_LEKKI);
        vm.stopPrank();

        assertEq(orderId, 1);
        assertEq(escrow.orderCount(), 1);

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(order.buyer, buyer);
        assertEq(order.seller, seller);
        assertEq(order.usdcAmount, USDC_PRICE);
        assertEq(order.zone, ZONE_LEKKI);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Funded));

        // USDC pulled from buyer into escrow
        assertEq(usdc.balanceOf(address(escrow)), USDC_PRICE);
    }

    function test_CreateOrder_IncrementOrderCount() public {
        _createOrder();
        _createOrder();
        assertEq(escrow.orderCount(), 2);
    }

    function test_CreateOrder_RevertsWithoutApproval() public {
        vm.prank(buyer);
        // No approve() — SafeERC20 will revert
        vm.expectRevert();
        escrow.createOrder(payable(seller), ZONE_LEKKI);
    }

    function test_CreateOrder_RevertsOnZeroAddress() public {
        vm.startPrank(buyer);
        usdc.approve(address(escrow), USDC_PRICE);
        vm.expectRevert(EscrowCore.EscrowCore__ZeroAddress.selector);
        escrow.createOrder(payable(address(0)), ZONE_LEKKI);
        vm.stopPrank();
    }

    function test_CreateOrder_RevertsSelfTrade() public {
        vm.startPrank(seller);
        usdc.approve(address(escrow), USDC_PRICE);
        vm.expectRevert(EscrowCore.EscrowCore__SelfTrade.selector);
        escrow.createOrder(payable(seller), ZONE_LEKKI);
        vm.stopPrank();
    }

    function test_CreateOrder_RevertsOnZeroZone() public {
        vm.startPrank(buyer);
        usdc.approve(address(escrow), USDC_PRICE);
        vm.expectRevert(EscrowCore.EscrowCore__InvalidZone.selector);
        escrow.createOrder(payable(seller), ZONE_INVALID);
        vm.stopPrank();
    }

    function test_CreateOrder_RevertsWhenSellerUnavailable() public {
        vm.prank(seller);
        escrow.setAvailability(false);

        vm.startPrank(buyer);
        usdc.approve(address(escrow), USDC_PRICE);
        vm.expectRevert(EscrowCore.EscrowCore__SellerUnavailable.selector);
        escrow.createOrder(payable(seller), ZONE_LEKKI);
        vm.stopPrank();
    }

    function test_CreateOrder_RevertsOnUnpricedZone() public {
        vm.startPrank(buyer);
        usdc.approve(address(escrow), USDC_PRICE);
        vm.expectRevert(EscrowCore.EscrowCore__ZoneNotFound.selector);
        escrow.createOrder(payable(seller), ZONE_IKEJA);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────
    // markDelivered
    // ─────────────────────────────────────────────────────────────

    function test_MarkDelivered_Success() public {
        uint256 orderId = _createOrder();

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.OrderDelivered(orderId, VALID_OTP_HASH);

        vm.prank(seller);
        escrow.markDelivered(orderId, VALID_OTP_HASH);

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Delivered));
        assertEq(order.otpHash, VALID_OTP_HASH);
        assertGt(order.deliveredAt, 0);
    }

    function test_MarkDelivered_RevertsIfNotSeller() public {
        uint256 orderId = _createOrder();
        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__NotSeller.selector);
        escrow.markDelivered(orderId, VALID_OTP_HASH);
    }

    function test_MarkDelivered_RevertsIfZeroOTPHash() public {
        uint256 orderId = _createOrder();
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__InvalidOTPHash.selector);
        escrow.markDelivered(orderId, bytes32(0));
    }

    function test_MarkDelivered_RevertsIfWrongStatus() public {
        uint256 orderId = _createAndDeliver();
        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Funded,
                EscrowCore.Status.Delivered
            )
        );
        escrow.markDelivered(orderId, VALID_OTP_HASH);
    }

    // ─────────────────────────────────────────────────────────────
    // confirmDelivery
    // ─────────────────────────────────────────────────────────────

    function test_ConfirmDelivery_Success() public {
        uint256 orderId = _createAndDeliver();

        vm.expectEmit(true, false, false, false);
        emit EscrowCore.OrderCompleted(orderId, block.timestamp);

        vm.prank(buyer);
        escrow.confirmDelivery(orderId, VALID_OTP);

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Completed));
        assertGt(order.confirmedAt, 0);
    }

    function test_ConfirmDelivery_RevertsIfNotBuyer() public {
        uint256 orderId = _createAndDeliver();
        vm.prank(other);
        vm.expectRevert(EscrowCore.EscrowCore__NotBuyer.selector);
        escrow.confirmDelivery(orderId, VALID_OTP);
    }

    function test_ConfirmDelivery_EmitsOTPFailed() public {
        uint256 orderId = _createAndDeliver();

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.OTPFailed(orderId, 1, escrow.MAX_OTP_ATTEMPTS() - 1);

        vm.prank(buyer);
        escrow.confirmDelivery(orderId, "bad");
    }

    function test_ConfirmDelivery_DisputesAfterMaxAttempts() public {
        uint256 orderId = _createAndDeliver();
        uint8 max = escrow.MAX_OTP_ATTEMPTS();

        for (uint8 i; i < max - 1; i++) {
            vm.prank(buyer);
            escrow.confirmDelivery(orderId, "wrong");
        }

        vm.expectEmit(true, false, false, false);
        emit EscrowCore.OrderDisputed(orderId);

        vm.prank(buyer);
        escrow.confirmDelivery(orderId, "wrong");

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Disputed));

        // Further attempts should revert — wrong status
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Delivered,
                EscrowCore.Status.Disputed
            )
        );
        escrow.confirmDelivery(orderId, VALID_OTP);
    }

    function test_ConfirmDelivery_RevertsIfNotDelivered() public {
        uint256 orderId = _createOrder();
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Delivered,
                EscrowCore.Status.Funded
            )
        );
        escrow.confirmDelivery(orderId, VALID_OTP);
    }

    // ─────────────────────────────────────────────────────────────
    // releaseFunds
    // ─────────────────────────────────────────────────────────────

    function test_ReleaseFunds_Success() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 sellerBefore = usdc.balanceOf(seller);

        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.OrderReleased(orderId, USDC_PRICE);

        escrow.releaseFunds(orderId);

        assertEq(usdc.balanceOf(seller), sellerBefore + USDC_PRICE);
        assertEq(usdc.balanceOf(address(escrow)), 0);

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Released));
        assertEq(order.usdcAmount, 0);
    }

    function test_ReleaseFunds_RevertsInsideDisputeWindow() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.expectRevert(EscrowCore.EscrowCore__DisputeWindowOpen.selector);
        escrow.releaseFunds(orderId);
    }

    function test_ReleaseFunds_RevertsIfNotCompleted() public {
        uint256 orderId = _createOrder();
        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Completed,
                EscrowCore.Status.Funded
            )
        );
        escrow.releaseFunds(orderId);
    }

    function test_ReleaseFunds_CallableByAnyone() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);

        vm.prank(other);
        escrow.releaseFunds(orderId);

        assertEq(uint8(escrow.getStatus(orderId)), uint8(EscrowCore.Status.Released));
    }

    // ─────────────────────────────────────────────────────────────
    // disputeOrder
    // ─────────────────────────────────────────────────────────────

    function test_DisputeOrder_Success() public {
        uint256 orderId = _createDeliverAndConfirm();

        vm.expectEmit(true, false, false, false);
        emit EscrowCore.OrderDisputed(orderId);

        vm.prank(buyer);
        escrow.disputeOrder(orderId);

        assertEq(uint8(escrow.getStatus(orderId)), uint8(EscrowCore.Status.Disputed));
    }

    function test_DisputeOrder_RevertsIfNotBuyer() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.prank(other);
        vm.expectRevert(EscrowCore.EscrowCore__NotBuyer.selector);
        escrow.disputeOrder(orderId);
    }

    function test_DisputeOrder_RevertsAfterDisputeWindow() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);

        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__DisputeWindowClosed.selector);
        escrow.disputeOrder(orderId);
    }

    function test_DisputeOrder_RevertsIfNotCompleted() public {
        uint256 orderId = _createOrder();
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Completed,
                EscrowCore.Status.Funded
            )
        );
        escrow.disputeOrder(orderId);
    }

    // ─────────────────────────────────────────────────────────────
    // resolveDispute
    // ─────────────────────────────────────────────────────────────

    function _disputedOrder() internal returns (uint256 orderId) {
        orderId = _createDeliverAndConfirm();
        vm.prank(buyer);
        escrow.disputeOrder(orderId);
    }

    function test_ResolveDispute_RefundBuyer() public {
        uint256 orderId = _disputedOrder();
        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.DisputeResolved(orderId, buyer, USDC_PRICE);

        escrow.resolveDispute(orderId, true);

        assertEq(usdc.balanceOf(buyer), buyerBefore + USDC_PRICE);
        assertEq(uint8(escrow.getStatus(orderId)), uint8(EscrowCore.Status.Refunded));
    }

    function test_ResolveDispute_ReleasesToSeller() public {
        uint256 orderId = _disputedOrder();
        uint256 sellerBefore = usdc.balanceOf(seller);

        escrow.resolveDispute(orderId, false);

        assertEq(usdc.balanceOf(seller), sellerBefore + USDC_PRICE);
        assertEq(uint8(escrow.getStatus(orderId)), uint8(EscrowCore.Status.Released));
    }

    function test_ResolveDispute_RevertsIfNotOwner() public {
        uint256 orderId = _disputedOrder();
        vm.prank(other);
        vm.expectRevert();
        escrow.resolveDispute(orderId, true);
    }

    function test_ResolveDispute_RevertsIfNotDisputed() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Disputed,
                EscrowCore.Status.Completed
            )
        );
        escrow.resolveDispute(orderId, true);
    }

    // ─────────────────────────────────────────────────────────────
    // claimRefund
    // ─────────────────────────────────────────────────────────────

    function test_ClaimRefund_Success() public {
        uint256 orderId = _createOrder();
        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);

        vm.expectEmit(true, false, false, false);
        emit EscrowCore.OrderRefunded(orderId);

        vm.prank(buyer);
        escrow.claimRefund(orderId);

        assertEq(usdc.balanceOf(buyer), buyerBefore + USDC_PRICE);
        assertEq(uint8(escrow.getStatus(orderId)), uint8(EscrowCore.Status.Refunded));
    }

    function test_ClaimRefund_RevertsBeforeTimeout() public {
        uint256 orderId = _createOrder();
        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() - 1);

        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__TimeoutNotReached.selector);
        escrow.claimRefund(orderId);
    }

    function test_ClaimRefund_RevertsIfNotBuyer() public {
        uint256 orderId = _createOrder();
        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);

        vm.prank(other);
        vm.expectRevert(EscrowCore.EscrowCore__NotBuyer.selector);
        escrow.claimRefund(orderId);
    }

    function test_ClaimRefund_RevertsIfNotFunded() public {
        uint256 orderId = _createAndDeliver();
        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Funded,
                EscrowCore.Status.Delivered
            )
        );
        escrow.claimRefund(orderId);
    }

    // ─────────────────────────────────────────────────────────────
    // disputeTimeLeft
    // ─────────────────────────────────────────────────────────────

    function test_DisputeTimeLeft_ReturnsWindowWhenJustConfirmed() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 left = escrow.disputeTimeLeft(orderId);
        assertApproxEqAbs(left, escrow.DISPUTE_WINDOW(), 5);
    }

    function test_DisputeTimeLeft_ReturnsZeroAfterWindow() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);
        assertEq(escrow.disputeTimeLeft(orderId), 0);
    }

    function test_DisputeTimeLeft_ReturnsZeroIfNotCompleted() public {
        uint256 orderId = _createOrder();
        assertEq(escrow.disputeTimeLeft(orderId), 0);
    }

    // ─────────────────────────────────────────────────────────────
    // Full happy-path flows
    // ─────────────────────────────────────────────────────────────

    function test_FullFlow_NoDispute() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 sellerBefore = usdc.balanceOf(seller);

        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);
        escrow.releaseFunds(orderId);

        assertGt(usdc.balanceOf(seller), sellerBefore);
    }

    function test_FullFlow_BuyerDisputesAndWins() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.prank(buyer);
        escrow.disputeOrder(orderId);
        escrow.resolveDispute(orderId, true);

        assertGt(usdc.balanceOf(buyer), buyerBefore);
    }

    function test_FullFlow_BuyerDisputesAndLoses() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 sellerBefore = usdc.balanceOf(seller);

        vm.prank(buyer);
        escrow.disputeOrder(orderId);
        escrow.resolveDispute(orderId, false);

        assertGt(usdc.balanceOf(seller), sellerBefore);
    }

    function test_FullFlow_SellerNeverDeliversBuyerRefunded() public {
        uint256 orderId = _createOrder();
        uint256 buyerBefore = usdc.balanceOf(buyer);

        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);
        vm.prank(buyer);
        escrow.claimRefund(orderId);

        assertGt(usdc.balanceOf(buyer), buyerBefore);
    }

    // ─────────────────────────────────────────────────────────────
    // State-machine integrity — can't skip steps
    // ─────────────────────────────────────────────────────────────

    function test_CannotDisputeFundedOrder() public {
        uint256 orderId = _createOrder();
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Completed,
                EscrowCore.Status.Funded
            )
        );
        escrow.disputeOrder(orderId);
    }

    function test_CannotConfirmDeliveryOnFundedOrder() public {
        uint256 orderId = _createOrder();
        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Delivered,
                EscrowCore.Status.Funded
            )
        );
        escrow.confirmDelivery(orderId, VALID_OTP);
    }

    function test_CannotReleaseAfterRefund() public {
        uint256 orderId = _createOrder();
        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);
        vm.prank(buyer);
        escrow.claimRefund(orderId);

        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Completed,
                EscrowCore.Status.Refunded
            )
        );
        escrow.releaseFunds(orderId);
    }

    function test_CannotReleaseTwice() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);
        escrow.releaseFunds(orderId);

        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Completed,
                EscrowCore.Status.Released
            )
        );
        escrow.releaseFunds(orderId);
    }

    function test_CannotDisputeAfterRelease() public {
        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);
        escrow.releaseFunds(orderId);

        vm.prank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                EscrowCore.EscrowCore__WrongStatus.selector,
                EscrowCore.Status.Completed,
                EscrowCore.Status.Released
            )
        );
        escrow.disputeOrder(orderId);
    }

    // ─────────────────────────────────────────────────────────────
    // Fuzz
    // ─────────────────────────────────────────────────────────────

    function testFuzz_SetPrice(bytes32 zone, uint256 amount) public {
        vm.assume(zone != bytes32(0));
        vm.assume(amount > 0);

        vm.prank(seller);
        escrow.setPrice(zone, amount);
        assertEq(escrow.sellerPrices(seller, zone), amount);
    }

    function testFuzz_CreateOrder_WithArbitraryUSDC(uint64 amount) public {
        vm.assume(amount > 0);

        // Set zone price to fuzz amount
        vm.prank(seller);
        escrow.setPrice(ZONE_LEKKI, uint256(amount));

        usdc.mint(buyer, uint256(amount));

        vm.startPrank(buyer);
        usdc.approve(address(escrow), uint256(amount));
        uint256 orderId = escrow.createOrder(payable(seller), ZONE_LEKKI);
        vm.stopPrank();

        EscrowCore.Order memory o = escrow.getOrder(orderId);
        assertEq(o.usdcAmount, uint256(amount));
    }

    function testFuzz_OTPAttemptTracking(uint8 wrongAttempts) public {
        uint8 max = escrow.MAX_OTP_ATTEMPTS();
        wrongAttempts = uint8(bound(wrongAttempts, 0, max - 1));

        uint256 orderId = _createAndDeliver();

        for (uint8 i; i < wrongAttempts; i++) {
            vm.prank(buyer);
            escrow.confirmDelivery(orderId, "bad");
        }

        // Correct OTP must still work within attempt limit
        vm.prank(buyer);
        escrow.confirmDelivery(orderId, VALID_OTP);
        assertEq(uint8(escrow.getStatus(orderId)), uint8(EscrowCore.Status.Completed));
    }

    function testFuzz_DisputeWindowBoundary(uint256 warpSeconds) public {
        uint256 window = escrow.DISPUTE_WINDOW();
        warpSeconds = bound(warpSeconds, 0, window - 1);

        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + warpSeconds);

        // Release must still be blocked inside window
        vm.expectRevert(EscrowCore.EscrowCore__DisputeWindowOpen.selector);
        escrow.releaseFunds(orderId);

        // Dispute must still be allowed inside window
        vm.prank(buyer);
        escrow.disputeOrder(orderId);
    }
}
