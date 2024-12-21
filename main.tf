
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
  vpc_id = data.aws_vpc.default.id  

  ingress {
    # cidr_blocks = ["0.0.0.0/0"]    -> con esta linea cualquiera podria acceder al lb
    # Con la siguiente linea que sustituye a la anterior, solo los miembros del security group podrian acceder al lb
    # Esto permite que solo la carga mandada desde el load balancer pueda acceder a los servidores
    security_groups = [aws_security_group.alb.id]
    description = "Acceso al puerto 8080 desde el exterior"
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
  }
}

# Definimos el balanceador de carga
resource "aws_lb" "alb" {
  load_balancer_type = "application"
  name = "terraformers-alb"
  security_groups = [aws_security_group.alb.id]
  subnets = [ data.aws_subnet.aviability_zone_a.id, data.aws_subnet.aviability_zone_b.id ]
}

resource "aws_security_group" "alb" {
  name = "alb-sg"
  vpc_id = data.aws_vpc.default.id

  # Trafico entrante permitido, permite que se le llame desde el listener
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 80 desde el exterior"
    from_port = 80
    to_port = 80
    protocol = "TCP"
  }
  
  # Trafico saliente permitido, permite llamar a las instancias de los servidores
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso al puerto 8080 de nuestros servidores"
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
  }
}

data "aws_vpc" "default" {  # Devuelve la VPC que tenemos por defecto en aws
  default = true
}

# Crea "grupos" de servidores para enfocar la carga que va llegando
resource "aws_lb_target_group" "this" { 
  name = "terraformers-alb-target-group"
  port = 80
  vpc_id = data.aws_vpc.default.id # virtual private cloud
  protocol = "HTTP"

   # Si devuelve un 200 significa que esta funcionando correctamente y por tanto el valanceador de carga le puede mandar peticiones, si no lo esta no le manda carga
   health_check { 
     enabled = true
     matcher = "200"
     path = "/"
     port = "8080"
     protocol = "HTTP"
   }
}

# Añadimos el servidor 1 al grupo de attachement
resource "aws_lb_target_group_attachment" "Servidor_1" {
 target_group_arn = aws_lb_target_group.this.arn # Indicador del target group
 target_id = aws_instance.Servidor_1.id # Indicador del servidor que se añade al group attachement
 port = 8080
}

resource "aws_lb_target_group_attachment" "Servidor_2" {
 target_group_arn = aws_lb_target_group.this.arn
 target_id = aws_instance.Servidor_2.id
 port = 8080
}


# Vamos a crear el escuchador que recibira las peticiones y le pasara estas al balanceador de carga para que las mande a los respectivos servidores
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.alb.id
  port = 80

  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type = "forward"
  }
}