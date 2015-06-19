module RGen
  module Specs
    # This class is used to store spec exhibit information used to document IP
    class Exhibit
      attr_accessor :id, :type, :title, :description, :reference, :markup

      def initialize(id, type, options = {})
        @id = id
        @type = type
        @title = options[:title]
        @description = options[:description]
        @reference = options[:reference]
        @markup = options[:markup]
      end
    end
  end
end