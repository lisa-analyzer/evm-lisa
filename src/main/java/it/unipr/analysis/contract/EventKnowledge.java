package it.unipr.analysis.contract;

import java.util.Arrays;
import java.util.List;

public class EventKnowledge {
	public enum EventType {
		DEPOSIT, WITHDRAWAL, UNKNOWN
	}

	public static final List<String> DEPOSIT_KNOWLEDGE = Arrays.asList(
			"Deposit", "Send", "LiFiTransferStarted", "LogAnySwapTradeTokensForTokens",
			"TokenDeposit", "TokenDepositAndSwap", "LockApplied", "CrossChainEvent",
			"TransferAllowance", "Sent");

	public static final List<String> WITHDRAWAL_KNOWLEDGE = Arrays.asList(
			"Transfer", "ProposalEvent", "Approval", "Authorize", "LiFiTransferCompleted",
			"LogWithdraw", "ProposalEvent", "ProposalVote", "LogAnySwapTradeTokensForNative",
			"Withdraw", "EmergencyWithdraw", "Harvest", "LockRemoved",
			"VerifyHeaderAndExecuteTxEvent", "TransferOut", "VaultTransfer");

	public static EventType getKnowledge(String signature) {
		signature = signature.toLowerCase();

		for (String keyword : DEPOSIT_KNOWLEDGE) {
			if (signature.contains(keyword.toLowerCase())) {
				return EventType.DEPOSIT;
			}
		}

		for (String keyword : WITHDRAWAL_KNOWLEDGE) {
			if (signature.contains(keyword.toLowerCase())) {
				return EventType.WITHDRAWAL;
			}
		}

		return EventType.UNKNOWN;
	}

	public static void main(String[] args) {
		System.out.println("Deposit Knowledge: " + DEPOSIT_KNOWLEDGE);
		System.out.println("Withdrawal Knowledge: " + WITHDRAWAL_KNOWLEDGE);
	}
}
