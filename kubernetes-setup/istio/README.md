# Istio

This is a quick and dirty description of how to install and use this repo.

## Get latest Istio

`curl -L https://git.io/getLatestIstio | sh -`

*Note:* At the time of writing this, Istio 1.0.6 was the latest version.

## Install

1) Modify `values.yaml` to your liking. If not modified:
    * Kiali is active (ingress will be created via nginx ingress)
    * Jaeger is active (ingress will be created via nginx ingress)
    * Default `ingressgateway` will be exposed via `LoadBalancer`

1) Install it like

    ```bash
      helm install \
        --name istio \
        --namespace istio-system \
        -f values.yaml
        istio-<istio_version>/install/kubernetes/helm/istio
    ```

1) Deploy secrets

    * Otherwise grafana and kiali deployments are not working (or deactivate authentication in `values.yaml`).

    ```shell
      kubectl apply -f secrets/grafana.yml --namespace istio-system
      kubectl apply -f secrets/kiali.yml --namespace istio-system
    ```

    * Note: It might also be necessary to tweak the `ConfigMap` of kiali (`kubectl edit configmap kiali -n istio-system`) to contain the auth for grafana (btw. dont do this for prod like this):

    ```yaml
      grafana:
        url: http://grafana-istio-system.127.0.0.1.nip.io:3000
        username: grafanaadmin
        password: admin123
    ```

Details:

* [Istio Helm istallation docu](https://istio.io/docs/setup/kubernetes/helm-install/)

## Deploy demos

*Note:* IMHO it is a good idea to create namespaces to deploy the demos (for example: `kubectl create ns bookinfo-demo`)

* [bookinfo](https://istio.io/docs/examples/bookinfo/)
* [microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)

## Do scenarios and stuff

This is up to you...
