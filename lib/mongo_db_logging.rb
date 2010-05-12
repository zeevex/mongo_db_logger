module MongoDBLogging
  def self.included(base)
    base.class_eval { around_filter :enable_mongo_logging }
  end

  protected

  def mongo_ignore_request?
    return false if logged_in?
    user_agent = request.headers["USER_AGENT"]
    return true if user_agent.blank? ||
            user_agent.match(/chartbeat|google|spider|relic|wormly|mon.?itor|service|crawl|index|bot|proxy|basicstate/i)
    return true if user_agent.match(/sucuri|scout|pingdom|nimbu|nagios/i)
    return true if request.headers["PATH_INFO"] == "/" && ! request.params[:monitor].blank?
    return true if controller_name.match(/health|monitor/)

    false
  end

  def enable_mongo_logging
    return yield unless Rails.logger.respond_to?(:mongoize) && !mongo_ignore_request?
    
    # make sure the controller knows how to filter its parameters
    f_params = respond_to?(:filter_parameters) ? filter_parameters(params) : params


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
      yield
      annotate_mongo_logger if respond_to? :annotate_mongo_logger
    end
  end
end
