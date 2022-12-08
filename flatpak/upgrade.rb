# frozen_string_literal: true

require 'yaml'
require 'fileutils'

unless ARGV.length > 1
  puts <<~USAGE
    usage: ruby upgrade.rb RELEASE_DATE RELEASE_VERSION [LANG]

    RELEASE_DATE and RELEASE_VERSION are respectivelly the git tag of a
    release and its "commercial" name.

    Example:

        ruby upgrade.rb 2022-09-06 2022.8

        ruby upgrade.rb 2022-09-06 2022.8 de
  USAGE
  exit 1
end

release_date = ARGV[0]
release_version = ARGV[1]
release_lang = ARGV[2] || 'en-US'
release_tarball = "Ghostery-#{release_version}.#{release_lang}.linux.tar.gz"
release_url = "https://github.com/ghostery/user-agent-desktop/releases/download/#{release_date}/#{release_tarball}"

# Download required version:
system 'curl', '-LO', release_url unless File.exist? release_tarball

release_hash = `sha256sum #{release_tarball}`.split(' ')[0]

data = YAML.load_file('com.ghostery.dawn.yml')
ghostery_index = data['modules'].index do |mod|
  mod.is_a?(Hash) && mod['name'] == 'ghostery'
end
source_index = data['modules'][ghostery_index]['sources'].index do |source|
  source.fetch('dest', nil) == 'ghostery_app'
end

data['modules'][ghostery_index]['sources'][source_index]['url'] = release_url
data['modules'][ghostery_index]['sources'][source_index]['sha256'] = release_hash
File.write('com.ghostery.dawn.yml', data.to_yaml)

system 'sed', '-i', "s|<release version=\"[0-9.]*\" date=\"[0-9-]*\"/>|<release version=\"#{release_version}\" date=\"#{release_date}\"/>|", 'com.ghostery.dawn.appdata.xml'

cache_dir = ".flatpak-builder/downloads/#{release_hash}"

FileUtils.mkdir_p cache_dir
FileUtils.mv release_tarball, cache_dir
