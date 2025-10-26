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
	# Deploy Reactive Contract - Uses local account for testnet, Ledger for mainnet
	@echo "Reading configuration..."
	@if [ "$(CHAIN)" = "ethereum" ] || [ "$(CHAIN)" = "arbitrum" ]; then \
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
	read -p "Enter value to send (in REACT, e.g., 0.1, 15): " VALUE; \
	if [ -z "$$VALUE" ]; then \
		VALUE="0.1"; \
		echo "No value provided, using default: 0.1 REACT"; \
	fi; \
	echo "Deploying with $$VALUE REACT..."; \
	if [ "$(CHAIN)" = "ethereum" ] || [ "$(CHAIN)" = "arbitrum" ]; then \
		LEDGER_IDX=$(if $(LEDGER_INDEX),$(LEDGER_INDEX),0); \
		echo "Using Ledger account index: $$LEDGER_IDX (set LEDGER_INDEX in .env to change)"; \
		forge create --broadcast \
			--rpc-url $$REACTIVE_RPC_URL \
			--chain-id $$REACTIVE_CHAIN_ID \
			--ledger \
			--mnemonic-index $$LEDGER_IDX \
			--value $${VALUE}ether \
			src/CronReactive.sol:CronReactive \
			--constructor-args $$REACTIVE_SYSTEM $$CRON_TOPIC $$DESTINATION_CHAIN_ID $$CALLBACK_CONTRACT; \
	else \
		echo "Using local keystore account: $(ACCOUNT)"; \
		forge create --broadcast \
			--rpc-url $$REACTIVE_RPC_URL \
			--chain-id $$REACTIVE_CHAIN_ID \
			--account $(ACCOUNT) \
			--value $${VALUE}ether \
			src/CronReactive.sol:CronReactive \
			--constructor-args $$REACTIVE_SYSTEM $$CRON_TOPIC $$DESTINATION_CHAIN_ID $$CALLBACK_CONTRACT; \
	fi

deploy-osiris:
	# Deploy Osiris - Uses local account for Sepolia, Ledger for mainnet chains
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
		LEDGER_IDX=$(if $(LEDGER_INDEX),$(LEDGER_INDEX),0); \
		echo "Using Ledger account index: $$LEDGER_IDX (set LEDGER_INDEX in .env to change)"; \
		SENDER_ADDR=$$(cast wallet address --ledger --mnemonic-index $$LEDGER_IDX); \
		echo "Ledger address: $$SENDER_ADDR"; \
		forge script script/Deploy.s.sol:DeployOsiris \
			--rpc-url $$RPC_URL \
			--ledger \
			--mnemonic-indexes $$LEDGER_IDX \
			--sender $$SENDER_ADDR \
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

fund-callback-proxy:
	# Send funds to the callback proxy contract
	@RPC_URL=$$(jq -r '.chains.$(CHAIN).rpcUrl' config/config.json); \
	CALLBACK_PROXY=$$(jq -r '.chains.$(CHAIN).callbackProxyContract' config/config.json); \
	CALLBACK_CONTRACT=$$(jq -r '.chains.$(CHAIN).callbackContract' config/config.json); \
	echo "==========================================="; \
	echo "Funding Callback Proxy on $(CHAIN)"; \
	echo "==========================================="; \
	echo "Network: $(CHAIN)"; \
	echo "RPC URL: $$RPC_URL"; \
	echo "Callback Proxy: $$CALLBACK_PROXY"; \
	echo "Callback Contract: $$CALLBACK_CONTRACT"; \
	echo ""; \
	read -p "Enter amount to send (in ETH, e.g., 0.1): " AMOUNT; \
	if [ -z "$$AMOUNT" ]; then \
		echo "Error: Amount cannot be empty"; \
		exit 1; \
	fi; \
	echo ""; \
	echo "Sending $${AMOUNT} ETH to callback proxy..."; \
	if [ "$(CHAIN)" = "sepolia" ]; then \
		echo "Using local keystore account: $(ACCOUNT)"; \
		cast send $$CALLBACK_PROXY \
			"depositTo(address)" $$CALLBACK_CONTRACT \
			--rpc-url $$RPC_URL \
			--account $(ACCOUNT) \
			--value $${AMOUNT}ether; \
	else \
		LEDGER_IDX=$(if $(LEDGER_INDEX),$(LEDGER_INDEX),0); \
		echo "Using Ledger account index: $$LEDGER_IDX"; \
		cast send $$CALLBACK_PROXY \
			"depositTo(address)" $$CALLBACK_CONTRACT \
			--rpc-url $$RPC_URL \
			--ledger \
			--mnemonic-index $$LEDGER_IDX \
			--value $${AMOUNT}ether; \
	fi; \
	echo "✅ Funds sent successfully!"

check-callback-balance:
	# Check the reserves balance in the callback proxy
	@RPC_URL=$$(jq -r '.chains.$(CHAIN).rpcUrl' config/config.json); \
	CALLBACK_PROXY=$$(jq -r '.chains.$(CHAIN).callbackProxyContract' config/config.json); \
	CALLBACK_CONTRACT=$$(jq -r '.chains.$(CHAIN).callbackContract' config/config.json); \
	echo "==========================================="; \
	echo "Checking Callback Balance on $(CHAIN)"; \
	echo "==========================================="; \
	echo "Network: $(CHAIN)"; \
	echo "Callback Proxy: $$CALLBACK_PROXY"; \
	echo "Callback Contract: $$CALLBACK_CONTRACT"; \
	echo ""; \
	BALANCE_WEI=$$(cast call $$CALLBACK_PROXY "reserves(address)" $$CALLBACK_CONTRACT --rpc-url $$RPC_URL | cast to-dec); \
	BALANCE_ETH=$$(cast to-unit $$BALANCE_WEI ether); \
	echo "💰 Balance: $$BALANCE_ETH ETH"

check-callback-debts:
	# Check the debts balance in the callback proxy
	@RPC_URL=$$(jq -r '.chains.$(CHAIN).rpcUrl' config/config.json); \
	CALLBACK_PROXY=$$(jq -r '.chains.$(CHAIN).callbackProxyContract' config/config.json); \
	CALLBACK_CONTRACT=$$(jq -r '.chains.$(CHAIN).callbackContract' config/config.json); \
	echo "==========================================="; \
	echo "Checking Callback Debts on $(CHAIN)"; \
	echo "==========================================="; \
	echo "Network: $(CHAIN)"; \
	echo "Callback Proxy: $$CALLBACK_PROXY"; \
	echo "Callback Contract: $$CALLBACK_CONTRACT"; \
	echo ""; \
	DEBTS_WEI=$$(cast call $$CALLBACK_PROXY "debts(address)" $$CALLBACK_CONTRACT --rpc-url $$RPC_URL | cast to-dec); \
	DEBTS_ETH=$$(cast to-unit $$DEBTS_WEI ether); \
	echo "💸 Debts: $$DEBTS_ETH ETH"
