FROM alpine:3.6

RUN apk add --no-cache bash git openssh-client
RUN apk add --no-cache py-pip
RUN pip install awscli --upgrade

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
