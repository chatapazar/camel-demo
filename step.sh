install operator amq-streams
install operator camel k

oc new-project amq-streams-camel

deploy obsidiandynamics/kafdrop
set KAFKA_BROKERCONNECT=my-cluster-kafka-bootstrap:9092
port 9000:9000

oc apply -f kafka.yaml
oc apply -f topic.yaml --> create 1 partition for easy describe
oc project amq-streams-camel
oc rsh my-cluster-kafka-0 
cd bin
./kafka-topics.sh --bootstrap-server localhost:9092 --list

#new terminal
oc run kafka-producer -ti \
--image=registry.redhat.io/amq7/amq-streams-kafka-32-rhel8:2.2.0 \
--rm=true \
--restart=Never \
-- bin/kafka-console-producer.sh \
--bootstrap-server my-cluster-kafka-bootstrap:9092 \
--topic my-topic

#for streams 2.3
oc run kafka-producer -ti \
--image=registry.redhat.io/amq7/amq-streams-kafka-33-rhel8:2.3.0 \
--rm=true \
--restart=Never \
-- bin/kafka-console-producer.sh \
--bootstrap-server cluster-name-kafka-bootstrap:9092 \
--topic my-topic

send data a,b,c and exit

oc run kafka-consumer -ti \
--image=registry.redhat.io/amq7/amq-streams-kafka-32-rhel8:2.2.0 \
--rm=true \
--restart=Never \
-- bin/kafka-console-consumer.sh \
--bootstrap-server my-cluster-kafka-bootstrap:9092 \
--topic my-topic \
--from-beginning \
--consumer-property group.id=exim

#for streams 2.3
oc run kafka-consumer -ti \
--image=registry.redhat.io/amq7/amq-streams-kafka-33-rhel8:2.3.0 \
--rm=true \
--restart=Never \
-- bin/kafka-console-consumer.sh \
--bootstrap-server cluster-name-kafka-bootstrap:9092 \
--topic my-topic --from-beginning

#run in oc rsh terminal
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group exim

#exit kafka-consumer and run again without --from-begining
#run in oc rsh terminal with
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --partition 0 --offset 1 --max-messages 1

#camel k
oc create secret generic kafka-props --from-file application.properties
kamel run --config secret:kafka-props KafkaConsumer.java --dev
kamel run --config secret:kafka-props KafkaProducer.java --dev
