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
  arr = rec_id.split(/\W/)
  id_array = arr.reject { |s| s.nil? || s.strip.empty? }
end

file = "logs/#{Time.now.getutc.to_i}.txt"
LOG = Logger.new(file)
begin
  config_file = "config.yml"
  CONFIG = YAML.load_file(config_file)
rescue
  err = "#{$!}"
  CheckErrors.handle_errors(err)
end
mode = %w(local dev stage)
user = CONFIG['user']
password = CONFIG['password']
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
r = aspace_session.get_records('/repositories/3','244')
split_ids = split_resource(r) if r
output_ids =  split_ids.to_s if split_ids

# do for all records
=begin
resource_ids.each_pair { |repo,resource_ids|
   resource_ids.each { |r|
     rec_id = aspace_session.get_records(repo,r)
     split_ids = split_resource(rec_id) if rec_id
     output_ids =  split_ids.to_s if split_ids
     LOG.info("#{repo}/#{r}: #{output_ids}")
     #aspace_session.update_record(repo, resource_id,rec_id)
   }

}
=end
