# Build stage only
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Use scratch to just export the dist folder
FROM scratch
COPY --from=build /app/dist /dist