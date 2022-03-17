resource "null_resource" "prepare_app_zip" {
  triggers = {
    app_version = var.app_version
    git_repo    = var.git_repo
  }

  provisioner "local-exec" {
    command = <<EOF
        mkdir -p ${var.dir_to_clone}
        cd ${var.dir_to_clone}
        git init
        git remote add origin ${var.git_repo}
        git fetch
        git checkout -t origin/master
        zip -r ${var.app_zip} *
        
EOF

  }
}

data "ibm_space" "spacedata" {
  space = var.space
  org   = var.org
}

resource "ibm_service_instance" "service-instance" {
  name       = var.service_instance_name
  space_guid = data.ibm_space.spacedata.id
  service    = var.service
  plan       = var.plan
  tags       = ["cluster-service", "cluster-bind"]
}

resource "ibm_service_key" "serviceKey" {
  name                  = var.service_key_name
  service_instance_guid = ibm_service_instance.service-instance.id
}

data "ibm_app_domain_shared" "domain" {
  name = "mybluemix.net"
}

resource "ibm_app_route" "route" {
  domain_guid = data.ibm_app_domain_shared.domain.id
  space_guid  = data.ibm_space.spacedata.id
  host        = var.route
}

resource "ibm_app" "app" {
  depends_on = [
    ibm_service_key.serviceKey,
    null_resource.prepare_app_zip,
  ]
  name              = var.app_name
  space_guid        = data.ibm_space.spacedata.id
  app_path          = var.app_zip
  wait_time_minutes = 10

  buildpack  = var.buildpack
  
  memory                = 256
  instances             = 2
  disk_quota            = 512
  route_guid            = [ibm_app_route.route.id]
  service_instance_guid = [ibm_service_instance.service-instance.id]
  app_version           = var.app_version
  command               = var.app_command
}