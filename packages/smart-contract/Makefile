-include .env

########################################################
# Makefile for ReactiveDCA Smart Contracts
########################################################

# Testing Commands
fork-sepolia:
	@RPC_URL=$$(jq -r '.chains.$(CHAIN).rpcUrl' config/config.json); \
	echo "Forking $(CHAIN) with RPC: $$RPC_URL"; \
	anvil --fork-url $$RPC_URL --port 8545

test-unit:
	# Run units tests with gas reporting
	forge test -vvv --gas-report --match-path "./test/units/**"

# Deployment Commands
deploy-reactive:
	# Deploy Reactive Contract - Uses lasna for sepolia, reactive mainnet for ethereum
	@echo "Reading configuration..."
	@if [ "$(CHAIN)" = "ethereum" ]; then \
		REACTIVE_NETWORK="reactive"; \
	else \
		REACTIVE_NETWORK="lasna"; \
	fi; \
	CRON_TOPIC=$$(jq -r ".chains.$$REACTIVE_NETWORK.cronTopic" config/config.json); \
	CALLBACK_CONTRACT=$$(jq -r '.chains.$(CHAIN).callbackContract' config/config.json); \
	REACTIVE_SYSTEM=$$(jq -r ".chains.$$REACTIVE_NETWORK.reactiveSystemContract" config/config.json); \
	DESTINATION_CHAIN_ID=$$(jq -r '.chains.$(CHAIN).chainId' config/config.json); \
	REACTIVE_CHAIN_ID=$$(jq -r ".chains.$$REACTIVE_NETWORK.chainId" config/config.json); \
	REACTIVE_RPC_URL=$$(jq -r ".chains.$$REACTIVE_NETWORK.rpcUrl" config/config.json); \
	echo "Deploying CronReactive to $$REACTIVE_NETWORK network with:"; \
	echo "  - Reactive Network: $$REACTIVE_NETWORK"; \
	echo "  - Reactive Chain ID: $$REACTIVE_CHAIN_ID"; \
	echo "  - Reactive RPC URL: $$REACTIVE_RPC_URL"; \
	echo "  - Reactive System: $$REACTIVE_SYSTEM"; \
	echo "  - Cron Topic: $$CRON_TOPIC"; \
	echo "  - Destination Chain ($(CHAIN)) ID: $$DESTINATION_CHAIN_ID"; \
	echo "  - Callback Contract: $$CALLBACK_CONTRACT"; \
	echo ""; \
	read -p "Enter value to send (in ether, e.g., 0.1, 15): " VALUE; \
	if [ -z "$$VALUE" ]; then \
		VALUE="0.1"; \
		echo "No value provided, using default: 0.1 ether"; \
	fi; \
	echo "Deploying with $$VALUE ether..."; \
	forge create --broadcast \
		--rpc-url $$REACTIVE_RPC_URL \
		--chain-id $$REACTIVE_CHAIN_ID \
		--account $(ACCOUNT) \
		--value $${VALUE}ether \
		src/CronReactive.sol:CronReactive \
		--constructor-args $$REACTIVE_SYSTEM $$CRON_TOPIC $$DESTINATION_CHAIN_ID $$CALLBACK_CONTRACT

deploy-osiris:
	# Deploy Osiris - Uses local account for Sepolia, Ledger for other chains
	@RPC_URL=$$(jq -r '.chains.$(CHAIN).rpcUrl' config/config.json); \
	echo "Deploying Osiris to $(CHAIN) with RPC: $$RPC_URL"; \
	if [ "$(CHAIN)" = "sepolia" ]; then \
		echo "Using local keystore account: $(ACCOUNT)"; \
		forge script script/Deploy.s.sol:DeployOsiris \
			--rpc-url $$RPC_URL \
			--account $(ACCOUNT) \
			--broadcast \
			--verify \
			--verifier etherscan \
			--verifier-api-key $(ETHERSCAN_API_KEY) \
			-vvv; \
	else \
		echo "Please connect your Ledger and unlock it..."; \
		echo "Make sure the Ethereum app is open on your Ledger"; \
		echo "Using Ledger address: $(LEDGER_ADDRESS)"; \
		forge script script/Deploy.s.sol:DeployOsiris \
			--rpc-url $$RPC_URL \
			--ledger \
			--sender $(LEDGER_ADDRESS) \
			--broadcast \
			--verify \
			--verifier etherscan \
			--verifier-api-key $(ETHERSCAN_API_KEY) \
			-vvv; \
	fi

# Cron Management Commands
pause-cron-reactive:
	# Pause the CronReactive contract on reactive network
	@if [ "$(CHAIN)" = "ethereum" ]; then \
		REACTIVE_NETWORK="reactive"; \
	else \
		REACTIVE_NETWORK="lasna"; \
	fi; \
	REACTIVE_RPC_URL=$$(jq -r ".chains.$$REACTIVE_NETWORK.rpcUrl" config/config.json); \
	echo "Pausing CronReactive on $$REACTIVE_NETWORK network"; \
	forge script script/CronAction.s.sol:CronActionPause \
		--rpc-url $$REACTIVE_RPC_URL \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv

unpause-cron-reactive:
	# Unpause the CronReactive contract on reactive network
	@if [ "$(CHAIN)" = "ethereum" ]; then \
		REACTIVE_NETWORK="reactive"; \
	else \
		REACTIVE_NETWORK="lasna"; \
	fi; \
	REACTIVE_RPC_URL=$$(jq -r ".chains.$$REACTIVE_NETWORK.rpcUrl" config/config.json); \
	echo "Unpausing CronReactive on $$REACTIVE_NETWORK network"; \
	forge script script/CronAction.s.sol:CronActionUnpause \
		--rpc-url $$REACTIVE_RPC_URL \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv

# Osiris Management Commands
trigger-osiris-callback:
	# Trigger the Osiris callback on Sepolia/Ethereum
	@RPC_URL=$$(jq -r '.chains.$(CHAIN).rpcUrl' config/config.json); \
	echo "Triggering Osiris callback on $(CHAIN) with RPC: $$RPC_URL"; \
	forge script script/OsirisAction.s.sol:TriggerOsirisCallback \
		--rpc-url $$RPC_URL \
		--account $(ACCOUNT) \
		--broadcast \
		-vvv
