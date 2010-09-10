module MongoDBLogging
  def self.included(base)
    base.class_eval do
      around_filter :enable_mongo_logging
      alias_method_chain :process_cleanup, :mongo
    end
  end

  protected

  def process_cleanup_with_mongo
    if @mongo_do_finalize and Rails.logger.respond_to?(:finalize_mongo)
      Rails.logger.finalize_mongo response
      @mongo_do_finalize = false
    end
  end

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

    @mongo_do_finalize = true
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
        annotate_mongo_logger if respond_to? :annotate_mongo_logger
      end
    end
  end
end
