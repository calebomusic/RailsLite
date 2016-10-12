class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @action_name = action_name
    @controller_class = controller_class
    @pattern = pattern
    @http_method = http_method
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    return false if @pattern.match(req.path).to_s != req.path
    return false if @http_method.to_s != req.request_method.downcase
    true
  end

  # use pattern to pull out route params
  # instantiate controller and call controller action
  def run(req, res)
    if matches?(req)
      regex = @pattern.match(req.path)
      
      params = {}

      regex.names.each do |name|
        params[name] = regex[name]
      end

      controller = @controller_class.new(req, res, params)
      controller.invoke_action(action_name)
    end
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    @routes.each do |route|
      return route if route.pattern.match(req.path).to_s == req.path
    end
    nil
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    matched_route = match(req)
    if matched_route
      matched_route.run(req, res)
    else
      res.status = 404
    end
  end
end
