FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm@10.33.2

# Copy dependency metadata before installing so Docker can cache dependencies.
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy app code
COPY . .

EXPOSE 3000

CMD ["pnpm", "run", "dev"]
