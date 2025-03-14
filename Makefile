default:

test:
	HELMYS_HOOKS=list-merge-hook.ys \
	VALUES_FILE=merge-env.yaml \
	helm template cronjob --post-renderer=helmys
