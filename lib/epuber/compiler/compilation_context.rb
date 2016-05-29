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
          begin
            plugin = Plugin.new(File.expand_path(path, Config.instance.project_path))
            plugin.files.each do |file|
              file_resolver.add_file(file)
            end
            plugin
          rescue LoadError
            UI.error "Can't find plugin at path #{path}"
          end
        end.compact
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
            next if instance.options.include?(:run_only_before_release) && !release_build

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

      def initialize(book, target)
        @book = book
        @target = target

        @source_file_database = FileDatabase.new(Config.instance.file_stat_database_path)
        @target_file_database = FileDatabase.new(Config.instance.target_file_stat_database_path(target))
      end
    end
  end
end
