# frozen_string_literal: true

require_relative '../../spec_helper'

module Epuber
  class Command
    describe Init do
      include FakeFS::SpecHelpers

      it "inits empty folder" do
        FakeFS::FileSystem.clone(Templates::DIR)

        working_dir = '/app'
        Dir.mkdir(working_dir)
        Dir.chdir(working_dir)

        expect(Dir.entries(".")).to contain_exactly '.', '..'

        argv = CLAide::ARGV.new(['book_name'])
        init = Init.new(argv)
        init.run

        expect(Dir.entries(".")).to contain_exactly '.', '..',
                                                    '.gitignore',
                                                    'book_name.bookspec',
                                                    'book_name.sublime-project',
                                                    'images',
                                                    'fonts',
                                                    'styles',
                                                    'text'
      end

      it "inits folder with .gitignore" do
        FakeFS::FileSystem.clone(Templates::DIR)

        working_dir = '/app'
        Dir.mkdir(working_dir)
        Dir.chdir(working_dir)

        gitignore_contents = <<~END
        .DS_Store
        Bla
        END
        File.write('.gitignore', gitignore_contents)

        argv = CLAide::ARGV.new(['book_name'])
        init = Init.new(argv)
        init.run

        expected = <<~NEW
          .DS_Store
          Bla

          # This is generated with `epuber init`
          *.epub
          *.mobi
          !.epuber/
          .epuber/build/
          .epuber/release_build/
          .epuber/build_cache/
          .epuber/metadata/
        NEW

        expect(File.read('.gitignore')).to eq expected
      end
    end
  end
end
