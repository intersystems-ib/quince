ARG IMAGE=containers.intersystems.com/intersystems/iris-community:latest-preview
FROM ${IMAGE}
USER root
RUN mkdir -p /iris-shared && chown irisowner:irisowner /iris-shared
USER irisowner
WORKDIR /opt/rugby
COPY --chown=irisowner:irisowner iris/ /opt/rugby/
ENV ISC_CPF_MERGE_FILE=/opt/rugby/iris.cpf
RUN iris start IRIS && iris session IRIS < /opt/rugby/build.script && test -d /opt/rugby/compiled && iris stop IRIS quietly
