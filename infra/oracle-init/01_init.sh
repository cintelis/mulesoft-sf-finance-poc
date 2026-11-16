#!/bin/bash
# Runs once when the Oracle data volume is first initialised.
# Applies the schema and seed data as the application user (not SYS).
set -e
cd /db
for f in schema.sql seed.sql; do
  echo "Applying $f as ${APP_USER}"
  sqlplus -s -L "${APP_USER}/${APP_USER_PASSWORD}@//localhost:1521/FREEPDB1" <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE
@$f
EXIT
EOF
done
