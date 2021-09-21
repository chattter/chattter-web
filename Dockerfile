FROM node:14.15.5-alpine3.13 AS build

WORKDIR /app

# install git
RUN apk add git

# use yarn to upgrade npm
RUN yarn global add npm@7

COPY ./package.json .
COPY ./package-lock.json .

# install frontend dependencies before copying the frontend code
# into the container so we get docker cache benefits
RUN npm install

# running ngcc before build_prod lets us utilize the docker
# cache and significantly speeds up builds without requiring us
# to import/export the node_modules folder from the container
RUN npm run ngcc

COPY ./angular.json .
COPY ./tsconfig.json .
COPY ./tsconfig.app.json .
COPY ./src ./src

RUN npm run build

# build minified version of frontend, served using caddy
FROM caddy:alpine

WORKDIR /app

COPY ./Caddyfile .
COPY --from=build /app/dist .

ARG git_shasum
ENV GIT_SHASUM=$git_shasum

# Default options overrideable by docker-compose
ENV CADDY_FILE "/app/Caddyfile"

ENTRYPOINT ["caddy", "run"]