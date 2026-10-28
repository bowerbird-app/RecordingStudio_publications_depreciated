# Migration Notes

## Current Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.2.0`)
- Accessible `~> 0.9` (dummy GitHub tag `v0.9.0`)
- Admin `~> 2.0` (dummy GitHub tag `2.0.1`)
- Attachable `~> 0.5` (dummy GitHub tag `v0.5.0`)
- Publishable `~> 0.3` (dummy GitHub tag `v0.3.0`)
- FlatPack `~> 0.1.143` (dummy GitHub tag `v0.1.329`)
- Public RubyGems and GitHub access for dependency installation

## Publications 0.4.3

Bump to `0.4.3`. Dummy no longer ships `config/initializers/flatpack_page_nav_url_aliases.rb`. Development and dummy Gemfiles pin FlatPack `v0.1.329`. The gemspec floor stays `~> 0.1.143` because this gem talks to PageNav through `recording_studio_page_nav`, not `FlatPack::PageNav::Component`. Hosts on FlatPack `>= 0.1.274` should drop any copy of that alias initializer. Cards no longer pass `style:`; use `hover:` / `border:` (or omit for default).

## Publications 0.4.1

Bump to `0.4.1`. The publications section renders total and over-time widgets for titles and articles, plus buttons to both inventories and **Publication types**. Dummy `/admin` is a host `:root` section. Hosts that still want `/admin` to open the publications section can keep `root_section: :publications`.

Title and article action screens are Recording Studio default layout. Pass `anchor_url` from the inventory or section that opened them, and keep it on redirects, or Close walks the action stack. Dummy maps layout `anchor_url` to Flatpack `anchor_href` in `config/initializers/flatpack_page_nav_url_aliases.rb`.

## Publications 0.4.0

Bump to `0.4.0`. Install the published-articles migration and register `RecordingStudioPublications::PublishedArticle`. Articles nest under a Publication recording only. Screenshots use Attachable images. Do not enable Publishable or Accessible on articles.

## Publications 0.3.0

Bump to `0.3.0`. Add Publishable `~> 0.3`, mount it at `/`, install its migrations, register `RecordingStudioPublishable::Publishable`, and call `FamilyManagement.install!`. Show and edit render `QuickActions` (not `EditButtonComponent`). Rename `LogoAuthorization` to `FamilyAuthorization` with no alias. Visible copy says publication type; the `kind` column and param stay. `install!` also wraps Preview so AdminRoot staff can open a draft from the status menu.

Do not enable Publishable on the shared catalogue. Do not assign Publishable’s `management_authorizer` from this engine.

## Publications 0.2.1

Hosts bump Accessible to `~> 0.9`, Attachable to `~> 0.5`, and Flatpack to `~> 0.1.143`. Catalogue migrations and AdminRoot wiring stay as in 0.2.0.

## Publications 0.2.0

Hosts need the engine catalogue migration plus, if missing:

- Host `admin_roots` table for the owned AdminRoot
- RecordingStudioAccessible tables (already required by 0.1.0 dummy)
- Active Storage tables
- RecordingStudioAttachable attachments table and indexes

Register `PublicationCatalogue`, `Publication`, `PublishedArticle`, `AdminRoot`, and `RecordingStudioAttachable::Attachment` before `RecordingStudio.validate_recordable_declarations!`.

Mount `RecordingStudioAccessible::Engine` at `/admin/access` so the publications section can open family Access on the owned AdminRoot. Do not enable Accessible on the shared catalogue.

Mount `RecordingStudioAttachable::Engine` so staff add or change a logo on Attachable’s screens after the title exists. Do not post `publication[logo]` from New/Edit. Keep Attachable on its blank layout so core `default_layout` does not add a second back.

Do not enable Accessible or Attachable on the shared catalogue root.

## Host layout

Authenticated dummy home and docs use the host Flatpack sidebar. Title and article new/show/edit should use `RecordingStudio::UsesDefaultLayout`. Core still puts `data-theme` on `<body>`. FlatPack themes belong on `<html>`. Hosts should add `app/views/recording_studio/_default_layout_head.html.erb` that renders `layouts/default_layout_head`, and `app/views/layouts/_default_layout_head.html.erb` that copies `data-theme="rounded"` onto `document.documentElement` with `javascript_tag nonce: true`. Do not put Sign out or a workspace switcher there.

## Verification

Install both bundles and run the complete gem and dummy app test path:

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy app from its directory for browser verification:

```bash
cd test/dummy
bin/dev
```

Use the [FlatPack repository](https://github.com/bowerbird-app/flatpack) and the live FlatPack demo linked from the top-level README for current component documentation.
