# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in recording_studio_publications.gemspec
gemspec

# These gems are not published to RubyGems; resolve the gemspec pins from GitHub.
gem "flat_pack", "~> 0.1.246", github: "bowerbird-app/flatpack", tag: "v0.1.329"
gem "recording_studio", "~> 4.2", github: "bowerbird-app/RecordingStudio", tag: "v4.7.1"
gem "recording_studio_accessible", "~> 0.9", github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.9.0"
gem "recording_studio_admin", "~> 2.0", github: "bowerbird-app/RecordingStudio_admin", tag: "2.0.1"
gem "recording_studio_attachable", "~> 0.5", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.5.0"
gem "recording_studio_publishable", "~> 0.3", github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.3.0"

gem "devise"
gem "puma"
gem "sprockets-rails"

group :development, :test do
  gem "debug"
  gem "simplecov", require: false
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
end
