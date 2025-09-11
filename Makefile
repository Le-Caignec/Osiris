-include .env


#
# Test and utility targets
#

fork-sepolia:
	anvil --fork-url $(SEPOLIA_RPC_URL) --port 8545

deploy-source:
	# Deploy to Sepolia (Origin Contract)
	forge script script/Deploy.s.sol:DeploySource \
	    --rpc-url $(RPC_URL) \
	    --account $(ACCOUNT) \
		--broadcast \
		-vvv

deploy-destination:
	# Deploy to Arbitrum Sepolia (Callback and Reactive Contracts)
	forge script script/Deploy.s.sol:DeployDestination \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv
