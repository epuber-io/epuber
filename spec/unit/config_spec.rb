# encoding: utf-8

require_relative '../spec_helper'
require 'epuber/config'

module Epuber
  describe Config do
    include FakeFS::SpecHelpers

    before do
      Config.clear_instance!
    end

    it "warns if the previous version of Epuber is newer" do
      lockfile = {
          'epuber_version' => '200000.0.0',
          'bade_version' => Bade::VERSION,
      }

      File.write('some.bookspec', '')
      File.write('some.bookspec.lock', lockfile.to_yaml)

      expect {
        Config.instance.warn_for_outdated_versions!
      }.to output(/Warning: the running version of Epuber is older than the version that created the lockfile. We suggest you upgrade to the latest version of Epuber by running `gem install epuber`\./).to_stdout
    end

    it "warns if the previous version of Bade is newer" do
      lockfile = {
          'epuber_version' => Epuber::VERSION,
          'bade_version' => '200000.0.0',
      }

      File.write('some.bookspec', '')
      File.write('some.bookspec.lock', lockfile.to_yaml)

      expect {
        Config.instance.warn_for_outdated_versions!
      }.to output(/Warning: the running version of Bade is older than the version that created the lockfile. We suggest you upgrade to the latest version of Bade by running `gem install bade`\./).to_stdout
    end

    it "is backward compatible" do
      lockfile = {
          'version' => '0.1',
      }

      File.write('some.bookspec', '')
      File.write('some.bookspec.lock', lockfile.to_yaml)

      expect(Config.instance.bookspec_lockfile.epuber_version.to_s).to eq '0.1'
      expect(Config.instance.bookspec_lockfile.bade_version).to eq nil

      expect {
        Config.instance.warn_for_outdated_versions!
      }.to_not raise_error
    end

    it "is working when there is no lockfile yet" do
      File.write('some.bookspec', '')

      expect(Config.instance.bookspec_lockfile.epuber_version).to_not be_nil
    end

    context '#diff_version_from_last_build?' do
      it 'detects when using different version of Epuber or Bade' do
        lockfile = {
            'epuber_version' => '200000.0.0',
            'bade_version' => '200000.0.0',
        }

        File.write('some.bookspec', '')
        File.write('some.bookspec.lock', lockfile.to_yaml)

        expect(Config.instance.same_version_as_last_run?).to be_falsey
      end

      it 'detects when using same versions of Epuber and Bade' do
        lockfile = {
            'epuber_version' => Epuber::VERSION,
            'bade_version' => Bade::VERSION,
        }

        File.write('some.bookspec', '')
        File.write('some.bookspec.lock', lockfile.to_yaml)

        expect(Config.instance.same_version_as_last_run?).to be_truthy
      end

      it 'is backward compatible' do
        lockfile = {
            'version' => '0.1',
        }

        File.write('some.bookspec', '')
        File.write('some.bookspec.lock', lockfile.to_yaml)

        expect(Config.instance.same_version_as_last_run?).to be_falsey
      end

      it 'is working when there is no lockfile yet' do
        File.write('some.bookspec', '')

        expect(Config.instance.same_version_as_last_run?).to_not be_falsey
      end
    end
  end
end
