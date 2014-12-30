require_relative '../command'

module Epuber
  class Command
    class Compile < Command
      self.summary = 'Compile targets into multiple epubs.'
      self.arguments = [
        CLAide::Argument.new('TARGETS', false, true)
      ]

      def self.options
        [
          ['--check', 'Performs additional validation on sources + checks result epub with epubcheck'],
        ].concat(super)
      end

      # @param argv [CLAide::ARGV]
      #
      def initialize(argv)
        @targets_names = argv.arguments!
        @should_check = argv.flag?('check', false)
        super(argv)
      end

      def validate!
        super
        verify_one_bookspec_exists!
        verify_all_targets_exists!
      end

      def run
        super
        require_relative '../compiler'

        puts "compiling book `#{book.file_path}`"

        targets.each do |target|
          compiler = Epuber::Compiler.new(book, target)

          build_dir = File.join(BASE_PATH, 'build', target.name.to_s)
          compiler.compile(build_dir, check: @should_check)
          archive_path = compiler.archive

          if @should_check
            system(%Q{epubcheck "#{archive_path}"})
          end
        end
      end

      private

      # @return [Array<Epuber::Book::Target>]
      #
      def targets
        @targets ||= (
          targets = @targets_names

          # when the list of targets is nil use them all
          if targets.empty?
            book.targets
          else
            targets.map { |target_name|
              book.target_named(target_name)
            }
          end
        )
      end

      def verify_all_targets_exists!
        index = targets.index { |t| t.nil? }
        help! "Not found target `#{@targets_names[index]}' in bookspec `#{@book.file_path}'" unless index.nil?
      end
    end
  end
end
