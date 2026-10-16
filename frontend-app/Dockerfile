# ============================================================================
# STAGE 1: HIGH-SCALE COMPILATION AND DEPENDENCIES RESOLUTION
# ============================================================================
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

# Cache dependencies layers cleanly
COPY backend-api/package*.json ./

RUN npm ci --only=production

# Copy application server logic rows
COPY backend-api/server.js ./

# ============================================================================
# STAGE 2: PRODUCTION RUNTIME ENVIRONMENT MINIFICATION
# ============================================================================
FROM node:18-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=80

# Bring over optimized dependencies and runtime files from Stage 1
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/server.js ./server.js
COPY --from=builder /usr/src/app/package.json ./package.json

# Run as a non-privileged secure user to prevent host-level exploit risks
USER node

EXPOSE 80

CMD ["npm", "start"]
