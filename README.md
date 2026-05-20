# input-foundry

Input Foundry is a Chinese input museum and Rime/Yuanshu package builder, served by one Racket app.

## Layout

- `web/app.rkt` serves the public museum HTML, keyboard layout previews, and ZIP builds.
- `build/gui.rkt` opens a native Racket GUI for local Yuanshu builds and
  iPhone pushes.
- `build/main.rkt` is the build facade; focused build modules live in
  `build/`.
- `build/` contains operational code for build, serve, Kubernetes, dictionary
  updates, Cloudflare route repair, and Yuanshu sync.
- `type.rkt` is only the product declaration surface for input methods,
  keyboard variants, Rime ids, target artifacts, and dependencies.
- `lang/` exposes only the repo-wide declaration languages for Rime schemas,
  the type catalog, and YAML objects.
- `targets/` contains platform-specific target renderers, adapters, and
  reference configs.
- `web/` contains server-rendered UI pages, components, locale handling, form
  parsing, and the app-specific style DSL.
- `assets/rime/` holds native upstream Rime YAML and dictionaries.
- `targets/rime/` holds Rime target modules. It emits Rime YAML from Racket
  definitions; it is not the source of truth for available methods.
- `core/` derives schemas, input-method records, keymaps, and keyboard
  dimensions from `type.rkt` and shared layout definitions.
- `build/profiles/` contains named build profiles such as the desktop Rime bundle.
- `targets/yuanshu/skin/` is the Yuanshu skin compiler and adapts generated
  Yuanshu page files into shared preview specs.
- Dockerfile and Kubernetes YAML are generated from `build/k8s.rkt` into
  temporary paths only when needed; neither artifact is checked in.

Generated Rime modules in `targets/rime/` use `#lang s-exp "../../lang/rime.rkt"` to describe
the emitted Rime schema/custom YAML directly. Supported input methods are
declared once in `type.rkt` with nested `(rime ...)` and `(layout ...)` clauses;
`core/methods.rkt` derives the concrete records and Rime-facing build
selectors. Schema identity and display metadata live in `type.rkt`. Reusable
keyboard dimensions live in `core/keyboard.rkt`; calculated input methods
compose schema logic, keymaps, keyboard skeletons, projections, placements, and
target-specific app behavior.
Inline `(keyboard ...)` clauses remain the generated Yuanshu skin definition
surface:

```racket
(input-method "double-pinyin-flypy"
  #:category "double-pinyin"
  #:name '("Flypy" "小鶴雙拼")
  #:keymap 'flypy
  #:legends '(abc flypy)
  (rime #:source "flypy" #:config "flypy" #:generated? #t #:custom? #t)
  (layout "double-pinyin-flypy"
    #:keyboard 'standard-26
    #:skin "flypy"
    #:placement 'split-flypy)
  (layout "double-pinyin-flypy-14"
    #:keyboard 'compact-14
    #:skin "flypy_14"
    #:placement 'compact-center
    #:rime-source "flypy_14"))
```

```racket
(rime-schema flypy_14
  (name "14鍵")
  (artifacts yuanshu)
  (keyboard flypy_14
    (model compact-14)
    (meta ...)
    (variant flypy-14)
    (print flypy center)
    (ipad standard-18))
  (deps cangjie6)
  (schema
    (version "0.1")
    (authors
      "double pinyin layout by 鶴")
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

- `type.mayphus.org`

Legacy hostnames redirect permanently to the main domain:

- `rime.mayphus.org`
- `rime-config.mayphus.org`

## Local development

This app uses the sibling `style` Racket package for the shared Mayphus CSS
base and its style DSL. Link it once on a local machine:

```sh
cd ../style
raco pkg install --auto --link .
```

```sh
racket main.rkt serve
```

Visit `http://localhost:5001`.

For browser reload during web development, run:

```sh
racket main.rkt dev
```

This restarts the Racket server when build, core, target, web, or library
files change. Pages opened in the browser reload after the new server is ready.

Run the native GUI when you want to push directly to a local iPhone:

```sh
racket main.rkt gui
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

`build/main.rkt` is the shared build facade for both web and GUI. The
implementation is split under `build/`:

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

Regenerate deploy artifacts after changing deploy settings:

```sh
racket main.rkt k8s
```

Check generated deploy artifacts:

```sh
racket main.rkt check-k8s
```

Build a profile from the command line:

```sh
racket main.rkt build --schema flypy --artifact yuanshu
```

## Deployment

This repo deploys the public web UI and build API together as one Racket app
on k3s on `pb62`. `build/k8s.rkt` owns the generated Dockerfile and
Kubernetes objects; both are generated into temporary paths when deployment
needs them.

There is no checked-in GitHub Actions deployment path right now. Validate and
deploy from a local machine:

```sh
raco test test
racket main.rkt k8s
racket main.rkt check-k8s
racket main.rkt build --schemas double-pinyin-flypy,cangjie6 --artifact rime --profile-name desktop
racket main.rkt build --schemas all --artifact yuanshu --profile-name all
```

Deployment notes:

- `build/k8s.rkt` is the source for deployment manifests; generated YAML and
  Dockerfile output stays temporary.
- The ingress manifest assumes `type.mayphus.org`, `rime.mayphus.org`, and
  `rime-config.mayphus.org` terminate in the cluster.
- Cloudflare should route those hostnames to the k3s ingress. The old Rime
  hostnames redirect permanently to `type.mayphus.org`, and the old Worker web
  UI is no longer part of this repo.
- The cert-manager issuer name is currently `letsencrypt`.
- If your k3s ingress class, cert-manager setup, or runtime image differs,
  adjust `build/k8s.rkt` and validate with `racket main.rkt check-k8s`.

## Current shape

The old ClojureScript/React/Bun/Wrangler web path has been removed. Racket
renders the museum catalog and exhibit pages, and the same Racket process builds
the downloadable ZIP archives.
