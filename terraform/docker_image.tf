resource "null_resource" "docker_push" {
  depends_on = [aws_ecr_repository.my_app]
  triggers = {
        script_hash = sha256("../app/Dockerfile")
  }
  provisioner "local-exec" {
    command = <<-EOT
           aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin "${aws_ecr_repository.my_app.repository_url}"
           cd ../app && docker build -t "${aws_ecr_repository.my_app.repository_url}:${var.app_version}" .
           docker push "${aws_ecr_repository.my_app.repository_url}:${var.app_version}"
      EOT
  }
}
