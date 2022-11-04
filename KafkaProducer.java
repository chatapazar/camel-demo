// camel-k: language=java dependency=mvn:org.apache.camel.quarkus:camel-quarkus-kafka

import org.apache.camel.builder.RouteBuilder;

public class KafkaProducer extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        log.info("About to start route: Timer -> Kafka ");

        from("timer:foo")
            .routeId("FromTimer2Kafka")
            .setBody()
                .simple("Message #${exchangeProperty.CamelTimerCounter}")
            .to("kafka:{{producer.topic}}")
            .log("Message correctly sent to the topic!");
    }
}