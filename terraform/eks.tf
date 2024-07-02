provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "main1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet1"
  }
}

resource "aws_subnet" "main2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "internet gateway"
  }
}

resource "aws_route_table" "route1" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "first" {
  subnet_id      = aws_subnet.main1.id
  route_table_id = aws_route_table.route1.id
}

resource "aws_route_table_association" "second" {
  subnet_id      = aws_subnet.main2.id
  route_table_id = aws_route_table.route1.id
}

resource "aws_security_group" "allow_tls" {
  name        = "my_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ssh from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "my-sg"
  }
}

 resource "aws_lb" "my_lb" {
   name               = "my-lb"
   internal           = false
   load_balancer_type = "application"
   security_groups    = [aws_security_group.allow_tls.id]
   subnets            = [aws_subnet.main1.id, aws_subnet.main2.id]
   tags = {
     Name = "my_lb"
   }
 }

 resource "aws_lb_target_group" "my_tg" {
   name     = "target-group"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.main.id
 }

resource "aws_iam_role" "my_role" {
  name = "my-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# output "worker_iam_role_name" {
#   value = aws_iam_role.my_role.name
# }


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main1.id, aws_subnet.main2.id]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t2.small"]
  }

  eks_managed_node_groups = {
    example = {
      min_size = 1
      max_size = 4
      #desired_size = 1

      instance_types = ["t2.small"]
      capacity_type  = "SPOT"
    }
  }

  # Cluster access entry
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    example = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::966117271938:role/my-role"

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

#