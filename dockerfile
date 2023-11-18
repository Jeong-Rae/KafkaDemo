FROM ubuntu

# java jdk 11 설치
RUN apt-get update && \
	apt-get install -y openjdk-11-jdk && \
	apt-get clean

# kafka home 경로 설정
ENV KAFKA_HOME=/usr/local/kafka
# 플러그인 경로 설정
ENV PLUGINS_DIR=/usr/local/share/kafka/plugins 

COPY ./kafka ${KAFKA_HOME}

COPY confluentinc-kafka-connect-mqtt.tar.gz ${KAFKA_HOME}

# Kafka Connect Mqtt 플러그인 설치
RUN mkdir -p ${PLUGINS_DIR} && \
	tar -zxvf ${KAFKA_HOME}/confluentinc-kafka-connect-mqtt.tar.gz -C ${KAFKA_HOME}&&\
	mv ${KAFKA_HOME}/confluentinc-kafka-connect-mqtt ${PLUGINS_DIR}/confluentinc-kafka-connect-mqtt


# kafka kraft 모드로 실행
CMD  ${KAFKA_HOME}/run-kraft-broker.sh