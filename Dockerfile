FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@10.33.2

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies (including dev dependencies)
RUN pnpm install

# Copy app code
COPY . .

EXPOSE 3000

CMD ["pnpm", "run", "dev"]
