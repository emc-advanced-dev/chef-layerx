# layerx-chef
Chef Cookbook for Layer-X
=======
layerx-chef Cookbook
====================
This is the official Chef Cookbook for deploying Layer-X.

Requirements
------------
It requires ETCD and Go, as well as at least one Resource Provider (Mesos, Kubernetes, or Docker Swarm) to be running.

Note: if using Mesos as a resource provider, the Layer-X RPI for Mesos must be deployed on the Mesos Master node.

e.g.
#### packages
- `golang` - layerx-chef needs golang to compile sources
- `etcd` - layerx requires etcd to be running and reachable

Attributes
----------
#### layerx-chef::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['commit']</tt></td>
    <td>String</td>
    <td>git commit checksum to use when building layer-x</td>
    <td><tt>latest</tt></td>
  </tr>
</table>

Usage
-----
#### layerx-chef::default
TODO: Write usage instructions for each cookbook.

e.g.
Just include `layerx-chef` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[layerx-chef]"
  ]
}
```
