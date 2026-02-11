FROM quay.io/jooholee/model-seaweedfs:intrim AS runtime

FROM chrislusf/seaweedfs:latest

USER root

# Copy data from runtime image
RUN mkdir -p /data1 && chmod 777 /data1
COPY --from=runtime /data1/ /data1/

COPY ./hacks/start.sh /usr/bin/start.sh

RUN chmod +x /usr/bin/start.sh

EXPOSE 8333 9333 8888 9340 23646

# Switch to the new user
USER 1000
ENTRYPOINT ["/usr/bin/start.sh"]
