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

def update_hash(ids)
  id_hash = {}
  size = ids.size - 1
  for i in 0..size
    id_hash["id_#{i}"] = ids[i]
  end
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
  ids = process_ids(rec_id)
  h = update_hash(ids)
  LOG.info("#{repo}/#{resource_id}: orig: #{rec_id} new: #{h}")
  @aspace_session.update_record(repo,resource_id,h)
end

def process_ids(str,ids = [], count = 0)
  match_string = str.partition(REGEXP)
  is_empty = match_string.join("").empty?
  if count <= 2 && not(is_empty)
    ids << match_string[0]
    count = count + 1
    process_ids(match_string[2], ids, count)
  else
    ids << match_string.join("") unless is_empty
  end
  ids
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
password = CONFIG['password'][pass_mode[1]]
url = CONFIG['aspace'][mode[0]]
login = "/users/#{user}/login"
repo = "/repositories"
REGEXP = /[\.|\s]/
@aspace_session = Session.new(url,password,repo,login,REGEXP)
resource_ids = {}
repo_url = "#{repo}/#{repo_arg}"
if repo_arg.nil? && resource.nil?
  resource_ids = run_all_repos
elsif repo_arg && resource.nil?
  resource_ids = run_one_repo(repo_url)
elsif repo_arg && resource
  rec_id = @aspace_session.get_records(repo_url,resource)
  process_formatted_ids(repo_url, resource, rec_id) if rec_id
else
  LOG.error("Invalid argument")
end


if resource_ids
  process_resource_ids(resource_ids)
elsif rec_id
  process_formatted_ids(repo, resource, rec_id)
end
