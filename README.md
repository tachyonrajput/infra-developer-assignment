# Infra-Developer-Assignment

# Step 1: 
# Minikube Blue-Green Deployment with NGINX Ingress Controller

This project demonstrates how to set up a blue-green deployment in a Kubernetes cluster using Minikube, with an NGINX Ingress Controller for traffic routing. The steps include creating deployments, services, and an Ingress resource to manage the blue-green traffic switch.

## Prerequisites

Before you start, make sure you have the following tools installed:

- **Minikube**: A tool for running Kubernetes clusters locally.
- **Kubectl**: Kubernetes command-line tool to interact with the cluster.
- **Helm**: A package manager for Kubernetes that simplifies the installation of complex resources.
- **Terraform** (optional, for automation): For automating the deployment of Kubernetes resources.

## Step 1: Run Minikube

1. Ensure you have **Minikube** installed. If not, follow the [installation guide](https://minikube.sigs.k8s.io/docs/).
2. Start Minikube with the following command:

   ```bash
   minikube start
This will start a Kubernetes cluster in your local machine using Minikube.


# Step 2: Create Deployments and Services
Create two deployments and services for the blue and green applications.

blue-app.yaml

    ```bash
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: blue-app
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: blue-app
      template:
        metadata:
          labels:
            app: blue-app
        spec:
          containers:
            - name: blue-app
              image: <blue-app-image>
              ports:
                - containerPort: 80
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: blue-app-service
    spec:
      selector:
        app: blue-app
      ports:
        - protocol: TCP
          port: 80
          targetPort: 80
      type: ClusterIP


greep-app.yaml

      ```bash
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: green-app
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: green-app
        template:
          metadata:
            labels:
              app: green-app
          spec:
            containers:
              - name: green-app
                image: <green-app-image>
                ports:
                  - containerPort: 80
      ---
      apiVersion: v1
      kind: Service
      metadata:
        name: green-app-service
      spec:
        selector:
          app: green-app
        ports:
          - protocol: TCP
            port: 80
            targetPort: 80
        type: ClusterIP



# Step 3: Setup NGINX Ingress Controller
  1. Install the NGINX Ingress Controller using Helm. If you don’t have Helm installed, follow the Helm installation guide.
  2. Add the Ingress NGINX Helm repository:
       ```bash
         helm repo add ingress-nginx https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/helm-chart

  3. Install the Ingress NGINX controller:
       ```bash
         helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.publishService.enabled=true

# Step 4: Create Ingress Resource
Next, create an Ingress resource to route traffic between the blue and green applications.

ingress.yaml

      ```bash
          apiVersion: networking.k8s.io/v1
          kind: Ingress
          metadata:
            name: blue-green-ingress
            annotations:
              nginx.ingress.kubernetes.io/rewrite-target: /
          spec:
            rules:
              - host: blue-green.local
                http:
                  paths:
                    - path: /blue
                      pathType: Prefix
                      backend:
                        service:
                          name: blue-app-service
                          port:
                            number: 80
                    - path: /green
                      pathType: Prefix
                      backend:
                        service:
                          name: green-app-service
                          port:
                            number: 80
This Ingress resource will route traffic based on the path (/blue or /green) to the respective services.


# Step 5: Apply the Resources
Once the deployment, services, and ingress YAML files are ready, apply them to your Minikube cluster:

    ```bash
    kubectl apply -f blue-app.yaml
    kubectl apply -f green-app.yaml
    kubectl apply -f ingress.yaml


This will create the deployments, services, and ingress resource in your Kubernetes cluster.

# Step 6: Testing the Ingress
To test the blue-green deployment setup:
  1. Find the Minikube IP by running:
     ```bash
       minikube ip
  2.  Update your /etc/hosts file (or Windows hosts file) to resolve blue-green.local to the Minikube IP:
      ```bash
      192.168.49.2 blue-green.local
  3. Test the blue and green apps by using curl:
       ```bash
       curl -H "Host: blue-green.local" http://<minikube-ip>/blue
       curl -H "Host: blue-green.local" http://<minikube-ip>/green
  You should receive responses from the respective applications.



# Step 7: (Optional) Automate with Terraform
To automate this process using Terraform, ensure you have Terraform and the Kubernetes provider installed. Here's an example main.tf file to automate the creation of deployments, services, and ingress resources.
main.tf
      ```bash
                provider "kubernetes" {
                host = "https://${minikube_ip}:8443"
                cluster_ca_certificate = base64decode(local.cluster_ca_certificate)
                token = local.token
              }
              
              locals {
                applications = [
                  {
                    name = "blue-app"
                    image = "<blue-app-image>"
                  },
                  {
                    name = "green-app"
                    image = "<green-app-image>"
                  }
                ]
              }
              
              resource "kubernetes_deployment" "blue_app" {
                metadata {
                  name = "blue-app"
                }
                spec {
                  replicas = 1
                  selector {
                    match_labels = {
                      app = "blue-app"
                    }
                  }
                  template {
                    metadata {
                      labels = {
                        app = "blue-app"
                      }
                    }
                    spec {
                      container {
                        name  = "blue-app"
                        image = local.applications[0].image
                        port {
                          container_port = 80
                        }
                      }
                    }
                  }
                }
              }
              
              resource "kubernetes_service" "blue_app_service" {
                metadata {
                  name = "blue-app-service"
                }
                spec {
                  selector = {
                    app = "blue-app"
                  }
                  port {
                    port = 80
                    target_port = 80
                  }
                  type = "ClusterIP"
                }
              }
              
              resource "kubernetes_ingress" "blue_green_ingress" {
                metadata {
                  name = "blue-green-ingress"
                }
                spec {
                  rule {
                    host = "blue-green.local"
                    http {
                      path {
                        path = "/blue"
                        backend {
                          service_name = kubernetes_service.blue_app_service.metadata[0].name
                          service_port = 80
                        }
                      }
                      path {
                        path = "/green"
                        backend {
                          service_name = kubernetes_service.green_app_service.metadata[0].name
                          service_port = 80
                        }
                      }
                    }
                  }
                }
              }



To use Terraform:
Initialize the Terraform configuration:

      ```bash
        terraform init
      
Apply the configuration to create resources:

      ```bash
        terraform apply


This will automatically deploy your applications, services, and Ingress resource on Kubernetes.
