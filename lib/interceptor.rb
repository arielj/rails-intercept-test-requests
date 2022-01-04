module Interceptor
  # Add an interception hash for a given url, http method, and response
  # @url can be a regexp or a string
  # @method can be a string or a symbol, an can be uppercase or lowercase
  def intercept(url, response = "", method = :any)
    @interceptions << {url: url, method: method, response: response}
  end

  def start_intercepting
    # ignore if the driver is RackTest
    return unless page.driver.browser.respond_to?(:intercept)

    # only attach the intercept callback once to the browser
    @interceptions = default_interceptions

    return if @intercepting

    page.driver.browser.intercept do |request, &continue|
      url = request.url
      method = request.method

      if (interception = response_for(url, method))
        # set mocked body if there's an interception for the url and method
        continue.call(request) do |response|
          response.body = interception[:response]
        end
      elsif allowed_request?(url, method)
        # leave request untouched if allowed
        continue.call(request)
      else
        # intercept any external request with an empty response and print some logs
        continue.call(request) do |response|
          log_request(url, method)
          response.body = ""
        end
      end
    end
    @intercepting = true
  end

  def stop_intercepting
    return unless @intercepting

    # remove the callback, cleanup
    clear_devtools_intercepts
    @intercepting = false
    # some requests may finish after the test is done if we let them go through untouched
    sleep(0.2)
  end

  # Override this method to define default interceptions that should apply to all tests
  # Each element of the array should be a hash with `url`, `response` and `method` key, like
  # the hash added by the `intercept` method
  #
  # For example:
  # - [{url: "https://external.api.com", response: ""}, {url: another_domain, response: fixed_response, method: :get}]
  def default_interceptions
    []
  end

  # Override this method to add more allowed requests that shouldn't be intercepted
  #
  # Elements of this array can be:
  # - a string
  # - a regexp
  # - a hash with `url` and `method` keys where:
  #   - url can be a string or a regexp
  #   - method can be `:any`, can be omitted (same as setting `:any`), or can be an
  #     http method as symbol or string and lowercase or uppercase
  #
  # For example, these are valid elements for the array:
  # - "https://allowed.domain.com"
  # - {url: "https://allowed.domain.com", method: "GET"} (or {url: /allowed\.domain\.com/, method: :get})
  # - {url: /allowed\.domain\.com/, method: :any} (or {url: /allowed\.domain\.com/} or /allowed\.domain\.com/)
  #
  # NOTE that you probably always want at least the Capybara.server_host url in this array
  def allowed_requests
    [%r{http://#{Capybara.server_host}}]
  end

  private

  # check if the given request url and http method pair is allowed by any rule
  def allowed_request?(url, method = "GET")
    allowed_requests.any? do |allowed|
      allowed_url = allowed.is_a?(Hash) ? allowed[:url] : allowed
      matches_url = url.match?(allowed_url)

      allowed_method = allowed.is_a?(Hash) ? allowed[:method] : :any
      allowed_method ||= :any
      matches_method = allowed_method == :any || method == allowed_method.to_s.upcase

      matches_url && matches_method
    end
  end

  # find the interception hash for a given url and http method pair
  def response_for(url, method = "GET")
    @interceptions.find do |interception|
      matches_url = url.match?(interception[:url])
      matches_method = interception[:method] == :any || method == interception[:method].to_s.upcase

      matches_url && matches_method
    end
  end

  # clears the devtools callback for the interceptions
  def clear_devtools_intercepts
    callbacks = page.driver.browser.devtools.callbacks
    if callbacks.has_key?("Fetch.requestPaused")
      callbacks.delete("Fetch.requestPaused")
    end
  end

  def log_request(url, method)
    message = "External JavaScript request not intercepted: #{method} #{url}"
    puts message
    Rails.logger.warn message
  end
end