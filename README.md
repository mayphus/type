# rime-config

Standalone Rime Config product, served by one Racket app.

## Layout

- `web.rkt` serves the public HTML, HTMX partials, previews, and ZIP builds.
- `gui.rkt` opens a native Racket GUI for local Yuanshu builds and iPhone pushes.
- `build.rkt` is the callable build library for schemas, mobile bundles, and archives.
- `web-ui.rkt` renders the server-side UI.
- `k8s.rkt` generates and checks the Kubernetes YAML.
- `rime/` holds native Rime YAML and dictionaries; `schema/` holds this project's DSL source.
- `schema/lib/lang.rkt` is the public schema DSL language.
- `schema/lib/yaml/` contains the internal YAML renderer.
- `schema/lib/mobile/` is the internal Yuanshu mobile compiler used by schema modules.
- `tools/` contains maintenance scripts.
- `k8s/` is ignored generated deploy output from `k8s.rkt`.

Generated schema modules use `#lang s-exp "lib/lang.rkt"` and declare their
mobile skin shape in the schema itself:

```racket
(rime-schema flypy_14
  (name "14鍵")
  (mobile-only)
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
    (description "適合 Yuanshu iPhone 14 鍵圖示皮膚。")
    (patch "recognizer/patterns/reverse_lookup" "`[a-z]*'?$"))
  (mobile-skin flypy_14
    (meta
      (name "Flypy 14" "小鶴十四鍵")
      (summary "A compact Yuanshu skin for the Flypy 14-key layout."))
    (phone-layout flypy-14)
    (ipad-layout standard-18)))
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
`Push to iPhone`. Leaving the URL blank lets the sync tool scan its known LAN
candidates.

GUI upload syncs schemas to `RimeUserData/rime/`, then refreshes Yuanshu
`Skins/` with only the selected generated skin folders. The Rime delete checkbox
only applies to `RimeUserData/rime/`; each selected skin folder is removed and
uploaded fresh so stale `.keyboard` caches do not survive. All other skins are
left untouched.

Regenerate Kubernetes manifests after changing deploy settings:

```sh
racket k8s.rkt
```

## Deployment

This repo deploys the public web UI and build API together as one Racket app
on k3s on `pb62`. `k8s.rkt` owns the Kubernetes objects; the YAML files in
`k8s/` are generated for Kustomize.

The GitHub Actions deploy flow builds the repo root into
`ghcr.io/mayphus/rime-config`, joins your tailnet with Tailscale OAuth
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
renders the pages, HTMX handles small form refreshes, and the same Racket process
builds the downloadable ZIP archives.
