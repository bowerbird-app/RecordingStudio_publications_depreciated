# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "nokogiri"

class PublicationsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ONE_PIXEL_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @admin = User.find_or_create_by!(email: "admin-publications-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @admin_recording = admin_root_recording_for_test
    Current.actor = @admin
  end

  teardown do
    Current.actor = nil
  end

  test "registers the publications section, screens, resource, and widgets" do
    assert_equal RecordingStudioPublications::Admin::PublicationsSection,
                 RecordingStudioAdmin.section_for("publications")
    assert_equal RecordingStudioPublications::Admin::PublicationsScreen,
                 RecordingStudioAdmin.screen_for("publications")
    assert_equal RecordingStudioPublications::Admin::ArticlesScreen,
                 RecordingStudioAdmin.screen_for("articles")
    assert_equal RecordingStudioPublications::Admin::PublicationTypesScreen,
                 RecordingStudioAdmin.screen_for("publication_types")
    assert_equal RecordingStudioPublications::Admin::PublicationsResource,
                 RecordingStudioAdmin.resource_for("publications")
    total = RecordingStudioAdmin.widget_for("widgets.publications.total")
    articles_total = RecordingStudioAdmin.widget_for("widgets.articles.total")
    over_time = RecordingStudioAdmin.widget_for("widgets.publications.over_time")
    articles_over_time = RecordingStudioAdmin.widget_for("widgets.articles.over_time")
    by_kind = RecordingStudioAdmin.widget_for("widgets.publications.by_kind")
    assert_equal :number, total.type
    assert_equal :number, articles_total.type
    assert_equal :chart, over_time.type
    assert_equal :line, over_time.chart_type
    assert over_time.value
    assert_equal :chart, articles_over_time.type
    assert_equal :line, articles_over_time.chart_type
    assert articles_over_time.value
    assert_equal :chart, by_kind.type
    assert_equal :bar, by_kind.chart_type
    assert_equal [
      "widgets.publications.over_time",
      "widgets.articles.over_time"
    ], RecordingStudioPublications::Admin::PublicationsSection.widget_keys
    assert_empty RecordingStudioPublications::Admin::PublicationsScreen.widget_keys
    assert RecordingStudioPublications::Admin::PublicationsScreen.chart_value
    assert_equal :area, RecordingStudioPublications::Admin::PublicationsScreen.chart_value.type_value
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsSection.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsScreen.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::ArticlesScreen.blast_radius
    assert_equal :site, RecordingStudioPublications::Admin::PublicationsResource.blast_radius
    assert_equal :admin, RecordingStudioPublications::Admin::PublicationsResource.action_for(:edit).required_access_role
    assert_equal :admin, RecordingStudioPublications::Admin::PublicationsResource.action_for(:new).required_access_role
    search_filter = RecordingStudioPublications::Admin::PublicationsScreen.filters.find { |filter| filter.key == :search }
    assert search_filter
    type_filter = RecordingStudioPublications::Admin::PublicationsScreen.filters.find do |filter|
      filter.key == :publication_type
    end
    assert type_filter
    assert_equal :kind, type_filter.options[:field]
    assert_equal RecordingStudioPublications::PublicationType::TOKENS, type_filter.options[:values]
    publication_filter = RecordingStudioPublications::Admin::ArticlesScreen.filters.find do |filter|
      filter.key == :publication
    end
    assert publication_filter
    new_button = RecordingStudioPublications::Admin::PublicationsScreen.buttons_value.find do |button|
      button.name == :new_publication
    end
    assert new_button
    assert_equal "Publication", new_button.text
    refute RecordingStudioPublications::Admin::PublicationsSection.links.any? { |link| link.name == :new_publication }
    inventory_link = RecordingStudioPublications::Admin::PublicationsSection.links.find do |link|
      link.name == :inventory
    end
    assert_equal "Publications", inventory_link.text
    articles_link = RecordingStudioPublications::Admin::PublicationsSection.links.find do |link|
      link.name == :articles
    end
    assert_equal "Articles", articles_link.text
    types_link = RecordingStudioPublications::Admin::PublicationsSection.links.find do |link|
      link.name == :publication_types
    end
    assert_equal "Publication types", types_link.text
    assert File.exist?(RecordingStudioPublications::Engine.root.join("app/overrides/recording_studio_admin/screens/show.html.erb"))
    assert File.exist?(RecordingStudioPublications::Engine.root.join("app/overrides/recording_studio_admin/sections/show.html.erb"))
    refute_includes File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications/admin.rb")),
                    "instance_variable_set"
    assert_equal RecordingStudioPublications::Publication::KINDS.map(&:titleize),
                 RecordingStudioPublications::Admin.titles_by_kind_series.first[:data].map { |point| point[:x] }
  end

  test "rejects an actor without AdminRoot access and permits the site admin" do
    sign_in @admin

    get recording_studio_publications.admin_publications_path
    assert_response :forbidden

    get "/admin/sections/publications"
    assert_response :forbidden

    bootstrap_owner_access!(@admin, @admin_recording)

    get recording_studio_publications.admin_publications_path
    assert_redirected_to "/admin/publications"

    get "/admin"
    assert_response :success
    assert_includes response.body, "Publications demo"
    refute_includes response.body, "Publications admin demo"
    refute_includes response.body, "Publications over time"
    refute_includes response.body, "Articles over time"
    refute_includes response.body, "/admin/access/recordings/"
    home = Nokogiri::HTML(response.body)
    section_button = home.css("a").find { |anchor| anchor["href"] == "/admin/sections/publications" }
    assert section_button, "expected the admin home to link to the publications section"
    assert_includes section_button.text, "Publications"

    get "/admin/sections/publications"
    assert_response :success
    assert_includes response.body, "Publications"
    assert_includes response.body, "Articles"
    assert_includes response.body, "Publication types"
    assert_includes response.body, "/admin/access/recordings/#{@admin_recording.id}/accesses"
    refute_includes response.body, "View all"
    refute_includes response.body, "Admin publications"
    refute_includes response.body, "All publications"
    refute_includes response.body, "+ Access"
    hub = Nokogiri::HTML(response.body)
    refute hub.at_css('a[href="/recording_studio_publications/admin/publications/new"]'),
           "hub should not include the new-title action"
    inventory = hub.css("a").find { |anchor| anchor["href"] == "/admin/publications" }
    assert inventory, "expected a Publications button to /admin/publications"
    assert_includes inventory.text, "Publications"
    articles = hub.css("a").find { |anchor| anchor["href"] == "/admin/articles" }
    assert articles, "expected an Articles button to /admin/articles"
    assert_includes articles.text, "Articles"
    types = hub.css("a").find { |anchor| anchor["href"] == "/admin/publication_types" }
    assert types, "expected a Publication types button to /admin/publication_types"
    assert_includes types.text, "Publication types"
    assert hub.at_css("[data-controller='flat-pack--chart']"),
           "expected cumulative publications and articles charts on the section"

    get "/admin/publications"
    assert_response :success
    inventory_page = Nokogiri::HTML(response.body)
    new_control = inventory_page.css("a").find do |anchor|
      anchor["href"]&.start_with?("/recording_studio_publications/admin/publications/new")
    end
    assert new_control, "expected + Publication under the inventory title"
    assert_includes new_control["href"], "anchor_url=%2Fadmin%2Fpublications"
    assert_includes new_control.text, "Publication"
    refute_includes new_control.text, "New"
    assert new_control.at_css('[data-flat-pack--icon-name-value="plus"]'),
           "expected the Publication inventory action to use the plus heroicon"
    refute inventory_page.at_css(".recording-studio-page-nav a[href='/recording_studio_publications/admin/publications/new']")
    assert_includes response.body, 'name="search"'
    assert_includes response.body, 'name="publication_type"'
    assert_includes response.body, "Publication type"
    assert_includes response.body, "screen-chart"
    assert_select "#screen-chart .fp-card.border-2", minimum: 1
    refute_includes response.body, "widgets.publications.over_time"
    refute_includes response.body, ">Publications</h3>"

    get "/admin/screens/publications"
    assert_response :success
    assert_includes response.body, "Publication"

    get "/admin/screens/publications/chart"
    assert_response :success
    assert_includes response.body, "Publications over time"
    assert_includes response.body, "screen-chart"

    get "/admin/screens/publications/table"
    assert_response :success
    assert_includes response.body, "Table data"
    assert_includes response.body, "Name"
    assert_includes response.body, "Publication type"
    assert_includes response.body, "Website"
    assert_includes response.body, "Articles"
    refute_match(/<th[^>]*>Key<\/th>/i, response.body)
  end

  test "admin can CRUD a publication through Resource required_role admin" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin

    get recording_studio_publications.new_admin_publication_path
    assert_response :success
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    refute_includes response.body, "flat-pack-sidebar-layout"
    assert_includes response.body, "Name"
    assert_includes response.body, "Key"
    assert_includes response.body, "Publication type"
    assert_includes response.body, "Website"
    assert_includes response.body, "Cancel"
    assert_includes response.body, "Save"
    refute_includes response.body, "ButtonGroup"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    refute_includes response.body, "Add logo"
    refute_includes response.body, "Change logo"
    refute_includes response.body, "multipart/form-data"

    post recording_studio_publications.admin_publications_path, params: {
      publication: {
        name: "Admin Created Journal",
        key: "admin-created-journal",
        kind: "journal",
        website: "https://journal.example"
      }
    }

    publication = RecordingStudioPublications.publications.find_by!(key: "admin-created-journal")
    recording = RecordingStudioPublications.recording_for(publication)
    assert_redirected_to recording_studio_publications.admin_publication_path(recording)
    assert_nil RecordingStudioPublications.logo_recording_for(publication)

    follow_redirect!
    assert_response :success
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    refute_includes response.body, "flat-pack-sidebar-layout"
    assert_includes response.body, "Admin Created Journal"
    assert_includes response.body, "Journal"
    assert_includes response.body, "Add logo"
    refute_includes response.body, "Change logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.recording_attachment_upload_path(recording)

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Edit publication"
    assert_includes response.body, "Add logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    refute_includes response.body, "multipart/form-data"

    patch recording_studio_publications.admin_publication_path(recording), params: {
      publication: {
        name: "Admin Revised Journal",
        key: "admin-created-journal",
        kind: "journal",
        website: "https://journal.example/revised"
      }
    }

    recording.reload
    assert_equal "Admin Revised Journal", recording.recordable.name
    assert_redirected_to recording_studio_publications.admin_publication_path(recording)
  end

  test "show and edit link to Attachable add and replace screens" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    recording = RecordingStudioPublications.record_publication!(
      { name: "Masthead Daily", kind: "newspaper" },
      actor: @admin
    )
    logo = attach_png_logo!(recording)

    get recording_studio_publications.admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Change logo"
    refute_includes response.body, "Add logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.attachment_path(logo)
    refute_includes response.body, recording_studio_attachable.recording_attachments_path(recording)

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :success
    assert_includes response.body, "Change logo"
    refute_includes response.body, "publication[logo]"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.attachment_path(logo)

    get recording_studio_attachable.recording_attachment_upload_path(
      recording,
      redirect_mode: "return_to",
      return_to: recording_studio_publications.admin_publication_path(recording)
    )
    assert_response :success
    assert_includes response.body, "Upload"
    assert_includes response.body, "Choose files"
    assert_equal 1, response.body.scan("flat-pack-page-nav").size
    refute_includes response.body, 'data-recording-studio-default-layout="true"'

    get recording_studio_attachable.attachment_path(
      logo,
      redirect_mode: "return_to",
      return_to: recording_studio_publications.admin_publication_path(recording)
    )
    assert_response :success
    assert_includes response.body, "Save"
    assert_includes response.body, logo.recordable.original_filename
    assert_equal 1, response.body.scan("flat-pack-page-nav").size
    refute_includes response.body, 'data-recording-studio-default-layout="true"'
  end

  test "view-only users cannot open new or edit" do
    view_only = User.find_or_create_by!(email: "view-only-publications-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    bootstrap_owner_access!(@admin, @admin_recording)
    grant_admin_access_for_test!(recording: @admin_recording, actor: view_only, role: :view)
    sign_in view_only

    recording = RecordingStudioPublications.record_publication!(
      { name: "View Only Title", kind: "site" },
      actor: @admin
    )

    get recording_studio_publications.new_admin_publication_path
    assert_response :forbidden

    get recording_studio_publications.edit_admin_publication_path(recording)
    assert_response :forbidden

    post recording_studio_publications.admin_publications_path, params: {
      publication: { name: "Blocked", kind: "site" }
    }
    assert_response :forbidden
  end

  test "inventory search uses the family Admin filter" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    RecordingStudioPublications.record_publication!(
      { name: "Searchable Atlantic", key: "searchable-atlantic", kind: "magazine" },
      actor: @admin
    )
    RecordingStudioPublications.record_publication!(
      { name: "Other Gazette", key: "other-gazette", kind: "newspaper" },
      actor: @admin
    )

    get "/admin/screens/publications/table", params: { search: "Atlantic" }
    assert_response :success
    assert_includes response.body, "Searchable Atlantic"
    refute_includes response.body, "Other Gazette"
  end

  test "inventory publication type filter scopes the table to that kind" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    RecordingStudioPublications.record_publication!(
      { name: "Typed Magazine", key: "typed-magazine", kind: "magazine" },
      actor: @admin
    )
    RecordingStudioPublications.record_publication!(
      { name: "Typed Newspaper", key: "typed-newspaper", kind: "newspaper" },
      actor: @admin
    )

    get "/admin/screens/publications/table", params: { publication_type: "magazine" }
    assert_response :success
    assert_includes response.body, "Typed Magazine"
    refute_includes response.body, "Typed Newspaper"
  end

  test "inventory name and article count link to show and the articles screen" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    publication_recording = RecordingStudioPublications.record_publication!(
      { name: "Linked Atlantic", key: "linked-atlantic", kind: "magazine" },
      actor: @admin
    )
    other_recording = RecordingStudioPublications.record_publication!(
      { name: "Linked Gazette", key: "linked-gazette", kind: "newspaper" },
      actor: @admin
    )
    RecordingStudioPublications.record_article!(
      publication_recording.recordable,
      { title: "House in the Rainforest", url: "https://example.com/house" },
      actor: @admin
    )
    RecordingStudioPublications.record_article!(
      publication_recording.recordable,
      { title: "Second Piece", url: "https://example.com/second" },
      actor: @admin
    )

    get "/admin/screens/publications/table", params: { search: "Linked Atlantic" }
    assert_response :success
    table = Nokogiri::HTML(response.body)
    name_link = table.css("a").find { |anchor| anchor.text.strip == "Linked Atlantic" }
    assert name_link, "expected the publication name to link to show"
    assert_equal "#{recording_studio_publications.admin_publication_path(publication_recording)}?anchor_url=%2Fadmin%2Fpublications",
                 name_link["href"]
    count_link = table.css("a").find { |anchor| anchor["href"]&.include?("/admin/articles") }
    assert count_link, "expected an article count link"
    assert_equal "2", count_link.text.strip
    assert_includes count_link["href"], "/admin/articles"
    assert_includes count_link["href"], "publication=linked-atlantic"

    get "/admin/articles", params: { publication: "linked-atlantic" }
    assert_response :success
    assert_includes response.body, 'name="publication"'
    assert_includes response.body, "linked-atlantic"

    get "/admin/screens/articles/table", params: { publication: "linked-atlantic" }
    assert_response :success
    assert_includes response.body, "House in the Rainforest"
    refute_includes response.body, "Linked Gazette"
    articles_table = Nokogiri::HTML(response.body)
    title_link = articles_table.css("a").find { |anchor| anchor.text.strip == "House in the Rainforest" }
    assert title_link, "expected the article title to link to the article show page"
    article = RecordingStudioPublications.articles_for(publication_recording.recordable).find_by!(title: "House in the Rainforest")
    article_recording = RecordingStudioPublications.article_recording_for(article)
    assert_equal "#{recording_studio_publications.admin_publication_article_path(
      publication_recording,
      article_recording
    )}?anchor_url=%2Fadmin%2Farticles", title_link["href"]

    get "/admin/screens/articles/table"
    assert_response :success
    assert_includes response.body, "House in the Rainforest"
    assert other_recording
  end

  test "publication CRUD pages do not ship a per-title Manage-access UI" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    recording = RecordingStudioPublications.record_publication!(
      { name: "No Access UI", kind: "magazine" },
      actor: @admin
    )

    [
      "/admin/publications",
      "/admin/screens/publications",
      recording_studio_publications.admin_publication_path(recording),
      recording_studio_publications.edit_admin_publication_path(recording),
      recording_studio_publications.new_admin_publication_path
    ].each do |path|
      get path
      assert_response :success, path
      refute_includes response.body, "Manage access", path
      refute_includes response.body, "Manage-access", path
    end

    admin_source = File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications/admin.rb"))
    refute_includes admin_source, "user.admin?"
    refute_includes admin_source, "Pundit"
    refute_includes admin_source, "Manage access"
  end

  test "publications persist helpers do not wrap Attachable uploads" do
    catalogue = File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications/catalogue/logos.rb"))
    controller = File.read(RecordingStudioPublications::Engine.root.join("app/controllers/recording_studio_publications/publications_controller.rb"))
    gem_api = File.read(RecordingStudioPublications::Engine.root.join("lib/recording_studio_publications.rb"))

    refute_includes catalogue, "attach_or_replace_logo!"
    refute_includes catalogue, "import_logo!"
    refute_includes catalogue, "replace_logo!"
    refute_includes controller, "attach_uploaded_logo!"
    refute_includes controller, "publication[:logo]"
    refute_includes gem_api, "attach_or_replace_logo!"
  end

  private

  def attach_png_logo!(recording)
    recording.import_attachment(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "masthead.png",
      content_type: "image/png",
      name: "Logo",
      actor: @admin
    )
  end
end
