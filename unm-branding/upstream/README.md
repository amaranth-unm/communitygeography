# Xanthan UNM Extension

Add University of New Mexico branding, navigation, and footer to your [Xanthan](https://github.com/fredgibbs/xanthan) static website.

## What This Extension Provides

This extension adds UNM-specific elements to a Xanthan site:
- **UNM Header** - Official UNM branding and navigation
- **Department Navigation** - Customizable departmental links
- **Site Navigation** - Your site's menu below the UNM header
- **UNM Footer** - Official UNM footer with required links
- **Google Tag Manager** - UNM analytics integration

## Prerequisites

You need an existing Xanthan site. If you don't have one yet:
1. Visit [Xanthan](https://github.com/fredgibbs/xanthan)
2. Click "Use this template" to create your site
3. Follow the Xanthan getting started guide
4. Then come back here to add UNM branding

## Installation

### Option 1: Manual Installation (GitHub Web Interface)

**Best for:** Most users, especially if you're editing through GitHub's web interface.

1. **Download this repository:**
   - Click the green "Code" button above
   - Select "Download ZIP"
   - Unzip the downloaded file on your computer

2. **Upload the layout file:**
   - In your Xanthan repository on GitHub, navigate to the `_layouts/` folder
   - Click "Add file" → "Upload files"
   - Drag `base-unm.html` from the downloaded files into the upload area
   - Commit the changes

3. **Create the UNM includes folder:**
   - Navigate to your `_includes/` folder
   - Click "Add file" → "Create new file"
   - Type `unm/placeholder.txt` as the filename (this creates the folder)
   - Add any text content (it doesn't matter what)
   - Commit the file

4. **Upload the UNM include files:**
   - Navigate to `_includes/unm/` (the folder you just created)
   - Click "Add file" → "Upload files"
   - Drag all files from the `_includes/unm/` folder in the downloaded files
   - Commit the changes
   - You can now delete `placeholder.txt`

### Option 2: Command Line Installation

**Best for:** Users working locally with Git.

```bash
# Navigate to your Xanthan repository
cd path/to/your-xanthan-site

# Copy the layout file
curl -o _layouts/base-unm.html https://raw.githubusercontent.com/amaranth-unm/xanthan-unm/main/_layouts/base-unm.html

# Create the unm folder and copy include files
mkdir -p _includes/unm
cd _includes/unm
curl -O https://raw.githubusercontent.com/amaranth-unm/xanthan-unm/main/_includes/unm/page-header-unm.html
curl -O https://raw.githubusercontent.com/amaranth-unm/xanthan-unm/main/_includes/unm/nav-unm.html
curl -O https://raw.githubusercontent.com/amaranth-unm/xanthan-unm/main/_includes/unm/nav-site.html
curl -O https://raw.githubusercontent.com/amaranth-unm/xanthan-unm/main/_includes/unm/footer-unm.html
curl -O https://raw.githubusercontent.com/amaranth-unm/xanthan-unm/main/_includes/unm/footer-site.html

# Commit and push
git add _layouts/base-unm.html _includes/unm/
git commit -m "Add UNM extension"
git push
```

## Usage

### Using UNM Layout on a Page

Add `layout: base-unm` to any page's YAML header:

```yaml
---
layout: base-unm
title: My UNM Page
---

# Your page content here
```

### Using UNM Layout Site-Wide

To use UNM branding on all pages, edit each page's front matter to use `layout: base-unm` instead of `layout: base`.

**Pro tip:** You can create a custom layout that includes UNM elements if you want more control over which pages use it.

## Customization

### Edit Department Navigation

The departmental navigation bar appears at the top of UNM pages. To customize the links:

1. Open `_includes/unm/nav-unm.html`
2. Find the navigation links section
3. Edit the URLs and text to match your department's needs

Example:
```html
<li><a href="https://history.unm.edu">History Department</a></li>
<li><a href="https://history.unm.edu/about">About</a></li>
<li><a href="https://history.unm.edu/people">People</a></li>
```

### Edit Site Navigation

Your site's navigation appears below the UNM header. To customize:

1. Open `_includes/unm/nav-site.html`
2. Edit the links to match your site structure

### Customize Footer

The UNM footer includes required university links. To customize optional sections:

1. Open `_includes/unm/footer-unm.html`
2. Modify the footer sections while maintaining required UNM elements

**Important:** UNM branding guidelines require certain elements to remain unchanged. Check with UNM Communications & Marketing before making significant changes.

### Remove Google Tag Manager

If you don't need UNM analytics tracking:

1. Open `_layouts/base-unm.html`
2. Delete or comment out the Google Tag Manager sections (lines 7-28)

## File Structure

```
xanthan-unm/
├── README.md (this file)
├── _layouts/
│   └── base-unm.html           # Main UNM layout template
└── _includes/
    └── unm/
        ├── page-header-unm.html   # HTML head with UNM-specific settings
        ├── nav-unm.html           # UNM departmental navigation
        ├── nav-site.html          # Your site navigation
        ├── footer-unm.html        # UNM official footer
        └── footer-site.html       # Alternative footer option
```

## Dependencies

This extension relies on the following Xanthan core includes (already in your Xanthan site):
- `breadcrumbs.html` - Page breadcrumb navigation
- `header-image.html` - Optional page header images
- `page-js.html` - JavaScript includes

These files are part of Xanthan core and don't need to be installed separately.

## Updating the Extension

When UNM updates branding or requirements:

1. Download the latest version of this repository
2. Replace your existing files in `_layouts/base-unm.html` and `_includes/unm/`
3. Commit and push the changes

We'll maintain version tags for stable releases. Check the [Releases](https://github.com/amaranth-unm/xanthan-unm/releases) page for updates.

## Troubleshooting

### UNM navigation doesn't appear

**Check:**
- Is your page using `layout: base-unm` in the YAML header?
- Did you upload all files from `_includes/unm/`?
- Wait 1-2 minutes after committing for GitHub to rebuild your site

### Layout looks broken

**Check:**
- Are all 5 files present in `_includes/unm/`?
- Did you upload `base-unm.html` to the `_layouts/` folder?
- Check GitHub Actions to see if there were build errors

### Analytics not working

**Check:**
- Is the Google Tag Manager ID correct in `base-unm.html`?
- Contact UNM Communications & Marketing for the correct tracking ID

## Support

- **Xanthan Issues:** [Xanthan GitHub Issues](https://github.com/fredgibbs/xanthan/issues)
- **UNM Extension Issues:** [File an issue](https://github.com/amaranth-unm/xanthan-unm/issues)
- **UNM Branding Questions:** UNM Communications & Marketing

## Contributing

If you improve the UNM extension:
1. Fork this repository
2. Make your changes
3. Submit a pull request
4. Describe what you changed and why

## License

This extension follows the same license as Xanthan core. See the main [Xanthan repository](https://github.com/fredgibbs/xanthan) for license details.

## Credits

- **Xanthan Template:** Fred Gibbs
- **UNM Extension:** [Contributors](https://github.com/amaranth-unm/xanthan-unm/contributors)
- **UNM Branding Guidelines:** UNM Communications & Marketing
