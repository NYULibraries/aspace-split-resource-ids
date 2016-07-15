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

def run_one_repo(repo)
  resource_ids = {}
  resource_ids[repo] = @aspace_session.get_resources(repo)
  resource_ids
end

def run_all_repos
  resource_ids = {}
  urls = @aspace_session.get_repo_urls

  urls.each { |url|
    resource_ids[url] = @aspace_session.get_resources(url)
  }
  resource_ids
end

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

def process_resource_ids(resource_ids)
  resource_ids.each_pair { |repo,resource_ids|
     resource_ids.each { |r|
       rec_id = @aspace_session.get_records(repo,r)
       if rec_id
         process_formatted_ids(repo, r, rec_id)
       end
     }
  }
end

def process_formatted_ids(repo, resource_id, rec_id)
  split_ids = split_resource(rec_id)
  h = update_hash(split_ids)
  puts "#{repo}/#{resource_id}: orig: #{rec_id} new: #{h}"
  LOG.info("#{repo}/#{resource_id}: orig: #{rec_id} new: #{h}")
  @aspace_session.update_record(repo,resource_id,h)
end

repo_arg = ARGV[0]
resource = ARGV[1]
file = "logs/#{Time.now.getutc.to_i}.txt"
LOG = Logger.new(file)
puts "Log is located here: #{file}"
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
@aspace_session = Session.new(url,password,repo,login)
resource_ids = {}
repo_url = "#{repo}/#{repo_arg}"
if repo_arg.nil? && resource.nil?
  resource_ids = run_all_repos
elsif repo_arg && resource.nil?
  resource_ids = run_one_repo(repo_url)
elsif repo_arg && resource
  rec_id = @aspace_session.get_records(repo_url,resource)
  process_formatted_ids(repo_url, resource, rec_id)
else
  LOG.error("Invalid argument")
end


if resource_ids
  process_resource_ids(resource_ids)
elsif rec_id
  process_formatted_ids(repo, resource, rec_id)
end
