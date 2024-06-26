# frozen_string_literal: true

require 'claide'

module Epuber
  class PlainInformative < StandardError
    include CLAide::InformativeError

    def message
      "[!] #{super}".ansi.red
    end
  end

  class Command < CLAide::Command
    require_relative 'command/build'
    require_relative 'command/compile'
    require_relative 'command/init'
    require_relative 'command/server'
    require_relative 'command/from_file'

    self.abstract_command = true
    self.command = 'epuber'
    self.version = VERSION
    self.description = 'Epuber, easy creating and maintaining e-book.'
    self.plugin_prefixes = plugin_prefixes + %w[epuber]

    def self.run(argv = [])
      super
    rescue Interrupt
      UI.error('[!] Cancelled')
    rescue StandardError => e
      UI.error!(e)
    end

    def initialize(argv)
      super

      UI.logger.verbose = verbose?
    end

    def run; end

    protected

    # @return [Epuber::Book::Book]
    #
    def book
      Config.instance.bookspec
    end

    # @return [void]
    #
    # @raise PlainInformative if no .bookspec file don't exists or there are too many
    #
    def verify_one_bookspec_exists!
      project_path = Config.instance.project_path
      bookspec_files = Config.find_bookspec_files(project_path)

      if bookspec_files.empty?
        raise PlainInformative, "No `.bookspec' found in the project directory (or in any parent folders)."
      end

      if bookspec_files.count > 1
        raise PlainInformative, "Multiple `.bookspec' found in directory (directory: #{project_path})"
      end
    end

    def write_lockfile
      return if Epuber::Config.test?

      Epuber::Config.instance.save_lockfile
    end

    def pre_build_checks
      Config.instance.warn_for_outdated_versions!

      # remove build caches if we are using different version of Epuber or Bade
      if !Config.instance.same_version_as_last_run? && File.exist?(Config.instance.working_path)
        UI.warning('Using different version of Epuber or Bade, removing all build caches')
        Config.instance.remove_build_caches
      end

      # ensure we are in the project directory
      if Dir.pwd != Config.instance.project_path
        UI.debug("Changing directory to project directory: #{Config.instance.project_path}")
        Dir.chdir(Config.instance.project_path)
      end
    end
  end
end
