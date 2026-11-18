#!/bin/sh
set -eu
# release.py ของ playbook ส่ง connection string ของ migrator ผ่านตัวแปร
# ConnectionStrings__Postgres (contract เดิม) — Prisma อ่าน DATABASE_URL
# map ชื่อตรงนี้จุดเดียว ไม่แก้ helper ของ playbook
# ถ้า RDS บังคับ TLS verify ให้ใส่ sslrootcert=/app/certs/rds-ap-southeast-7-bundle.pem
# ใน connection string ของ APP_MIGRATOR_POSTGRES_CONNECTION
export DATABASE_URL="${ConnectionStrings__Postgres:?APP_MIGRATOR_POSTGRES_CONNECTION is required}"
exec ./node_modules/.bin/prisma migrate deploy
