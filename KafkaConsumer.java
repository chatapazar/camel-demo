// camel-k: language=java dependency=mvn:org.apache.camel.quarkus:camel-quarkus-kafka

import org.apache.camel.builder.RouteBuilder;

public class KafkaConsumer extends RouteBuilder {
    @Override
    public void configure() throws Exception {
        log.info("About to start route: Kafka -> Log ");

        from("kafka:{{consumer.topic}}")
            .routeId("FromKafka2Log")
            .log("${body}");
    }
}