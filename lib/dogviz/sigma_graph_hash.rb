require 'json'

module Dogviz
  class SigmaGraphHash < Hash
    def initialize(hash)
      hash.each { |k, v|
        self[k] = v
      }
    end

    def output(type_to_filename)
      raise StandardError.new('must provide hash (json: somejsonfilename.json)') unless type_to_filename.is_a?(Hash)
      filename = get_json_filename(type_to_filename)
      File.write filename, to_json
    end

    private

    def get_json_filename(type_to_filename)
      type = type_to_filename.keys.first
      raise StandardError.new('json output only supported') unless type == :json
      type_to_filename[type]
    end
  end
end