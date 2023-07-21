# frozen_string_literal: true

require 'yaml'
require 'digest'
require 'optparse'
require 'fileutils'

options = {
  date: nil,
  version: nil,
  branch: 'stable',
  lang: 'en-US'
}
parser = OptionParser.new do |parser| # rubocop:disable Metrics/BlockLength
  parser.banner = <<~HELP
    Usage: ruby upgrade.rb [options]

    Example:

        ruby upgrade.rb -d 2022-09-06 -v 2022.8

        ruby upgrade.rb -d 2022-12-06 -v 2022.8.2 -l de -b beta
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

unless options[:date] && options[:version]
  puts parser.help
  exit 1
end

release_tarball = "Ghostery-#{options[:version]}.#{options[:lang]}.linux.tar.gz"
release_url = "https://github.com/ghostery/user-agent-desktop/releases/download/#{options[:date]}/#{release_tarball}"

# Download required version:
system 'curl', '-LO', release_url unless File.exist? release_tarball

data = YAML.load_file('com.ghostery.dawn.yml')

ghostery_index = data['modules'].index do |mod|
  mod.is_a?(Hash) && mod['name'] == 'ghostery'
end
source_index = data['modules'][ghostery_index]['sources'].index do |source|
  source.fetch('dest', nil) == 'ghostery_app'
end
data['modules'][ghostery_index]['sources'][source_index]['url'] = release_url
release_hash = Digest::SHA256.file(release_tarball).hexdigest
data['modules'][ghostery_index]['sources'][source_index]['sha256'] = release_hash

data['default-branch'] = options[:branch]

File.write('com.ghostery.dawn.yml', data.to_yaml)

system 'sed', '-i', "s|<release version=\"[0-9.]*\" date=\"[0-9-]*\"/>|<release version=\"#{options[:version]}\" date=\"#{options[:date]}\"/>|", 'com.ghostery.dawn.appdata.xml'

cache_dir = ".flatpak-builder/downloads/#{release_hash}"

FileUtils.mkdir_p cache_dir
FileUtils.mv release_tarball, cache_dir
