resource "helm_release" "istio_base"{

    name = "istio-base"
    namespace = "istio-system"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart = "base"
    version = "1.21.2"
    create_namespace = true
    wait = true
    reset_values = true

    depends_on = [
        module.eks,
        module.iam_eks_role_lb
    ]   
}



resource "helm_release" "istiod"{

    name = "istiod"
    namespace = "istio-system"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart = "istiod"
    version = "1.21.2"
    wait = true
    reset_values = true

    set {
          name  = "meshConfig.accessLogFile"
          value = "/dev/stdout"
        }
      
    

    depends_on = [
        helm_release.istio_base
    ]   
}


resource "helm_release" "istio_ingress"{

    name = "istio-ingress"
    namespace = "istio-ingress"
    create_namespace = true
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart = "gateway"
    version = "1.21.2"
    wait = true
    reset_values = true

    values = [
    "${file("files/istio-ingress/values-${var.env}.yaml")}"
  ]


    depends_on = [
        helm_release.istiod
    ]   
}


resource "helm_release" "istio_ingress-internal"{

    name = "istio-ingress-internal"
    namespace = "istio-ingress-internal"
    create_namespace = true
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart = "gateway"
    version = "1.21.2"
    wait = true
    reset_values = true

    values = [
    "${file("files/istio-ingress/values-${var.env}-int.yaml")}"
  ]


    depends_on = [
        helm_release.istiod
    ]   
}
