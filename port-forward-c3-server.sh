#!/bin/bash

export CLUSTER3_CONTEXT=k3d-c3

kubectl --context $CLUSTER3_CONTEXT -n consul port-forward consul-server-0 8502:8501
