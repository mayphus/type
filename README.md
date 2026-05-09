# input-foundry

Input Foundry is a Chinese input museum and Rime/Yuanshu package builder, served by one Racket app.

## Layout

- `web.rkt` serves the public museum HTML, keyboard layout previews, and ZIP builds.
- `gui.rkt` opens a native Racket GUI for local Yuanshu builds and iPhone pushes.
- `build.rkt` is the callable build facade; focused build modules live in `build/`.
- `web/` contains server-rendered UI pages, components, locale handling, and form parsing.
- `k8s.rkt` generates and checks the Kubernetes YAML.
- `assets/rime/` holds native Rime YAML and dictionaries; `schema/` holds this project's DSL source.
- `schema/lib/lang.rkt` is the public schema DSL language.
- `keyboard/` contains reusable keyboard models shared by schemas:
  `models.rkt` for keyboard geometry and print-slot defaults,
  `shapes.rkt` for blank keyboard geometry, and `catalog.rkt` as the public
  resolver. Schema modules own schema-specific printed labels and layout
  binding.
- `preview/` contains shared preview layout and SVG rendering code used by the
  web app and Yuanshu build outputs.
- `lib/yaml/` contains the internal YAML renderer.
- `yuanshu/skin/` is the Yuanshu skin compiler and adapts generated Yuanshu
  page files into shared preview specs.
- `tools/` contains maintenance scripts.
- `k8s/` is ignored generated deploy output from `k8s.rkt`.

Generated schema modules use `#lang s-exp "lib/lang.rkt"` and declare their
artifact support in the schema itself. Reusable keyboard models live in
`keyboard/catalog.rkt`; schema modules define what gets printed on those
keyboards. Inline `(keyboard-layout ...)` clauses are schema-local Yuanshu skin
definitions:

```racket
(rime-schema flypy_14
  (name "14鍵")
  (artifacts yuanshu)
  (keyboard-layout flypy_14
    (meta ...)
    (phone-layout flypy-14)
    (ipad-layout standard-18))
  (deps cangjie6)
  (static-files "rime_ice.dict.yaml")
  (static-dirs "rime_ice_dicts")
  (schema
    (version "0.1")
    (authors
      "double pinyin layout by 鶴"
      "dictionary import from iDvel/rime-ice")
    (description "朙月拼音＋小鶴雙拼 14 鍵方案。")
    (switches ...)
    (engine ...)
    (speller ...)
    (translator ...))
  (custom "flypy_14.custom.yaml"
    (includes yuanshu_common_patch yuanshu_reverse_lookup_patch)
    (version "0.1")
    (description "適合 Yuanshu iPhone 14 鍵圖示鍵盤佈局。")
    (patch "recognizer/patterns/reverse_lookup" "`[a-z]*'?$")))
```

## URL strategy

The product is served directly by the k3s-hosted Racket app:

- `rime.mayphus.org`
- `rime-config.mayphus.org`

## Local development

```sh
racket web.rkt
```

Visit `http://localhost:5001`.

Run the native GUI when you want to push directly to a local iPhone:

```sh
racket gui.rkt
```

Open Yuanshu's WiFi transfer screen on the iPhone, keep both devices on the
same LAN, then paste the URL shown by Yuanshu into the GUI and press
`Push to iPhone`. Leaving the URL blank lets the sync tool scan the current LAN.

GUI upload syncs schemas to `RimeUserData/rime/`, then refreshes Yuanshu
`Skins/` with only the selected generated keyboard layout folders. The Rime
delete checkbox only applies to `RimeUserData/rime/`; each selected layout
folder is rebuilt with runtime YAML plus `README.md` and `demo.png`, then
removed and uploaded fresh so stale `.keyboard` caches do not survive. All
other Yuanshu layouts are left untouched.

## Build logic

`build.rkt` is the shared build facade for both web and GUI. The implementation
is split under `build/`:

- `paths.rkt` owns shared paths and tool locations.
- `schema.rkt` resolves schemas, profiles, artifacts, and asset lists.
- `keyboard.rkt` creates dynamic Yuanshu keyboard layout modules.
- `writer.rkt` writes exported module file hashes to disk.
- `profile.rkt` builds profiles, keyboard layout packages, previews, and ZIPs.
- `upload.rkt` syncs generated bundles to Yuanshu.
- `deploy.rkt` deploys the desktop Rime config.

The build flow is:

1. `build-output!` is the single filesystem writer. By default it writes
   `output/rime/`.
2. Parameters choose the schema set, artifact (`rime` or `yuanshu`), optional
   zip path, and optional unpacked skin directory for Yuanshu upload.
3. `resolve-schemas` expands dependencies and filters schemas by artifact
   support, so Yuanshu-only schemas stay out of Rime packages.
4. `compute-assets` decides the generated YAML, static Rime files, static
   directories, and keyboard layouts needed by the resolved schemas.
5. The normal generated output is one Rime profile directory containing schema
   YAML plus `skins/*.cskin` for Yuanshu keyboard layouts.
6. `do-upload!` syncs the built profile to Yuanshu `RimeUserData/rime/`; when an
   unpacked skin directory is provided, it also refreshes only those selected
   `/Skins/` folders.

Regenerate Kubernetes manifests after changing deploy settings:

```sh
racket k8s.rkt
```

## Deployment

This repo deploys the public web UI and build API together as one Racket app
on k3s on `pb62`. `k8s.rkt` owns the Kubernetes objects; the YAML files in
`k8s/` are generated for Kustomize.

The GitHub Actions deploy flow builds the repo root into
`ghcr.io/mayphus/input-foundry`, joins your tailnet with Tailscale OAuth
credentials, uses `KUBECONFIG_PB62` to reach k3s on `pb62`, applies `k8s/`, and
updates the image tag.

Required GitHub secrets:

- `TAILSCALE_OAUTH_CLIENT_ID`
- `TAILSCALE_OAUTH_SECRET`
- `KUBECONFIG_PB62`
- `GHCR_PULL_TOKEN`

Deployment notes:

- The deploy workflow rewrites the kubeconfig `server:` to
  `https://100.116.247.67:6443` before running `kubectl`, so the stored
  `KUBECONFIG_PB62` secret can keep the original cluster/user/certificate data.
- If `pb62` gets a different Tailscale IP, update `K8S_API_SERVER` in
  `.github/workflows/deploy-k3s.yml`.
- `GHCR_PULL_TOKEN` should be a GitHub personal access token for `mayphus` with
  at least `read:packages`, so the workflow can create the `ghcr-pull` image
  pull secret before deploying.
- The ingress manifest assumes `rime.mayphus.org` and
  `rime-config.mayphus.org` terminate in the cluster.
- Cloudflare should route those hostnames to the k3s ingress. The old Worker
  web UI is no longer part of this repo.
- The cert-manager issuer name is currently `letsencrypt`.
- If your k3s ingress class or cert-manager setup differs, adjust `k8s.rkt` and
  regenerate with `racket k8s.rkt`.

## Current shape

The old ClojureScript/React/Bun/Wrangler web path has been removed. Racket
renders the museum catalog and exhibit pages, and the same Racket process builds
the downloadable ZIP archives.
