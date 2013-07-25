module MongoDBLogging
  def self.included(base)
    base.class_eval do
      around_filter :enable_mongo_logging
    end
  end

  protected

  def mongo_ignore_request?
    return false if request.ssl? || request.xhr?
    return false if logged_in?
    user_agent = request.headers["USER_AGENT"]
    return false if controller_name == "zesa"
    if !user_agent.blank?
      return true if
            user_agent.match(/chartbeat|google|spider|relic|wormly|mon.?itor|service|crawl|pingdom|basicstate/i)
      return true if user_agent.match(/sucuri|scout|pingdom|nimbu|nagios|newrelicpinger/i)
    end
    return true if request.headers["PATH_INFO"] == "/" && ! request.params[:monitor].blank?
    return true if controller_name.match(/health|monitor/)

    false
  end

  def enable_mongo_logging
    # our logger isn't mongoized or we don't like this request
    return yield unless Rails.logger.respond_to?(:mongoize, true) && !mongo_ignore_request?

    # this filter has already run
    return yield if Thread.current[:mongo_do_finalize]

    # make sure the controller knows how to filter its parameters
    f_params = respond_to?(:filter_parameters, true) ? filter_parameters(params) : params

    Thread.current[:mongo_do_finalize] = true
    Thread.current[:mongo_current_response] = response

    Rails.logger.mongoize({
      :method         => request.request_method,
      :action         => action_name,
      :controller     => controller_name,
      :path           => request.path,
      :url            => request.url,
      :params         => f_params,
      :ip             => request.remote_ip,
      :ssl            => request.ssl?,
      :xhr            => request.xhr?,
      :request_headers    => MongoLogger.sanitize_hash(request.headers)
    }, request, response) do
      begin
        yield
      ensure
        annotate_mongo_logger if respond_to?(:annotate_mongo_logger, true)
      end
    end
  end
end

ActionDispatch::Callbacks.after do
  if Thread.current[:mongo_do_finalize] and Rails.logger.respond_to?(:finalize_mongo, true)
    Rails.logger.finalize_mongo Thread.current[:mongo_current_response]
    Thread.current[:mongo_do_finalize] = nil
    Thread.current[:mongo_current_response] = nil
  end
end
