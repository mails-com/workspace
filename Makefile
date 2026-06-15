.PHONY: dev stop restart-backend restart-frontend connect-backend

dev:
	@./scripts/check-workspace.sh
	overmind start -f Procfile.dev -N

stop:
	overmind quit

restart-backend:
	overmind restart backend

restart-frontend:
	overmind restart frontend

connect-backend:
	overmind connect backend
