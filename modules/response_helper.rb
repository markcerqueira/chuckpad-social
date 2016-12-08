module ResponseHelper

  # Response codes that client should be aware of
  CODE_SUCCESS = 200
  CODE_ERROR = 500
  CODE_INVALID_AUTH = 400

  # Responds with a success code to the caller.
  # Success method router that takes either 3 or 4 arguments. See handle_internal below.
  def self.success(*args)
    if args.size == 3 || args.size == 4
      handle_internal(CODE_SUCCESS, args)
    else
      raise StandardError
    end
  end

  # Responds with a generic error code to the caller.
  # Error method router that takes either 3 or 4 arguments. See handle_internal below.
  def self.error(*args)
    if args.size == 3 || args.size == 4
      handle_internal(CODE_ERROR, args)
    else
      raise StandardError
    end
  end

  # Responds with an invalid auth token error code to the caller.
  def self.auth_error(controller, request, message)
    handle_message(CODE_INVALID_AUTH, controller, request, message, message)
  end

  # Responds with raw JSON and a success code internally
  def self.success_with_json_msg(controller, message)
    controller.respond(CODE_SUCCESS, message)
  end

  # Private Implementation Methods

  # Cheesy overloaded method courtesy of http://rubylearning.com/satishtalim/ruby_overloading_methods.html
  def self.handle_internal(*args)
    # By this point we have "double-wrapped" the original vargs call to success or error so args here will be an array
    # with the first element being the code and the second element being an array of the original argument array to the
    # success/error calls. Cheesy!
    if args[1].size == 4
      # [code, [controller, request, message, message]] (in this case message is used twice as native/web message is shared)
      handle_message(args[0], args[1][0], args[1][1], args[1][2], args[1][2])
    else
      # [code, [controller, request, native message, web message]]
      handle_message(args[0], args[1][0], args[1][1], args[1][2], args[1][3])
    end
  end

  def self.handle_message(code, controller, request, native_message, web_message)
    if controller.from_native_client(request)
      controller.respond(code, native_message)
    else
      controller.redirect_to_index_with_status_msg(controller, web_message)
    end
  end

end
