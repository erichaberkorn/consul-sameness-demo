#!/bin/bash

export CLUSTER4_CONTEXT=k3d-c4

kubectl --context $CLUSTER4_CONTEXT -n consul port-forward consul-server-0 8503:8501
