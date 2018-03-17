module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Completion < Base
          def process
            again = false
            host.synchronize do
              begin
                kind_map = {
                  'Class' => 7,
                  'Constant' => 21,
                  'Field' => 5,
                  'Keyword' => 14,
                  'Method' => 2,
                  'Module' => 9,
                  'Property' => 10,
                  'Variable' => 6
                }
                if host.changing?(params['textDocument']['uri'])
                  set_result(
                    isIncomplete: false,
                    items: []
                  )
                else
                  source = host.read(params['textDocument']['uri'])
                  code_map = Solargraph::CodeMap.from_source(source, host.api_map)
                  offset = code_map.get_offset(params['position']['line'], params['position']['character'])
                  range = code_map.symbol_range_at(offset)
                  suggestions = code_map.suggest_at(offset)
                  items = suggestions.map do |sugg|
                    detail = ''
                    detail += "(#{sugg.arguments.join(', ')}) " unless sugg.arguments.empty?
                    detail += "=> #{sugg.return_type}" unless sugg.return_type.nil?
                    result = {
                      label: sugg.label,
                      kind: kind_map[sugg.kind],
                      data: {
                        identifier: sugg.location || sugg.path
                      },
                      textEdit: {
                        range: range,
                        newText: sugg.label
                      }
                    }
                    result[:detail] = detail unless detail.empty?
                    result
                  end
                  suggestion_map = {}
                  suggestions.each do |s|
                    suggestion_map[s.location || s.path] = s
                  end
                  host.resolvable = suggestion_map
                  set_result(
                    isIncomplete: false,
                    items: items
                  )
                end
              rescue Exception => e
                if e.message.include?('Invalid offset') #and host.changing?(params['textDocument']['uri'])
                  STDERR.puts "Changing. Try again"
                  again = true
                else
                  STDERR.puts "#{e}"
                  STDERR.puts "#{e.backtrace}"
                  set_error Solargraph::LanguageServer::ErrorCodes::INTERNAL_ERROR, e.message
                end
              end
            end
            if again
              sleep 0.01
              process
            end
          end
        end
      end
    end
  end
end