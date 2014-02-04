$: << File.dirname(__FILE__)+'/../lib'
require 'rubygems'
require 'bundler/setup'
require 'revolution909/router'
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
      [200,{ "Access-Control-Allow-Origin" => "*"},result]
    end
  end
end


class Repositories
  def initialize(params)
    @params = params
  end

  def search
    http = EM::HttpRequest.new('https://api.github.com'+"/search/repositories?#{@params}+in:name").get
    parsed = MultiJson.load(http.response)
    search_result = parsed['items'].map {|item| {full_name: item['full_name'], href: item['full_name']} }
    return {items: search_result, total_count: parsed['total_count']}
  end
end

class Repository
  def initialize(id)
    @id = id
  end
  def statistics
    data = EM::HttpRequest.new('https://api.github.com'+"/repos/#{@id}/commits?page=1&per_page=100").get
    parsed = MultiJson.load(data.response)
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

