resource "null_resource" "eks_setup" {

  provisioner "local-exec" {
    command = "aws eks --region us-east-1 update-kubeconfig --name ${module.eks.cluster_name}"
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [ module.eks ]
}


resource "helm_release" "argocd" {
  name = "argocd"

  depends_on = [ null_resource.eks_setup ]

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"
  

  values = [file("${path.module}/values/argocd.yaml")]
}