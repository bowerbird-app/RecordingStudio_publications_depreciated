# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.3] - 2026-10-28

Dummy tests FlatPack native PageNav. The gemspec floor stays `~> 0.1.143`.

### Removed
- Dummy initializer `config/initializers/flatpack_page_nav_url_aliases.rb`. FlatPack `>= 0.1.274` rejects the old `anchor_url` / `back_url` keywords, so the alias shim raises instead of mapping Close

### Changed
- Development and dummy Gemfiles pin FlatPack GitHub tag `v0.1.329` (lockfiles follow). Gem callers still use `recording_studio_page_nav(page_nav_anchor_url:)`, not `FlatPack::PageNav::Component` directly, so the gemspec stays `~> 0.1.143`
- Dummy and development pin Recording Studio GitHub tag `v4.7.1` (gemspec stays `~> 4.2`). 4.2.0’s default layout still passes PageNav `back_icon` / `anchor_label`; 4.7.1 uses `with_back` / `with_close`
- Dummy pins Admin `v2.5.1` (at the host ceiling) plus Trashable `v0.10.1` and Metrics `v0.2.3` so section widgets use Card `border: :strong` instead of `style:`
- Dummy overrides Root Switchable `v0.5.0` `root_switches/show` and Attachable `v0.5.0` upload/show so Close uses `with_close` (those engine templates still pass keywords FlatPack `v0.1.329` rejects)
- Article empty state uses EmptyState `item` (FlatPack `v0.1.329` dropped `slot`)
- Dummy lockfile takes `crass` `>= 1.0.8` and `net-ssh` `>= 7.3.5` for Bundler Audit
- Gem and dummy `FlatPack::Card::Component` callers no longer pass the removed `style:` keyword (`interactive` → `hover: :strong`, `outlined` → `border: :strong`, `default` omitted). That unblocks current FlatPack; older FlatPack only changes visuals

### Upgrade notes
- Bump to `0.4.3`
- Drop any host copy of the dummy PageNav `anchor_url` alias if you are on FlatPack `>= 0.1.274`. This gem does not require that native API at runtime
- On FlatPack that rejects Card `style:`, stop passing it. Mapping: outlined → `border: :strong`; elevated → `shadow: :md`; flat → `background: :shaded, border: :none`; interactive → `hover: :strong`; list → `hover: :subtle`; default → omit the keyword
- Dummy/dev Recording Studio pin is `v4.7.1` so default-layout PageNav matches FlatPack `>= 0.1.274`. Hosts that still pin `v4.2.0` with FlatPack `>= 0.1.274` need that 4.7.1 layout (or their own `with_back` / `with_close` override)
- Dummy Admin is `v2.5.1`. Hosts that keep Admin `2.0.1` with FlatPack `>= 0.1.237` still hit Card `style:` on widgets until they bump Admin
- Article empty-state actions use EmptyState `item`, not `slot`
- Dummy CI Ruby setup uses `3.3` (not `.ruby-version` `3.3.6`) on ubuntu-latest. `.ruby-version` is unchanged

## [0.4.1] - 2026-09-18

Publications section widgets, inventory chart title, and article edit layout.

### Changed
- Inventory Screen chart title is **Publications over time**
- Publications section shows two normal chart widgets (cumulative titles and articles over time, each with a total count) plus **Publications**, **Articles**, and **Publication types** buttons. Accessible avatars sit in the page-nav right slot on that section.
- Article show no longer lists Canonical URL
- Article edit uses a two-column Flatpack Grid (form, then screenshot) and puts Save before Cancel
- Dummy `/admin` is a host `:root` section titled **Publications demo** with one primary button to the publications section
- Title and article default-layout actions take `anchor_url` from the inventory or section that first opened them. Close, Cancel, and save redirects keep that origin so back does not loop through the action stack

### Added
- Publication types Screen at `/admin/publication_types`. Each closed category is a table row with a count of titles using it

### Upgrade notes
- Bump to `0.4.1`
- The publications section renders widgets again. Hosts that used that section as a title-only hub should add their own `:root` section if they still want a bare home
- Dummy mounts `root_section: :root`. Hosts that want `/admin` to open the publications section can keep `root_section: :publications`
- Inventory Show, Edit, and Publication links now append `anchor_url` for the inventory. Hosts that copy those URLs should keep the query so Close returns to the list
- Map Recording Studio default layout `anchor_url` to Flatpack `anchor_href` if Close does not appear (dummy: `config/initializers/flatpack_page_nav_url_aliases.rb`)

## [0.4.0] - 2026-09-17

Articles published by a title, nested under that Publication recording.

### Added
- `RecordingStudioPublications::PublishedArticle` domain child of `Publication` only (`allowed_parent_types`). Required title. Optional URL, canonical URL, published date, author (`byline`), and excerpt
- Catalogue writes `record_article!` / `revise_article!` pass `parent_recording:` to the title recording. `Recording#record` otherwise parents to the catalogue root
- Live URL uniqueness among siblings of the same title. The same URL may exist under a different title
- Optional Attachable screenshot on the article (images only). Persist stays on `import_attachment` / `replace_attachment_file`. No capture, crawl, download, or PDF storage
- Nested engine routes at `/recording_studio_publications/admin/publications/:id/articles`. Index filters: search, year, author, has URL, has screenshot, chronological or title sort
- Family articles Screen at `/admin/articles` with a publication filter. Inventory at `/admin/publications` filters by search and Publication type, and lists an Articles count that opens that Screen
- Reusable article index, card, show, and screenshot partials. Title show is an attribute table; Articles is a count that opens `/admin/articles?publication=`
- Dummy seeds three Atlantic articles. One has a screenshot
- Admin hub is title **Publications** plus one button to `/admin/publications`. Inventory **Publication** (plus heroicon) sits under the title. Table Name links to the admin show page

### Upgrade notes
- Bump to `0.4.0`
- Install the `create_recording_studio_publications_published_articles` migration
- Register `RecordingStudioPublications::PublishedArticle` in `RecordingStudio.configure`
- Article screens stay on Recording Studio default layout. Copy says **article**, not recordable names

## [0.3.0] - 2026-09-17

Publishable on each title, a public press page, family-management composition, and publication-type copy.

### Added
- `recording_studio_publishable ~> 0.3` runtime dependency. Dummy pins GitHub tag `v0.3.0`
- `RecordingStudio::Capabilities::Publishable.to` on `Publication` only, with public path `/publications/:uuid/:slug`
- `PublicationType` closed token registry. `Publication::KINDS` derives from it. `#publication_type` is a reader
- `FamilyAuthorization` replaces `LogoAuthorization` for logos and publish screens (AdminRoot first, then per-title Accessible)
- `FamilyManagement.install!` wraps the current Publishable authorizer, close-URL resolver, and Preview authorization (`FamilyAuthorization` `:view`). Idempotent. The engine does not assign those globals on boot. Draft Preview also ensures a publishable child so QuickActions Preview does not 404
- `PublishedPublication` public page model and a callback-free `PublicPublicationsController#show`
- Public layout `recording_studio_publications/public` with no PageNav and no competing Open Graph tags
- Show and edit render Publishable’s `QuickActions` dropdown (not `EditButtonComponent`). Closed labels are Draft, a scheduled date, or Published. Inline publish and unpublish stay on the title page
- Hub line chart **Publications over time** (`widgets.publications.over_time`) before the type chart

### Changed
- Admin section title is **Admin publications**. Screen, widget, catalogue label, and dummy `app_name` stay **Publications**. Keys stay `publications`
- Visible copy says **Publication type**. The `kind` column, param, sort key, and `widgets.publications.by_kind` stay `kind`
- Hub type chart title is **Publication types**
- Hub primary action is **Publication** with Flatpack’s plus heroicon. Secondary inventory action is **View all**. Admin 2.0.1 `Section#link` has no icon field and passes `url:` (Flatpack only links on `href:`), so this gem overrides `sections/show` for those two Button props. Inventory Screen still uses **New**
- Dummy authenticated home and docs use Flatpack `flat_pack_sidebar`. Recording Studio default layout stays on gem clear-action screens (title new/show/edit). Attachable stays blank so that layout does not add a second back

### Upgrade notes
- Bump to `0.3.0`
- Add `recording_studio_publishable ~> 0.3`, install its migrations, register `RecordingStudioPublishable::Publishable`, and mount `RecordingStudioPublishable::Engine` at `/`. Replace `EditButtonComponent` with `QuickActions::Component` on host title pages
- Call `RecordingStudioPublications::FamilyManagement.install!` after any host Publishable authorizer for other types. Preview for titles uses family `:view` (AdminRoot first), not a per-title Accessible grant alone
- Rename `LogoAuthorization` callers to `FamilyAuthorization`. There is no alias
- Scan Publishable views and components in Tailwind `@source`
- Form posts stay `publication[kind]`. Only the visible label changed
- Dummy hosts that put home/docs on Recording Studio default layout should switch those pages to a host sidebar. Title new/show/edit stay on `UsesDefaultLayout`

## [0.2.1] - 2026-09-02

Pins, dummy Tailwind scan for system gem paths, real seed logos, and dummy Admin recapture. Catalogue and CRUD stay as in 0.2.0.

### Changed
- Accessible gemspec `~> 0.9`, dummy GitHub tag `v0.9.0` (was `~> 0.6` / `v0.7.0`)
- Attachable gemspec `~> 0.5`, dummy GitHub tag `v0.5.0` (was `~> 0.4` / `0.4.0`)
- Flatpack gemspec `~> 0.1.143`, dummy GitHub tag `v0.1.143` (was `~> 0.1.133` / `v0.1.133`)
- Dummy Tailwind `@source` now also scans `/usr/local/lib/ruby/gems/**/bundler/gems` so Flatpack Grid/Table classes generate on Cloud Agent images that do not use `vendor/bundle`
- Dummy seed logos are a real 128px PNG (`test/dummy/db/seed_assets/publication_logo.png`), not a 1×1 pixel
- Dropped the copied Admin `sections/show` override. Family Admin 2.0.1 already renders Access avatars on the section
- Dummy Admin screens recaptured as public `doc/review/*.png` (hub, inventory, new, show, edit, Attachable add logo, Attachable change logo). Inventory shows the family Screen chart only. There is no compact titles-over-time card.

Left with family Admin / Flatpack, not forked here. Hub New/All publications render as `<button url>` because Admin 2.0.1 `sections/show` passes `url:` and Flatpack Button only links on `href:`. Titles-by-kind integer counts still draw on a 0.0–1.0 axis. Inventory table heading stays “Table data” (Admin `title` has no public hide API). Full chart widgets sit in the first cell of a 3-column Grid.

Recording Studio stays `~> 4.2` / dummy `v4.2.0`. Admin stays `~> 2.0` / dummy `2.0.1`. Root Switchable dummy stays `v0.5.0`. Do not pin unreleased Flatpack `0.1.144`.

### Upgrade notes
- Bump to `0.2.1`
- Hosts bump Accessible to `~> 0.9`, Attachable to `~> 0.5`, and Flatpack to `~> 0.1.143`
- Keep Recording Studio `~> 4.2` and Admin `~> 2.0`

## [0.2.0] - 2026-08-22

Shared publication catalogue and family-admin CRUD. Stacked on 0.1.0 identity/pins. No public Publishable pages.

### Added
- `RecordingStudioPublications::PublicationCatalogue` shared root (`label: "Publications"`, `root: true`, `shared: true`). One per host. Accessible and Attachable are not enabled on this root
- `RecordingStudioPublications::Publication` nested only under that catalogue: required name, required kind (`magazine`, `newspaper`, `journal`, `site`, `broadcast`), optional website, stable key
- One Attachable logo per publication (images only). New has no logo field. Show and edit link to Attachable’s add (`/recording_studio_attachable/recordings/:id/attachments/upload`) and change (`/recording_studio_attachable/attachments/:id`) screens. Persist stays on `import_attachment` / `replace_attachment_file`
- Inventory uses the family Admin Screen template. New is a registered Screen `button` to this gem’s New page. Family table heading stays “Table data” (Admin `title` has no public hide API)
- Accessible enabled on Publication for later per-title grants. No Manage-access UI
- Family admin section `publications`: hub count widget (`type :number`), titles-by-kind bar chart (`type :chart`, `chart_type :bar`), inventory family Screen chart (`type :area`, no compact over-time widget), Screen `filter :search`, Resource `required_role: :admin` for writes, new/show/edit forms. Inventory table is Name, Kind, Website, Actions
- Section Access avatars on the owned AdminRoot via `recording_studio_accessible_avatars` and dummy mount `RecordingStudioAccessible::Engine` at `/admin/access`
- Dummy `AdminRoot` (`shared: false`) with `AllowsAdminSections`, Accessible, and `section :publications`
- Dummy seeds for The Atlantic, The Guardian, Nature, BBC News, and The Verge

### Upgrade notes
- Bump to `0.2.0` and install engine migrations (`create_recording_studio_publications_catalogue`)
- Register `RecordingStudioPublications::PublicationCatalogue` and `RecordingStudioPublications::Publication` in host `recordable_types`
- Add an owned host `AdminRoot` (`shared: false`), enable Accessible on it, and `section :publications`
- Configure `RecordingStudioAdmin` access and site-admin resolvers to that AdminRoot recording
- Mount `recording_studio_admin_for` and `RecordingStudioPublications::Engine`
- Mount `RecordingStudioAccessible::Engine` at `/admin/access` so the publications section can open family Access on the AdminRoot
- Install Attachable migrations and Active Storage if the host does not already have them
- Mount `RecordingStudioAttachable::Engine` and keep logo add/replace on those screens. Do not post `publication[logo]` from New/Edit
- Keep Attachable on its blank layout. Core `default_layout` always renders a back; wrapping Attachable in that layout stacks a second PageNav on add/change
- Bootstrap first-owner admin access on the AdminRoot recording. Do not grant Accessible on the shared catalogue
- Keep `UsesDefaultLayout` plus the html `data-theme="rounded"` head workaround from 0.1.0
- No public Publishable page ships in this version

## [0.1.0] - 2026-08-22

First `recording_studio_publications` identity. This release is rename, dependency pins, and dummy host theme only. It does not ship a publication directory.

### Added
- Gem name `recording_studio_publications` and namespace `RecordingStudioPublications`
- Gemspec pins: `recording_studio ~> 4.2`, `rails ~> 8.1.0`, `recording_studio_accessible ~> 0.6`, `recording_studio_admin ~> 2.0`, `recording_studio_attachable ~> 0.4`, `flat_pack ~> 0.1.133`
- Dummy host copies FlatPack `rounded` onto `<html>` via `layouts/_default_layout_head`, rendered from the core `recording_studio/default_layout_head` hook
- Dummy `recordable_types` includes `RecordingStudioAttachable::Attachment` so the Attachable pin can boot without enabling the capability

### Changed
- Dummy GitHub tags: Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, FlatPack `v0.1.133`
- Dummy authenticated pages stay on `RecordingStudio::UsesDefaultLayout`; Devise keeps its own sign-in layout
- Dummy PageNav no longer puts Sign out or the workspace switcher in the default-layout slot

### Upgrade notes
- Require `recording_studio_publications` and mount `RecordingStudioPublications::Engine`
- Point host or dummy Gemfiles at Recording Studio `v4.2.0`, Accessible `v0.7.0`, Attachable `0.4.0`, Admin `2.0.1`, and FlatPack `v0.1.133`
- Keep `RecordingStudio::UsesDefaultLayout` for authenticated screens. If core puts theme on `body`, render `layouts/_default_layout_head` from the `recording_studio/default_layout_head` hook so `html` gets `data-theme="rounded"`
- Do not put Sign out or a workspace switcher in the default-layout slot or that head partial

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_publications/compare/v0.4.3...HEAD
[0.4.3]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.4.3
[0.4.1]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.4.1
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.3.0
[0.2.1]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.2.1
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_publications/releases/tag/v0.1.0
