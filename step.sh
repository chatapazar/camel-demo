oc new-project amq-streams
oc apply -f kafka.yaml
oc apply -f topic.yaml --> create 1 partition for easy describe
oc rsh my-cluster-kafka-0 -n amq-streams
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

#run in oc rsh terminal
./kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group exim

#exit kafka-consumer and run again without --from-begining
#run in oc rsh terminal with
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic my-topic --partition 0 --offset 1 --max-messages 1

#camel k
oc create secret generic kafka-props --from-file application.properties
kamel run --config secret:kafka-props KafkaProducer.java --dev
kamel run --config secret:kafka-props KafkaConsumer.java --dev