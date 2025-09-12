-include .env

#
# Test and utility targets
#

fork-sepolia:
	anvil --fork-url $(SEPOLIA_RPC_URL) --port 8545

deploy-reactive:
	# Deploy to Lasna (Cron Reactive Contract)
	forge script script/Deploy.s.sol:DeployCronReactive \
		--rpc-url $(LASNA_RPC) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--verifier sourcify \
		--verifier-url $(LASNA_VERIFIER_URL) \
		-vvv

deploy-callback:
	# Deploy to Sepolia (Callback Contracts)
	forge script script/Deploy.s.sol:DeployCallback \
		--rpc-url $(SEPOLIA_RPC) \
		--account $(ACCOUNT) \
		--broadcast \
		--verify \
		--verifier etherscan \
		--verifier-api-key $(ETHERSCAN_API_KEY) \
		-vvv

#### Pause CronReactive Contract on Lasna ####
pause-cron-reactive:
	# Pause the CronReactive contract on Lasna
	forge script script/CronAction.s.sol:CronActionPause \
		--rpc-url $(LASNA_RPC) \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv

unpause-cron-reactive:
	# Unpause the CronReactive contract on Lasna
	forge script script/CronAction.s.sol:CronActionUnpause \
		--rpc-url $(LASNA_RPC) \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv
