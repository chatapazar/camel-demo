oc get kamelet -n openshift-operators

oc new-project my-camel-k-project

oc describe -n openshift-operators kamelets/ftp-source

oc apply -f coffee-source.kamelet.yaml

oc apply -f coffee-to-log.yaml

oc get kameletbindings

oc get integrations

kamel log coffee-to-log

oc delete kameletbindings/coffee-to-log

## advance kamelet
oc apply -f coffee-to-log-adv.yaml

oc get kameletbindings

oc get integrations

kamel logs coffee-to-log

oc delete kameletbindings/coffee-to-log