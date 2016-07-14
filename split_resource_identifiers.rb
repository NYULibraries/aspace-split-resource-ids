## get download to work. Log
require 'rubygems'
require 'bundler/setup'
require 'pry'
require 'multi_json'
require 'yaml'
require 'logger'
require_relative 'lib/session'
require_relative 'lib/check_errors'
include CheckErrors

def split_resource(rec_id)
  right_ids = []
  rec_id.each { |id|
    arr = id.split(/\W/)
    formatted_id = arr.reject { |s| s.nil? || s.strip.empty? }
    right_ids << formatted_id
  }
  right_ids.flatten
end

def update_hash(ids)
  id_hash = {}
  position = 0
  stuff = []
  ids.each { |i|
    if position < 3
      id_hash["id_#{position}"] = i
    else
      stuff << i
    end
    position = position + 1
  }
  id_hash['id_3'] = stuff.join("") unless stuff.empty?
  id_hash
end

file = "logs/#{Time.now.getutc.to_i}.txt"
LOG = Logger.new(STDOUT)
begin
  config_file = "config.yml"
  CONFIG = YAML.load_file(config_file)
rescue
  err = "#{$!}"
  CheckErrors.handle_errors(err)
end
mode = %w(local dev stage)
pass_mode = %w(local_test local_prod)
user = CONFIG['user']
password = CONFIG['password'][pass_mode[0]]
url = CONFIG['aspace'][mode[0]]
login = "/users/#{user}/login"
repo = "/repositories"
aspace_session = Session.new(url,password,repo,login)
urls = aspace_session.get_repo_urls
resource_ids = {}
urls.each { |url|
  resource_ids[url] = aspace_session.get_resources(url)
}

#count = 0
#repo = resource_ids.keys[0]
#resource_id = resource_ids['repo'][2]
#r = aspace_session.get_records('/repositories/3','141')
#r = aspace_session.get_records('/repositories/3','244')
#split_ids = split_resource(r) if r
#output_ids =  split_ids.to_s if split_ids

# do for all records

resource_ids.each_pair { |repo,resource_ids|
   resource_ids.each { |r|
     rec_id = aspace_session.get_records(repo,r)
     if rec_id
       split_ids = split_resource(rec_id)
       h = update_hash(split_ids)
       #puts "#{repo}/#{r}: orig: #{rec_id} new: #{h}"
     end

   }

}
