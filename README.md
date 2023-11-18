# 카프카 운영방법

## 카프카 설치

### 카프카 설치 경로

```shell
$KAFKA_HOME=usr/local/kafka
```

### kafka mqtt 커넥터 플로그인 설치 경로

```shell
usr/local/share/kafka/plugins
```

### 사용한 kafka mqtt 플러그인 [confluentinc-kafka-connect-mqtt](https://www.confluent.io/hub/confluentinc/kafka-connect-mqtt)

```shell
# 위 경로에서 zip 설치
unzip confluentinc-kafka-connect-mqtt-1.7.1.zip

# jar이 들어있는 lib를 plugins 폴더안에 복사
cp -r confluentinc-kafka-connect-mqtt-1.7.1/lib  usr/local/share/kafka/plugins
```

## 카프카 설정

### kraft 모드로 kafka 운영

```shell
# server 설정파일 적절하게 수정
vim $KAFKA_HOME/config/kraft/server.properties
```

kraft 모드로 kafka를 실행할 예정이므로 kraft 디렉토리 안에 있는 설정파일을 수정해야한다.

### 신경써야 하는 server.properties 설정들

```properties
# The connect string for the controller quorum
controller.quorum.voters=1@localhost:9093

listeners=PLAINTEXT://:9092,CONTROLLER://:9093
advertised.listeners=PLAINTEXT://localhost:9092

# default replication factor count
# kafka broker를 1개만 사용할 경우 설정
default.replication.factor=1

# A comma separated list of directories under which to store log files
log.dirs=/usr/local/kafka/kraft-combined-logs
```

### mqtt broker와 연결시 사용할 json 설정 파일

```json
{
    "name": "mqtt-connector",
    "config": {
        "connector.class": "io.confluent.connect.mqtt.MqttSourceConnector",
        "confluent.topic.replication.factor": "1",
        "tasks.max": "1",
        "mqtt.server.uri": "tcp://{mqtt.server.host}:1883",
        "mqtt.topics": "{mqtt.topic}",
        "kafka.topic": "{kafka.topic}",
        "key.converter": "org.apache.kafka.connect.storage.StringConverter",
        "value.converter": "org.apache.kafka.connect.json.JsonConverter",
        "value.converter.schemas.enable": "false",
        "confluent.topic.bootstrap.servers": "{kafka.server.host}:9092"
    }
}
```

-   `confluent.topic.replication.factor` : 현재 클러스터에서 운영중인 broker의 개수를 설정해주어야한다. 기본값은 3이다
-   `"mqtt.server.uri` : mqtt broker가 운영중인 호스트위치를 작성
-   `value.converter` : key는 topic을 말하며, value는 실질적인 message에 해당된다. json을 사용할 것이라면 `JsonConverter`, 문자열을 사용할 것이라면 `StringConverter`를 사용할 수 있다.
-   `value.converter.schemas.enable` : json 형식의 value가 전달될 때 connecter는 스키마를 같이 보낸다. 해당 옵션을 false로 변경하면 json 내용만 잘 전달 된다.
-   topic들과 host는 적절하게 잘 작성하면 된다.

## 카프카 실행

### kafka broker 실행

```shell
./bin/kafka-server-start.sh config/kraft/server.properties

# 백그라운드로 실행
nohup ./bin/kafka-server-start.sh config/kraft/server.properties > broker.log 2>&1 &
```

카프카 서버에서 추가적인 작업을 수행하여면 백그라운드로 서버를 실행해야한다.

### kafka connecter 실행

```shell
nohup ./bin/connect-distributed.sh config/connect-distributed.properties > connector.log 2>&1 &
```

커넥터도 백그라운드로 실행한다.

## 토픽 관리

### 토픽 생성

```shell
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic {kafka.topic} --partitions 1 --replication-factor {factor.count}
```

topic 명칭을 적절하게 선택한다. `--replication-factor`는 broker 개수에 맞춰 값을 설정한다.

### 토픽 제거

```shell
./bin/kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic {kafka.topic}
```

### 토픽 메시지 확인

```shell
./bin/kafka-console-consumer.sh --topic {kafka.topic} --bootstrap-server localhost:9092 --from-beginning
```

--from-beginning 은 모든 메시지를 조회한다. 없이 사용할 경우 도착하는 메시지만 확인된다.

## mqtt broker와 kafka connecter 연결

### kafka connecter 등록

```shell
curl -X POST -H "Content-Type: application/json" --data @/${KAFKA_HOME}/config/mqtt-connector.json http://localhost:8083/connectors
```

REST api를 사용하여 커넥터를 등록한다.  
이 시점에서 mqtt 브로커와 kafka가 연결된다.

### kafka connecter 해제

```shell
curl -X DELETE http://localhost:8083/connectors/mqtt-connector
```

connecter 연결을 해제시킨다.

## docker image

### jeongrae/coffee-kafka
