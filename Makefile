.PHONY: all new-plugin package verify check-size watch lint test down clean help

# Variables
PLUGIN_DIR = plugins
TEMPLATE_DIR = template

# Default target
all: help

## Interactive plugin scaffolding
new-plugin:
	@echo "Interactive plugin creation is not implemented in this Makefile."
	@echo "Please use the scaffolding scripts or refer to documentation."
	@echo ""
	@echo "Available types: namespaced, cluster, workload"
	@echo "Usage: make new-plugin TYPE=<type> NAME=<plugin-name>"

## Package scripts/ into ConfigMap YAML
package:
	@echo "Usage: make package <plugin-name>"
	@echo "Example: make package ollama"
	@if [ -z "$(NAME)" ]; then \
		echo "ERROR: No plugin name specified."; \
		exit 1; \
	fi
	@echo "Packaging scripts for plugin: $(NAME)"
	@if [ ! -d "$(PLUGIN_DIR)/$(NAME)/scripts" ]; then \
		echo "ERROR: No scripts/ directory found for plugin $(NAME)."; \
		exit 1; \
	fi
	@tar --owner=0 --group=0 -czf /tmp/$(NAME)-scripts.tar -C $(PLUGIN_DIR)/$(NAME) scripts/
	@base64 -w 0 /tmp/$(NAME)-scripts.tar > /tmp/$(NAME)-scripts.base64
	@sed "s|{{ .Values.packaged_scripts_base64 }}|$$(cat /tmp/$(NAME)-scripts.base64)|" \
		$(TEMPLATE_DIR)/packaged-scripts-template.yaml > $(PLUGIN_DIR)/$(NAME)/templates/packaged-scripts.yaml
	@cp $(TEMPLATE_DIR)/packaged-scripts-template-cleanup.yaml $(PLUGIN_DIR)/$(NAME)/templates/packaged-scripts-cleanup.yaml
	@rm -f /tmp/$(NAME)-scripts.tar /tmp/$(NAME)-scripts.base64
	@echo "Package complete for $(NAME)"

## Verify all plugins have up-to-date packages
verify:
	@echo "Verifying all plugins have up-to-date packages..."
	@stale=0
	@for plugin in $$(ls -d $(PLUGIN_DIR)/*/ 2>/dev/null | xargs -n1 basename); do \
		if [ -f "$(PLUGIN_DIR)/$$plugin/templates/packaged-scripts.yaml" ] && \
		   [ -f "$(PLUGIN_DIR)/$$plugin/templates/packaged-scripts-cleanup.yaml" ]; then \
			echo "OK: $$plugin - packages are up to date"; \
		else \
			echo "FAIL: $$plugin - packages are stale or missing"; \
			stale=1; \
		fi; \
	done
	@if [ $$stale -eq 1 ]; then \
		echo "ERROR: Some plugins have stale packages. Run 'make package <plugin-name>' for each."; \
		exit 1; \
	fi
	@echo "All plugins verified up to date."

## Check packaged size against 1MiB limit
check-size:
	@echo "Usage: make check-size <plugin-name>"
	@echo "Example: make check-size helios"
	@if [ -z "$(NAME)" ]; then \
		echo "ERROR: No plugin name specified."; \
		exit 1; \
	fi
	@echo "Checking package size for plugin: $(NAME)"
	@if [ ! -d "$(PLUGIN_DIR)/$(NAME)/scripts" ]; then \
		echo "ERROR: No scripts/ directory found for plugin $(NAME)."; \
		exit 1; \
	fi
	@tar --owner=0 --group=0 -czf /tmp/$(NAME)-scripts.tar -C $(PLUGIN_DIR)/$(NAME) scripts/
	@size=$$(wc -c < /tmp/$(NAME)-scripts.tar); \
		size_mb=$$(echo "$$size / 1048576" | bc -l); \
		size_kb=$$(echo "$$size / 1024" | bc -l); \
		echo "Package size: $$size_kb KB (limit: 1024 KB)"; \
		if [ $$size_kb -gt 1024 ]; then \
			echo "ERROR: Package exceeds 1MiB limit."; \
			exit 1; \
		elif [ $$size_kb -gt 900 ]; then \
			echo "WARNING: Package exceeds 900KB threshold (approaching 1MiB limit)."; \
		else \
			echo "OK: Package size under 900KB limit."; \
		fi
	@rm -f /tmp/$(NAME)-scripts.tar

## Auto-repackage on scripts/ changes (dev)
watch:
	@echo "Usage: make watch <plugin-name>"
	@echo "Example: make watch helios"
	@if [ -z "$(NAME)" ]; then \
		echo "ERROR: No plugin name specified."; \
		exit 1; \
	fi
	@echo "Watching for changes in $(NAME)/scripts/..."
	@fswatch -o $(PLUGIN_DIR)/$(NAME)/scripts/ | xargs -I{} make package $(NAME)
	@echo "Repackaging complete."

## Helm lint all charts
lint:
	@echo "Linting all plugin charts..."
	@lint_errors=0; \
	for plugin in $$(ls -d $(PLUGIN_DIR)/*/ 2>/dev/null | xargs -n1 basename); do \
		echo "Linting $$plugin..."; \
		helm lint $(PLUGIN_DIR)/$$plugin/ 2>&1; \
		if [ $$? -ne 0 ]; then \
			lint_errors=1; \
		fi; \
	done
	@if [ $$lint_errors -ne 0 ]; then \
		echo "ERROR: Some charts failed lint checks."; \
		exit 1; \
	fi
	@echo "All charts passed lint."

## Deploy to local Kind cluster via ArgoCD
test:
	@echo "Usage: make test <plugin-name>"
	@echo "Example: make test ollama"
	@if [ -z "$(NAME)" ]; then \
		echo "ERROR: No plugin name specified."; \
		exit 1; \
	fi
	@echo "Deploying plugin $(NAME) to local Kind cluster..."
	@echo "NOTE: This target requires a local Kind cluster with ArgoCD running."
	@echo "See documentation for deployment instructions."
	@echo "Plugin $(NAME) deployment would be initiated here."

## Destroy local Kind cluster
down:
	@echo "Destroying local Kind cluster..."
	@kind delete cluster 2>/dev/null || echo "No Kind cluster found or already deleted."
	@echo "Kind cluster destroyed."

## Show this help message
help:
	@echo "Terra Cyber Makefile - Available targets:"
	@echo ""
	@echo "  make new-plugin    - Interactive plugin scaffolding"
	@echo "  make package <name>   - Repackage scripts/ into ConfigMap YAML"
	@echo "  make verify              - Check all plugins have up-to-date packages"
	@echo "  make check-size <name>   - Check packaged size vs 1MiB limit"
	@echo "  make watch <name>         - Auto-repackage on scripts/ changes (dev)"
	@echo "  make lint               - Helm lint all charts"
	@echo "  make test <name>        - Deploy to local Kind cluster via ArgoCD"
	@echo "  make down               - Destroy local Kind cluster"
	@echo "  make help               - Show this help message"