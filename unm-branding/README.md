# UNM branding integration

The original request referenced an `unm-branding/` folder in `xanthan-web/xanthan-web.github.io`; its main branch did not contain that folder when inspected on September 12, 2026. Branding comes from the separately supplied [Xanthan UNM extension](https://github.com/amaranth-unm/xanthan-unm).

`upstream/` preserves the extension's original layout, includes, and README at commit `d7f0caf8c77677480486b55a7159f17741b1c732`. This reference folder is excluded from the published site.

The active branding uses the revised extension at commit `ab21b0a6a434783e78a3ee9be4195c5db9e03a8d`, developed alongside this migration and published to its main branch on September 13, 2026. It matches UNM's narrow top utility bar, white hanging wordmark, and cherry university footer without loading UNM's global Bootstrap styles or secondary navigation row.

Active files:

- `_layouts/base-unm.html`: the center's custom layout, preserving its banner, breadcrumbs, and content regions.
- `_includes/unm/`: the shared utility header, university search, head adapter, opt-in analytics, and university footer; `footer-site.html` holds the center's contact information.
- `assets/unm/`: packaged official UNM wordmarks and footer background.
- `assets/css/unm.css` and `assets/js/unm.js`: scoped branding and keyboard-friendly disclosure behavior from the revised extension.
- `assets/css/themes/unm.css`: site-wide cherry/silver theme and typography.
- `assets/css/community.css`: center-specific layout.

The shared UNM shell has a 1170px maximum width and 15px gutters. Community Geography uses these same dimensions for its home content, project directory, navigation, and center footer. Xanthan's article grid remains responsible for reading width. Brand images originate from `webcore.unm.edu`; university fonts use its hosted font stylesheet.

For future upgrades, copy the shared university components and assets while retaining this site's custom base layout and `footer-site.html`. The original university analytics ID remains explicit in `_config.yml`; the revised extension itself has no default tracking ID.
