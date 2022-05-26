# ArgoCD Demo

## Introduction

This demo will create a GKE cluster and has the required tools to deploy ArgoCD over it

There are two floders present

- terraform: Terraform definitions to create a GKE cluster with autopilot and all of the networking configuration for it
- kubernetes: Modified version of the ArgoCD official installer to reduce the resource consumption


## Prerequisites

For creating the cluster and the networking infrastructure with terraform you would need a valid GCP account with a project that has the Cloud Compute API enabled.
In addition, you need to install the following tools:

- ArgoCD CLI
- Kubectl
- Terraform
- Gcloud

## Creating the cluster

1. Create a cloud storage bucket manually for the terraform state. If you want you can modify the terraform code to use another backend 
2. Go to the terraform folder and edit the following variables:

##### main.tf
```
backend "gcs" {
    bucket = "<your_state_bucket_name>"
    prefix = "terraform-state"
  }
```
##### vars.tf
```
variable "gcp_project_id" {
  type = string
  default = "<your-project-name>"
}
```

3. Get your public IP address and create the env variable for authorize traffic to the cluster 

```
export TF_VAR_authorized_source_ranges='["<your_ip_address>/32"]'
```

4. Login to Gcloud and obtain you access token with `gcloud auth print-access-token`. You need to pass this token to Terraform by setting the var GOOGLE_OAUTH_ACCESS_TOKEN to authenticate. 

##### Tip:

You can use the following alias to obtain the token and pass it to terraform:

```
alias tf='GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token 2>/dev/null) terraform'
```

After creating the alias you can use `tf` instead of `terraform` in the next steps

5.  Run a `terraform init` to initialize the backend
6.  Run `terraform plan` to get an overview of the GKE cluster creation and then `terraform apply` to create it. This might take some time to be ready

## Installing ArgoCD

1. Get the GKE cluster credentials on you local computer so kubectl con communicate with it

```
gcloud container clusters get-credentials --region <your-region> k8s-cluster
```

3. Create the `argocd` namespace:

```
kubectl create namespace argocd
```

4. Go to the `kubernetes` folder and apply the manifest

```
kubectl apply -f argocd.yaml
```

5. Get the first admin password for your argocd installation by listing it from the secret. If the secret is missing the cluster is still not ready so try again after some time

```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

6. Obtain any node external IP and connect to the interface by using the port 30001. Login with admin and the password obtained from the previous step

7. Deploy you first app by forking and using any sample from https://github.com/argoproj/argocd-example-apps. 

Keep in mind that GKE autopilot has some default quotas and it won't scale up after a couple of nodes. You can use the `kustomize-guestbook` app from my fork https://github.com/andresrrey/argocd-example-apps which already nhave limits set to deploy at least 3 pods.
