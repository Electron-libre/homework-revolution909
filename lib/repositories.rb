
module Repositories
  
  def initialize(params)
    @params = params
  end

  def search
    http = EM::HttpRequest.new('https://api.github.com'+"/search/repositories?#{@params}").get
    parsed = MultiJson.load(http.response)
    search_result = parsed['items'].map {|item| {full_name: item['full_name'], href: item['full_name']} }
    return {items: search_result, total_count: parsed['total_count']}
  end
end
