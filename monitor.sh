https://developers.redhat.com/blog/2021/04/19/connect-amq-streams-to-your-red-hat-openshift-4-monitoring-stack#install_amq_streams_and_grafana

oc new-project streams-kafka-cluster
cd strimzi-kafka-operator
oc apply -f examples/metrics/kafka-metrics.yaml -n streams-kafka-cluster
oc get pod -n streams-kafka-cluster
oc new-project streams-grafana
deploy operator grafana at streams-grafana
oc get pods -n streams-grafana

cat << EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |
    enableUserWorkload: true
EOF

oc get po -n openshift-user-workload-monitoring
cat examples/metrics/prometheus-install/strimzi-pod-monitor.yaml | sed "s#myproject#streams-kafka-cluster#g" | oc apply -n streams-kafka-cluster -f -

check metrics strimzi_resources in project streams-kafka-cluster 

delete limitrange project streams-grafana

cat << EOF | oc apply -f -
apiVersion: integreatly.org/v1alpha1
kind: Grafana
metadata:
  name: grafana
  namespace: streams-grafana
spec:
  ingress:
    enabled: True
  config:
    log:
      mode: "console"
      level: "warn"
    security:
      admin_user: "admin"
      admin_password: "admin"
    auth:
      disable_login_form: False
      disable_signout_menu: True
    auth.anonymous:
      enabled: True
  dashboardLabelSelector:
    - matchExpressions:
        - { key: app, operator: In, values: [strimzi] }
  resources:
    limits:
      cpu: 2000m
      memory: 8000Mi
    requests:
      cpu: 100m
      memory: 200Mi
EOF

cat << EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana-serviceaccount
  labels:
    app: strimzi
    namespace: streams-grafana
EOF

cat << EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: grafana-cluster-monitoring-binding
  labels:
    app: strimzi
subjects:
  - kind: ServiceAccount
    name: grafana-serviceaccount
    namespace: streams-grafana
roleRef:
  kind: ClusterRole
  name: cluster-monitoring-view
  apiGroup: rbac.authorization.k8s.io
EOF
# case don't found token after create sa
#oc create token -n streams-grafan grafana-serviceaccount
export TOKEN=$(oc serviceaccounts get-token grafana-serviceaccount -n streams-grafana)

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
import dashboard (kafka, zookeeper, exporter)


#create topic
kind: KafkaTopic
apiVersion: kafka.strimzi.io/v1beta2
metadata:
  name: my-topic
  labels:
    strimzi.io/cluster: my-cluster
  namespace: streams-kafka-cluster
spec:
  partitions: 3
  replicas: 3
  config:
    retention.ms: 604800000
    segment.bytes: 1073741824

#create producer
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-producer
  labels:
    app: hello-world-producer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world-producer
  template:
    metadata:
      labels:
        app: hello-world-producer
    spec:
      containers:
      - name: hello-world-producer
        image: strimzi/hello-world-producer:latest
        env:
          - name: BOOTSTRAP_SERVERS
            value: my-cluster-kafka-bootstrap:9092
          - name: TOPIC
            value: my-topic
          - name: DELAY_MS
            value: "10"
          - name: LOG_LEVEL
            value: "INFO"
          - name: MESSAGE_COUNT
            value: "1000000"


#crate consumer


apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-consumer
  labels:
    app: hello-world-consumer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world-consumer
  template:
    metadata:
      labels:
        app: hello-world-consumer
    spec:
      containers:
      - name: hello-world-consumer
        image: strimzi/hello-world-consumer:latest
        env:
          - name: BOOTSTRAP_SERVERS
            value: my-cluster-kafka-bootstrap:9092
          - name: TOPIC
            value: my-topic
          - name: GROUP_ID
            value: my-hello-world-consumer
          - name: LOG_LEVEL
            value: "INFO"
          - name: MESSAGE_COUNT
            value: "1000000"