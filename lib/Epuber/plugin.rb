# encoding: utf-8

require_relative 'checker'


module Epuber
  class PluginFile
    # @return [String]
    #
    attr_reader :file_path

    # @return [Array]
    #
    attr_reader :instances

    def initialize(file_path)
      @file_path = file_path
      @instances = []

      eval(::File.read(file_path), binding, file_path)
    end


    # Method for creating new instance of checker in packages
    #
    # @param source_type [Symbol] source type of checker, see Checker#source_type
    # @param run_when [Symbol] when should this checker run, see Checker#run_when
    # @yield value for checking, depends on type of checker
    #
    # @return [Checker]
    #
    def check(source_type, run_when, &block)
      checker_class = Checker.class_for_source_type(source_type)
      checker = checker_class.new(source_type, run_when, &block)

      instances << checker

      checker
    end
  end

  class Plugin
    # @return [String]
    #
    attr_reader :path

    # @return [Array<PluginFile>]
    #
    attr_reader :files

    # @param path [String]
    #
    def initialize(path)
      @path = path

      @files = if ::File.file?(path)
                 [PluginFile.new(path)]
               else
                 raise NotImplementedError, 'Not implemented functionality of dir plugins'
               end
    end

    def checkers
      files.map do |plugin_file|
        plugin_file.instances.select { |inst| inst.is_a?(Checker) }
      end.flatten
    end
  end
end
