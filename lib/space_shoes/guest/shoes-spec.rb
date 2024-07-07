# frozen_string_literal: true

require "minitest"

module SpaceShoes
  class ShoesSpec
    class << self
      attr_accessor :test_class
    end

    def self.run_shoes_spec_test_code(code, class_name: nil, test_name: nil)
      if @shoes_spec_init
        raise Shoes::Errors::MultipleShoesSpecRunsError, "SpaceShoes can only run a single Shoes spec per process!"
      end
      @shoes_spec_init = true

      class_name ||= ENV["SHOES_MINITEST_CLASS_NAME"] || "TestShoesSpecCode"
      test_name ||= ENV["SHOES_MINITEST_METHOD_NAME"] || "test_shoes_spec"

      test_class = Class.new(SpaceShoes::ShoesSpecTest)
      ShoesSpec.test_class = test_class
      Object.const_set(Scarpe::Components::StringHelpers.camelize(class_name), test_class)
      test_name = "test_" + test_name unless test_name.start_with?("test_")
      test_class.class_eval(<<~CLASS_EVAL)
        attr_reader :reporter
        attr_reader :summary

        def self.run(reporter, options)
          @reporter = reporter # When run, save a copy of reporter
          @summary = reporter.reporters.grep(Minitest::SummaryReporter).first
          super
        end

        def self.results
          {
            cases: @summary.count,
            assertions: @summary.assertions, # number of assertions
            failures: @summary.failures,     # number of failures
            errors: @summary.errors,         # number of errors
            skips: @summary.skips,           # number of skips
            results: @summary.results,       # actual failure exception objects
          }
        end

        def #{test_name}
#{code}
        end
      CLASS_EVAL
    end
  end
end

# For now we send most events at the Scarpe layer. It would be quite sensible
# to send browser events rather than Scarpe events, but it will also take a lot
# more code to do it. We'll get there.

class SpaceShoes::ShoesSpecTest < Minitest::Test
  Shoes::Drawable.drawable_classes.each do |drawable_class|
    finder_name = drawable_class.dsl_name

    define_method(finder_name) do |*args|
      drawables = Shoes::App.find_drawables_by(drawable_class, *args)

      raise Shoes::Errors::MultipleDrawablesFoundError, "Found more than one #{finder_name} matching #{args.inspect}!" if drawables.size > 1
      raise Shoes::Errors::NoDrawablesFoundError, "Found no #{finder_name} matching #{args.inspect}!" if drawables.empty?

      SpaceShoes::ShoesSpecProxy.new(drawables[0])
    end
  end

  def drawable(*specs)
    drawables = Shoes::App.find_drawables_by(*specs)
    raise Shoes::Errors::MultipleDrawablesFoundError, "Found more than one #{finder_name} matching #{args.inspect}!" if drawables.size > 1
    raise Shoes::Errors::NoDrawablesFoundError, "Found no #{finder_name} matching #{args.inspect}!" if drawables.empty?
    SpaceShoes::ShoesSpecProxy.new(drawables[0])
  end
end

class SpaceShoes::ShoesSpecProxy
  attr_reader :obj
  attr_reader :linkable_id
  attr_reader :display

  def initialize(obj)
    @obj = obj
    @linkable_id = obj.linkable_id
    @display = ::Shoes::DisplayService.display_service.query_display_drawable_for(obj.linkable_id)
  end

  def method_missing(method, ...)
    if @obj.respond_to?(method)
      self.singleton_class.define_method(method) do |*args, **kwargs, &block|
        @obj.send(method, *args, **kwargs, &block)
      end
      send(method, ...)
    else
      super # raise an exception
    end
  end

  JS_EVENTS = [:click, :hover, :leave]
  JS_EVENTS.each do |event|
    define_method("trigger_#{event}") do |*args, **kwargs|
      ::Shoes::DisplayService.dispatch_event(event.to_s, @linkable_id, *args, **kwargs)
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @obj.respond_to_missing?(method_name, include_private)
  end
end
