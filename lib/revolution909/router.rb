class Router
  def initialize(path, verb, params)
    p verb + ' ' + path
    @path = path
    @verb = verb
    @params = params
  end

  def route
    case @path
    when '/repositories'
      Repositories.new(@params).search
    when /\/repositories\/(.*)\/statistics/
      Repository.new($1).statistics
    else
     raise "path #{@path} has no registered route"
    end
  end

end

