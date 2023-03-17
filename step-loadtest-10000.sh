https://developers.redhat.com/blog/2021/04/19/connect-amq-streams-to-your-red-hat-openshift-4-monitoring-stack#install_amq_streams_and_grafana

oc new-project streams-kafka-cluster
oc delete limitranges --all -n streams-kafka-cluster
oc apply -f loadtest-kafka-metrics.yaml -n streams-kafka-cluster
oc get pod -n streams-kafka-cluster
#show entity-operator, kafka, zookeeper, kafka-exporter

oc new-project streams-grafana
#deploy operator grafana at streams-grafana
oc delete limitranges --all -n streams-grafana
oc apply -f operator-group.yml -n streams-grafana
oc apply -f grafana-subscription.yml -n streams-grafana
oc get pods -n streams-grafana
# create application workload monitoring configmap
oc apply -f enable-user-workload.yml
oc get po -n openshift-user-workload-monitoring
cat strimzi-pod-monitor.yaml | sed "s#myproject#streams-kafka-cluster#g" | oc apply -n streams-kafka-cluster -f -
#check metrics strimzi_resources in project streams-kafka-cluster 
oc apply -f create-grafana.yml
#4.11
export TOKEN=$(oc serviceaccounts get-token grafana-serviceaccount -n streams-grafana)
#4.12
export TOKEN=$(oc create token --duration=999h -n streams-grafana grafana-serviceaccount)

cat << EOF | oc apply -f -
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDataSource
metadata:
  name: grafanadatasource
  namespace: streams-grafana
spec:
  name: middleware.yaml
  datasources:
    - name: Prometheus
      type: prometheus
      access: proxy
      url: https://thanos-querier.openshift-monitoring.svc.cluster.local:9091
      basicAuth: false
      basicAuthUser: internal
      isDefault: true
      version: 1
      editable: true
      jsonData:
        tlsSkipVerify: true
        timeInterval: "5s"
        httpHeaderName1: "Authorization"
      secureJsonData:
        httpHeaderValue1: "Bearer $TOKEN"
EOF

open grafana in streams-grafana
user: admin/admin
test datasources
import dashboard (kafka, zookeeper, exporter) from strimzi-kafka-operator download folder


oc apply -f loadtest-topic.yml -n streams-kafka-cluster
oc apply -f load-job.yml -n streams-kafka-cluster
