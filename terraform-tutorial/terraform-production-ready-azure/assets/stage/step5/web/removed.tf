removed {
  from = module.networking
  lifecycle { destroy = false }
}

removed {
  from = module.security
  lifecycle { destroy = false }
}

removed {
  from = module.storage
  lifecycle { destroy = false }
}

removed {
  from = module.dns
  lifecycle { destroy = false }
}
