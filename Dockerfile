FROM node:alpine

################
# These variables are here as a list of what variables are used/checked
# Please modify them using `-e "env=value"` and NOT by modifying this file
################
# The image will not work without these set
ENV NS_HOST="https://mynightscout.azurewebsites.net"
ENV START_DATE="YYYY-MM-DD"

# Optional: Extra preferences to pass along when running `oref0-autotune`
# Example: -e "AUTOTUNE_PREFS=--end-date=2018-06-15" 
ENV AUTOTUNE_PREFS=""

# Optional, only necessary if your NS is set to disallow anonymous read access
ENV API_SECRET=""

# Timezone: should be set to the same value as your Nightscout instance
ENV TZ=UTC

################

RUN apk update && apk add bash bc coreutils curl git jq tzdata python3 py3-requests && \
      mkdir -p /openaps/settings /openaps/autotune && \
      cp /usr/share/zoneinfo/$TZ /etc/localtime && \
      chown -Rh node:node /openaps/ /etc/localtime
COPY ./oref0 /oref0
WORKDIR /oref0
RUN npm install -g

COPY entrypoint.sh /entrypoint.sh
USER node
CMD ["/entrypoint.sh"]
