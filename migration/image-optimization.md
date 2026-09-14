# Optimize Images

The [Optimize Images workflow](https://github.com/amaranth-unm/communitygeography/actions/workflows/optimize-images.yml) brings Xanthan's image-maintenance workflow into this migrated site. It works with the existing HTML images, Markdown images, layout images, and images referenced from YAML. Using a Xanthan image include is not a prerequisite.

## Use it on GitHub

1. Open the repository's **Actions** tab and select **Optimize Images**.
2. Click **Run workflow**, using the `main` branch.
3. Choose a folder. `.` scans all tracked images; narrower choices include `about`, `events`, `news`, or `projects/past-projects`. Subfolders are included.
4. Choose the longest edge and JPEG quality. The inherited starting values are **1600 pixels** and **85**. Detailed flyers, maps, or photographs intended for close examination may need a larger edge or a separate treatment.
5. Leave **Actually change the files** unticked for a preview. Open the completed run's summary to see measured before/after sizes for each image.
6. When ready to apply the chosen settings, run it again with the checkbox ticked. It commits smaller images and starts the normal Pages build, including its link checks. Review affected images on the published site.

The preview measures savings by encoding temporary copies; it does not show a visual comparison. Review a representative sample at the chosen settings before applying a broad batch. Applying changes on a branch other than `main` commits to that branch without publishing it, which provides another way to review a batch first.

## Adaptations for the Cascade migration

- **Preserved filenames and formats.** JPEG stays JPEG and PNG stays PNG. The workflow does not rename images, delete original URL paths, or rewrite content references. PNG transparency is preserved.
- **Scattered and extensionless assets.** The default folder is the repository root, and images are recognized by their file contents. Referenced images such as `claudia` and `news/casa-san-ysidro-by-ramona-m.` are included.
- **Tracked files only.** Local build output, source captures, and other untracked files are not processed. GIFs, SVGs, PDFs, and other formats are unchanged; multi-frame images are skipped.
- **Measured savings.** A candidate replaces the original only if it is smaller. Images already under 300 KB and within the requested dimensions are skipped. Photos are oriented before resizing and never enlarged; JPEG quality is not applied to PNGs.
- **Repeat-run tracking.** Applied outputs and their settings are recorded in `.github/image-optimization-state.json`. An unchanged image with the same settings is skipped on later runs, preventing repeated lossy encoding. Replacing an image or changing the settings makes it eligible for review again.
- **Originals in Git history.** Apply reduces files in place. Their previous versions remain in the optimization commit's history; it does not create a second public set of full-resolution downloads. Choose a separate display-copy strategy if visitors need both versions.
- **Working publication.** After committing to `main`, the job explicitly starts the Pages workflow. GitHub-token pushes do not themselves start another push-triggered workflow; [GitHub documents this behavior](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow).

## Local use and verification

Requires Python 3.10 or newer, Git, and ImageMagick. From the repository:

```sh
bash scripts/optimize-images.sh --preview --recursive --base-dir projects --max-edge 1600 --quality 85
```

Preview is also the default when neither mode is specified. Use `--apply` to replace images, then inspect, commit, and push the changes. Selected images must already be committed before applying so Git retains their previous versions. Unlike the GitHub workflow, a local run does not commit or publish automatically.

To exercise preview, apply, transparency, unchanged URLs, repeat runs, and error handling on temporary images:

```sh
python3 scripts/test-optimize-images.py
```

The tests use an isolated temporary repository and do not modify the site's images. The GitHub workflow runs these tests before processing the selected folder.

## Upstream provenance

Source: [Xanthan's Optimize Images workflow](https://github.com/xanthan-web/xanthan-web.github.io/blob/5e106aac8ba5c93467d638db02ffe8430346ecd6/.github/workflows/optimize-images.yml) and its `scripts/optimize-images.sh`, at commit `5e106aac8ba5c93467d638db02ffe8430346ecd6`.

The manual workflow and settings come from Xanthan. This site's implementation uses a small shell entry point and a Python/ImageMagick backend for tracked-file selection, measured previews, preserved formats, and repeat-run tracking. Upstream's PNG-to-JPEG conversion and `update-image-refs.sh` are intentionally not used: that updater only handles Markdown references, while this site also references images in layouts, CSS, and YAML. No reference-update script is needed when names stay the same.

For future Cascade conversions, carry over the framework's maintenance workflows and dependencies during the baseline migration. Configure them for the actual asset locations and verify preview behavior before declaring the conversion complete.
