module "amz-tailscale-client" {
  source           = "lbrlabs/tailscale/cloudinit"
  version          = "0.0.5"
  auth_key         = var.tailscale_auth_key
  enable_ssh       = true
  hostname         = var.name
  advertise_tags   = var.advertise_tags
  advertise_routes = var.advertise_addresses
  accept_routes    = true
  max_retries      = 10
  retry_delay      = 10
  additional_parts = [
    {
      filename     = "ssm.sh"
      content_type = "text/x-shellscript"
      content      = file("${path.module}/files/ssm.sh")
    },
    {
      filename     = "network.sh"
      content_type = "text/x-shellscript"
      content = templatefile("${path.module}/templates/network.sh.tmpl", {
        ENI_ID   = aws_network_interface.main.id
        HOSTNAME = var.name
      })
    }
  ]
}
