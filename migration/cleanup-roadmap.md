# Cascade → GitHub Pages: cleanup and improvement checklist

The purpose of this process is to demonstrate that an existing institutional website can become easier to maintain in GitHub Pages. A successful basic conversion gives editors working pages and readable source files. It does not need to resolve every inherited content or design problem.

Work through three tiers. Each tier should leave a usable site, and later improvements are optional. A site does not need a new design or a structured database to benefit from the conversion.

| Tier | Purpose | Boundary |
| --- | --- | --- |
| 1. Strict cleanup | Remove conversion debris and unambiguous formatting errors. | Preserve wording, factual values, content order, public URLs, and intended structure. |
| 2. Consistent presentation and files | Establish a small set of image, header, layout, and file conventions. | Make deliberate presentation choices; preserve content and existing links. |
| 3. Easier ongoing maintenance | Organize repeated information so editors can update it reliably. | Change how content is stored or generated when that reduces routine work. |

If a proposed Tier 1 fix requires interpreting what the author meant, changing a fact, choosing a design, or retiring content, move it to a later tier or the editorial review list.

## Before cleanup: keep a baseline

- [ ] Record the original site, capture date, framework version, and first working Git commit.
- [ ] Keep an inventory connecting original URLs to new pages and assets. Keep the source capture outside the published site.
- [ ] Record broken links and unavailable source material separately from migration failures.
- [ ] Verify the converted site builds and publishes, its original page paths work, and its navigation, images, downloads, and search are usable.
- [ ] Carry over the framework's maintenance workflows and their scripts. Configure image optimization for the migrated asset locations and verify its preview mode.

Community Geography already has a source inventory in [manifest.json](manifest.json), a capture dated September 12, 2026, and [migration review notes](README.md). Existing build checks cover internal links, image targets, fragments, page landmarks, preserved routes, and search JSON. Those checks do not establish that formatting or editorial content is correct.

The [Optimize Images workflow](image-optimization.md) is available for measured previews and optional application. It supports the existing image markup and preserves asset URLs. Applying image compression is a separate decision from installing and verifying the maintenance tool.

## Tier 1 — strict cleanup

The standard here is: an editor can explain the correction without making a new content or design decision.

- [ ] **C1. Review forced line breaks.** Remove redundant breaks at the ends of paragraphs and accidental breaks within ordinary prose. Keep intended breaks in addresses, poetry, signatures, and event label/value blocks. A normal source newline is not necessarily a browser line break: this site uses `hard_wrap: false`; two trailing spaces explicitly request a break. Do not strip every line ending indiscriminately.
- [ ] **C2. Remove empty content artifacts.** Remove empty headings, empty emphasis, spacer-only paragraphs, and empty links that convey no content. Preserve named anchors and IDs unless their removal has been checked against incoming fragments. When a link has no text but appears to contain a unique resource, record it for review before discarding it.
- [ ] **C3. Normalize accidental whitespace.** Remove whitespace-only lines, excessive blank lines, and obvious nonbreaking-space debris. Preserve spaces between inline elements, deliberate nonbreaking spaces, code indentation, and nested-list indentation. Check for words joined at link or formatting boundaries.
- [ ] **C4. Simplify redundant markup.** Remove emphasis around an entire heading or an image when it serves no purpose. Remove blank attributes such as `title=" "`. Remove obsolete CMS classes only after checking that current styles and scripts do not use them. Retain IDs, links, image dimensions, loading behavior, credits, and meaningful emphasis.
- [ ] **C5. Repair unambiguous structural conversion errors.** Fix malformed lists, tables, Markdown rendered as literal punctuation, and paragraph boundaries when the captured source establishes the intended structure. Preserve heading text and anchor targets. Choosing a new heading hierarchy belongs in Tier 2.
- [ ] **C6. Clean serialized metadata.** Normalize accidental CR/LF escapes and whitespace in imported front matter without rewriting the text. Preserve `title`, `permalink`, dates, and source references. Writing a shorter or more useful description is an editorial improvement, not a whitespace fix.
- [ ] **C7. Repair demonstrated migration link errors.** Correct a URL that became malformed during conversion when its intended destination is known. Preserve query strings and fragments, and ensure internal links work under the GitHub Pages project path. Keep pre-existing unavailable destinations on the review list when no reliable replacement is known.

**Completion check:** build successfully; run the existing route/link checks; compare wording, link destinations, image references, dates, and page count with the baseline; visually review affected patterns on desktop and phone. Differences should be limited to the intended cleanup. Report uncertain cases instead of silently resolving them.

### Community Geography starting points

Read-only inspection of the 134 migrated page bodies on September 14, 2026 found:

| Finding | Evidence | First action |
| --- | --- | --- |
| 272 explicit Markdown break markers across 78 pages | Two or more trailing spaces on nonblank lines; this is a candidate count, not an error count. | Review a representative sample before applying C1 across the site. |
| Redundant prose breaks and intentional address breaks coexist | [Lobo Garden Fall Party](../events/-display-name.md). | Remove redundant paragraph-ending breaks; retain the two-line address. |
| An empty heading and an empty link remain | [Community Engagement Week](../events/community-engagement-week.md). | Remove the empty heading; inspect and record the empty link's destination. |
| Redundant emphasis and inline image/prose boundaries | [Our Team](../about/our-team.md): `## **Associate Director**`, an italicized image, and prose adjacent to image tags. | Simplify formatting and confirm word/paragraph boundaries without changing biographies or titles. |
| Imported metadata contains literal CR/LF escapes | The long `summary` in [Faculty Affiliates](../about/affiliates.md). | Normalize whitespace; defer rewriting or shortening the description. |

These counts exclude layouts, includes, and archived upstream files. No literal HTML `<br>` tags were found in those page bodies; the forced breaks are represented in Markdown.

## Tier 2 — consistent presentation and files

These changes involve choices about how the site should look and how authors should insert content. Try each convention on a few representative pages before applying it widely.

- [ ] **P1. Choose image conventions by purpose.** Document the preferred treatment for ordinary inline images, captioned figures, portraits, linked flyers, project thumbnails, galleries, and hero images. Preserve meaningful alternative text, captions, credits, click destinations, and image proportions.
- [ ] **P2. Standardize headers by page type.** Distinguish the shared UNM utility bar and hanging logo, the center's identity banner, and optional page-specific hero images. Decide which page types need a hero; define a small set of heights, title placements, and mobile crops. The center banner is already shared in the layout, but is hardcoded there rather than configured as a reusable site setting. Do not turn every event flyer or first image into a hero.
- [ ] **P3. Establish reusable page patterns.** Set consistent spacing and heading hierarchy for articles, event details, project pages, and people profiles. Replace brittle legacy image floats where they interfere with separate profiles or mobile reading. Changing a page pattern belongs here even when the wording stays the same.
- [ ] **P4. Review image delivery and accessibility.** Correct filename-style alternative text using the actual image and context; preserve decorative images appropriately. Check dimensions, loading behavior, oversized downloads, and legibility of flyer text. Create smaller display copies where useful while retaining originals and their existing public paths. Supplying missing substantive descriptions or transcribing information requires content review.
- [ ] **P5. Audit stray and duplicate files.** Inventory files as referenced, intentionally retained, generated, duplicate candidates, or unresolved. Check references in Markdown, YAML, layouts, includes, CSS, JavaScript, generated pages, and the source manifest. Lack of an internal link does not prove a formerly public asset is unused. Keep compatibility copies or an explicit URL migration plan when renaming or moving public files.
- [ ] **P6. Establish a simple folder convention.** Choose where new images and downloads belong, and document it. Apply the convention prospectively; moving every imported file is optional. Keep build output, local caches, and source-capture files out of the published site.
- [ ] **P7. Document and check the adopted components.** Keep editor examples short. Verify the representative patterns on desktop and phone, then run the route/link checks after wider adoption.

**Completion check:** common page types look consistent, media remains usable and accessible, old paths still work, and an editor can follow a short example to add similar content.

### Should every image use a Xanthan include?

**No universal conversion is needed.** Use the simplest representation that supports the image's purpose. Keeping HTML images during the initial migration was reasonable because it preserved dimensions, alignment, loading attributes, and link behavior.

| Image purpose | Starting recommendation |
| --- | --- |
| Simple image without special layout or caption | Plain Markdown can be sufficient. Keep HTML when explicit dimensions or loading controls are needed. |
| Standalone captioned figure | Consider `images/figure.html` for consistent captions and presentation. |
| A deliberately paired image and short text block | Consider `images/figure-wrap.html`; check whether putting the text in an include parameter makes editing easier. |
| Image linking to an external project, map, or other destination | Preserve its destination explicitly. Do not replace it with a component that only links to the image file. |
| Repeated people or project images | Let the relevant people/project component render the image consistently. |
| Shared brand marks, identity banners, and page heroes | Render through the layout or the appropriate header component. An ordinary figure include is not the right abstraction. |

The installed [figure include](../_includes/images/figure.html) defaults to a 40% width and makes the image a link to its own file. It does not currently preserve the imported `loading`, `decoding`, or intrinsic width/height attributes. The [figure-wrap include](../_includes/images/figure-wrap.html) creates a two-column block rather than reproducing a legacy text float. These are meaningful behavior changes to evaluate before bulk replacement. Always supply intentional alternative text rather than relying on a caption fallback.

This audit found 184 raw HTML image elements in 107 migrated page bodies, with no image includes in those bodies. That is an inventory, not 184 defects. Project cards already render images through [a shared component](../_includes/community/projects.html) and [YAML data](../_data/projects.yml).

For the file audit, names alone are particularly misleading here: `claudia` and `about/thomas-de-pree` are referenced portrait files, `events/-display-name.md` contains a real event, and `projects/project/test-project-1.md` contains a named project. They are not automatically disposable.

## Tier 3 — easier ongoing maintenance

Start with a recurring editing task. Adopt a data structure or collection only when it makes that task simpler, reduces duplicated information, or supports a useful generated view.

- [ ] **M1. Model affiliates and team members.** Agree on the small set of fields editors actually maintain: name, role, department, image, image alternative, profile link, display order, and active/past status where needed. Preserve existing values and order during the structural conversion; confirming whether those values are current is a separate editorial task.
- [ ] **M2. Choose YAML or Markdown records based on the content.** Use `_data/affiliates.yml` for a short directory of consistent fields. For the current affiliates page's substantial biographies, prefer one Markdown record per person in a Jekyll collection, with structured fields in front matter and the biography in the body. A collection can generate the directory without publishing a separate page for every person. Retain a hand-edited page if it remains the easiest option for its editor.
- [ ] **M3. Give repeated content one maintained source.** Consider shared records for contact details, people, projects, and recurring links. Avoid maintaining both a generated directory and a separate hand-edited copy of the same records.
- [ ] **M4. Structure news, events, and projects where useful.** Consider collections with dates, summaries, images, locations, and status fields. Preserve existing public permalinks. The existing project YAML is a starting point; decide whether it should remain a short directory or be derived from fuller project records.
- [ ] **M5. Generate useful lists.** Build news archives, current/past project views, or an upcoming-events list from the agreed fields. Decide what belongs on the homepage explicitly; a featured item and the most recent item are not always the same. Define how undated and ongoing items behave before automating their placement.
- [ ] **M6. Make editing teachable.** Provide one short example for adding a person, an event, or a project, showing exactly which fields are required. Add checks for missing required values, duplicate identifiers, invalid dates, and broken image paths where those checks prevent likely editing mistakes.
- [ ] **M7. Demonstrate the maintenance improvement.** Have an editor perform a real update using the new structure. Compare the number of places edited and the clarity of the process with the previous approach. Keep the structure only if it helps.

**Completion check:** a common update can be made in one clear place, appears in the appropriate views, preserves existing URLs, and can be completed by the site's intended editor without changing layout code.

## Editorial review accompanies all three tiers

Track decisions about current leadership, outdated announcements, eligibility, amounts, closed applications, placeholder pages, missing descriptions, and content retirement separately. Structural conversion should not silently settle those questions. The existing [review notes](README.md) provide the initial list for this site.

## How to work through the list

1. Start with C1–C4 on a small sample: the homepage, a text page, a people page, an event, and a project.
2. Record the exact rule and its exceptions, then apply it to other matching pages. Use small commits organized by the cleanup rule so the result is easy to review or undo.
3. Keep a short completion note for each batch: item IDs, affected pages, checks performed, and unresolved examples. A flagged candidate is not a completed correction.
4. After Tier 1, select one Tier 2 convention to demonstrate and one recurring Tier 3 editing task. There is no requirement to complete every optional improvement.
5. Feed well-understood mechanical fixes back into the converter for future sites. Keep site-specific editorial and design decisions outside the generic conversion rules. Do not rerun the current converter over hand-edited content: it overwrites the imported pages.

**Next proposed batch:** C1–C4 on the sample pages above. This document records the plan and initial findings; it does not mark the cleanup as completed.
