terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

resource "aws_vpc" "nba-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "nba-vpc"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_subnet" "nba-public1" {
  vpc_id                  = aws_vpc.nba-vpc.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "nba-public1"
  }
}

resource "aws_subnet" "nba-public2" {
  vpc_id                  = aws_vpc.nba-vpc.id
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "nba-public2"
  }
}


resource "aws_subnet" "nba-private1" {
  vpc_id            = aws_vpc.nba-vpc.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = "ap-northeast-1a"
  tags = {
    Name = "nba-private1"
  }
}


resource "aws_subnet" "nba-private2" {
  vpc_id            = aws_vpc.nba-vpc.id
  cidr_block        = "10.10.12.0/24"
  availability_zone = "ap-northeast-1c"
  tags = {
    Name = "nba-private2"
  }
}

resource "aws_subnet" "nba-private3" {
  vpc_id            = aws_vpc.nba-vpc.id
  cidr_block        = "10.10.13.0/24"
  availability_zone = "ap-northeast-1d"
  tags = {
    Name = "nba-private3"
  }
}


resource "aws_internet_gateway" "nba-igw" {
  vpc_id = aws_vpc.nba-vpc.id
  tags = {
    Name = "nba-igw"
  }
}


resource "aws_route_table" "nba-public1" {
  vpc_id = aws_vpc.nba-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nba-igw.id
  }
  tags = {
    Name = "nba-public1"
  }
}


resource "aws_route_table" "nba-public2" {
  vpc_id = aws_vpc.nba-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nba-igw.id
  }
  tags = {
    Name = "nba-public2"
  }
}


resource "aws_route_table_association" "nba-routing-public1" {
  subnet_id      = aws_subnet.nba-public1.id
  route_table_id = aws_route_table.nba-public1.id
}



resource "aws_route_table_association" "nba-routing-public2" {
  subnet_id      = aws_subnet.nba-public2.id
  route_table_id = aws_route_table.nba-public2.id
}


resource "aws_eip" "nba-natgw-eip" {
  domain = "vpc"
  tags = {
    Name = "nba-natgw-eip"
  }
}


resource "aws_nat_gateway" "nba-nat-gw" {
  allocation_id = aws_eip.nba-natgw-eip.id
  subnet_id     = aws_subnet.nba-public1.id

  tags = {
    Name = "nba-nat-gw"
  }
}

resource "aws_route_table" "nba-private1" {
  vpc_id = aws_vpc.nba-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nba-nat-gw.id
  }
  tags = {
    Name = "nba-private1"
  }
}

resource "aws_route_table" "nba-private2" {
  vpc_id = aws_vpc.nba-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nba-nat-gw.id
  }
  tags = {
    Name = "nba-private2"
  }
}
resource "aws_route_table" "nba-private3" {
  vpc_id = aws_vpc.nba-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nba-nat-gw.id
  }
  tags = {
    Name = "nba-private3"
  }
}

resource "aws_route_table_association" "nba-routing-private1" {
  subnet_id      = aws_subnet.nba-private1.id
  route_table_id = aws_route_table.nba-private1.id
}


resource "aws_route_table_association" "nba-routing-private2" {
  subnet_id      = aws_subnet.nba-private2.id
  route_table_id = aws_route_table.nba-private2.id
}

resource "aws_route_table_association" "nba-routing-private3" {
  subnet_id      = aws_subnet.nba-private3.id
  route_table_id = aws_route_table.nba-private3.id
}

resource "aws_instance" "gitops-host" {
  ami                         = "ami-0a5f9e25e60e0982d"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.nba-private1.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.gitops-host-sg.id, ]
  key_name                    = aws_key_pair.gitops-key-pair.key_name
  private_ip                  = "10.10.11.100"

  tags = {
    Name = "gitops-host"
  }
}

resource "aws_instance" "bastion-host" {
  ami                         = "ami-0c53faf64a54b403d"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.nba-public1.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.bastion-host-sg.id, ]
  key_name                    = aws_key_pair.bastion-key-pair.key_name
  private_ip                  = "10.10.1.100"

  tags = {
    Name = "bastion-host"
  }
}

resource "aws_security_group" "gitops-host-sg" {
  name   = "gitops-host-sg"
  vpc_id = aws_vpc.nba-vpc.id

  tags = {
    Name = "gitops-host-sg"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.0/24"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.0/24"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.10.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bastion-host-sg" {
  name   = "bastion-host-sg"
  vpc_id = aws_vpc.nba-vpc.id

  tags = {
    Name = "bastion-host-sg"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 81
    to_port     = 81
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group" "eks-node-sg" {
#   name   = "eks-node-sg"
#   vpc_id = aws_vpc.nba-vpc.id

#   tags = {
#     Name = "eks-node-sg"
#   }

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["10.10.0.0/16"]
#   }
#   ingress {
#     from_port   = -1
#     to_port     = -1
#     protocol    = "icmp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

resource "aws_key_pair" "gitops-key-pair" {
  key_name   = "gitops-key"
  public_key = file("gitops.pem.pub")
  tags = {
    description = "terraform key pair import"
  }
}

resource "aws_key_pair" "bastion-key-pair" {
  key_name   = "bastion-key"
  public_key = file("bastion.pem.pub")
  tags = {
    description = "terraform key pair import"
  }
}

resource "aws_key_pair" "eks-node-key-pair" {
  key_name   = "eks-node-key"
  public_key = file("eks-node.pem.pub")
  tags = {
    description = "terraform key pair import"
  }
}

resource "aws_db_subnet_group" "nba_rds_subnet_group" {
  name       = "nba_rds_subnet_group"
  subnet_ids = [aws_subnet.nba-private1.id, aws_subnet.nba-private2.id, aws_subnet.nba-private3.id]

  tags = {
    Name = "nba_rds_subnet_group"
  }
}

resource "aws_security_group" "nba-rds-sg" {
  name        = "nba-rds-sg"
  vpc_id      = aws_vpc.nba-vpc.id
  description = "Security group for RDS instance"

  tags = {
    Name = "nba-rds-sg"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "nba-rds" {
  allocated_storage          = 30
  storage_type               = "gp2"
  engine                     = "mysql"
  engine_version             = "8.0.33"
  instance_class             = "db.t3.micro"
  identifier                 = "nba-rds"
  db_name                    = "nba"
  username                   = "nba"
  password                   = "kakaoschool2023"
  parameter_group_name       = "default.mysql8.0"
  skip_final_snapshot        = true
  vpc_security_group_ids     = [aws_security_group.nba-rds-sg.id, ]
  db_subnet_group_name       = aws_db_subnet_group.nba_rds_subnet_group.name
  multi_az                   = false
  publicly_accessible        = false
  storage_encrypted          = true
  auto_minor_version_upgrade = false
  tags = {
    Name = "nba-rds"
  }
}

resource "aws_eks_cluster" "nba-eks" {
  name     = "nba-eks"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids              = [aws_subnet.nba-private1.id, aws_subnet.nba-private2.id, aws_subnet.nba-private3.id]
    endpoint_public_access  = false
    endpoint_private_access = true
    security_group_ids      = [aws_security_group.nba-eks-sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSVPCResourceController,
  ]
}

resource "aws_security_group" "nba-eks-sg" {
  name        = "nba-eks-sg"
  vpc_id      = aws_vpc.nba-vpc.id
  description = "Security group for EKS EndPoint"

  tags = {
    Name = "nba-eks-sg"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/16"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_node_group" "eks-node-group" {
  cluster_name    = aws_eks_cluster.nba-eks.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.node-group-role.arn
  subnet_ids      = [aws_subnet.nba-private1.id, aws_subnet.nba-private2.id, aws_subnet.nba-private3.id]
  instance_types  = ["t3.medium"]
  capacity_type   = "SPOT"
  scaling_config {
    min_size     = 2
    max_size     = 5
    desired_size = 3
  }
  remote_access {
    ec2_ssh_key = aws_key_pair.eks-node-key-pair.key_name
    # source_security_group_ids = [aws_security_group.eks-node-sg.id]
  }
  depends_on = [aws_iam_role_policy_attachment.attach-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.attach-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.attach-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.attach-AmazonEC2ContainerRegistryFullAccess,
  aws_iam_role_policy_attachment.attach-EC2InstanceProfileForImageBuilderECRContainerBuilds]
}

data "aws_iam_policy_document" "assume_role-eks" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "assume_role-nodegroup" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "eks_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role-eks.json
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role" "node-group-role" {
  name               = "node-group-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role-nodegroup.json
}

resource "aws_iam_role_policy_attachment" "attach-AmazonEC2ContainerRegistryFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "attach-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "attach-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "attach-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-group-role.name
}

resource "aws_iam_role_policy_attachment" "attach-EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.node-group-role.name
}


resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.nba-eks.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks-node-group]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.nba-eks.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks-node-group]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.nba-eks.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.eks-node-group]
}

output "nba-eks-endpoint" {
  description = "Private NBA EKS Endpoint"
  value       = aws_eks_cluster.nba-eks.endpoint
}

output "bastion-host-public-ip" {
  description = "Public IP address of Bastion Host"
  value       = aws_instance.bastion-host.public_ip
}
