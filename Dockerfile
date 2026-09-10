```dockerfile
###################################################
# Stage: base
#
# This base stage ensures all other stages are using
# the same base image and provides common configuration.
###################################################
FROM node:20 AS base

WORKDIR /usr/local/app


################## CLIENT STAGES ##################

###################################################
# Stage: client-base
#
# Common base for client development and production build.
###################################################
FROM base AS client-base

COPY client/package.json client/yarn.lock ./

# Clean Yarn cache to avoid corrupted cached packages
RUN yarn cache clean && yarn install

COPY client/.eslintrc.cjs client/index.html client/vite.config.js ./
COPY client/public ./public
COPY client/src ./src


###################################################
# Stage: client-dev
#
# Development stage for the Vite client.
###################################################
FROM client-base AS client-dev

CMD ["yarn", "dev"]


###################################################
# Stage: client-build
#
# Builds the production client application.
###################################################
FROM client-base AS client-build

RUN yarn build


################  BACKEND STAGES #################

###################################################
# Stage: backend-dev
#
# Development stage for the backend.
###################################################
FROM base AS backend-dev

COPY backend/package.json backend/yarn.lock ./

# No BuildKit Yarn cache to avoid corrupted CI cache
RUN yarn install --frozen-lockfile

COPY backend/spec ./spec
COPY backend/src ./src

CMD ["yarn", "dev"]


###################################################
# Stage: test
#
# Runs backend tests.
###################################################
FROM backend-dev AS test

RUN yarn test


###################################################
# Stage: final
#
# Production image.
###################################################
FROM base AS final

ENV NODE_ENV=production

COPY --from=test /usr/local/app/package.json /usr/local/app/yarn.lock ./

# Production dependencies only
RUN yarn install --production --frozen-lockfile

COPY backend/src ./src

COPY --from=client-build /usr/local/app/dist ./src/static

EXPOSE 3000

CMD ["node", "src/index.js"]
```
