require_relative '../command'

module Epuber
  class Command
    class Compile < Command
      self.summary = 'Compile targets into epub.'
      self.arguments = [
        CLAide::Argument.new('TARGETS', false, true)
      ]

      # @param argv [CLAide::ARGV]
      #
      def initialize(argv)
        @targets_names = argv.arguments!
        super(argv)
      end

      def validate!
        verify_one_bookspec_exists!
        verify_all_targets_exists!
      end

      def run
        require_relative '../compiler'

        puts "compiling book `#{book.file_path}`"

        targets.each do |target|
          compiler = Epuber::Compiler.new(book, target)
          compiler.compile(File.join(BASE_PATH, 'build', target.name.to_s))
          compiler.archive
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
