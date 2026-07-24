# Candidate Onboarding with CV Upload

A two-step candidate onboarding module for a dental recruitment platform, built
with Ruby on Rails. A candidate uploads a CV, the system extracts as much as it
can in the background, and the candidate reviews, corrects, and completes a
prefilled profile before saving.

- **Step 1 — Upload CV:** drag-and-drop upload (PDF / DOC / DOCX), consent, and a
  "continue manually" escape hatch. Parsing runs in a background job with a live
  processing state.
- **Step 2 — Review & complete:** a sectioned, prefilled form with conditional
  fields, repeaters for education / work experience / languages, function-aware
  skills, "Extracted from CV" / "Missing" badges, and full validation on save.

## Stack

- Ruby 3.4, Rails 8.1
- SQLite + Active Record
- Active Storage (local disk) for private CV storage
- Active Job (Solid Queue in production, async in development) for CV parsing
- Hotwire (Turbo + Stimulus), Import Maps, Propshaft
- `pdf-reader` and `docx` for CV text extraction

## Getting started

```bash
bin/setup            # installs gems, prepares the database, seeds reference data
bin/rails server
```

Or manually:

```bash
bundle install
bin/rails db:prepare   # create + migrate + seed
bin/rails server
```

Then open http://localhost:3000 and create a candidate account.

### Demo accounts (development/test seeds)

| Role       | Email                   | Password      |
|------------|-------------------------|---------------|
| Admin      | `admin@example.com`     | `password123` |
| Recruiter  | `recruiter@example.com` | `password123` |

Candidates register themselves via **Create an account**.

### Configuration

Onboarding settings live in [`config/onboarding.yml`](config/onboarding.yml) and
can be overridden with environment variables:

| Setting                  | ENV var                  | Default                    |
|--------------------------|--------------------------|----------------------------|
| Max CV upload size (MB)  | `MAX_CV_UPLOAD_SIZE_MB`  | `25`                       |
| Recruitment team email   | `RECRUITMENT_TEAM_EMAIL` | `recruitment@example.com`  |
| Completion webhook URL    | `ONBOARDING_WEBHOOK_URL` | *(disabled when blank)*    |

## How it works

### Data model

`User` `has_one` `CandidateProfile`, which owns the rest of the graph:

```
User ─┬─ CandidateProfile ─┬─ CandidateDocument (has_one_attached :file)
      │                    ├─ Education (many)
      │                    ├─ WorkExperience (many)
      │                    ├─ CandidateSkill (many) ── Skill
      │                    └─ CandidateLanguage (many) ── Language
```

- Small fixed option sets (job functions, employment types, regions, transport,
  BIG statuses, education levels, working days, language levels) and all the
  conditional-form rules live in one place:
  [`Onboarding::Options`](app/models/onboarding/options.rb). Multi-selects are
  stored as JSON arrays validated against these lists.
- Matchable reference data (`Skill`, `Language`) lives in the database and is
  seeded from [`db/seeds.rb`](db/seeds.rb).

### CV parsing pipeline

Business logic lives in **interactors + organizers** ([`interactor`](https://github.com/collectiveidea/interactor))
under [`app/interactors/`](app/interactors), not in service objects — controllers
just call an interactor and route its result.

Parsing runs in a background job ([`ParseCandidateCvJob`](app/jobs/parse_candidate_cv_job.rb))
that invokes the [`Cv::ParseCandidateCv`](app/interactors/cv/parse_candidate_cv.rb)
**organizer**, which chains three interactors:

1. **[`Cv::ExtractText`](app/interactors/cv/extract_text.rb)** — attached file → plain text (PDF, DOCX, best-effort DOC).
2. **[`Cv::ParseText`](app/interactors/cv/parse_text.rb)** — text → `Cv::ParsedResult` (pure data).
3. **[`Cv::MapProfile`](app/interactors/cv/map_profile.rb)** — result → prefilled draft `CandidateProfile`.

`Cv::ParseText` is the single **strategy** seam: it delegates to
[`Cv::HeuristicParser`](app/parsers/cv/heuristic_parser.rb) — a deterministic,
dependency-free, Dutch + English parser (fully testable, no external API).
Swapping in an LLM-backed parser only requires a class exposing
`.call(text) -> Cv::ParsedResult`.

Key guarantees (PRD §5):

- It never invents data — unfound fields stay blank.
- Prefilled fields are recorded on the profile (`extracted_fields`) to drive the
  **"Extracted from CV"** badges; still-empty required fields show **"Missing"**.
- If a CV can't be parsed, the document is marked `failed` and the candidate can
  still continue manually.

### Conditional form logic

The rules in `Onboarding::Options` (which functions need BIG registration,
which employment types show salary vs percentage, function → skill group) drive
**both** the server-side completion validations and the client-side show/hide via
the [`conditional-fields`](app/javascript/controllers/conditional_fields_controller.js)
Stimulus controller, so they can't drift apart.

### Validation & completion

Drafts are lenient so partial CV data always saves. The full validation set
(PRD §8) runs only on completion via the `:complete` validation context, which
also propagates to nested records. Completion is the
[`Onboarding::CompleteProfile`](app/interactors/onboarding/complete_profile.rb)
organizer: it saves the profile + skill selection in one transaction and, on the
first completion only, [`Onboarding::AnnounceCompletion`](app/interactors/onboarding/announce_completion.rb)
emails the recruitment team and (if configured) fires the
`candidate_onboarding_completed` webhook.

### Privacy

CV files are never served via public Active Storage URLs. Downloads always go
through an authorized controller action ([`CvStreaming`](app/controllers/concerns/cv_streaming.rb))
so only the owning candidate and staff (recruiter/admin) can access them. Consent
is required before uploading or saving, and raw parser output is never shown to
candidates.

## Running the tests

The suite uses **RSpec** (`rspec-rails`), with Rails fixtures for reference data:

```bash
bundle exec rspec
```

Covers models & validations, the CV parser and mapper (including idempotent
re-parsing and "never invent data" guarantees), the parsing job, the upload
validator, the mailer/notifier, and full request-level flows (upload, manual
continue, review, completion, admin access, and CV download authorization).

Static analysis:

```bash
bin/rubocop      # style (rubocop-rails-omakase)
bin/brakeman     # security scan
```

## Notes & trade-offs

- The heuristic parser favors precision over recall — it is intentionally
  conservative to satisfy "never invent data". Accuracy is best on well-structured
  CVs; anything uncertain is left for the candidate to complete. It is designed to
  be replaced by an AI-backed strategy without touching the rest of the flow.
- Legacy binary `.doc` has no reliable pure-Ruby parser, so extraction is
  best-effort; unreadable uploads fall back to manual onboarding.
- Reference option lists are centralized in code for clarity; promoting them to
  admin-managed tables is a natural next step.
