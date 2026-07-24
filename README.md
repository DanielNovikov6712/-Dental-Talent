# Candidate Onboarding with CV Upload

Two-step candidate onboarding for a dental recruitment platform: a candidate
uploads a CV, the app extracts what it can in a background job, and the candidate
reviews and completes a prefilled profile. Recruiters/admins review completed
profiles and download the CV from an admin area.

## Stack

- Ruby 3.4, Rails 8.1
- SQLite + Active Record
- Active Storage (local disk) — private CV storage
- Solid Queue / Solid Cache / Solid Cable
- Hotwire (Turbo + Stimulus), Import Maps, Propshaft
- [`interactor`](https://github.com/collectiveidea/interactor) — business logic
- `pdf-reader`, `docx` — CV text extraction
- RSpec, RuboCop, Brakeman

## Run locally

Requires Ruby 3.4.8 (see [`.ruby-version`](.ruby-version)).

```bash
bin/setup            # install gems, create + migrate + seed the database
bin/rails server
```

Open <http://localhost:3000> and click **Create an account** to onboard as a
candidate.

Seeded staff accounts for the admin review area:

| Role      | Email                   | Password      |
|-----------|-------------------------|---------------|
| Admin     | `admin@example.com`     | `password123` |
| Recruiter | `recruiter@example.com` | `password123` |

## Configuration (optional)

Onboarding settings live in [`config/onboarding.yml`](config/onboarding.yml) and
can be overridden via environment variables:

| ENV var                  | Default                   |
|--------------------------|---------------------------|
| `MAX_CV_UPLOAD_SIZE_MB`  | `25`                      |
| `RECRUITMENT_TEAM_EMAIL` | `recruitment@example.com` |
| `ONBOARDING_WEBHOOK_URL` | *(blank — disabled)*      |

## Tests & checks

```bash
bin/rspec            # test suite
bin/rubocop          # style
bin/brakeman         # security scan
```
