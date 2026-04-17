removed {
  from = random_string.suffix
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
  from = module.security
  lifecycle { destroy = false }
}

removed {
  from = aws_ssm_parameter.app_config
  lifecycle { destroy = false }
}

removed {
  from = aws_cloudwatch_log_group.app
  lifecycle { destroy = false }
}
