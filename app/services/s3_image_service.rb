require 'aws-sdk-s3'

class S3ImageService
    attr_reader :client, :bucket
  def initialize
    @client = Aws::S3::Client.new(
      access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
      secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key),
      region: Rails.application.credentials.dig(:aws, :region)
    )
    @bucket = Rails.application.credentials.dig(:aws, :bucket)
  end

def list_images(prefix = '')
  resp = @client.list_objects_v2(bucket: @bucket, prefix: prefix)
  
  resp.contents.map(&:key).reject do |key|
    key == prefix || key.ends_with?('/')
  end
end

  def image_url(key)
    signer = Aws::S3::Presigner.new(client: @client)
    signer.presigned_url(:get_object, bucket: @bucket, key: key, expires_in: 3600)
  end
end