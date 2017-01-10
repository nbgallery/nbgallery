require 'json'
require 'httmultiparty'

# Client library for command line testing
class GalleryClient
  include HTTMultiParty
  format(:json)
  headers('Accept' => 'application/json')
  base_uri(ENV['GALLERY_BASE_URI']) if ENV['GALLERY_BASE_URI']

  # Exception class for failed requests
  class Exception < RuntimeError
    attr_reader :json
    def initialize(message, json=nil)
      super(message)
      @json = json
    end
  end

  class << self
    def stage(filename, params={})
      params = {
        file: File.new(filename),
        agree: true
      }.merge(params)
      response = post('/stages', body: params)
      raise Exception.new('stage failed', response.parsed_response) unless
        response.code == 201
      response['staging_id']
    end

    def preprocess(staging_id)
      get("/stages/#{staging_id}/preprocess").parsed_response
    end

    def upload(staging_id, params={})
      params = {
        staging_id: staging_id,
        agree: true,
        title: staging_id,
        description: 'No description provided'
      }.merge(params)
      response = post('/notebooks', body: params)
      raise Exception.new('upload failed', response.parsed_response) unless
        response.code == 200 || response.code == 201
      response['uuid']
    end

    def update(uuid, staging_id, params={})
      params = {
        staging_id: staging_id,
        agree: true
      }.merge(params)
      response = patch("/notebooks/#{uuid}", body: params)
      raise Exception.new('update failed', response.parsed_response) unless
        response.code == 200
      response['uuid']
    end
  end
end
