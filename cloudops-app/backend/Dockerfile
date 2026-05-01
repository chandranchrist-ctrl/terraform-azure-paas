FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]


# az acr login --name uatbookshopacr01.azurecr.io
# docker build -t uatbookshopacr01.azurecr.io/backend:v1 ./backend
# docker push uatbookshopacr01.azurecr.io/backend:v1