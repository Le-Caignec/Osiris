-include .env


#
# Test and utility targets
#

fork-sepolia:
	anvil --fork-url $(SEPOLIA_RPC_URL) --port 8545

fork-arbitrum-sepolia:
	anvil --fork-url $(ARBITRUM_SEPOLIA_RPC_URL) --port 8546

deploy:
	@echo "Deploying contracts..."
	$(MAKE) deploy-source RPC_URL=$(ORIGIN_RPC)
	$(MAKE) deploy-destination RPC_URL=$(DESTINATION_RPC)

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
