class Rack::Attack
  # Determine where to store client IP and expiry info
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Individual IPs are given a 100 requests per hour limit
  throttle('req/ip', limit: 100, period: 1.hour) do |req|
    req.ip
  end

  # If throttled then respond saying how long till expiry finishes
  self.throttled_response = lambda do |env|
    period = env['rack.attack.match_data'][:period]
    n = period - (Time.now.to_i % period)
    [ 429, {}, ["Rate limit exceeded. Try again in #{n} seconds}"] ]
  end
end
