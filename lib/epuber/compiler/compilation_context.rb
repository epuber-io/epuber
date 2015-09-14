# encoding: utf-8


module Epuber
  class Compiler
    class CompilationContext
      # @return [Epuber::Book]
      #
      attr_reader :book

      # @return [Epuber::Book::Target]
      #
      attr_reader :target

      # @return [Epuber::Compiler::FileResolver]
      #
      attr_accessor :file_resolver

      # @return [Array<Epuber::Plugin>]
      #
      def plugins
        @plugins ||= @target.plugins.map do |path|
          Plugin.new(File.expand_path(path, Config.instance.project_path))
        end
      end

      # @param [Class] klass class of thing you want to perform (Checker or Transformer)
      # @param [Symbol] source_type source type of that thing (Checker or Transformer)
      #
      # @yield
      # @yieldparam [Epuber::CheckerTransformerBase] instance of checker or transformer
      #
      # @return nil
      #
      def perform_plugin_things(klass, source_type)
        plugins.each do |plugin|
          plugin.instances(klass).each do |instance|
            # @type [Epuber::CheckerTransformerBase] instance

            next if instance.source_type != source_type
            next if instance.options.include?(:run_only_before_release) && release_build

            yield instance
          end
        end
      end


      #########

      # @return [Bool]
      #
      attr_accessor :should_check

      # @return [Bool]
      #
      attr_accessor :should_write

      # @return [Bool]
      #
      attr_accessor :release_build


      def initialize(book, target)
        @book = book
        @target = target
      end
    end
  end
end
