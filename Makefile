# .PHONY moodle
include .env
export

moodle:
	@docker run -t --name moodle -p 80:8080 -p 443:8443 \
	  --env MOODLE_DATABASE_TYPE=pgsql \
	  --env MOODLE_DATABASE_HOST=34.30.205.27 \
	  --env MOODLE_DATABASE_PORT_NUMBER=5432 \
	  --env MOODLE_DATABASE_NAME=postgres \
	  --env MOODLE_DATABASE_USER=postgres \
	  --env MOODLE_DATABASE_PASSWORD=12345678 \
	  bitnami/moodle:latest


# ./cloud_sql_proxy -credential_file ./service-account.json
#
# -instances="${{ secrets.GCP_PROJECT_ID }}:${{ secrets.GCP_REGION }}:${{ secrets.GCP_DB_INSTANCE }}=tcp:${{ secrets.DB_PORT }}"
#
