module CheckErrors
  extend self

  def handle_errors(text)
    LOG.error(text)
    raise RuntimeError, text
  end

  def check_arguments(args)
    size = 2
    msg = "\nNumber of arguments must be 2\n"
    usage = "\nUsage: ruby #{$0} repository_id resource_id\n"
    handle_errors(msg+usage) unless args.size == 2
  end
end
