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
    http = EM::HttpRequest.new('https://api.github.com'+"/search/repositories?#{@params}").get
    parsed = MultiJson.load(http.response)
    search_result = parsed['items'].map {|item| {full_name: item['full_name'], href: item['full_name']} }
    return {items: search_result, total_count: parsed['total_count'], link: pagination_links(http)}
  end

  def pagination_links(http)
    link_header = http.response_header['LINK']
    link_header.gsub(/\<|\>|;|"/, '').split(",").map do |lnk|
      href, rel = lnk.split("rel=")
      {
        href: href.gsub(/https\:\/\/api\.github\.com\/search/),
        rel: rel,
        page: CGI.parse(URI.parse(href).query)['page']
      }
    end if link_header
  end

end

class Repository
  def initialize(id)
    @id = id
  end
  def statistics
    data = EM::HttpRequest.new('https://api.github.com'+"/repos/#{@id}/commits?page=1&per_page=100").get
    @parsed = MultiJson.load(data.response)
    committers = map_committers
    return {committers: committers , commits_count: @parsed.count} 
  end

  private

  def committers_commits
    @parsed.group_by { |commit| commit['committer']}
  end

  def map_committers
    committers_commits.map do |k,v|
      {committer: format_committer(k), commits: {count: v.count, dates: commit_timeline(v) }}
    end
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

  def min_max_dates
     map_block = Proc.new {|commit| commit['commit']['committer']['date']}
     @min_date ||= map_block.call @parsed.min_by(&map_block)
     @max_date ||= map_block.call @parsed.max_by(&map_block)
     [@min_date,@max_date]
  end


  def build_dates_array
    (DateTime.parse(min_max_dates[0]).to_date..DateTime.parse(min_max_dates[1]).to_date).map { |date| [date,0]}
  end

  
  def commit_timeline(v)
    ploted_timeline=   v.reduce(build_dates_array) do |timeline, commit|
        date = DateTime.parse(commit['commit']['committer']['date']).to_date
        timeline[timeline.find_index{|day| day[0] == date }][1] += 1
        timeline
    end
   return ploted_timeline 
  end

end

