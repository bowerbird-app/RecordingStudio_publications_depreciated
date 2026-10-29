# frozen_string_literal: true

require_relative "lib/recording_studio_publications/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_publications"
  spec.version     = RecordingStudioPublications::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/RecordingStudio_publications"
  spec.summary     = "Publication directory for the Recording Studio ecosystem"
  spec.description = "A mountable Rails engine for a publication directory in Recording Studio hosts."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "flat_pack", "~> 0.1.246"
  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
  spec.add_dependency "recording_studio_accessible", "~> 0.9"
  spec.add_dependency "recording_studio_admin", "~> 2.0"
  spec.add_dependency "recording_studio_attachable", "~> 0.5"
  spec.add_dependency "recording_studio_publishable", "~> 0.3"
end
