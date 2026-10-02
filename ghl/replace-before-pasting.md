# Replace before pasting

Six tokens. Nothing renders correctly until they are gone.

---

## Image tokens

Upload these four files to **GHL -> Media Library**, then paste each
resulting URL over the matching token.

| Token | Upload this file | Where it appears |
|---|---|---|
| `{{IMG_HERO}}` | `assets/images/optimized/Student_smiling_with_tutor.jpg` | Landing hero |
| `{{IMG_WORKSHEET}}` | `assets/images/optimized/Student_solving_math_worksheet.jpg` | Landing, beside the sample report |
| `{{IMG_CLASSROOM}}` | `assets/images/optimized/Students_studying_with_teacher.jpg` | Landing, trial class |
| `{{IMG_ARRIVAL}}` | `assets/images/optimized/Mother_and_daughter_entering_school.jpg` | Landing, a day at the centre |

All four are already compressed from 3.3MB to 734KB. Do not upload the
larger originals in `assets/images/` — the `optimized/` folder is the one
the pages expect.

`{{IMG_ARRIVAL}}` is cropped to a square in CSS via
`object-position: 82% 50%`. That crop is what removes the "The Little
Bloomers Learning Center" signage from the doorway in that photograph.
**If you swap this image for a different one, re-check that framing** or
the signage comes back.

---

## Link tokens

| Token | Replace with | Occurrences |
|---|---|---|
| `{{INDEX_URL}}` | Full URL of the landing page | 24 |
| `{{BOOKING_URL}}` | Full URL of the booking page | 10 |

Per file:

| File | Tokens actually present |
|---|---|
| `page-1-landing.html` | `{{INDEX_URL}}`, `{{BOOKING_URL}}`, and all four `{{IMG_*}}` |
| `page-2-booking.html` | `{{INDEX_URL}}` only (the Back link) |
| `page-3-confirmation.html` | `{{INDEX_URL}}`, `{{BOOKING_URL}}` |

`{{INDEX_URL}}` also carries the anchor fragments, so replacing the token
automatically fixes links like `{{INDEX_URL}}#hours` and
`{{INDEX_URL}}#report`.

Use the **full absolute URL**, not a relative path. GHL step URLs are long
and slug-dependent, and a relative path breaks the moment the funnel
domain changes.

---

## The seventh token that is not in any file

`{{THANKS_URL}}` does not appear in the HTML. The post-booking redirect is
a **calendar setting**, not a link:

> GHL -> Calendar (`PtUhcLCSm96dyQaVPAoo`) -> Settings -> Redirect after
> booking -> the confirmation page URL

Until that is set, GHL shows its own in-widget confirmation and the
`page-3-confirmation.html` page is never reached.

---

## Quick check before you publish

Search each file for `{{`. You should get zero matches.

```
page-1-landing.html     -> 0
page-2-booking.html     -> 0
page-3-confirmation.html -> 0
```

If any remain, that link or image will be broken on the live page.
