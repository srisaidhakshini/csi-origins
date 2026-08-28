#!/bin/sh
set -e

echo "⏳ Waiting for database to be ready..."
until nc -z -v -w30 postgres 5432 2>/dev/null || pg_isready -h postgres -p 5432 -U postgres 2>/dev/null; do
  echo "Waiting for postgres..."
  sleep 2
done

echo "📦 Pushing Prisma schema to PostgreSQL..."
npx prisma db push --accept-data-loss

echo "🌱 Seeding database..."
npx ts-node prisma/seed.ts || true

echo "🚀 Starting backend application..."
exec "$@"
