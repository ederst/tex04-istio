# demo time

## request routing

```shell
kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-all-v1.yaml
```

* edit virtual service `reviews` to use `v2` 
* edit virtual service `reviews` to use `v4` -> this will increase error rate

```shell
kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

* login with jason (not json!!!) and experience a new feature

## shifting

```shell
kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-all-v1.yaml

kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
```

Canary deployment: https://istio.io/blog/2017/0.1-canary/ -> needs autoscaling, hpa -> metrics server enabled, could not get it to work


## request timeouts / fault injection

* delay calls to `ratings` for some seconds

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percent: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
        subset: v1
```

* add timeout to `reviews` -> reviews should be unavailable

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
```

* screw over jason

```shell
kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-all-v1.yaml

kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml
```

* login with json should suck
* change percentage and delays

## mirroring

* change a `VirtualService` (best `reviews`) to mirror traffic to v2/v3

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
      weight: 100
    mirror:
      host: reviews
      subset: v2
```

## circuit breaking

* change `DestinationRule` of `productpage` accordingly

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: productpage
  namespace: bookinfo-demo
spec:
  host: productpage
  subsets:
  - labels:
      version: v1
    name: v1

  trafficPolicy:
    connectionPool:
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
      tcp:
        maxConnections: 1
    outlierDetection:
      baseEjectionTime: 180.000s
      consecutiveErrors: 1
      interval: 1.000s
      maxEjectionPercent: 100
```

## rate limiting

Rate limit configuration is split into 2 parts.

* Client Side
  * "QuotaSpec" defines quota name and amount that the client should request.
  * "QuotaSpecBinding" conditionally associates QuotaSpec with one or more services.
* Mixer Side
  * "quota instance" defines how quota is dimensioned by Mixer.
  * "memquota adapter" defines memquota adapter configuration.
  * "quota rule" defines when quota instance is dispatched to the memquota adapter.

```shell
kubectl apply -f istio-1.0.6/samples/bookinfo/networking/virtual-service-all-v1.yaml
kubectl apply -f istio-1.0.6/samples/bookinfo/policy/mixer-rule-productpage-ratelimit.yaml
```

* conditional -> logged in vs not logged in (`kubectl -n istio-system edit rules quota`)

```yaml
apiVersion: config.istio.io/v1alpha2
kind: rule
metadata:
  name: quota
  namespace: istio-system
spec:
  match: match(request.headers["cookie"], "user=*") == false
  actions:
  - handler: handler.memquota
    instances:
    - requestcount.quota
```