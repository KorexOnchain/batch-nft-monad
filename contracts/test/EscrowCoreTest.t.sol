// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {EscrowCore} from "../src/EscrowCore.sol";

contract EscrowCoreTest is Test {
    EscrowCore public escrow;

    address public owner;
    address public seller;
    address public buyer;
    address public other;

    bytes32 public constant ZONE_LEKKI = keccak256("lekki");
    bytes32 public constant ZONE_IKEJA = keccak256("ikeja");
    bytes32 public constant ZONE_INVALID = bytes32(0);

    uint256 public constant PRICE_CENTS = 1500; // $15.00
    uint256 public constant MONAD_AMOUNT = 1 ether;

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

        escrow = new EscrowCore();

        VALID_OTP_HASH = keccak256(abi.encodePacked(VALID_OTP));

        // Fund buyer
        vm.deal(buyer, 100 ether);
        vm.deal(seller, 100 ether);

        // Seller sets up
        vm.startPrank(seller);
        escrow.setAvailability(true);
        escrow.setPrice(ZONE_LEKKI, PRICE_CENTS);
        vm.stopPrank();
    }

    // ─────────────────────────────────────────────────────────────
    // Helpers
    // ─────────────────────────────────────────────────────────────

    function _createOrder() internal returns (uint256 orderId) {
        vm.prank(buyer);
        orderId = escrow.createOrder{value: MONAD_AMOUNT}(
            payable(seller),
            ZONE_LEKKI
        );
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
        escrow.setPrice(ZONE_IKEJA, 2000);
        assertEq(escrow.sellerPrices(seller, ZONE_IKEJA), 2000);
    }

    function test_SetPrice_RevertsOnZeroZone() public {
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__InvalidZone.selector);
        escrow.setPrice(ZONE_INVALID, PRICE_CENTS);
    }

    function test_SetPrice_RevertsOnZeroCents() public {
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__ZeroPriceCents.selector);
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
        vm.expectEmit(true, true, true, true);
        emit EscrowCore.OrderCreated(
            1,
            buyer,
            seller,
            ZONE_LEKKI,
            PRICE_CENTS,
            MONAD_AMOUNT
        );

        uint256 orderId = _createOrder();
        assertEq(orderId, 1);
        assertEq(escrow.orderCount(), 1);

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(order.buyer, buyer);
        assertEq(order.seller, seller);
        assertEq(order.usdPrice, PRICE_CENTS);
        assertEq(order.monadAmount, MONAD_AMOUNT);
        assertEq(order.zone, ZONE_LEKKI);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Funded));
        assertEq(address(escrow).balance, MONAD_AMOUNT);
    }

    function test_CreateOrder_IncrementOrderCount() public {
        _createOrder();
        _createOrder();
        assertEq(escrow.orderCount(), 2);
    }

    function test_CreateOrder_RevertsOnZeroValue() public {
        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__ZeroPayment.selector);
        escrow.createOrder{value: 0}(payable(seller), ZONE_LEKKI);
    }

    function test_CreateOrder_RevertsOnZeroAddress() public {
        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__ZeroAddress.selector);
        escrow.createOrder{value: MONAD_AMOUNT}(
            payable(address(0)),
            ZONE_LEKKI
        );
    }

    function test_CreateOrder_RevertsSelfTrade() public {
        vm.prank(seller);
        vm.expectRevert(EscrowCore.EscrowCore__SelfTrade.selector);
        escrow.createOrder{value: MONAD_AMOUNT}(payable(seller), ZONE_LEKKI);
    }

    function test_CreateOrder_RevertsOnZeroZone() public {
        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__InvalidZone.selector);
        escrow.createOrder{value: MONAD_AMOUNT}(payable(seller), ZONE_INVALID);
    }

    function test_CreateOrder_RevertsWhenSellerUnavailable() public {
        vm.prank(seller);
        escrow.setAvailability(false);

        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__SellerUnavailable.selector);
        escrow.createOrder{value: MONAD_AMOUNT}(payable(seller), ZONE_LEKKI);
    }

    function test_CreateOrder_RevertsOnUnpricedZone() public {
        vm.prank(buyer);
        vm.expectRevert(EscrowCore.EscrowCore__ZoneNotFound.selector);
        escrow.createOrder{value: MONAD_AMOUNT}(payable(seller), ZONE_IKEJA);
    }

    function test_CreateOrder_RevertsDirectEthSend() public {
        vm.prank(buyer);
        vm.expectRevert("Use createOrder()");
        (bool ok, ) = address(escrow).call{value: 1 ether}("");
        assertTrue(!ok || true); // suppress unused-variable warning
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

        // Fail OTP max - 1 times
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
        uint256 sellerBefore = seller.balance;

        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.OrderReleased(orderId, MONAD_AMOUNT);

        escrow.releaseFunds(orderId); 
        assertEq(seller.balance, sellerBefore + MONAD_AMOUNT);

        EscrowCore.Order memory order = escrow.getOrder(orderId);
        assertEq(uint8(order.status), uint8(EscrowCore.Status.Released));
        assertEq(order.monadAmount, 0);
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

        vm.prank(other); // not buyer or seller
        escrow.releaseFunds(orderId);

        assertEq(
            uint8(escrow.getStatus(orderId)),
            uint8(EscrowCore.Status.Released)
        );
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

        assertEq(
            uint8(escrow.getStatus(orderId)),
            uint8(EscrowCore.Status.Disputed)
        );
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
        uint256 buyerBefore = buyer.balance;

        vm.expectEmit(true, false, false, true);
        emit EscrowCore.DisputeResolved(orderId, buyer, MONAD_AMOUNT);

        escrow.resolveDispute(orderId, true);

        assertEq(buyer.balance, buyerBefore + MONAD_AMOUNT);
        assertEq(
            uint8(escrow.getStatus(orderId)),
            uint8(EscrowCore.Status.Refunded)
        );
    }

    function test_ResolveDispute_ReleasesToSeller() public {
        uint256 orderId = _disputedOrder();
        uint256 sellerBefore = seller.balance;

        escrow.resolveDispute(orderId, false);

        assertEq(seller.balance, sellerBefore + MONAD_AMOUNT);
        assertEq(
            uint8(escrow.getStatus(orderId)),
            uint8(EscrowCore.Status.Released)
        );
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
        uint256 buyerBefore = buyer.balance;

        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);

        vm.expectEmit(true, false, false, false);
        emit EscrowCore.OrderRefunded(orderId);

        vm.prank(buyer);
        escrow.claimRefund(orderId);

        assertEq(buyer.balance, buyerBefore + MONAD_AMOUNT);
        assertEq(
            uint8(escrow.getStatus(orderId)),
            uint8(EscrowCore.Status.Refunded)
        );
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

        vm.warp(block.timestamp + escrow.DISPUTE_WINDOW() + 1);
        uint256 sellerBefore = seller.balance;
        escrow.releaseFunds(orderId);
        assertGt(seller.balance, sellerBefore);
    }

    function test_FullFlow_BuyerDisputesAndWins() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 buyerBefore = buyer.balance;

        vm.prank(buyer);
        escrow.disputeOrder(orderId);

        escrow.resolveDispute(orderId, true);
        assertGt(buyer.balance, buyerBefore);
    }

    function test_FullFlow_BuyerDisputesAndLoses() public {
        uint256 orderId = _createDeliverAndConfirm();
        uint256 sellerBefore = seller.balance;

        vm.prank(buyer);
        escrow.disputeOrder(orderId);

        escrow.resolveDispute(orderId, false);
        assertGt(seller.balance, sellerBefore);
    }

    function test_FullFlow_SellerNeverDeliversBuyerRefunded() public {
        uint256 orderId = _createOrder();
        uint256 buyerBefore = buyer.balance;

        vm.warp(block.timestamp + escrow.REFUND_TIMEOUT() + 1);
        vm.prank(buyer);
        escrow.claimRefund(orderId);
        assertGt(buyer.balance, buyerBefore);
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

    function testFuzz_SetPrice(bytes32 zone, uint256 cents) public {
        vm.assume(zone != bytes32(0));
        vm.assume(cents > 0);

        vm.prank(seller);
        escrow.setPrice(zone, cents);
        assertEq(escrow.sellerPrices(seller, zone), cents);
    }

    function testFuzz_CreateOrder_WithArbitraryValue(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(buyer, uint256(amount));

        vm.prank(buyer);
        uint256 orderId = escrow.createOrder{value: amount}(
            payable(seller),
            ZONE_LEKKI
        );

        EscrowCore.Order memory o = escrow.getOrder(orderId);
        assertEq(o.monadAmount, amount);
    }

    function testFuzz_OTPAttemptTracking(uint8 wrongAttempts) public {
        uint8 max = escrow.MAX_OTP_ATTEMPTS();
        wrongAttempts = uint8(bound(wrongAttempts, 0, max - 1));

        uint256 orderId = _createAndDeliver();

        for (uint8 i; i < wrongAttempts; i++) {
            vm.prank(buyer);
            try escrow.confirmDelivery(orderId, "bad") {} catch {}
        }

        // Correct OTP should still work as long as attempts < max
        vm.prank(buyer);
        escrow.confirmDelivery(orderId, VALID_OTP);
        assertEq(
            uint8(escrow.getStatus(orderId)),
            uint8(EscrowCore.Status.Completed)
        );
    }

    function testFuzz_DisputeWindowBoundary(uint256 warpSeconds) public {
        uint256 window = escrow.DISPUTE_WINDOW();
        warpSeconds = bound(warpSeconds, 0, window - 1);

        uint256 orderId = _createDeliverAndConfirm();
        vm.warp(block.timestamp + warpSeconds);

        // Must still be within window
        vm.expectRevert(EscrowCore.EscrowCore__DisputeWindowOpen.selector);
        escrow.releaseFunds(orderId);

        // Dispute must still be allowed
        vm.prank(buyer);
        escrow.disputeOrder(orderId); // should not revert
    }
}
