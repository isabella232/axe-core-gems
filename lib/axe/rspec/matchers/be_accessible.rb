require 'json'
require 'forwardable'
require 'axe/javascript_library'
require 'axe/page'
require 'axe/api'
require 'ostruct'

module Axe
  module RSpec
    module Matchers
      LIBRARY_IDENTIFIER = "axe"
      RESULTS_IDENTIFIER = LIBRARY_IDENTIFIER + ".rspecResult"

      class BeAccessible
        extend Forwardable

        def_delegator :@results, :failure_message
        def_delegator :@results, :failure_message, :failure_message_when_negated

        def initialize
          @js_lib = JavaScriptLibrary.new
        end

        def matches?(page)
          @page = Page.new(page)

          inject_axe_lib
          run_accessibility_audit
          parse_audit_results

          @results.passed?
        end

        def within(inclusion)
          @inclusion = inclusion
          self
        end

        def excluding(exclusion)
          @exclusion = exclusion
          self
        end

        def for_tag(tag)
          tags = tag.is_a?(Array) ? tag : tag.split(/, ?/)
          @options = "{runOnly:{type:\"tag\",values:#{tags.to_json}}}"
          self
        end
        alias :for_tags :for_tag

        def for_rule(rule)
          rules = rule.is_a?(Array) ? rule : rule.split(/, ?/)
          @options = "{runOnly:{type:\"rule\",values:#{rules.to_json}}}"
          self
        end
        alias :for_rules :for_rule

        def with_options(options)
          @options = options
          self
        end

        private

        def inject_axe_lib
          @js_lib.inject_into @page
        end

        def run_accessibility_audit
          @page.execute(script_for_execute)
        end

        def script_for_execute
          "#{LIBRARY_IDENTIFIER}.a11yCheck(#{context_for_execute}, #{options_for_execute}, function(results){#{RESULTS_IDENTIFIER} = results;});"
        end

        def context_for_execute
          return formatted_include if @exclusion.nil?
          return formatted_exclude if @inclusion.nil?
          formatted_include_exclude
        end

        def formatted_include
          if @inclusion.is_a?(Array) || (@inclusion.is_a?(String) && @inclusion.include?(","))
            "{include:[#{wrapped_inexclusion(@inclusion)}]}"
          else
            @inclusion ? "'#{@inclusion}'" : "document"
          end
        end

        def formatted_exclude
          "{include:document,exclude:[#{wrapped_inexclusion(@exclusion)}]}"
        end

        def formatted_include_exclude
          "{include:[#{wrapped_inexclusion(@inclusion)}],exclude:[#{wrapped_inexclusion(@exclusion)}]}"
        end

        def wrapped_inexclusion(input)
          input = input.split(/, ?/) if input.is_a?(String)
          input.map { |n| Array(n).to_json }.join(",")
        end

        def options_for_execute
          @options || 'null'
        end

        def parse_audit_results
          @results = API::Results.from_hash audit_results
        end

        def audit_results
          @page.wait_until { @page.evaluate(RESULTS_IDENTIFIER) }
        end
      end

      def be_accessible
        BeAccessible.new
      end
    end
  end
end