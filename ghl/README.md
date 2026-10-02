# Bright Minds -> GoHighLevel paste guide

Three funnel pages, prepared as paste-ready fragments for the GHL funnel
builder. Built from the working site in the parent folder.

| File | Paste into |
|---|---|
| `bm-SHARED-CSS.css` | Page editor -> CSS icon (top toolbar). Same file for all three pages. |
| `page-1-landing.html` | Custom Code element -> Code Editor, on the landing page |
| `page-2-booking.html` | Custom Code element -> Code Editor, on the booking page |
| `page-3-confirmation.html` | Custom Code element -> Code Editor, on the confirmation page |

---

## Why the code is shaped this way

GHL injects a Custom Code block into an already-rendered page body. That
forces three changes to what you had:

1. **No document shell.** No `<!DOCTYPE>`, `<html>`, `<head>` or `<body>`.
   Only the fragment between `<div class="bm-page">` and its closing tag.
2. **No linked stylesheet.** `styles.css` cannot be reached from inside the
   builder, so the CSS is pasted into the page's CSS panel instead. The
   Google Fonts link is now an `@import` at the top of that file, which is
   why the fonts still load.
3. **Every CSS rule is scoped to `.bm-page`.** This is the important one.
   The original stylesheet opens with `*, *::before, *::after { margin: 0;
   padding: 0 }` and a `body` rule. Pasted unscoped, those would reset
   GHL's own header, footer, section and row layout, not just our content.
   Everything is now scoped to the wrapper div, so it can only touch our
   markup. The reset uses `:where()`, which has zero specificity and fills
   gaps without ever overriding a GHL rule.

Two GHL-specific overrides are already at the top of the CSS file:
`html, body { background: #fdf9f4 !important }` because GHL defaults the
page to white, and `.inner { max-width: 100% !important }` because GHL
silently caps its container at 1170px.

---

## Order of work

### 1. Create the three pages

For each page: add a page to your funnel, pick the blankest template
available, and delete every default block GHL puts in it. You are using
only the Custom Code element and GHL's own chrome.

### 2. Zero the section and row padding

This one cannot be done from the pasted code, because section and row are
*ancestors* of our element. Select the section and row containing the code
element and set padding to 0 in GHL's layout controls. Skip this and the
whole page sits inside a padded box that is narrower than the design
expects.

### 3. Paste the CSS

Open the page's CSS panel, select all, delete, paste the whole of
`bm-SHARED-CSS.css`. Do this on each page, or paste it once into
Funnel Settings -> Custom CSS if your plan has one.

### 4. Paste the HTML

Add a Custom Code element to the page, open its Code Editor, select all,
delete, paste the relevant page file.

### 5. Replace the tokens

See `replace-before-pasting.md`. Do this before publishing or the page
will render with broken links and blank image frames.

### 6. Set page SEO by hand

GHL owns the document head, so a code block cannot set a title or meta
description. Paste these into each page's SEO settings:

**Landing page**
- Title: `Tutoring for Grades 1 to 8 in Dasmarinas | Bright Minds Learning Center`
- Description: `One free Saturday visit: a one hour tutoring diagnostic, a trial class in a real session, and a written report on exactly where the gap is. Mathematics, English and Science, Grades 1 to 8. Dasmarinas, Cavite.`

**Booking page**
- Title: `Reserve a Free Saturday Slot | Bright Minds Learning Center`
- Description: `Reserve your child's free one hour tutoring diagnostic and trial class at Bright Minds Learning Center, Dasmarinas, Cavite. Saturdays 8am to 5pm, Grades 1 to 8.`
- Robots: `noindex`

**Confirmation page**
- Title: `Booking Received | Bright Minds Learning Center`
- Description: `Your free Saturday tutoring slot is booked. Bright Minds Learning Center will confirm by text or email.`
- Robots: `noindex`

### 7. Point the calendar redirect

In GHL, open the booking calendar (`PtUhcLCSm96dyQaVPAoo`) and set its
post-booking redirect to the **confirmation page URL**. This is a setting,
not a token, which is why `{{THANKS_URL}}` does not appear in any HTML file.

### 8. Check the calendar availability

The calendar must be restricted to the six Saturday slots, otherwise it
will happily offer weekdays:

```
8:00 AM   9:30 AM   11:00 AM   1:00 PM   2:30 PM   4:00 PM
```

### 9. Publish and check

Publish each page, then load it in a private window. Things worth looking
at:

- The calendar renders at full height, not clipped. `.gcal` sets
  `min-height` only, because the widget's `iframeResizer` sets the real
  height. If the widget is short, the resizer script is being blocked.
- No horizontal scrollbar on a phone. The long CTA wraps to two lines by
  design via `.btn-wrap`.
- The photos show. Until the tokens are replaced they are blank frames,
  sized correctly so nothing shifts once the URLs are in.

---

## Regenerating these files

`ghl/` is generated output. Do not hand-edit it. If the site copy changes in
the parent folder, run:

```powershell
.\ghl-build.ps1    # rebuilds bm-SHARED-CSS.css
.\ghl-html.ps1     # rebuilds the three page fragments
```

Both scripts refuse to write if the output looks malformed. The CSS build
aborts on any rule that ends up unscoped, or if a prefix leaks into a
property value.

---

## Known limits

- **`<meta>` and `<title>` cannot be injected.** GHL renders the head, so
  step 6 is manual.
- **Section padding is manual.** See step 2.
- **Images must be uploaded before pasting.** Local paths do not resolve in
  GHL, so they ship as tokens.
- **The calendar's selected slot cannot be read back.** The widget is on
  `leadconnectorhq.com` and same-origin policy blocks it, which is why the
  confirmation page has no personalised receipt.
