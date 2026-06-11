# Releasing

`country_phone_field` publishes to [pub.dev](https://pub.dev/packages/country_phone_field)
through GitHub Actions. You never run `dart pub publish` by hand.

## How the pipeline works

```
bump version + changelog ──▶ Release workflow ──▶ pushes tag v<version> ──▶ Publish workflow ──▶ pub.dev
        (you)                 (manual dispatch)        (automatic)            (OIDC, automatic)
```

- **`.github/workflows/release.yml`** — a manual (`workflow_dispatch`) job. It
  validates the release, creates and pushes the `v<version>` tag, and opens a
  GitHub Release.
- **`.github/workflows/publish.yml`** — fires on any pushed tag matching
  `v[0-9]+.[0-9]+.[0-9]+*` and publishes to pub.dev using pub.dev's official
  OIDC reusable workflow (no API tokens needed for the publish itself).

The Release workflow **refuses to run** unless all of these line up, so they are
your pre-flight checklist:

1. `version:` in `pubspec.yaml` exactly equals the version you dispatch.
2. `CHANGELOG.md` has a header line `## <version>` (exact match).
3. The tag `v<version>` does not already exist.
4. The version is valid semver: `MAJOR.MINOR.PATCH` with an optional
   `-prerelease` suffix (e.g. `1.2.3` or `1.2.3-beta.1`).

> Branching: this repo integrates on `dev` and releases from `main`. Land the
> version bump on `main` first (merge `dev` → `main`), then dispatch the Release
> workflow against `main`.

## One-time setup (already done for this repo)

- **pub.dev → package → Admin → Automated publishing**: enable GitHub Actions,
  repository `mchigangawa/country_phone_field`, tag pattern `v{{version}}`.
- **Repo/org secret `RELEASE_PAT`**: a PAT with `contents: write` (and
  `workflow`) so the tag the Release workflow pushes can trigger
  `publish.yml`. (A tag pushed by the default `GITHUB_TOKEN` would not.)

---

## Release a stable version

Example: `0.2.0`.

1. **Bump `pubspec.yaml`:**
   ```yaml
   version: 0.2.0
   ```
2. **Add a CHANGELOG section** at the top:
   ```markdown
   ## 0.2.0

   * … what changed …
   ```
3. **(Optional) sanity-check locally:**
   ```bash
   dart pub publish --dry-run
   flutter analyze && flutter test
   ```
4. **Merge to `main`** (via PR), then **dispatch the Release workflow:**
   ```bash
   gh workflow run Release -f version=0.2.0 --ref main
   ```
   (or GitHub → Actions → **Release** → **Run workflow** → enter `0.2.0`.)
5. The workflow tags `v0.2.0`, which triggers `publish.yml` and ships to
   pub.dev. Watch it under the **Actions** tab.

Consumers install it normally:
```yaml
dependencies:
  country_phone_field: ^0.2.0
```

---

## Release a beta (prerelease)

Same pipeline — the only difference is a `-beta.N` suffix on the version. The
version regex and the publish tag glob both accept it.

Example: `0.2.0-beta.1`.

1. **Bump `pubspec.yaml`:**
   ```yaml
   version: 0.2.0-beta.1
   ```
2. **Add the matching CHANGELOG header:**
   ```markdown
   ## 0.2.0-beta.1

   * … what's in the beta …
   ```
3. **(Recommended) point the README install snippet at the prerelease** so
   testers can actually resolve it (a plain `^0.2.0` constraint will *not* pull
   a prerelease):
   ```yaml
   dependencies:
     country_phone_field: ^0.2.0-beta.1
   ```
4. **Merge to `main`**, then **dispatch:**
   ```bash
   gh workflow run Release -f version=0.2.0-beta.1 --ref main
   ```

### What a prerelease means on pub.dev

- It is published but is **not** shown as the latest stable version, and normal
  constraints like `^0.1.x` will **not** upgrade to it.
- Testers opt in explicitly. `^0.2.0-beta.1` resolves to
  `>=0.2.0-beta.1 <0.3.0`, so it allows later betas *and* the eventual stable
  `0.2.0`:
  ```yaml
  dependencies:
    country_phone_field: ^0.2.0-beta.1
  ```
- Ordering is standard semver: `0.2.0-beta.1 < 0.2.0-beta.2 < 0.2.0`.

### Iterating and graduating to stable

- Next beta: bump to `0.2.0-beta.2` (+ CHANGELOG header), dispatch again.
- When ready, ship **stable** `0.2.0` with the steps in the previous section.
  The stable release supersedes the betas; you can revert the README constraint
  to `^0.2.0` at that point.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| Release workflow fails at "Verify pubspec version" | `pubspec.yaml` `version:` ≠ dispatched version. |
| Fails at "Verify changelog contains version" | Missing/typo'd `## <version>` header in `CHANGELOG.md`. |
| Fails at "Check tag does not already exist" | `v<version>` was already tagged — bump to the next version. |
| Tag created but nothing published | Confirm pub.dev automated publishing is enabled with tag pattern `v{{version}}`, and that `publish.yml` ran (Actions tab). |
| Tag push didn't trigger Publish | `RELEASE_PAT` missing/expired — a tag pushed by `GITHUB_TOKEN` won't trigger workflows. |
