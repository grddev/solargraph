module Solargraph
  module Pin
    class MethodParameter < Base
      include Localized

      attr_reader :block

      def initialize location, namespace, name, docstring, block
        super(location, namespace, name, docstring)
        @block = block
        @presence = block.location.range
      end

      def completion_item_kind
        Solargraph::LanguageServer::CompletionItemKinds::VARIABLE
      end

      def return_type
        if @return_type.nil? and !block.docstring.nil?
          found = nil
          params = block.docstring.tags(:param)
          params.each do |p|
            next unless p.name == name
            found = p
          end
          @return_type = found.types[0] unless found.nil? or found.types.nil?
        end
        @return_type
      end
    end
  end
end
