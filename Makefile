CURRENT_DIR := $(shell pwd)

# Use venv ansible-playbook if the venv exists, otherwise fall back to system
ANSIBLE := $(shell [ -f $(CURRENT_DIR)/.venv/bin/ansible-playbook ] && echo $(CURRENT_DIR)/.venv/bin/ansible-playbook || echo ansible-playbook)

.PHONY: help
help: ## Display help message
	@grep -E '^[0-9a-zA-Z_-]+\.*[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Create Python venv and install all dependencies
	python3 -m venv $(CURRENT_DIR)/.venv
	$(CURRENT_DIR)/.venv/bin/pip install --upgrade pip
	$(CURRENT_DIR)/.venv/bin/pip install -r requirements.txt
	$(CURRENT_DIR)/.venv/bin/ansible-galaxy collection install -r requirements.yml

.PHONY: start
start: ## Deploy ceos lab
	sudo containerlab deploy --debug --topo $(CURRENT_DIR)/topology.clab.yml --max-workers 10 --timeout 5m --reconfigure

.PHONY: stop
stop: ## Destroy ceos lab
	sudo containerlab destroy --debug --topo $(CURRENT_DIR)/topology.clab.yml --cleanup

.PHONY: inspect
inspect: ## Inspect ceos lab
	@sudo containerlab inspect --topo $(CURRENT_DIR)/topology.clab.yml
	@echo ""
	@echo "You can check the lab status, hostnames and management addresses above."
	@echo "To connect to a lab device use \`ssh admin@<hostname>\` and password \`admin\`."

.PHONY: build
build: ## Build Configs
	$(ANSIBLE) avd/playbooks/build.yml -i avd/inventory.yml -e "target_hosts=CAMPUS_FABRIC"

.PHONY: deploy
deploy: ## Deploy Configs via eAPI
	$(ANSIBLE) avd/playbooks/deploy.yml -i avd/inventory.yml -e "target_hosts=CAMPUS_FABRIC"

.PHONY: validate
validate: ## Validate Fabric
	$(ANSIBLE) avd/playbooks/validate.yml -i avd/inventory.yml -e "target_hosts=CAMPUS_FABRIC"
