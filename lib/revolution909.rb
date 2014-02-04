$: << File.dirname(__FILE__)+'/../lib'
require 'bundler'
require 'json'
require 'revolution909/router'
require 'revolution909/config'
require 'goliath'
require 'em-synchrony/em-http'
require 'pry'

class Revolution909 < Goliath::API
  use Goliath::Rack::Params
  use Goliath::Rack::Formatters::JSON
  use Goliath::Rack::Render

  def response(env)
    begin
      result = ::Router.new(env[Goliath::Request::REQUEST_PATH],env[Goliath::Request::REQUEST_METHOD],env['QUERY_STRING']).route
    rescue Exception => exception
      [404,{ "Access-Control-Allow-Origin" => "*"}, exception.message]
    else  
      response = result
      [200,{ "Access-Control-Allow-Origin" => "*"},response]
    end
  end

end

class Repositories
  def initialize(params)
    @params = params
  end


  def search
    EM::HttpRequest.new(Config.github_api+"/search/repositories?#{@params}+in:name").get.response
  end
end

class Repository
  def initialize(id)
    @id = id
  end
  def statistics
    data = EM::HttpRequest.new(Config.github_api+"/repos/#{@id}/commits?page=1&per_page=100").get.response
    parsed = JSON.parse(data)
    grouped_data = parsed.group_by { |commit| commit['author']}
    committers = map_committers(grouped_data)
    commits_dates = parsed.map {|c| c['commit']['committer']['date']}.sort
    return {committers: committers, commits_dates: commits_dates} 
  end

  private

  def map_committers(data)
    data.map{|k,v| {committer: format_committer(k), commits: v.count}}
  end

  def format_committer(committer)
    lformat = ->(l,au) {{login: l, avatar_url:au}}
    case committer
    when nil
      lformat.call('null', 'null')
    else
      lformat.call(committer['login'],committer['avatar_url'])
    end
  end


end

