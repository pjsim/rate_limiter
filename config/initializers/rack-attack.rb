class Rack::Attack
  # Determine where to store client ip and expiry info
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
end
