removed {
  from = module.networking
  lifecycle { destroy = false }
}

removed {
  from = module.security
  lifecycle { destroy = false }
}

removed {
  from = module.web
  lifecycle { destroy = false }
}

removed {
  from = module.dns
  lifecycle { destroy = false }
}
