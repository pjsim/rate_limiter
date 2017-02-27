class RequestHandler
  @@cache = Rails.cache
  include ActionView::Helpers::TextHelper # Only used to grab pluralize method

  attr_reader :status, :text

  def initialize(request_ip)
    @request_ip = request_ip

    handle_cache_entry

    if throttled?
      @status = 429
      @text = "Rate limit exceeded. Try again in #{seconds_till_expires}"
    else
      @status = 200
      @text = 'ok'
    end
  end

  private

  # If the cache has expired or doesn't exist then make a new entry, otherwise increment the counter on the existing one
  def handle_cache_entry
    @cache_entry = @@cache.read(@request_ip)
    if @cache_entry
      @expires_at = @cache_entry[:expires_at]
      @counter = @cache_entry[:counter]

      if @expires_at <= Time.current
        write_new_cache_entry(0) # Set counter to 0 so it updates to 1 when handled again
        handle_cache_entry
      else
        update_existing_cache_entry
      end
    else
      write_new_cache_entry
    end
  end

  def write_new_cache_entry(counter=1)
    @@cache.write(@request_ip, { counter: counter, expires_at: 1.hour.from_now }, expires_in: 1.hour)
  end

  def update_existing_cache_entry
    @@cache.write(@request_ip, { counter: @counter + 1, expires_at: @expires_at }) # Rails.cache.increment breaks 'expires_in' so I use my own counter
  end

  def throttled?
    @counter.present? && @counter >= 100
  end

  def seconds_till_expires
    pluralize(@expires_at.to_i - Time.current.to_i, 'second')
  end
end
