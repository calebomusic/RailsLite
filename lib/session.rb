require 'json'
require 'byebug'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    @cookies ||= {}
    cookie = req.cookies["_rails_lite_app"]
    if cookie
      cookie =  JSON.parse(cookie)
      key = cookie.keys[0]
      val = cookie.values[0]
      @cookies[key] = val
    end
  end

  def [](key)
    @cookies[key]
  end

  def []=(key, val)
    @cookies[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    saved_cookies = @cookies.to_json
    res.set_cookie("_rails_lite_app", saved_cookies)
  end
end
