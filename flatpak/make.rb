# frozen_string_literal: true

require 'yaml'
require 'digest'
require 'optparse'
require 'fileutils'

module GhosteryDawn
  class VersionBumper
    RELEASE_TARBALL = 'Ghostery-%<version>s.%<lang>s.linux.tar.gz'

    RELEASE_URL = 'https://github.com/ghostery/user-agent-desktop/releases/download/%<date>s/%<tarball>s'

    def initialize(options)
      @options = options
      release_tarball = format(RELEASE_TARBALL, @options)
      @options[:tarball] = release_tarball
      release_url = format(RELEASE_URL, @options)
      @options[:url] = release_url
    end

    def bump
      # Download required version:
      system 'curl', '-LO', @options[:url] unless File.exist? @options[:tarball]
      sha256 = upgrade_manifest
      cache_tarball sha256
      upgrade_appdata
    end

    class << self
      def ghostery_source_indexes(data)
        ghostery_index = data['modules'].index do |mod|
          mod.is_a?(Hash) && mod['name'] == 'ghostery_browser'
        end
        source_index = data['modules'][ghostery_index]['sources'].index do |source|
          source.fetch('dest', nil) == 'ghostery_app'
        end
        [ghostery_index, source_index].freeze
      end
    end

    private

    def upgrade_manifest
      data = YAML.load_file('com.ghostery.browser.yml')
      ghost_index, src_index = VersionBumper.ghostery_source_indexes(data)
      data['modules'][ghost_index]['sources'][src_index]['url'] = @options[:url]
      release_hash = Digest::SHA256.file(@options[:tarball]).hexdigest
      data['modules'][ghost_index]['sources'][src_index]['sha256'] = release_hash
      data['default-branch'] = @options[:branch]
      File.write('com.ghostery.browser.yml', data.to_yaml)
      release_hash
    end

    def upgrade_appdata
      appdata = File.read('com.ghostery.browser.appdata.xml').split("\n")
      appdata.map! do |line|
        line.gsub(
          %r{<release version="[0-9.]+" date="[0-9-]+"/>},
          "<release version=\"#{@options[:version]}\" date=\"#{@options[:date]}\"/>"
        )
      end
      File.write 'com.ghostery.browser.appdata.xml', appdata.join("\n")
    end

    def cache_tarball(release_hash)
      cache_dir = ".flatpak-builder/downloads/#{release_hash}"
      FileUtils.mkdir_p cache_dir
      FileUtils.mv @options[:tarball], cache_dir
    end
  end

  module Helper
    def self.run_cmd(cmd)
      puts cmd.join ' '
      system(*cmd, exception: true)
    end
  end

  module Builder
    FLATPAK_USER = %w[flatpak --user --noninteractive].freeze

    def self.build
      Helper.run_cmd(%w[flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo])
      Helper.run_cmd(FLATPAK_USER + %w[install org.freedesktop.Platform//22.08])
      Helper.run_cmd(FLATPAK_USER + %w[install org.freedesktop.Sdk//22.08])
      Helper.run_cmd %w[flatpak-builder --force-clean build-dir com.ghostery.browser.yml]
    end

    def self.install
      Helper.run_cmd %w[flatpak-builder --user --install --force-clean build-dir com.ghostery.browser.yml]
    end

    def self.uninstall
      Helper.run_cmd(FLATPAK_USER + %w[uninstall com.ghostery.browser])
    end

    def self.clean
      FileUtils.rm_rf 'build-dir'
    end

    def self.cleanall
      clean
      FileUtils.rm_rf '.flatpak-builder'
    end
  end
end

return unless $PROGRAM_NAME == __FILE__

possible_commands = GhosteryDawn::Builder.methods(false).sort.freeze
options = {
  date: nil,
  version: nil,
  branch: 'stable',
  lang: 'en-US'
}
parser = OptionParser.new do |parser| # rubocop:disable Metrics/BlockLength
  parser.banner = <<~HELP
    Usage: ruby make.rb [options] COMMAND

    Example:
        ruby make.rb -d 2022-09-06 -v 2022.8
        ruby make.rb bump -d 2022-12-06 -v 2022.8.2 -l de -b beta
        ruby make.rb build

    Commands:
        bump (default)
        #{possible_commands.join("\n    ")}
  HELP

  parser.separator "\nOptions"

  parser.on('-h', '--help', 'Show this help message') do
    puts parser.help
    exit
  end

  parser.on('-d', '--date DATE', 'Git tag of the new release')

  parser.on('-v', '--version VERSION', '"Commercial" name of the new release')

  parser.on('-b', '--branch [BRANCH]',
            'Branch of this new release, i.e. stable or beta.',
            '(default: stable)')

  parser.on('-l', '--lang [LANG]',
            'Lang of the upstream package to use',
            '(default: en-US)')
end
parser.parse!(into: options)
command = (ARGV[0] || 'bump').to_sym

if File.directory?('com.ghostery.browser')
  FileUtils.cd 'com.ghostery.browser'

elsif File.exist?('com.ghostery.browser')
  warn 'com.ghostery.browser must be a folder!'
  exit 2

else
  GhosteryDawn::Helper.run_cmd(%w[git clone https://github.com/flathub/com.ghostery.browser])
  FileUtils.cd 'com.ghostery.browser'
  GhosteryDawn::Helper.run_cmd(%w[git submodule init])
  GhosteryDawn::Helper.run_cmd(%w[git submodule update])
end

if command == :bump && options[:date] && options[:version]
  GhosteryDawn::VersionBumper.new(options).bump

elsif possible_commands.include?(command)
  GhosteryDawn::Builder.send(command)

else
  puts parser.help
  exit 2
end
