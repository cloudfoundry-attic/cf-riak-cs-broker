require 'fog'
require 'fog/aws/requests/storage/acl_utils'
require 'nokogiri'

Fog::Storage::AWS.class_eval do
  class << self
    alias_method :hash_to_acl_without_stripping, :hash_to_acl

    def hash_to_acl_with_stripping(*args)
      doc = Nokogiri::XML.parse(hash_to_acl_without_stripping(*args))
      doc.xpath('//text()').each do |node|
        node.remove unless node.content =~ /\S/
      end
      doc.to_xml(indent: 0).gsub("\n", '')
    end

    def hash_to_acl(*args)
      hash_to_acl_with_stripping(*args)
    end
  end
end
