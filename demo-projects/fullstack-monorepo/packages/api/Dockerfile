FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY src/ ./src/
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 4000
ENV PORT=4000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:4000/api/health || exit 1
CMD ["node", "src/index.js"]
