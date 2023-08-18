# k3sup-linode

Setup a HA K3sup cluster on Linode

## Instructions

Clone this repository

Run: `terraform init`

Edit main.tfvars, set the amount of servers to an odd number, then add your api_token from the Linode dashboard.

Apply the plan:

```
terraform apply -var-file ./main.tfvars
```

The output will contain the Load Balancer IP address (TLS SAN for K3s) along with the public IPs and private VLAN IPs for the K3s servers.

The VLAN range is 192.168.3.0/24.

Adding agents is an exercise for the reader.
