require 'logger'
require "faraday"
require "uri"
require 'faraday_middleware'
require_relative 'check_errors'
include CheckErrors

class Session
  attr_reader :url, :password, :repo_url, :login_url, :regexp
  ERROR_PATH = "errors"
  def initialize(url, password, resource_url, login_url, regexp)
    @regexp = regexp
    @url = url
    @password = password
    @repo_url = repo_url
    @login_url = login_url
    @conn = aspace_connect
    @rsp = aspace_login
    @session = get_session
  end

  def update_record(repo, aspace_res_id, id_hash)
    @updated_record = @record.merge(id_hash)
    response = put_record(repo,aspace_res_id)
    if response.success?
      msg = response.body['status']
      LOG.info("#{msg}: #{repo}/#{aspace_res_id}")
    else
      # writing out the file for further investigation
      gen_json_files(aspace_res_id)
      err = response.body['error']
      LOG.error("Problem updating #{repo}/#{aspace_res_id}")
      LOG.info("File has been written out for further investigation: #{@filename}")
      LOG.error("#{response.body}")
    end
  end

  def get_repo_urls
    rec = get_repo
    payload = rec.body
    if rec.success?
      urls = []
      payload.each { |data|
        repo_code = data['repo_code']
        urls << data['uri'] if CONFIG['repositories'].include?(repo_code)
      }
      urls
    else
      CheckErrors.handle_errors(export)
    end
  end

  def get_resources(repo)
    rec = get_resource_ids(repo)
    if rec.success?
      id = rec.body
    else
      CheckErrors.handle_errors(rec)
    end
  end
  def get_records(repo, resource_id)
    rec = get_resource_records(repo, resource_id)
    if rec.success?
      @record = rec.body
      process_ids(repo, resource_id)
    else
      CheckErrors.handle_errors(rec)
    end
  end



  private
  def gen_json_files(resource_id)
    @filename = "#{ERROR_PATH}/#{resource_id}.json"
    File.delete(@filename) if File.exist?(@filename)
    begin
      file = File.open(@filename,'w')
      file.write(@updated_record)
    rescue IOError => e
      CheckErrors.handle_errors(e)
    ensure
      file.close unless file.nil?
    end

  end

  def aspace_connect
    Faraday.new(:url => @url) do |req|
      req.options.timeout = 3600
      req.request :json
      req.response :json, :content_type => /\bjson$/
      req.adapter :net_http

    end
  end

  def aspace_login
    @conn.post do |req|
      req.url @login_url
      req.params['password'] = @password
    end
  end

  def get_session
    if @rsp.success?
      LOG.info("Logged in")
      @rsp.body['session']
    else
      CheckErrors.handle_errors("Problem with login: #{@rsp.body}")
    end
  end

  def get_resource_records(repo, id)
    resource_url = "#{repo}/resources/#{id}"
    @conn.get do |req|
      req.url resource_url
      req.headers['X-ArchivesSpace-Session'] = @session
    end
  end

  def get_resource_ids(repo)
    resource_url = "#{repo}/resources"
    @conn.get do |req|
      req.url resource_url
      req.headers['X-ArchivesSpace-Session'] = @session
      req.params['all_ids'] = true
    end
  end

  def get_repo
    @conn.get do |req|
      req.url "/repositories"
      req.headers['X-ArchivesSpace-Session'] = @session
    end
  end

  def put_record(repo,id)
      @conn.post do |req|
        req.url "#{repo}/resources/#{id}"
        req.headers['X-ArchivesSpace-Session'] = @session
        req.body = @updated_record
        #req.body = record
      end
  end
  def process_ids(repo, resource_id)
    result = nil
    unwanted = /[\/|-|,]/
    ids = []
    for i in 0..3
      ids << @record["id_#{i}"]
    end
    ids.compact!
    ids.each { |id|
      if @regexp.match(id) and not(unwanted.match(id))
        result = ids
      end
    }
    if result.nil?
      LOG.info("Skipping #{repo}/#{resource_id}, ids: #{ids.to_s}")
    else
      LOG.info("Processing #{repo}/#{resource_id}")
    end

    # returning a string unless result is nil
    result.join("") unless result.nil?

  end
end
