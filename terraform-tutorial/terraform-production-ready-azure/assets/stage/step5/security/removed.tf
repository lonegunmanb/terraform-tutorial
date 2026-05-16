removed {
  from = tls_private_key.web_ssh
  lifecycle { destroy = false }
}

removed {
  from = module.networking
  lifecycle { destroy = false }
}

removed {
  from = module.web
  lifecycle { destroy = false }
}

removed {
  from = module.data
  lifecycle { destroy = false }
}

removed {
  from = module.storage
  lifecycle { destroy = false }
}
