require 'json'

module CustomA11yMatchers
  class BeAccessible

    def matches?(page)
      @page = page

      execute_test_script
      evaluate_test_results

      violations_count == 0
    end

    def failure_message
      message =         "Found #{violations_count} accessibility #{violations_count == 1 ? 'violation' : 'violations'}:\n"
      @results['violations'].each_with_index do |v, i|
        message +=      "  #{i+1}) #{v['help']}: #{v['helpUrl']}\n"
        v['nodes'].each do |n|
          n['target'].each do |t|
            message +=  "    #{t}\n"
          end
          message +=    "    #{n['html']}\n"
          message +=    "    #{n['failureSummary'].gsub(/\n/, "\n    ")}\n"
        end
      end
      message
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

    def execute_test_script
      @page.execute_script(script_for_execute)
    end

    def script_for_execute
      "dqre.a11yCheck(#{context_for_execute}, #{options_for_execute}, function(result){dqre.rspecResult = JSON.stringify(result);});"
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

    def evaluate_test_results
      # Tries #evaluate_script for Capybara, falls back to #execute_script for Watir
      results = @page.respond_to?(:evaluate_script) ? @page.evaluate_script(script_for_evaluate) : @page.execute_script(script_for_evaluate)
      @results = JSON.parse(results)
    end

    def script_for_evaluate
      "(function(){return dqre.rspecResult;})()"
    end

    def violations_count
      @results['violations'].count
    end
  end

  def be_accessible
    BeAccessible.new
  end
end