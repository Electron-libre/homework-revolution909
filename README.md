Dependencies 
============

* rvm 
* ruby 2.1 
* bundler

Installation
============

#Get sources# run` bundle install`# run` bundle exec ruby lib / revolution909.rb`

Usage 
=====


Search for repository 
=====================
=====================


GET / repositories ? q = {Github formated search terms}


results format :


    {
        "items": [{
            "full_name": "playframework/playframework",
            "href": "playframework/playframework"
        }, {
            "full_name": "feliperazeek/playframework-elasticsearch",
            "href": "feliperazeek/playframework-elasticsearch"
        }, {
            "full_name": "ReactiveMongo/Play-ReactiveMongo",
            "href": "ReactiveMongo/Play-ReactiveMongo"
        }
    ,...

     {
        }],
        "total_count": 404,
        "link": [{
            "href": "/repositories?q=playframework&page=2",
            "rel": "next",
            "page": ["2"]
        }, {
            "href": " /repositories?q=playframework&page=14",
            "rel": "last",
            "page": ["14"]
        }]
    }


* Link contains pagination links.
* Total count contains the number of repositories found
* Items contains the 30 first results search with their href 


