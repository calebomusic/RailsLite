require 'active_support/inflector'
require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, route_params)
    @req = req
    @res = res
    @params = configure_params(params)
  end

  # Merges query_params and body_params with route_params
  def configure_params(params)
    if req["rack.request.query_string"]
      params.merge!(req["rack.request.query_string"])
    end

    if req["rack.request.query_hash"]
      params.merge!(req["rack.request.query_string"])
    end

    params
  end
  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response ||= false
  end

  # Set the response status code and header
  def redirect_to(url)
    raise if already_built_response?
    @already_built_response = true

    @res["location"] = url
    @res.status = 302

    @session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise if already_built_response?
    @already_built_response = true

    @res['Content-Type'] = content_type
    @res.write(content)

    @session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller_name = self.class.to_s.underscore
    file_name = "views/#{controller_name}/#{template_name}.html.erb"
    read_file = File.read(file_name)
    erb = ERB.new(read_file).result(binding)

    render_content(erb, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)

    unless already_built_response?
      render(template_name)
    end
  end
end
