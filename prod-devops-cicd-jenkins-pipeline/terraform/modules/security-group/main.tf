locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ─── Jenkins Controller Security Group ───────────────────────────────────────
resource "aws_security_group" "jenkins" {
  name        = "${local.name_prefix}-sg-jenkins"
  description = "Jenkins controller: UI on 8080, JNLP on 50000"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-jenkins" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_ui" {
  security_group_id = aws_security_group.jenkins.id
  description       = "Jenkins UI from admin CIDR (bastion/VPN)"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_cidr
  tags              = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_jnlp" {
  security_group_id = aws_security_group.jenkins.id
  description       = "Jenkins JNLP agent connections from VPC"
  from_port         = 50000
  to_port           = 50000
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
  tags              = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "jenkins_all" {
  security_group_id = aws_security_group.jenkins.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# ─── SonarQube Security Group ─────────────────────────────────────────────────
resource "aws_security_group" "sonarqube" {
  name        = "${local.name_prefix}-sg-sonarqube"
  description = "SonarQube: UI on 9000 from Jenkins and admin CIDR"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-sonarqube" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "sonarqube_from_jenkins" {
  security_group_id            = aws_security_group.sonarqube.id
  description                  = "SonarQube UI from Jenkins controller"
  from_port                    = 9000
  to_port                      = 9000
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.jenkins.id
  tags                         = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "sonarqube_admin" {
  security_group_id = aws_security_group.sonarqube.id
  description       = "SonarQube UI from admin CIDR (bastion/VPN)"
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_cidr
  tags              = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "sonarqube_all" {
  security_group_id = aws_security_group.sonarqube.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# ─── Jenkins Agent Security Group ────────────────────────────────────────────
resource "aws_security_group" "jenkins_agent" {
  name        = "${local.name_prefix}-sg-jenkins-agent"
  description = "Optional Jenkins agent nodes: SSH from Jenkins controller only"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-jenkins-agent" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "agent_ssh_from_jenkins" {
  security_group_id            = aws_security_group.jenkins_agent.id
  description                  = "SSH from Jenkins controller"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.jenkins.id
  tags                         = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "agent_all" {
  security_group_id = aws_security_group.jenkins_agent.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# ─── Nexus Security Group ─────────────────────────────────────────────────────
resource "aws_security_group" "nexus" {
  name        = "${local.name_prefix}-sg-nexus"
  description = "Nexus: port 8081 from Jenkins and admin CIDR"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-nexus" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "nexus_from_jenkins" {
  security_group_id            = aws_security_group.nexus.id
  description                  = "Nexus UI from Jenkins"
  from_port                    = 8081
  to_port                      = 8081
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.jenkins.id
  tags                         = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "nexus_admin" {
  security_group_id = aws_security_group.nexus.id
  description       = "Nexus UI from admin CIDR"
  from_port         = 8081
  to_port           = 8081
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_cidr
  tags              = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "nexus_all" {
  security_group_id = aws_security_group.nexus.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# ─── PostgreSQL Security Group ───────────────────────────────────────────────
resource "aws_security_group" "postgres" {
  name        = "${local.name_prefix}-sg-postgres"
  description = "PostgreSQL: port 5432 from SonarQube and Jenkins only"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-postgres" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_sonarqube" {
  security_group_id            = aws_security_group.postgres.id
  description                  = "PostgreSQL from SonarQube"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sonarqube.id
  tags                         = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_jenkins" {
  security_group_id            = aws_security_group.postgres.id
  description                  = "PostgreSQL from Jenkins"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.jenkins.id
  tags                         = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "postgres_all" {
  security_group_id = aws_security_group.postgres.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}

# ─── ALB Security Group ───────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-sg-alb"
  description = "Internal ALB placeholder: HTTPS/HTTP from admin CIDR"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from admin CIDR"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_cidr
  tags              = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from admin CIDR (redirect to HTTPS)"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.admin_cidr
  tags              = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound to targets"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.common_tags
}
