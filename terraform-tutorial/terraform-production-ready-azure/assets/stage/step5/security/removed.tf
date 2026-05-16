removed {
  from = module.networking
  lifecycle { destroy = false }
}

removed {
  from = module.web
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
