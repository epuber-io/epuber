# frozen_string_literal: true

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

      # This will track source files regardless of current target
      #
      # @return [Epuber::Compiler::FileDatabase]
      #
      attr_reader :source_file_database

      # This will track source files depend on current target
      #
      # @return [Epuber::Compiler::FileDatabase]
      #
      attr_reader :target_file_database

      # @return [Array<Epuber::Plugin>]
      #
      def plugins
        @plugins ||= @target.plugins.map do |path|
          plugin = Plugin.new(path)
          plugin.files.each do |file|
            file_resolver.add_file(file)
          end
          plugin
        rescue LoadError => e
          UI.error "Can't find plugin at path #{path}, #{e}"
        end.compact
      end

      # @param [Class] klass class of thing you want to perform (Checker or Transformer)
      # @param [Symbol] source_type source type of that thing (Checker or Transformer)
      # @param [String] processing_time_step_name name of step for processing time
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
            next if instance.options.include?(:run_only_before_release) && !release_build

            location = instance.block.source_location.map(&:to_s).join(':')
            message = "performing #{source_type.inspect} from plugin #{location}"
            UI.print_step_processing_time(message) do
              yield instance
            end
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

      # @return [Bool]
      #
      attr_accessor :use_cache

      # @return [Bool]
      #
      attr_accessor :verbose

      def verbose?
        verbose
      end

      def debug?
        !release_build
      end

      def incremental_build?
        use_cache
      end

      def release_build?
        release_build
      end

      def initialize(book, target)
        @book = book
        @target = target

        @source_file_database = FileDatabase.new(Config.instance.file_stat_database_path)
        @target_file_database = FileDatabase.new(Config.instance.target_file_stat_database_path(target))
      end
    end
  end
end
