FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY app.js ./

EXPOSE 8080

USER node

CMD ["node", "app.js"]
