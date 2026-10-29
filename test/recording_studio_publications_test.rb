# frozen_string_literal: true

require "test_helper"

class RecordingStudioPublicationsTest < Minitest::Test
  def test_version_matches_release
    assert_equal "0.4.3", ::RecordingStudioPublications::VERSION
  end

  def test_engine_exists
    assert_kind_of Class, ::RecordingStudioPublications::Engine
  end

  def test_gemspec_pins_family_constraints
    gemspec = File.read(File.expand_path("../recording_studio_publications.gemspec", __dir__))

    assert_includes gemspec, 'spec.add_dependency "recording_studio", "~> 4.2"'
    assert_includes gemspec, 'spec.add_dependency "rails", "~> 8.1.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_accessible", "~> 0.9"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_admin", "~> 2.0"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_attachable", "~> 0.5"'
    assert_includes gemspec, 'spec.add_dependency "recording_studio_publishable", "~> 0.3"'
    assert_includes gemspec, 'spec.add_dependency "flat_pack", "~> 0.1.143"'
  end

  def test_dummy_gemfile_pins_verified_4x_github_tags
    gemfile = File.read(File.expand_path("dummy/Gemfile", __dir__))

    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio", tag: "v4.7.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_accessible", tag: "v0.9.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_publishable", tag: "v0.3.0"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_admin", tag: "v2.5.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_trashable", tag: "v0.10.1"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_metrics", tag: "v0.2.3"'
    assert_includes gemfile, 'github: "bowerbird-app/RecordingStudio_root_switchable", tag: "v0.5.0"'
    assert_includes gemfile, 'github: "bowerbird-app/flatpack", tag: "v0.1.329"'
    refute_includes gemfile, "recording_studio/v3.0.0"
    refute_includes gemfile, 'tag: "v0.1.144"'
    refute_includes gemfile, 'tag: "0.3.1"'
  end

  def test_template_does_not_ship_copied_core_hooks_or_base_service
    refute File.exist?(File.expand_path("../lib/recording_studio_publications/hooks.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_publications/services/base_service.rb", __dir__))
    refute File.exist?(File.expand_path("../lib/recording_studio_publications/services/example_service.rb", __dir__))
  end

  def test_example_capability_wraps_include_for_and_is_not_enabled_globally
    source = File.read(File.expand_path("../lib/recording_studio_publications/capabilities/example.rb", __dir__))

    assert_includes source, "def self.to(**)"
    assert_includes source, "RecordingStudio::Capabilities.include_for(:example, **)"
    refute_includes source, "enable_capability"
    refute_includes source, "set_capability_options"
    refute RecordingStudio.capability_enabled?(:example, for: "Folder")
    refute RecordingStudio.capability_enabled?(:example, for: "Page")
    assert_empty RecordingStudio.configuration.enabled_recordable_types_for(:example)
  end

  def test_public_layout_loads_theme_css_without_staff_chrome
    public_layout = File.read(
      File.expand_path("../app/views/layouts/recording_studio_publications/public.html.erb", __dir__)
    )

    assert_includes public_layout, 'data-theme="rounded"'
    assert_includes public_layout, 'stylesheet_link_tag "tailwind"'
    assert_includes public_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes public_layout, 'stylesheet_link_tag "flat_pack/rich_text"'
    refute_includes public_layout, "Go back"
    refute_includes public_layout, "PageNav"

    public_show = File.read(
      File.expand_path("../app/views/recording_studio_publications/public_publications/show.html.erb", __dir__)
    )
    assert_includes public_show, "publishable_preview_badge"
  end

  def test_show_and_edit_use_publishable_quick_actions
    show = File.read(File.expand_path("../app/views/recording_studio_publications/publications/show.html.erb", __dir__))
    edit = File.read(File.expand_path("../app/views/recording_studio_publications/publications/edit.html.erb", __dir__))

    [show, edit].each do |view|
      assert_includes view, "RecordingStudioPublishable::QuickActions::Component"
      refute_includes view, "EditButtonComponent"
      refute_includes view, "StatusBadge"
      refute_includes view, "Public page"
      refute_includes view, "publication_public_page_button_text"
    end
  end

  def test_dummy_host_mounts_attachable_and_wires_turbo
    routes = File.read(File.expand_path("dummy/config/routes.rb", __dir__))
    importmap = File.read(File.expand_path("dummy/config/importmap.rb", __dir__))
    application_js = File.read(File.expand_path("dummy/app/javascript/application.js", __dir__))

    assert_includes routes, 'mount RecordingStudioPublishable::Engine, at: "/"'
    assert_includes routes, 'mount RecordingStudioAttachable::Engine, at: "/recording_studio_attachable"'
    assert_includes routes, 'mount RecordingStudioAccessible::Engine, at: "/admin/access"'
    assert_includes importmap, 'pin "@hotwired/turbo-rails"'
    assert_includes importmap, 'pin "@rails/activestorage"'
    assert_includes application_js, 'import "@hotwired/turbo-rails"'
    assert_includes application_js, "ActiveStorage.start()"

    attachable_initializer = File.read(
      File.expand_path("dummy/config/initializers/recording_studio_attachable.rb", __dir__)
    )
    assert_includes attachable_initializer, "config.layout = :blank"
    refute_includes attachable_initializer, 'config.layout = "recording_studio/default_layout"'
  end

  def test_dummy_app_uses_flatpack_sidebar_for_host_pages
    application_controller_path = File.expand_path("dummy/app/controllers/application_controller.rb", __dir__)
    controller_source = File.read(application_controller_path)
    gem_controller_source = File.read(
      File.expand_path("../app/controllers/recording_studio_publications/application_controller.rb", __dir__)
    )
    default_layout_initializer = File.read(
      File.expand_path("dummy/config/initializers/recording_studio_default_layout.rb", __dir__)
    )

    assert_includes controller_source, "include RecordingStudio::RootSwitchable::ControllerSupport"
    assert_includes controller_source, '"flat_pack_sidebar"'
    assert_includes controller_source, "devise_controller? ? \"application\""
    refute_includes controller_source, "include RecordingStudio::UsesDefaultLayout"
    refute_includes controller_source, '"recording_studio/default_layout"'
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack_sidebar.html.erb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_sidebar.html.erb", __dir__))
    assert File.exist?(File.expand_path("dummy/app/views/layouts/flat_pack/_top_nav.html.erb", __dir__))
    assert_includes gem_controller_source, "layout \"recording_studio/default_layout\""
    assert_includes default_layout_initializer, "RecordingStudio::ApplicationController.include(RecordingStudio::UsesDefaultLayout)"
    refute File.exist?(
      File.expand_path("dummy/config/initializers/flatpack_page_nav_url_aliases.rb", __dir__)
    )
  end

  def test_dummy_login_layout_keeps_flatpack_assets_without_tight_main_offset
    application_layout = File.read(File.expand_path("dummy/app/views/layouts/application.html.erb", __dir__))

    assert_includes application_layout, '<html data-theme="rounded">'
    assert_includes application_layout, 'stylesheet_link_tag "flat_pack/variables"'
    assert_includes application_layout, "javascript_importmap_tags"
    assert_includes application_layout, "min-h-screen"
    refute_includes application_layout, "mt-28"
    refute_includes application_layout, "flat_pack_sidebar"
  end

  def test_dummy_default_layout_head_sets_html_theme_without_chrome
    layout_head = File.read(File.expand_path("dummy/app/views/layouts/_default_layout_head.html.erb", __dir__))
    core_hook = File.read(File.expand_path("dummy/app/views/recording_studio/_default_layout_head.html.erb", __dir__))
    helper_source = File.read(File.expand_path("dummy/app/helpers/application_helper.rb", __dir__))

    assert_includes core_hook, 'render "layouts/default_layout_head"'
    assert_includes layout_head, 'document.documentElement.setAttribute("data-theme", "rounded")'
    assert_includes layout_head, "javascript_tag nonce: true"
    refute_includes layout_head, "recording_studio_root_switch_dropdown"
    refute_includes layout_head, "recording_studio_page_nav_right"
    refute_includes layout_head, "Sign out"
    refute_includes layout_head, "destroy_user_session_path"
    refute_includes helper_source, "dummy_page_nav"
    refute_includes helper_source, "Sign out"
    refute_includes helper_source, "recording_studio_root_switch_dropdown"
  end

  def test_dummy_tailwind_keeps_flatpack_theme_selection_in_flatpack
    tailwind_source = File.read(File.expand_path("dummy/app/assets/tailwind/application.css", __dir__))

    assert_includes tailwind_source, "../../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}"
    assert_includes tailwind_source, "flatpack-*/app/components/**/*.{rb,erb}"
    assert_includes tailwind_source, "usr/local/lib/ruby/gems/**/bundler/gems/flatpack-*"
    assert_includes tailwind_source, '"/usr/local/lib/ruby/gems/**/bundler/gems/flatpack-*'
    assert_includes tailwind_source, "../../../vendor/bundle/**/recording_studio/app/views/**/*.erb"
    assert_includes tailwind_source, "recordingstudio-*/app/views/**/*.erb"
    assert_includes tailwind_source, "recording_studio_admin/app/views/**/*.erb"
    assert_includes tailwind_source, "recording_studio_attachable/app/views/**/*.erb"
    assert_includes tailwind_source, "recording_studio_publishable/app/views/**/*.erb"
    assert_includes tailwind_source, "recording_studio_publishable/app/components/**/*.{rb,erb}"
    refute_includes tailwind_source, "@theme"
    refute_includes tailwind_source, ":root {"
    refute_includes tailwind_source, "--color-fp-primary"
  end

  def test_recording_studio_keeps_strict_recordable_declarations_enabled
    initializer_path = File.expand_path("dummy/config/initializers/recording_studio.rb", __dir__)
    initializer_source = File.read(initializer_path)

    assert_includes initializer_source, "config.require_recordable_declarations = true"
    assert_includes initializer_source, '"Workspace"'
    assert_includes initializer_source, '"Folder"'
    assert_includes initializer_source, '"Page"'
    assert_includes initializer_source, '"AdminRoot"'
    assert_includes initializer_source, '"RecordingStudioPublications::PublicationCatalogue"'
    assert_includes initializer_source, '"RecordingStudioPublications::Publication"'
    assert_includes initializer_source, '"RecordingStudioPublications::PublishedArticle"'
    assert_includes initializer_source, '"RecordingStudioAttachable::Attachment"'
    assert_includes initializer_source, '"RecordingStudioPublishable::Publishable"'
    family_management = File.read(
      File.expand_path("../lib/recording_studio_publications/family_management.rb", __dir__)
    )
    engine_source = File.read(File.expand_path("../lib/recording_studio_publications/engine.rb", __dir__))
    assert_includes family_management, "Preview.install!(config)"
    refute_includes engine_source, "management_authorizer ="
    refute_includes engine_source, "FamilyManagement.install!"
    refute_includes initializer_source, "config.include_children"
    refute_includes initializer_source, "config.features."
    refute_includes initializer_source, "v3"
  end

  def test_dummy_readme_explains_dummy_app_purpose
    readme_path = File.expand_path("dummy/README.md", __dir__)
    readme_source = File.read(readme_path)

    assert_includes readme_source, "This Rails app exists to validate the Recording Studio publications gem"
    assert_includes readme_source, "/recording_studio"
    assert_includes readme_source, "redirects to `/`"
    assert_includes readme_source, "/recording_studio_attachable"
    assert_includes readme_source, "flat_pack_sidebar"
  end

  def test_product_readme_is_the_template_guide
    readme = File.read(File.expand_path("../README.md", __dir__))

    assert_includes readme, "RecordingStudio"
    assert_includes readme, "v4.2.0"
    assert_includes readme, "v0.1.143"
    refute_includes readme, "v3 declarations"
    refute_includes readme, "RecordingStudio v3"
    refute_includes readme, "ExampleService"
    refute_includes readme, "recording_studio/v3.0.0"
  end

  def test_dummy_home_page_uses_demo_title_only
    view_path = File.expand_path("dummy/app/views/home/index.html.erb", __dir__)
    view_source = File.read(view_path)

    assert_includes view_source, 'title: "Publication directory"'
    assert_includes view_source, "shared publications catalogue"
    assert_includes view_source, "FlatPack::Card::Component"
    assert_includes view_source, "border: :strong"
    refute_includes view_source, "style: :default"
    refute_includes view_source, "style: :outlined"
    refute_includes view_source, "dummy_page_nav"
    refute_includes view_source, 'title: "Demo"'
    refute_includes view_source, "FlatPack::Breadcrumb::Component"
  end

  def test_dummy_docs_pages_use_minimal_flatpack_documentation_components
    docs_view_paths = Dir[File.expand_path("dummy/app/views/docs/*.html.erb", __dir__)].reject do |view_path|
      File.basename(view_path).start_with?("_")
    end
    refute_empty docs_view_paths

    docs_view_paths.each do |view_path|
      view_source = File.read(view_path)

      refute_includes view_source, "dummy_page_nav"
      assert_includes view_source, "FlatPack::PageTitle::Component"
      refute_includes view_source, "FlatPack::Card::Component"
      refute_includes view_source, "FlatPack::Breadcrumb::Component"
    end

    methods_view = File.read(File.expand_path("dummy/app/views/docs/methods.html.erb", __dir__))
    assert_includes methods_view, "FlatPack::SectionTitle::Component"
    assert_includes methods_view, "FlatPack::CodeBlock::Component"

    gem_views_view = File.read(File.expand_path("dummy/app/views/docs/gem_views.html.erb", __dir__))
    assert_includes gem_views_view, "FlatPack::Table::Component"
    refute_includes gem_views_view, "FlatPack::List::Component"

    recordable_types_view = File.read(File.expand_path("dummy/app/views/docs/recordable_types.html.erb", __dir__))
    assert_includes recordable_types_view, "FlatPack::List::Component"
    refute_includes recordable_types_view, "v3 parent/root"

    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_dummy_recordings_tree_view_omits_structure_section_copy
    recordings_tree_view = File.read(File.expand_path("dummy/app/views/docs/recordings_tree.html.erb", __dir__))

    assert_includes recordings_tree_view, 'title: "Recordings tree"'
    assert_includes recordings_tree_view, "FlatPack::Tree::Component"
    recording_tree_partial = File.read(File.expand_path("dummy/app/views/docs/_recording_tree_node.html.erb", __dir__))
    assert_includes recording_tree_partial, "parent_builder.node"
    refute_includes recordings_tree_view, "Current structure"
    refute_includes recordings_tree_view, "This tree is generated from RecordingStudio::Recording records"
  end

  def test_dummy_seed_logo_is_a_real_png
    path = File.expand_path("dummy/db/seed_assets/publication_logo.png", __dir__)
    bytes = File.binread(path)

    assert bytes.bytesize >= 200
    assert_equal "\x89PNG".b, bytes.byteslice(0, 4)
  end

  def test_engine_does_not_ship_a_home_view
    view_path = File.expand_path("../app/views/recording_studio_publications/home/index.html.erb", __dir__)

    refute File.exist?(view_path)
  end

  def test_admin_types_screen_and_action_origin_helpers_are_wired
    admin = File.read(File.expand_path("../lib/recording_studio_publications/admin.rb", __dir__))
    section = File.read(File.expand_path("../lib/recording_studio_publications/admin/publications_section.rb", __dir__))
    paths = File.read(File.expand_path("../lib/recording_studio_publications/admin/paths.rb", __dir__))
    anchors = File.read(File.expand_path("../lib/recording_studio_publications/admin/anchor_urls.rb", __dir__))
    controller = File.read(
      File.expand_path("../app/controllers/recording_studio_publications/catalogue_admin_controller.rb", __dir__)
    )
    show = File.read(File.expand_path("../app/views/recording_studio_publications/publications/show.html.erb", __dir__))

    assert_includes admin, 'TYPES_SCREEN_KEY = "publication_types"'
    types_screen = File.expand_path(
      "../lib/recording_studio_publications/admin/publication_types_screen.rb",
      __dir__
    )
    assert File.exist?(types_screen)
    assert_includes section, "link :publication_types"
    assert_includes anchors, "def originating_page_for"
    assert_includes paths, "publication_types"
    assert_includes controller, "def action_close_url"
    assert_includes show, "action_close_url(default: inventory_path)"
  end

  def test_flatpack_callers_use_native_card_and_page_nav_helpers
    article_card = File.read(
      File.expand_path("../app/views/recording_studio_publications/published_articles/_article_card.html.erb", __dir__)
    )
    screen_show = File.read(
      File.expand_path("../app/overrides/recording_studio_admin/screens/show.html.erb", __dir__)
    )
    dummy_views = File.expand_path("dummy/app/views", __dir__)
    dummy_root_switch_path = File.join(dummy_views, "recording_studio_root_switchable/root_switches/show.html.erb")
    dummy_native_page_nav = [
      dummy_root_switch_path,
      *Dir[File.join(dummy_views, "recording_studio_attachable/**/*.html.erb")]
    ]
    dummy_root_switch = File.read(dummy_root_switch_path)
    sources = Dir[
      File.expand_path("../app/**/*.{rb,erb}", __dir__),
      File.expand_path("../lib/**/*.{rb,erb}", __dir__),
      File.expand_path("dummy/app/**/*.{rb,erb}", __dir__)
    ].reject { |path| dummy_native_page_nav.include?(path) }.map { |path| File.read(path) }

    assert_includes article_card, "hover: :strong"
    refute_includes article_card, "style: :interactive"
    assert_includes screen_show, "border: :strong"
    refute_includes screen_show, "style: :outlined"
    refute_includes screen_show, "FlatPack::PageNav::Component"
    dummy_native_page_nav.each do |path|
      source = File.read(path)
      assert_includes source, "page_nav.with_close"
      refute_includes source, "anchor_label:"
      refute_includes source, "anchor_url:"
      refute_includes source, "back_icon:"
    end
    refute_match(/Card::Component\.new\([^)]*style:/, dummy_root_switch)
    index_results = File.read(
      File.expand_path("../app/views/recording_studio_publications/published_articles/_index_results.html.erb", __dir__)
    )
    assert_includes index_results, "empty_state.item"
    refute_includes index_results, "empty_state.slot"
    sources.each do |source|
      refute_match(/Card::Component\.new\([^)]*style:/, source)
      refute_includes source, "FlatPack::PageNav::Component.new"
    end
  end
end
