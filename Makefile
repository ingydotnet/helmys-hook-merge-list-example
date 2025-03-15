default:

test: test-1 test-2 test-3

test-1:
	@echo
	HELMYS_HOOKS=list-merge-hook.ys \
	VALUES_FILE=merge-env.yaml \
	helm template cronjob --post-renderer=helmys

test-2:
	@echo
	HELMYS_HOOKS=https://raw.githubusercontent.com/ingydotnet/helmys-hook-merge-list-example/refs/heads/main/list-merge-hook.ys \
	VALUES_FILE=merge-env.yaml \
	helmys template cronjob

test-3:
	@echo
	VALUES_FILE=merge-env.yaml \
	helm template cronjob --post-renderer=./my-post-renderer
