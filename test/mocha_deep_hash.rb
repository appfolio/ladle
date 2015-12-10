require 'mocha/parameter_matchers/base'
require 'hashdiff'
require 'erb'

module Mocha
  module ParameterMatchers

    # Matches +Hash+ using HashDiff, printing out differences on failure.
    #
    # @overload def deep_hash(expected)
    #   @param [Object] expected hash.
    #
    # @return [DeepHash] parameter matcher.
    #
    # @see Expectation#with
    #
    # @example Actual parameter contains expected entry supplied as key and value.
    #   object = mock()
    #   object.expects(:method_1).with(deep_hash({a: 'blah'})
    #   object.method_1({a: 'blah'})
    #   # no error raised
    #
    # @example Actual parameter does not contain expected entry supplied as key and value.
    #   object = mock()
    #   object.expects(:method_1).with(deep_hash({a: 'blah'})
    #   object.method_1({b: 'blah'})
    #   # error raised, because method_1 was not called with a Hash matching {a: 'blah'}
    #
    def deep_hash(expected)
      DeepHash.new(expected)
    end

    # Parameter matcher which matches when actual parameter contains expected +Hash+ entry.
    class DeepHash < Base

      def initialize(expected)
        @expected = expected
        @differences = []
      end

      def matches?(available_parameters)
        parameter = available_parameters.shift

        @differences = HashDiff.diff(@expected, parameter)

        @differences == []
      end

      TEMPLATE = <<-ERB
      deep_hash(<%= @expected.mocha_inspect %>)
      Differences:
        <% @differences.each do |difference| %>
        <%= difference.inspect %>
        <% end %>
      ERB

      def mocha_inspect
        rb_balls = ERB.new(TEMPLATE)
        rb_balls.result(binding)
      end
    end
  end
end
