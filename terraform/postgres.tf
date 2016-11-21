# Vault username
resource "random_id" "vault_username" {
  byte_length = 8
}

# Vault password
resource "random_id" "vault_password" {
  byte_length = 16
}

# User-data script
data "template_file" "postgres" {
  template = "${file("${path.module}/templates/postgres.sh.tpl")}"
  vars {
    hostname   = "postgres.${var.dnsimple_domain}"
    cidr_block = "${var.cidr_block}"
    username   = "${random_id.vault_username.hex}"
    password   = "${random_id.vault_password.hex}"
  }
}

# Postgres server
resource "aws_instance" "postgres" {
  ami           = "${data.aws_ami.ubuntu-1404.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.default.key_name}"

  subnet_id              = "${aws_subnet.default.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  tags {
    Name = "${var.namespace}-postgres"
  }

  user_data = "${data.template_file.postgres.rendered}"
}

output "postgres" {
  value = "${aws_instance.postgres.public_ip}"
}
