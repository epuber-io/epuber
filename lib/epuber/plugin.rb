# frozen_string_literal: true

require_relative 'checker'
require_relative 'transformer'
require_relative 'compiler/file_types/source_file'


module Epuber
  class Plugin
    class PluginFile < Compiler::FileTypes::SourceFile
      # @return [Array]
      #
      attr_reader :instances

      # @param [String] relative_path path to plugin file (relative to project root)
      #
      def initialize(file_path)
        super(file_path)
        @instances = []

        eval(::File.read(file_path), binding, file_path) # rubocop:disable Security/Eval
      end

      # @param [Symbol] name  name of the plugin function
      # @param [Class] klass  class of what it should create
      #
      # @return nil
      #
      def self.plugin_instance_function(name, klass)
        define_method(name) do |source_type, *options, &block|
          checker_class = klass.class_for_source_type(source_type)
          checker = checker_class.new(source_type, *options, &block)
          instances << checker
          checker
        end
      end


      # Method for creating new instance of checker in packages
      #
      # @param [Symbol] source_type  source type of checker, see Checker#source_type
      # @param [Array<Symbol>] options list of other arguments, usually flags
      # @yield value for checking, depends on type of checker
      #
      # @return [Checker]
      #
      plugin_instance_function(:check, Checker)

      # Method for creating new instance of checker in packages
      #
      # @param [Symbol] source_type source type of transformer, see Transformer#source_type
      # @param [Array<Symbol>] options list of other arguments, usually flags
      # @yield value for checking, depends on type of checker
      #
      # @return [Transformer]
      #
      plugin_instance_function(:transform, Transformer)
    end


    # @return [String]
    #
    attr_reader :path

    # @return [Array<PluginFile>]
    #
    attr_reader :files

    # @param [String] path
    #
    def initialize(path)
      @path = path

      @files = if ::File.file?(path)
                 [PluginFile.new(path)]
               elsif ::File.directory?(path)
                 Dir.glob(File.expand_path('**/*.rb', path)).map do |file_path|
                   PluginFile.new(Config.instance.pretty_path_from_project(file_path))
                 end
               else
                 raise LoadError, "#{self}: Can't find anything for #{path}"
               end

      # expand abs_source_paths to every file
      @files.each do |file|
        file.abs_source_path = File.expand_path(file.source_path, Config.instance.project_path)
      end
    end

    # @param [Class] klass  base class of all instances
    #
    # @return [Array<CheckerTransformerBase>]
    #
    def instances(klass)
      files.map do |plugin_file|
        plugin_file.instances.select { |inst| inst.is_a?(klass) }
      end.flatten
    end

    # @return [Array<Checker>]
    #
    def checkers
      instances(Checker)
    end

    # @return [Array<Transformer>]
    #
    def transformers
      instances(Transformer)
    end
  end
end
