# frozen_string_literal: true

require_relative '../spec_helper'
require 'epuber/config'

module Epuber
  describe Config do
    include FakeFS::SpecHelpers

    before do
      described_class.clear_instance!
    end

    it 'warns if the previous version of Epuber is newer' do
      lockfile = {
        'epuber_version' => '200000.0.0',
        'bade_version' => Bade::VERSION,
      }

      File.write('some.bookspec', '')
      File.write('some.bookspec.lock', lockfile.to_yaml)

      expect do
        described_class.instance.warn_for_outdated_versions!
      end.to output(/Warning: the running version of Epuber is older than the version that created the lockfile. We suggest you upgrade to the latest version of Epuber by running `gem install epuber`\./).to_stdout
    end

    it 'warns if the previous version of Bade is newer' do
      lockfile = {
        'epuber_version' => Epuber::VERSION,
        'bade_version' => '200000.0.0',
      }

      File.write('some.bookspec', '')
      File.write('some.bookspec.lock', lockfile.to_yaml)

      expect do
        described_class.instance.warn_for_outdated_versions!
      end.to output(/Warning: the running version of Bade is older than the version that created the lockfile. We suggest you upgrade to the latest version of Bade by running `gem install bade`\./).to_stdout
    end

    it 'is backward compatible' do
      lockfile = {
        'version' => '0.1',
      }

      File.write('some.bookspec', '')
      File.write('some.bookspec.lock', lockfile.to_yaml)

      expect(described_class.instance.bookspec_lockfile.epuber_version.to_s).to eq '0.1'
      expect(described_class.instance.bookspec_lockfile.bade_version).to eq nil

      expect do
        described_class.instance.warn_for_outdated_versions!
      end.not_to raise_error
    end

    it 'is working when there is no lockfile yet' do
      File.write('some.bookspec', '')

      expect(described_class.instance.bookspec_lockfile.epuber_version).not_to be_nil
    end

    describe '#diff_version_from_last_build?' do
      it 'detects when using different version of Epuber or Bade' do
        lockfile = {
          'epuber_version' => '200000.0.0',
          'bade_version' => '200000.0.0',
        }

        File.write('some.bookspec', '')
        File.write('some.bookspec.lock', lockfile.to_yaml)

        expect(described_class.instance).not_to be_same_version_as_last_run
      end

      it 'detects when using same versions of Epuber and Bade' do
        lockfile = {
          'epuber_version' => Epuber::VERSION,
          'bade_version' => Bade::VERSION,
        }

        File.write('some.bookspec', '')
        File.write('some.bookspec.lock', lockfile.to_yaml)

        expect(described_class.instance).to be_same_version_as_last_run
      end

      it 'is backward compatible' do
        lockfile = {
          'version' => '0.1',
        }

        File.write('some.bookspec', '')
        File.write('some.bookspec.lock', lockfile.to_yaml)

        expect(described_class.instance).not_to be_same_version_as_last_run
      end

      it 'is working when there is no lockfile yet' do
        File.write('some.bookspec', '')

        expect(described_class.instance).to be_same_version_as_last_run
      end
    end
  end
end
