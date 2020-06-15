class RateLimiter
  MAX_REQUESTS_PER_PERIOD = 33
  TIME_PERIOD_IN_SECONDS = 45
  BASE_REDIS_KEY = 'request-count-ip'

  def self.should_block_request?(ip, path)
    recent_requests(ip, path).to_i >= MAX_REQUESTS_PER_PERIOD
  end

  def self.incr_requests(ip, path)
    Redis.current.multi do |multi|
      key = redis_key(ip, path)
      multi.incr(key)
      multi.expire(key, TIME_PERIOD_IN_SECONDS)
    end
  end

  def self.recent_requests(ip, path)
    Redis.current.get(redis_key(ip, path))
  end

  def self.block_requests(ip, seconds = TIME_PERIOD_IN_SECONDS)
    Redis.current.set(redis_key(ip, path), MAX_REQUESTS_PER_PERIOD, ex: seconds)
  end

  def self.redis_key(ip, path)
    path = path.starts_with?("/stocks/") ? path.split("/")[3] : path
    "#{BASE_REDIS_KEY}-#{ip}-#{path}-#{TIME_PERIOD_IN_SECONDS}-#{Time.current.to_i / TIME_PERIOD_IN_SECONDS}"
  end
end
