# frozen_string_literal: true

module RedisService
  EXP = 30.minutes.to_i

  def self.save!(uuid, data, exp = EXP)
    REDIS.setex(uuid, exp, data.to_json)
  end

  def self.fetch(uuid)
    raw = REDIS.get(uuid)
    raw && JSON.parse(raw)
  end

  def self.delete(uuid)
    REDIS.del(uuid)
  end

  def self.ping
    REDIS.ping
  end
end
