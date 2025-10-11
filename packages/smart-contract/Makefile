-include .env

########################################################
# Makefile for ReactiveDCA Smart Contracts
########################################################

# Testing Commands
fork-sepolia:
	anvil --fork-url $(RPC_URL) --port 8545

test-unit:
	# Run units tests with gas reporting
	forge test -vvv --gas-report --match-path "./test/units/**"

# Deployment Commands
deploy-reactive:
	# Deploy to Lasna (Cron Reactive Contract)
	forge script script/Deploy.s.sol:DeployCronReactive \
		--rpc-url $(LASNA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--verifier sourcify \
		--verifier-url $(LASNA_VERIFIER_URL) \
		-vvv

deploy-osiris:
	# Deploy to Ethereum/Sepolia (Swap Contracts)
	forge script script/Deploy.s.sol:DeployOsiris \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--verifier etherscan \
		--verifier-api-key $(ETHERSCAN_API_KEY) \
		-vvv

# Cron Management Commands
pause-cron-reactive:
	# Pause the CronReactive contract on Lasna
	forge script script/CronAction.s.sol:CronActionPause \
		--rpc-url $(LASNA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv

unpause-cron-reactive:
	# Unpause the CronReactive contract on Lasna
	forge script script/CronAction.s.sol:CronActionUnpause \
		--rpc-url $(LASNA_RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv

# Osiris Management Commands
trigger-osiris-callback:
	# Trigger the Osiris callback on Sepolia/Ethereum
	forge script script/OsirisAction.s.sol:TriggerOsirisCallback \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv
