# Center for Community Geography

The R.H. Mallory Center for Community Geography at the University of New Mexico. Migrated from [communitygeography.unm.edu](https://communitygeography.unm.edu/) to Jekyll and GitHub Pages using [Xanthan](https://github.com/xanthan-web/xanthan-web.github.io) and the [Xanthan UNM extension](https://github.com/amaranth-unm/xanthan-unm).

## Editing the site

Each original HTML page has a matching Markdown file. For example, edit `about/our-team.md` to update `/about/our-team.html`. Keep the `permalink` value in its opening YAML block to preserve existing links.

- `index.md`: homepage introduction.
- `_includes/community/home-news.md`: homepage news list, preserved from the source homepage.
- `about/`, `community-geography/`, `news/`, `funding/`, `events/`, `donate/`, and `projects/`: page content and local media. Several original event and news pages also live at the root.
- `_data/nav-top.yml`: menus. News years are displayed newest first.
- `_data/projects.yml`: current project directory cards. The past-projects page retains its source content.
- `_config.yml`: site identity, contact information, branding theme, and publishing address.
- `assets/css/themes/unm.css`: UNM colors and typography through Xanthan's theme variables.
- `assets/css/unm.css`: scoped university utility bar, hanging logo, and footer.
- `assets/css/community.css`: center-specific page layout.
- `unm-branding/`: branding provenance and the unchanged upstream extension for reference.

Images and downloads retain their original paths, including source files that have no file extension. Complex image formatting and embedded resources remain small HTML elements within otherwise editable Markdown. External resources remain external links.

## Local preview

Use Ruby 3.3 or later and Bundler:

```sh
bundle install
bundle exec jekyll serve --port 4178
```

Open `http://localhost:4178/communitygeography/`. To build and check all internal links, images, preserved routes, and the search index:

```sh
bundle exec jekyll build --strict_front_matter
bundle exec ruby scripts/check-site.rb _site
```

University analytics runs only in production builds. The original university Google Tag Manager ID is preserved in `_config.yml`; remove it to disable it. Optional separate Google Analytics is blank.

## Publishing

GitHub Pages address: [amaranth.unm.edu/communitygeography](https://amaranth.unm.edu/communitygeography/), using the organization's existing custom domain.

Push to `main`. The `Deploy Jekyll site to Pages` workflow builds, checks, and publishes the site. GitHub Pages must use **GitHub Actions** as its build source. The workflow reads the actual Pages hostname and project path from GitHub, so it also handles an organization with an existing custom domain.

## Moving the UNM domain

The migration initially publishes at this repository's GitHub Pages address. The existing UNM domain is not changed by a repository push.

When UNM is ready to switch:

1. Verify `communitygeography.unm.edu` ownership in the GitHub organization if required by its domain policy.
2. Set `communitygeography.unm.edu` as this repository's custom domain under Settings → Pages.
3. Have the UNM DNS administrator set the `communitygeography.unm.edu` CNAME to `amaranth-unm.github.io` (a hostname, without the repository path).
4. After GitHub provisions its certificate, enable **Enforce HTTPS**.
5. Set local `_config.yml` defaults to `url: https://communitygeography.unm.edu` and `baseurl: ""`, and rerun the deployment. The workflow already uses the address supplied by Pages.
6. Check the homepage, a nested project, a download, and site search at the custom domain.

The preserved `.html` URLs allow existing links to continue working after the switch. No `CNAME` file is committed during staging.

## Migration record

See `migration/manifest.json` for source URLs, destination files, downloaded assets, and unavailable source links; see `migration/README.md` for review notes. The source capture is dated September 12, 2026. Original copy and dates have been preserved, including historical announcements and inconsistencies that need an editorial decision.

`scripts/crawl.rb` captures the public source site into ignored `.migration/` files. `scripts/convert.rb` recreates the initial import from that capture and requires Pandoc. **Do not rerun the converter after editing pages without saving those edits: it overwrites imported content.** Neither script is needed for ordinary editing or deployment.

## Credits and licensing

Xanthan framework source: `xanthan-web/xanthan-web.github.io`, commit `5e106aac8ba5c93467d638db02ffe8430346ecd6`.

UNM extension source: `amaranth-unm/xanthan-unm`, revised commit `ab21b0a6a434783e78a3ee9be4195c5db9e03a8d`. The original extension at `d7f0caf8c77677480486b55a7159f17741b1c732` is archived in `unm-branding/upstream/`.

The framework and derivative code follow the upstream GPL-3.0 license in `LICENSE`. UNM trademarks and the source site's text, photographs, project materials, and third-party resources retain their respective rights; this migration does not relicense them.
