.PHONY: dev stop restart-backend restart-frontend connect-backend sync-contracts

dev:
	@./scripts/check-workspace.sh
	@./scripts/prepare-dev.sh
	overmind start -f Procfile.dev -N

stop:
	@./scripts/prepare-dev.sh

restart-backend:
	overmind restart backend

restart-frontend:
	overmind restart frontend

connect-backend:
	overmind connect backend

# Copy API contract JSON from backend to frontend (run after editing mails-backend/contracts/)
sync-contracts:
	cp mails-backend/contracts/user.json mails-frontend/contracts/user.json
