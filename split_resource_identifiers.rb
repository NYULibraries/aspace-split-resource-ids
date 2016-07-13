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

def download(rec)
    filename = "#{@resource_id}_marc.xml"
    begin
      LOG.info("Resource #{@resource_id} found")
      File.delete(filename) if File.exist?(filename)
      file = File.open(filename, "w")
      file.write(rec)
      LOG.info("Resource #{@resource_id} downloaded to #{filename}")
    rescue IOError => e
      CheckErrors.handle_errors(e)
    ensure
      file.close unless file.nil?
    end

  unless File.exist?(filename)
    CheckErrors.handle_errors("File must exist: #{filename}")
  end
end


LOG = Logger.new(STDOUT)
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
resource = "repositories/#{@repo_id}/resources/#{@resource_id}"
aspace_session = Session.new(url,password,repo,login)
urls = aspace_session.get_repo_urls
resource_ids = {}
urls.each { |url|
  resource_ids[url] = aspace_session.get_resources(url)
}
count = 0
repo = resource_ids.keys[0]
resource_id = resource_ids[repo][10]
r = aspace_session.get_records(repo,resource_id)
s = r.split(/\W/)
puts s
# do for all records
#resource_ids.each_pair { |repo,resource_id|
    #r = aspace_session.get_resource_records(repo,resource_id)   unless count == 1

#}
