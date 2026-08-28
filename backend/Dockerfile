# syntax=docker/dockerfile:1
FROM node:20-alpine AS base

# Install netcat and postgresql-client for health check in entrypoint
RUN apk add --no-cache netcat-openbsd postgresql-client

WORKDIR /app

# Install dependencies
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

# Generate Prisma Client
RUN npx prisma generate

# Copy source code and config
COPY tsconfig.json ./
COPY src ./src/
COPY docker-entrypoint.sh ./

RUN chmod +x docker-entrypoint.sh

# Build TypeScript to dist
RUN npm run build || true

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["npm", "start"]
