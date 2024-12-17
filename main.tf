
# Definimos el provider como AWS
provider "aws" {
  region = "eu-west-1"
  shared_config_files = [ "/home/manuel/.aws/config" ]
  shared_credentials_files = [ "/home/manuel/.aws/credentials" ]
}


# 
data "aws_subnet" "aviability_zone_a"{
    availability_zone = "eu-west-1a"
}

#
data "aws_subnet" "aviability_zone_b"{
    availability_zone = "eu-west-1b"
}

# Creamos la instancia 1 de EC2 con AMI Ubuntu 22
resource "aws_instance" "Servidor_1" {
  ami = "ami-0a422d70f727fe93e"
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.aviability_zone_a.id
  vpc_security_group_ids = [aws_security_group.mi_grupo_de_seguridad.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hola terraform! Aqui servidor 1" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags = {
    Name = "servidor-1"
  }
}

# Creamos la instancia 1 de EC2 con AMI Ubuntu 22
resource "aws_instance" "Servidor_2" {
  ami = "ami-0a422d70f727fe93e"
  instance_type = "t2.micro"
  subnet_id = data.aws_subnet.aviability_zone_b.id
  vpc_security_group_ids = [aws_security_group.mi_grupo_de_seguridad.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hola terraform! Aqui servidor 2" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

  tags = {
    Name = "servidor-2"
  }
}


#
resource "aws_security_group" "mi_grupo_de_seguridad" {
  name = "primer-servidor-sg"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 8080 desde el exterior"
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
  }
}
