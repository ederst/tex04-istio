#!/bin/bash

helm del --purge istio
kubectl delete -f istio-1.0.6/install/kubernetes/helm/istio/templates/crds.yaml -n istio-system