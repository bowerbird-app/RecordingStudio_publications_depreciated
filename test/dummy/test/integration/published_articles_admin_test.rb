# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"
require "nokogiri"

class PublishedArticlesAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  ONE_PIXEL_PNG = Base64.decode64(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
  ).freeze

  setup do
    @admin = User.find_or_create_by!(email: "admin-articles-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    @admin_recording = admin_root_recording_for_test
    Current.actor = @admin
  end

  teardown do
    Current.actor = nil
  end

  test "admin can CRUD an article under a publication and attach a screenshot" do
    bootstrap_owner_access!(@admin, @admin_recording)
    sign_in @admin
    publication_recording = RecordingStudioPublications.record_publication!(
      { name: "Dezeen", kind: "site", website: "https://www.dezeen.com" },
      actor: @admin
    )

    get recording_studio_publications.admin_publication_path(publication_recording)
    assert_response :success
    assert_includes response.body, "Articles"
    show_page = Nokogiri::HTML(response.body)
    articles_link = show_page.css("a").find { |anchor| anchor["href"]&.include?("/admin/articles") }
    assert articles_link, "expected an Articles count link on show"
    assert_equal "0", articles_link.text.strip
    assert_includes articles_link["href"], "/admin/articles"
    assert_includes articles_link["href"], "publication="
    refute_includes response.body, "No articles yet."
    refute_includes response.body, "Add article"
    refute_includes response.body, "View all"
    refute_includes response.body, "PublishedArticle"
    refute_includes response.body, "recordable"

    get recording_studio_publications.admin_publication_articles_path(publication_recording)
    assert_response :success
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    assert_includes response.body, "Search"
    assert_includes response.body, "Has screenshot"
    assert_includes response.body, "Add article"
    refute_includes response.body, "FileInput"

    get recording_studio_publications.new_admin_publication_article_path(publication_recording)
    assert_response :success
    assert_includes response.body, "New article"
    assert_includes response.body, "Title"
    assert_includes response.body, "Author"
    assert_includes response.body, "Excerpt"
    refute_includes response.body, "article[screenshot]"
    refute_includes response.body, "FileInput"
    refute_includes response.body, "multipart/form-data"

    post recording_studio_publications.admin_publication_articles_path(publication_recording), params: {
      article: {
        title: "House in the Rainforest",
        url: "https://www.dezeen.com/house-in-the-rainforest",
        canonical_url: "https://www.dezeen.com/house-in-the-rainforest/",
        published_on: "2024-03-12",
        byline: "Jane Architect",
        excerpt: "A house designed around the existing trees."
      }
    }

    article = RecordingStudioPublications.articles_for(publication_recording.recordable).find_by!(title: "House in the Rainforest")
    article_recording = RecordingStudioPublications.article_recording_for(article)
    assert_equal publication_recording, article_recording.parent_recording
    assert_redirected_to recording_studio_publications.admin_publication_article_path(
      publication_recording,
      article_recording
    )
    assert_nil RecordingStudioPublications.screenshot_recording_for(article)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "House in the Rainforest"
    assert_includes response.body, "Jane Architect"
    refute_includes response.body, "Canonical URL"
    assert_includes response.body, "Add screenshot"
    refute_includes response.body, "Change screenshot"
    refute_includes response.body, "FileInput"
    assert_includes response.body, recording_studio_attachable.recording_attachment_upload_path(article_recording)

    screenshot = article_recording.import_attachment(
      io: StringIO.new(ONE_PIXEL_PNG),
      filename: "screenshot.png",
      content_type: "image/png",
      name: "Screenshot",
      actor: @admin
    )

    get recording_studio_publications.admin_publication_article_path(publication_recording, article_recording)
    assert_response :success
    assert_includes response.body, "Change screenshot"
    refute_includes response.body, "Add screenshot"
    assert_includes response.body, recording_studio_attachable.attachment_path(screenshot)

    get recording_studio_publications.admin_publication_articles_path(publication_recording)
    assert_response :success
    assert_includes response.body, "House in the Rainforest"
    assert_includes response.body, "House in the Rainforest screenshot"
    article_href = recording_studio_publications.admin_publication_article_path(
      publication_recording,
      article_recording
    )
    assert_select "a.fp-card-hover-strong[href='#{article_href}']", minimum: 1

    get recording_studio_publications.admin_publication_articles_path(publication_recording, params: { q: "Rainforest" })
    assert_response :success
    assert_includes response.body, "House in the Rainforest"

    get recording_studio_publications.edit_admin_publication_article_path(publication_recording, article_recording)
    assert_response :success
    assert_includes response.body, "Edit article"
    assert_includes response.body, "Change screenshot"
    assert_includes response.body, "grid-cols-2"
    save_index = response.body.index(">Save<")
    cancel_index = response.body.index(">Cancel<")
    assert save_index, "expected a Save button on edit"
    assert cancel_index, "expected a Cancel button on edit"
    assert save_index < cancel_index, "Save should come before Cancel"

    patch recording_studio_publications.admin_publication_article_path(publication_recording, article_recording),
          params: {
            article: {
              title: "House in the Rainforest",
              url: "https://www.dezeen.com/house-in-the-rainforest",
              byline: "Jane Architect",
              excerpt: "Revised excerpt."
            }
          }
    assert_redirected_to recording_studio_publications.admin_publication_article_path(
      publication_recording,
      article_recording
    )
    follow_redirect!
    assert_includes response.body, "Revised excerpt."

    get recording_studio_publications.admin_publication_path(publication_recording)
    assert_response :success
    refute_includes response.body, "House in the Rainforest"
    refute_includes response.body, "View all"
    refute_includes response.body, "Add article"
    show_page = Nokogiri::HTML(response.body)
    articles_link = show_page.css("a").find { |anchor| anchor["href"]&.include?("/admin/articles") }
    assert articles_link, "expected an Articles count link on show"
    assert_equal "1", articles_link.text.strip
    assert_includes articles_link["href"], "/admin/articles"
    assert_includes articles_link["href"], "publication="
  end

  test "view-only users cannot create articles" do
    view_only = User.find_or_create_by!(email: "view-only-articles-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    bootstrap_owner_access!(@admin, @admin_recording)
    grant_admin_access_for_test!(recording: @admin_recording, actor: view_only, role: :view)
    sign_in view_only

    publication_recording = RecordingStudioPublications.record_publication!(
      { name: "View Only Mag", kind: "site" },
      actor: @admin
    )

    get recording_studio_publications.new_admin_publication_article_path(publication_recording)
    assert_response :forbidden
  end
end
