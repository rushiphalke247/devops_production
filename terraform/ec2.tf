# =============================================================================
# EC2 Instances - Jenkins, K8s Master, K8s Worker
# =============================================================================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- Jenkins Server ---
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.large"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jenkins.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install -y fontconfig openjdk-17-jre
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update -y
    sudo apt install -y jenkins docker.io
    sudo systemctl enable jenkins docker
    sudo systemctl start jenkins docker
    sudo usermod -aG docker jenkins
    sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
  EOF

  tags = {
    Name = "${var.project_name}-jenkins"
  }
}

# --- Kubernetes Master (Control Plane) ---
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.k8s.id]

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname k8s-master
  EOF

  tags = {
    Name = "${var.project_name}-k8s-master"
  }
}

# --- Kubernetes Worker Node ---
resource "aws_instance" "k8s_worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.k8s.id]

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname k8s-worker
  EOF

  tags = {
    Name = "${var.project_name}-k8s-worker"
  }
}
