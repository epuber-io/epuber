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
    # @param type [Symbol] type of checker, see #type
    # @param configuration [Symbol] configuration for this checker, see #configuration
    # @yield value for checking, depends on type of checker
    #
    # @return [Checker]
    #
    def check(type, configuration, &block)
      checker_class = Checker.checker_class_for_type(type)
      checker = checker_class.new(type, configuration, &block)

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
        plugin_file.instances.select { |inst| inst.class < Checker }
      end.flatten
    end
  end
end
