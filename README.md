# Consul Sameness Test Setup

## Architecture

![sameness architecture](./images/sameness_architecture.png)

## Setup Steps

1. `./reset-clusters.sh` - This deletes and creates four `k3d` Kubernetes clusters.
2. `./install-consul.sh` - This installs Consul on each of the four Kubernetes created in the previous step.
3. `./configure_k8s.sh` - Runs the `static-client` and `static-server` services on each Kubernetes cluster. `static-server` returns the peer name for the given partition.
4. `./sameness-sync.sh` - Syncronizes configuration entires to each member of the sameness group.

## Testing

After runing the setup steps, the following tests making requests from `static-client` in `cluster-01-a` `static-server`.
`static-server` is configured to failover to sameness group members in the following order: `cluster-01-a`, `cluster-01-b`, `cluster-02` and finally `cluster-03`.

Run the following commands to verify this:
1. `./make_request.sh` - Returns `cluster-01-a`
2. `./scale.sh 1 0` to trigger a failover.
3. `./make_request.sh` - Returns `cluster-01-b`
4. `./scale.sh 2 0` to trigger a failover.
3. `./make_request.sh` - Returns `cluster-03`
4. `./scale.sh 4 0` to trigger a failover.
3. `./make_request.sh` - Returns `cluster-02`
