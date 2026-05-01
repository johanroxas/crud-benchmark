FROM node:20-alpine

WORKDIR /app

# Install build tools needed for native modules like sqlite3
RUN apk add --no-cache python3 make g++

# Install pnpm
RUN npm install -g pnpm@10.33.2

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies (including dev dependencies)
RUN pnpm install --frozen-lockfile

# Copy app code
COPY . .

EXPOSE 3000

CMD ["pnpm", "run", "dev"]
