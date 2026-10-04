FROM trinodb/trino:455

USER root
COPY trino/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER trino

ENTRYPOINT ["/entrypoint.sh"]
