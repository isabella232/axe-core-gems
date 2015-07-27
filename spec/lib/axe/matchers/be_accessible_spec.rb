require 'timeout'
require 'axe/matchers/be_accessible'

module Axe::Matchers
  describe BeAccessible do
    let(:audit) { spy('audit') }
    let(:results) { spy('results') }
    before :each do
      subject.instance_variable_set :@audit, audit
    end

    describe "#matches?" do
      let(:page) { spy('page') }

      it "should run the audit against the page" do
        subject.matches?(page)
        expect(audit).to have_received(:run_against).with(page)
      end

      it "should save results" do
        allow(audit).to receive(:run_against).and_return(results)

        subject.matches? page

        expect( subject.instance_variable_get :@results ).to be results
      end

      it "should return results.passed" do
        allow(audit).to receive(:run_against).and_return(results)
        allow(results).to receive(:passed?).and_return(:passed)

        expect( subject.matches?(page) ).to be :passed
      end
    end

    describe "@results" do
      before :each do
        subject.instance_variable_set :@results, results
      end

      it "should be delegated #failure_message" do
        expect(results).to receive(:failure_message).and_return(:foo)
        expect(subject.failure_message).to eq :foo
      end

      it "should be delegated #failure_message_when_negated" do
        expect(results).to receive(:failure_message).and_return(:foo)
        expect(subject.failure_message_when_negated).to eq :foo
      end
    end

    describe "#failure_message" do


      # before :each do
      #   allow(page).to receive(:evaluate_script).and_return(results)
      # end

      # let(:results) { {
      #   "violations" => [ {
      #     "help" => "V1 help",
      #     "helpUrl" => "V1 url",
      #     "nodes" => [ {
      #       "target" => ["#target-1-1"],
      #       "html" => "V1 html",
      #       "any" => [ { "message" => "Fix from any 1" } ],
      #       "all" => [ { "message" => "Fix from all 1" } ]
      #     } ]
      #   }, {
      #     "help" => "V2 help",
      #     "helpUrl" => "V2 url",
      #     "nodes" => [ {
      #       "target" => ["#target-2-1", "#target-2-2"],
      #       "html" => "V2 html",
      #       "any" => [ { "message" => "Fix from any 2" } ],
      #       "all" => [ { "message" => "Fix from all 2" } ]
      #     } ]
      #   } ]
      # } }

      # it "should return formatted error message" do
      #   subject.matches?(page)
      #   subject.failure_message.tap do |message|
      #     expect(message).to include("Found 2 accessibility violations")

      #     expect(message).to include "V1 help", "V2 help"
      #     expect(message).to include "V1 url", "V2 url"

      #     expect(message).to include "V1 html", "V2 html"
      #     expect(message).to include "#target-1-1", "#target-2-1, #target-2-2"

      #     expect(message).to include "Fix from any 1", "Fix from all 1", "Fix from any 2", "Fix from all 2"
      #   end
      # end
    end

    describe "#within" do
      it "should be delegated to @audit" do
        subject.within(:foo)
        expect(audit).to have_received(:include).with(:foo)
      end
    end

    describe "#excluding" do
      it "should be delegated to @audit" do
        subject.excluding(:foo)
        expect(audit).to have_received(:exclude).with(:foo)
      end
    end

    describe "#for_tag" do
      it "should be delegated to @audit" do
        subject.for_tag(:foo)
        expect(audit).to have_received(:rules_by_tags)
      end

      it "should accept a single tag" do
        subject.for_tag(:foo)
        expect(audit).to have_received(:rules_by_tags).with([:foo])
      end

      it "should accept many tags" do
        subject.for_tag(:foo, :bar)
        expect(audit).to have_received(:rules_by_tags).with([:foo, :bar])
      end

      it "should accept an array of tags" do
        subject.for_tag([:foo, :bar])
        expect(audit).to have_received(:rules_by_tags).with([:foo, :bar])
      end

      it "should have the plural form #for_tags" do
        subject.for_tags(:foo, :bar)
        expect(audit).to have_received(:rules_by_tags).with([:foo, :bar])
      end
    end

    describe "#for_rule" do
      it "should be delegated to @audit" do
        subject.for_rule(:foo)
        expect(audit).to have_received(:run_only_rules)
      end

      it "should accept a single rule" do
        subject.for_rule(:foo)
        expect(audit).to have_received(:run_only_rules).with([:foo])
      end

      it "should accept many rules" do
        subject.for_rule(:foo, :bar)
        expect(audit).to have_received(:run_only_rules).with([:foo, :bar])
      end

      it "should accept an array of rules" do
        subject.for_rule([:foo, :bar])
        expect(audit).to have_received(:run_only_rules).with([:foo, :bar])
      end

      it "should have the plural form #for_rules" do
        subject.for_rules(:foo, :bar)
        expect(audit).to have_received(:run_only_rules).with([:foo, :bar])
      end
    end

    xdescribe "#with_options" do
      it "should pass the options string to the script" do
        test_options = '{these:{are:{my:"options"}}}'
        expect(page).to receive(:execute_script).with(script_for_execute('document', test_options))
        subject.with_options(test_options).matches?(page)
      end
    end

    private

    def script_for_execute(context='document', options={})
      "axe.a11yCheck(#{context}, #{options}, function(results){axe.rspecResult = results;});"
    end

    def script_for_evaluate
      "axe.rspecResult"
    end
  end
end
