# k3sup-linode

This is a Terraform plan to create a K3s cluster on Linode with a Load Balancer and a private VLAN.

It's part of a blog post commissioned by Linode/Akamai for running production-ready FaaS:

[How to set up production-ready K3s with OpenFaaS on Linode](https://www.openfaas.com/blog/production-faas-linode/)

![HA K3s](https://www.openfaas.com/images/2023-08-linode-k3s/k3s-ha.png)
> What you'll get: HA K3s

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

Then head over to the [blog post to install K3s using K3sup and OpenFaaS](https://www.openfaas.com/blog/production-faas-linode/).

## License

MIT
