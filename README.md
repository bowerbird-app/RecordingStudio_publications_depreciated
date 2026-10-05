# RecordingStudioPublications

Publication directory addon for Recording Studio 4.x hosts.

This gem is the `recording_studio_publications` engine (`RecordingStudioPublications`). Version 0.4.1 restores the publications section widgets (totals and over-time charts for titles and articles) and buttons to both inventories. Version 0.4.0 adds `PublishedArticle` children under each title, an article index, and optional Attachable screenshots. Version 0.3.0 added Publishable on each title, a public page at `/publications/:uuid/:slug`, and family-management composition. It keeps the 0.2 grant-less shared catalogue and family-admin CRUD, and pins Accessible `~> 0.9`, Attachable `~> 0.5`, Publishable `~> 0.3`, and Flatpack `~> 0.1.143`. It does not ship Featured In or a per-title Manage-access UI.

## What's Included

- **PublicationCatalogue** — one shared Recording Studio root per host (`label: "Publications"`, `root: true`, `shared: true`). Same idea as `RecordingStudioUser::People`. Accessible and Attachable stay off this root.
- **Publication** — nested titles under that catalogue only. Required name, required publication type stored as `kind` (`magazine`, `newspaper`, `journal`, `site`, `broadcast`), optional website, and a stable key.
- **PublishedArticle** — nested articles under a Publication only. Required title, optional URL, canonical URL, published date, author, and excerpt. The parent recording is the Publication that published the article. There is no `publication_id` column.
- **One Attachable logo** per title. Images only. Create the title first, then add or change the logo on Attachable’s own upload and attachment screens. Persist stays on `import_attachment` / `replace_attachment_file`. There is no FileInput on New or Edit, and no Publications upload wrapper.
- **One Attachable screenshot** per article, the same way. Store and retrieve an image. This gem does not capture, crawl, or download pages, and it does not store article PDFs.
- **Family admin** — one `publications` section in RecordingStudioAdmin 2.0. The section title is **Publications**, with **Publications** and **Articles** buttons to `/admin/publications` and `/admin/articles`. Two normal chart widgets show cumulative titles and articles over time plus each total. Accessible avatars sit in the page-nav right slot. Staff CRUD is gated by an owned host `AdminRoot` plus `RecordingStudioAdmin::Resource` `required_role: :admin`. Inventory is a family Admin Screen: search, a **Publication** button (plus heroicon) under the title, a publications-over-time chart, and a table of Name (links to the admin show page), Publication type, Website, and Articles (count linking to `/admin/articles` with that title selected). Articles is a second family Screen with a publication filter. Nested article new/show/edit stay this gem’s controllers. Admin does not need a grant on each title.
- **Publishable on Publication only** — one `RecordingStudioPublishable::Publishable` child holds slug, schedule, SEO, and social state. Staff change state from show/edit with Publishable’s `QuickActions` dropdown. Readers hit `/publications/:uuid/:slug` without signing in. Draft, scheduled, and expired URLs 404. A stale slug redirects. `PublicationCatalogue` stays capability-free.
- **Dummy host** (`test/dummy/`) — thin Devise host with a Flatpack sidebar for home and docs, FlatPack Rounded on `<html>`, seeded titles with a real 128px logo PNG, and `/admin` as a demo home (**Publications demo** plus a primary button to the publications section). Title new/show/edit stay on Recording Studio’s default layout. Dummy Tailwind `@source` scans Flatpack, Admin, and Attachable under `vendor/bundle`, `/usr/local/bundle`, and `/usr/local/lib/ruby/gems` so Cloud Agent images still emit Grid/Table classes.

This is a directory gem, not a two-sided marketplace. Hosts stay thin: they register recordable types, own `AdminRoot`, seed first staff access, and mount the engines.

## Quick Start

### GitHub Codespaces (Recommended)

1. Click **Code** → **Codespaces** → **Create codespace**
2. Wait for setup to complete
3. Run:
   ```bash
   cd test/dummy
   bin/rails db:setup
   bin/dev
   ```
4. Open port 3000, sign in at `/users/sign_in`, then open `/admin`

Dummy credentials (`test/dummy/config/credentials.yml.enc`) are encrypted with the shared RecordingStudio_* development master key. Set `RAILS_MASTER_KEY` or put that key in `test/dummy/config/master.key` (gitignored). Keep the encrypted file; do not generate a per-repo dummy key.

### Login Credentials

| Field    | Value             |
|----------|-------------------|
| Email    | admin@admin.com   |
| Password | Password          |

The login form is prefilled with these credentials for fast access. `member@admin.com` / `Password` is a signed-in user without AdminRoot access.

### Useful Routes

- `/` — dummy host home
- `/users/sign_in` — Devise sign-in
- `/admin` — dummy admin home (title **Publications demo** and a primary button to the publications section)
- `/admin/sections/publications` — publications section (count-plus-chart widgets, Accessible avatars, and buttons to both inventories)
- `/admin/access` — Accessible engine for AdminRoot grants
- `/admin/publications` — inventory (family search filter; chart and table still load from `/admin/screens/publications/...`)
- `/admin/articles` — articles inventory (filter by publication)
- `/publications/:uuid/:slug` — public page for a currently published title
- `/recording_studio_publications/admin/publications/:id/articles` — articles published by that title (search, year, author, URL, screenshot, sort)
- `/recording_studio_publications/admin/publications/new` — new title (no logo field)
- `/recording_studio_attachable/recordings/:id/attachments/upload` — Attachable add-logo screen
- `/recording_studio_attachable/attachments/:id` — Attachable change-logo screen
- `/docs/install`, `/docs/config`, `/docs/recordable_types`, `/docs/recordings_tree`, `/docs/gem_views`, `/docs/methods` — dummy-only sandbox pages

## Architecture

### Shared catalogue

`RecordingStudioPublications::PublicationCatalogue` is the forest root. There is one per host. Nobody owns the forest through that node.

```ruby
RecordingStudioPublications.catalogue_root.record(RecordingStudioPublications::Publication) do |publication|
  publication.name = "The Atlantic"
  publication.kind = "magazine"
  publication.website = "https://www.theatlantic.com"
end
```

```ruby
RecordingStudioPublications.record_article!(publication, {
  title: "House in the Rainforest",
  url: "https://www.theatlantic.com/house-in-the-rainforest",
  published_on: Date.new(2024, 3, 12),
  byline: "Jane Architect",
  excerpt: "A house designed around the existing trees."
}, actor: current_user)
```

`PublishedArticle` may not nest under Workspace, Folder, or the catalogue. Pass `parent_recording:` when calling `Recording#record` directly. `record` otherwise parents to the catalogue root.

`Publication` may enable Accessible so later per-title grants can work. v1 does not ship a Manage-access UI. Admin CRUD authorizes against the host AdminRoot, not against a grant on the title.

Do not enable `:accessible` or Attachable on the shared catalogue. Accessible 0.9 rejects grants on shared roots. Attachable 0.5 is for domain children under that root.

### Host AdminRoot

The host owns a separate admin root (`shared: false`) and opts the publications section in:

```ruby
class AdminRoot < ApplicationRecord
  include RecordingStudioAdmin::AllowsAdminSections

  recording_studio_recordable label: "Admin", root: true, shared: false
  RecordingStudio.enable_capability(:accessible, on: self)

  recording_studio_admin_sections do
    section :publications
  end
end
```

Seed first staff with `RecordingStudioAccessible.bootstrap_owner_access!` on that admin recording. Do not use `user.admin?`, Pundit, or a custom ACL.

### Family admin

The gem registers a Section, Screen, Resource, and widgets with `blast_radius :site`:

| Surface | Path |
| --- | --- |
| Section | `/admin/sections/publications` (or `/admin` when that is the root section) |
| Access | `/admin/access/recordings/:admin_root_id/accesses` |
| Inventory | `/admin/publications` |
| Articles inventory | `/admin/articles` |
| Publication types | `/admin/publication_types` |
| New / show / edit | `/recording_studio_publications/admin/publications/...` |
| Articles for one title | `/recording_studio_publications/admin/publications/:id/articles` |

The publications section has **Publications**, **Articles**, and **Publication types** buttons and two normal chart widgets (cumulative titles and articles over time, each with a total count). Accessible avatars sit in the page-nav right slot. Each widget and button links to its inventory or the types table. Family Admin 2.0.1 only enables Screens whose section-link URLs match `admin_screen_path` (`/admin/screens/:key`), so the section also keeps hidden family-path links that the override does not render. Inventory puts **Publication** (plus heroicon) in the PageTitle slot, not the top-right PageNav. Inventory filters are search plus **Publication type** (the closed `kind` list). The inventory table is Name (admin show), Publication type, Website, Articles (count → `/admin/articles?publication=`), and Actions — no Key column. The inventory chart title is **Publications over time**. The publication types Screen lists every closed category with a count of titles using it (count → inventory filtered by that type). The articles Screen lists Title, Publication, Published, and Author, with a publication filter. Article new/show/edit stay nested under the title. The form still posts `publication[kind]`. Admin’s table `title` only assigns a present value, so the family default “Table data” heading stays. Do not put Accessible on the shared catalogue. FlatPack `Chart::Component` is rendered by family Admin — this gem does not add a chart library. Admin 2.0.1 `Section#link` cannot pass `icon:` or `href:`, so section and inventory templates are overridden at `app/overrides/recording_studio_admin/sections/show.html.erb` and `screens/show.html.erb`.

New, show, and edit stay this gem’s controllers and forms. New/edit forms are Name, Key, Publication type, and Website — one field per row. Publication type is the closed `kind` list, not a second recordable. Cancel and Save are separate Buttons. Show (and Edit) display the current logo when one exists, plus a FlatPack Button to Attachable’s add or change screens. Show is an attribute table: Name, Key, Publication type, Website, and Articles (count → `/admin/articles?publication=`). Nested article index, new, show, and edit stay this gem’s controllers. Article forms are Title, URL, Canonical URL, Published date, Author, and Excerpt. Article show omits Canonical URL. Article edit puts the form in column one of a two-column Flatpack Grid and the screenshot in column two, with Save before Cancel. Screenshots use Attachable after the article exists. When Edit is allowed, show and edit render Publishable’s `QuickActions` dropdown (closed label **Draft**, a scheduled date, or **Published**). The menu holds Publish now, Schedule or Change schedule, Unpublish, Preview or View, then SEO and Social. Preview is a staff-only rendering of the public page (badge **Preview**, `noindex`); it is not the live `/publications/:uuid/:slug` URL. Inline publish and unpublish stay on the title page. New has no logo field.

### Capabilities

| Recordable | Accessible | Attachable | Publishable |
| --- | --- | --- | --- |
| `PublicationCatalogue` | No | No | No |
| `Publication` | Yes (no Manage-access UI) | Yes, images only, one logo | Yes |
| `PublishedArticle` | No | Yes, images only, one screenshot | No |
| Host `AdminRoot` | Yes | No | No |
| Host `Workspace` | Dummy only | No | No |

Logo add/replace is Attachable’s own UI. Authorization for logos and publish screens goes through `FamilyAuthorization`: AdminRoot first, then a per-title Accessible grant. Hosts call `RecordingStudioPublications::FamilyManagement.install!` after any other Publishable authorizer so Publication parents use family policy and other types keep their previous callable. Install also wraps Publishable Preview: family staff are checked with `:view` on AdminRoot (then the title), and a draft without a publishable child gets one so the public template can render. The engine does not write Publishable’s global authorizer on boot. Mount `RecordingStudioAttachable::Engine` and `RecordingStudioPublishable::Engine` in the host.

### FlatPack UI

All views use FlatPack ViewComponents. The live reference is [flatpack.bowerbird.io](https://flatpack.bowerbird.io/). Theme `rounded` is monochrome charcoal. Use family admin screens, widgets, and resources — do not invent a second admin stack.

## Installing in a host

1. Add the gem and the family pins from the gemspec / dummy Gemfile.
2. Run `rails generate recording_studio_publications:install`.
3. Run `rails generate recording_studio_publications:migrations`.
4. Install Accessible, Admin, Attachable, and Publishable migrations if the host does not already have them. Attachable also needs Active Storage.
5. Register `AdminRoot`, `RecordingStudioPublications::PublicationCatalogue`, `RecordingStudioPublications::Publication`, `RecordingStudioPublications::PublishedArticle`, `RecordingStudioAttachable::Attachment`, and `RecordingStudioPublishable::Publishable` in `RecordingStudio.configure`.
6. Create an owned `AdminRoot`, enable Accessible on it, and `section :publications`. Add a host `:root` section only when `/admin` should be a separate home.
7. Point `RecordingStudioAdmin` `access_recording_resolver` and `site_admin_recording_resolver` at that admin recording.
8. Mount `recording_studio_admin_for :admin, at: "/admin", root_section: :publications` to land on the publications section, or `root_section: :root` when the host owns a demo/home section.
9. Mount `RecordingStudioAccessible::Engine` at `/admin/access` so the section Access avatars open the family Access UI on the AdminRoot.
10. Mount `RecordingStudioAttachable::Engine` (dummy: `/recording_studio_attachable`) so add/change logo can use Attachable’s screens. Keep Attachable on its blank layout so core `default_layout` does not add a second back.
11. Add `recording_studio_publishable ~> 0.3`, install its migrations, and mount `RecordingStudioPublishable::Engine` at `/`. Call `RecordingStudioPublications::FamilyManagement.install!` from a host initializer. Scan Publishable views and components in Tailwind `@source`.
12. Bootstrap first-owner admin access on the AdminRoot recording.

Authenticated dummy home and docs use Flatpack `flat_pack_sidebar`, like other Recording Studio gems. Publication and article new/show/edit stay on `RecordingStudio::UsesDefaultLayout`. Inventory Show, Edit, and Publication links pass `anchor_url` from that list so Close, Cancel, and save return there instead of walking the action stack. If core puts `data-theme` on `<body>`, render `layouts/_default_layout_head` from the `recording_studio/default_layout_head` hook so `<html>` gets `data-theme="rounded"`. Do not put Sign out or a workspace switcher in that default-layout slot; those belong on the host sidebar. Dummy maps layout `anchor_url` to Flatpack `anchor_href` in `config/initializers/flatpack_page_nav_url_aliases.rb`.

## Out of scope

- Featured In / press-kit foreign keys
- Moveable, Sitemaps, journalist or submission flows
- ISSN / country
- Webpage screenshot capture, crawling, or remote download
- Article PDF storage
- A second admin app, host Tailwind themes, or CSS forks

## Tech Stack

| Component       | Version |
|-----------------|---------|
| Ruby            | 3.3+    |
| Rails           | 8.1+    |
| PostgreSQL      | 16      |
| TailwindCSS     | 4       |
| RecordingStudio | 4.x (`~> 4.2` in the gemspec; dummy GitHub tag `v4.2.0`) |
| Accessible      | `~> 0.9` (dummy GitHub tag `v0.9.0`) |
| Admin           | `~> 2.0` (dummy GitHub tag `2.0.1`) |
| Attachable      | `~> 0.5` (dummy GitHub tag `v0.5.0`) |
| Publishable     | `~> 0.3` (dummy GitHub tag `v0.3.0`) |
| Root Switchable | dummy GitHub tag `v0.5.0` |
| FlatPack        | `~> 0.1.143` (dummy GitHub tag `v0.1.143`) |
| Devise          | latest  |

## Documentation

Dummy admin viewports live in `doc/review/` (`publications-admin-hub.png`, inventory, new, show, edit, plus Attachable add/change). Recapture those from the dummy host with `html data-theme="rounded"` and seeded titles. Dummy `/admin` is **Publications demo** plus a primary button to the publications section. The publications section must show two count-plus-chart widgets, Accessible avatars, and buttons to both inventories. Inventory must show **Publication** under the title, name links, and an Articles count.

The original gem template documentation is preserved in `docs/gem_template/` as architectural reference material. This README, `CHANGELOG.md`, and the dummy app are the source of truth for the publications directory.
