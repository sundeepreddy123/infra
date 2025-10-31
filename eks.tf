module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  name                   = var.cluster_name
  kubernetes_version     = var.cluster_version
  endpoint_public_access = true
  version = "~> 21.0"
  # Gives Terraform identity admin access to cluster which will
  # allow deploying resources (Karpenter) into the cluster
    enable_cluster_creator_admin_permissions = true
    #endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs


  addons = {
      eks-pod-identity-agent = {
        before_compute = true
      }
    coredns = {
      most_recent = true
      before_compute  = false
      # configuration_values = jsonencode({
      # computeType = "Fargate"
      #   # Ensure that we fully utilize the minimum amount of resources that are supplied by
      #   # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
      #   # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
      #   # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
      #   # compute configuration that most closely matches the sum of vCPU and memory requests in
      #   # order to ensure pods always have the resources that they need to run.
      #   resources = {
      #     limits = {
      #       cpu = "0.25"
      #       # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
      #       # request/limit to ensure we can fit within that task
      #       memory = "256M"
      #     }
      #     requests = {
      #       cpu = "0.25"
      #       # We are targeting the smallest Task size of 512Mb, so we subtract 256Mb from the
      #       # request/limit to ensure we can fit within that task
      #       memory = "256M"
      #     }
      #   }
      # })
    }
    kube-proxy = {
        most_recent = true
        before_compute = false
    }
    vpc-cni    = {
        most_recent = true
        before_compute = true
        configuration_values = jsonencode({
            env ={
           ENABLE_PREFIX_DELEGATION = "true"
           WARM_PREFIX_TARGET = "1"
            }
        })
    }
  }

  vpc_id                   = module.network.vpc_id
  subnet_ids               = module.network.private_subnets
  #control_plane_subnet_ids = module.vpc.intra_subnets
   authentication_mode = "API"
  # Fargate profiles use the cluster primary security group so these are not utilized
  create_security_group = false
  create_node_security_group    = false

  # fargate_profiles = {
  #   karpenter = {
  #     selectors = [
  #      { namespace = "karpenter" }
  #     ]
  #   }
  #   kube-system = {
  #     selectors = [
  #       { namespace = "kube-system" }
  #     ]
  #   }
  # }

    eks_managed_node_groups = {
    karpenter = {
      ami_type       = "BOTTLEROCKET_x86_64"
      instance_types = ["m5.large"]

      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }
       taints = {
          nodetype = {
            key    = "nodetype"
            value  = "core"
            effect = "NO_SCHEDULE"
          }
        }

    }
  }

   
   

   access_entries = {
     #One access entry with a policy associated
     Devs = {
       kubernetes_groups = []
       principal_arn     = one(data.aws_iam_roles.admin_eks.arns)

       policy_associations = {
         cluster_admin = {
           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
           access_scope = {
             namespaces = []
             type       = "cluster"
            }
          }
        }
      }
    }

  tags =  {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  }
}


  module "karpenter" {
    source = "terraform-aws-modules/eks/aws//modules/karpenter"

    cluster_name = module.eks.cluster_name

    # EKS Fargate currently does not support Pod Identity
    #enable_irsa            = true
    #irsa_oidc_provider_arn = module.eks.oidc_provider_arn

     node_iam_role_use_name_prefix   = false
     node_iam_role_name              = "${var.cluster_name}-karpenter"
     create_pod_identity_association = true

    # Used to attach additional IAM policies to the Karpenter node IAM role
    node_iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

  }

 # #resource "aws_iam_service_linked_role" "spot" {
 #  # aws_service_name = "spot.amazonaws.com"
 # #}



  # module "iam_eks_role_lb" {
  #   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  #   version   = "~> 5.34.0"

  #   role_name = "EKSLoadBalancerControllerRole"
  #   attach_load_balancer_controller_policy = true

  #   oidc_providers = {
  #     main = {
  #       provider_arn               = module.eks.oidc_provider_arn
  #       namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
  #     }
  #   }

  #   depends_on = [
  #     module.eks
  #   ]
  # }


module "aws_lb_controller_pod_identity" {
  source = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.0.0"

  name = "EKSLoadBalancerControllerRole"

  attach_aws_lb_controller_policy = true

  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-load-balancer-controller"
  }
  
  associations = {
    one_cluster = {
      cluster_name = module.eks.cluster_name
    }
  }
}
