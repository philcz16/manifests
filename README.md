# BootStrap K8s with ArgoCD


## Table of Contents

1. [Introduction](#introduction)
2. [Clone the Repository](#clone-the-repository)
3. [Provision EKS Cluster](#provision-eks-cluster)
    - [Initialize Terraform](#initialize-terraform)
    - [Plan Terraform](#Plan-terraform)
    - [Apply Terraform Configuration](#apply-terraform-configuration)
4. [Update EKS Configuration](#update-eks-configuration)
5. [Apply Manifest Files](#apply-manifest-files)
6. [Bootstrapping with ArgoCD](#bootstrapping-with-argocd)
    - [Add a Namespace for ArgoCD](#add-a-namespace-for-argocd)
    - [Install ArgoCD](#install-argocd)
    - [Confirm ArgoCD Pods](#confirm-argocd-pods)
    - [Map Port for ArgoCD Access](#map-port-for-argocd-access)
    - [Retrieve ArgoCD Admin Password](#retrieve-argocd-admin-password)
    - [Log in to ArgoCD](#log-in-to-argocd)
    - [Connect GitHub Repository to ArgoCD](#connect-github-repository-to-argocd)
    - [Add Your Cluster to ArgoCD](#add-your-cluster-to-argocd)
    - [Create and Sync Your Application](#create-and-sync-your-application)
7. [Conclusion](#conclusion)

### Introduction
In this article, we will learn how to bootstrap our Kubernetes cluster with ArgoCD. To achieve this, we need a running cluster which can either be EKS, GKS, or AKS, our manifest files which are inside our GitHub repository, and an ArgoCD account.


### Clone the repository

```sh
git clone https://github.com/Victoria-OA/manifests.git
```

cd into the eks folder which contains the Terraform files to provision your cluster on AWS:

```sh
terraform init
terraform plan
terraform apply
```

### Update EKS Configuration

After our EKS configuration has been successfully applied to AWS, update it using the following command so our manifest files can be applied to the cluster:

```sh
aws eks --region <region> update-kubeconfig --name <cluster-name>
```

### Apply Manifest Files

After updating your cluster to receive manifests configuration, apply the files in the manifest folder with:

```sh
kubectl apply -f a.yaml
```

### Bootstrapping with ArgoCD

Once your manifest files have been applied, the next step is to bootstrap them to ArgoCD to enhance continuous delivery. Follow these steps:

1. **Add a namespace for ArgoCD:**

    ```sh
    kubectl create namespace argocd
    ```

2. **Install ArgoCD:**

    ```sh
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

3. **Confirm ArgoCD Pods:**

    After installation, wait for a while for the pods to be ready and confirm it using:

    ```sh
    kubectl get pods -n argocd
    ```

4. **Map Port for ArgoCD Access:**

    When the pods are ready, map your port to access ArgoCD in the browser:

    ```sh
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

5. **Retrieve ArgoCD Admin Password:**

    Upon access, you will be required to log in with a username and a password. The username is `admin`, and the password can be retrieved using the following command:

    ```sh
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

6. **Log in to ArgoCD:**

    When the password has been retrieved, log in to ArgoCD with:

    ```sh
    argocd login localhost:8080
    ```

7. **Connect GitHub Repository to ArgoCD:**

    Once logged in successfully, connect the GitHub repo that contains the manifest with the following command:

    ```sh
    argocd repo add https://github.com/username/repourl --username <your-github-username> --password <your-personal-access-token>
    ```

    Note: To get your GitHub password, use your GitHub token, which can be generated in developer’s settings.

8. **Add Your Cluster to ArgoCD:**

    Once your repo has been connected successfully, add your cluster to the ArgoCD server using the following command:

    ```sh
    kubectl config get-contexts
    argocd cluster add <context-name>
    ```

9. **Create and Sync Your Application:**

    Once the cluster has been added successfully, proceed to create your app and configure your ArgoCD using:

    ```sh
    argocd app create appname \
       --repo https://github.com/username/repourl \
       --path manifests/ \
       --dest-server https://kubernetes.default.svc \
       --dest-namespace argocd
    ```

10. **Sync Your Application:**

    Finally, sync your app using the following command:

    ```sh
    argocd app sync newapp
    ```

Once the sync is successful, you can log in to your ArgoCD via the browser to check it out.

## Conclusion

By following these steps, you have set up a Kubernetes cluster, applied your manifest files, and integrated ArgoCD for continuous delivery. This setup not only streamlines your deployment process but also enhances the manageability and scalability of your applications.
