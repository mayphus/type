#lang racket/base

(require style/main)

(provide app-css-rules
         app-css-text)

(define-styles app-css-rules
  (style
    (rule ":root"
      ["--inline-note-bg" "color-mix(in oklab, var(--fg), transparent 95%)"]
      ["--keyboard-special-bg" "color-mix(in oklab, var(--surface), var(--fg) 8%)"]
      ["--qr-frame-bg" "transparent"]
      ["--glass-button-bg" "color-mix(in oklab, var(--surface), transparent 66%)"]
      ["--glass-button-bg-hover" "color-mix(in oklab, var(--surface), transparent 42%)"]
      ["--glass-button-border" "color-mix(in oklab, var(--surface), var(--fg) 10%)"]
      ["--glass-button-shadow" "0 10px 30px color-mix(in oklab, var(--fg), transparent 88%), inset 0 1px 0 color-mix(in oklab, var(--surface), white 36%)"]
      ["--error" "#a83f2f"]
      ["--radius-lg" "1.1rem"]
      ["--radius-md" "0.85rem"]
    )
    (dark
      (rule ":root"
        ["--inline-note-bg" "color-mix(in oklab, var(--fg), transparent 92%)"]
        ["--keyboard-special-bg" "color-mix(in oklab, var(--surface), var(--fg) 10%)"]
        ["--qr-frame-bg" "#fff"]
        ["--glass-button-bg" "color-mix(in oklab, var(--surface), transparent 60%)"]
        ["--glass-button-bg-hover" "color-mix(in oklab, var(--surface), transparent 34%)"]
        ["--glass-button-border" "color-mix(in oklab, var(--fg), transparent 82%)"]
        ["--glass-button-shadow" "0 10px 30px rgba(0, 0, 0, 0.34), inset 0 1px 0 color-mix(in oklab, var(--fg), transparent 82%)"]
        ["--error" "#ff9a88"]
      )
    )
    (rule "#app"
      ["width" "100%"]
      ["margin" "0 auto"]
      ["padding" "1.25rem clamp(1rem, 4vw, 2.5rem) 2.2rem"]
    )
    (rule ".page-title,\n.rime-section-title"
      ["margin" "0"]
      ["font-family" "\"Iowan Old Style\", \"Palatino Linotype\", \"Book Antiqua\", serif"]
      ["font-weight" "500"]
      ["letter-spacing" "0"]
    )
    (rule ".page-title"
      ["font-size" "clamp(2rem, 4.2vw, 3.45rem)"]
      ["line-height" "1"]
      ["white-space" "normal"]
    )
    (rule ".rime-section-title"
      ["font-size" "1.45rem"]
      ["line-height" "1.05"]
    )
    (rule ".rime-section-copy,\n.rime-help-text,\n.rime-empty-state"
      ["margin" "0"]
      ["color" "var(--muted)"]
    )
    (rule ".rime-unready-device"
      ["text-decoration-line" "line-through"]
      ["text-decoration-thickness" "0.11em"]
      ["text-decoration-color" "var(--error)"]
    )
    (rule ".rime-config-shell,\n.rime-museum-shell,\n.rime-primary-column,\n.rime-section-header,\n.rime-option-copy,\n.keyboard-preview,\n.rime-footer"
      ["display" "flex"]
      ["flex-direction" "column"]
    )
    (rule ".rime-config-shell"
      ["gap" "1rem"]
    )
    (rule ".rime-museum-shell"
      ["gap" "0.95rem"]
    )
    (rule ".rime-hero-card,\n.rime-section,\n.rime-notes-card"
      ["border" "0"]
      ["border-radius" "0"]
      ["background" "transparent"]
      ["box-shadow" "none"]
    )
    (rule ".rime-hero-card"
      ["padding" "0 0 0.9rem"]
      ["background" "transparent"]
    )
    (rule ".rime-section,\n.rime-notes-card"
      ["padding" "0.95rem 0 0"]
    )
    (rule ".rime-exhibit-overview"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "1rem"]
      ["padding" "0 0 1.1rem"]
    )
    (rule ".rime-exhibit-copy"
      ["width" "100%"]
      ["min-width" "0"]
    )
    (rule ".rime-exhibit-copy .rime-hero-copy"
      ["max-width" "38rem"]
    )
    (rule ".rime-hero-head"
      ["display" "flex"]
      ["justify-content" "space-between"]
      ["align-items" "flex-start"]
      ["gap" "1rem"]
    )
    (rule ".rime-back-link,\n.rime-platform-tab"
      ["color" "var(--fg)"]
      ["text-decoration" "none"]
    )
    (rule ".rime-back-link"
      ["display" "inline-flex"]
      ["margin-bottom" "0.65rem"]
      ["color" "var(--accent)"]
      ["font-size" "0.86rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-platform-tabs"
      ["display" "inline-flex"]
      ["flex-wrap" "wrap"]
      ["gap" "0.4rem"]
      ["margin-top" "1rem"]
    )
    (rule ".rime-platform-tab"
      ["display" "inline-flex"]
      ["align-items" "center"]
      ["min-height" "2.3rem"]
      ["padding" "0.46rem 0.85rem"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "999px"]
      ["color" "var(--muted)"]
      ["font-size" "0.86rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-platform-tab:hover,\n.rime-platform-tab.is-active"
      ["border-color" "var(--line-strong)"]
      ["background" "var(--accent-soft)"]
      ["color" "var(--fg)"]
    )
    (rule ".rime-language-toggle"
      ["flex" "0 0 auto"]
      ["appearance" "none"]
      ["display" "inline-flex"]
      ["min-width" "2.7rem"]
      ["align-items" "center"]
      ["justify-content" "center"]
      ["padding" "0.38rem 0.72rem"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "999px"]
      ["background" "var(--bg)"]
      ["color" "var(--muted)"]
      ["cursor" "pointer"]
      ["font-size" "0.76rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-language-toggle:hover"
      ["border-color" "var(--line-strong)"]
      ["color" "var(--fg)"]
    )
    (rule ".rime-config-grid"
      ["display" "block"]
    )
    (rule ".rime-primary-column"
      ["gap" "1.1rem"]
    )
    (rule ".rime-section-header,\n.keyboard-preview"
      ["gap" "0.5rem"]
    )
    (rule ".rime-platform-grid"
      ["display" "grid"]
      ["grid-template-columns" "repeat(2, minmax(0, 1fr))"]
      ["gap" "0.75rem"]
    )
    (rule ".rime-schema-categories"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "1.35rem"]
    )
    (rule ".rime-customizer"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "0.9rem"]
      ["padding-bottom" "1.1rem"]
      ["border-bottom" "1px solid var(--line)"]
    )
    (rule ".rime-customizer-grid"
      ["display" "grid"]
      ["grid-template-columns" "repeat(2, minmax(14rem, 1fr))"]
      ["gap" "0.75rem 1rem"]
      ["align-items" "start"]
      ["flex" "1 1 auto"]
    )
    (rule ".rime-customizer-panel"
      ["min-width" "0"]
    )
    (rule ".rime-customizer-heading"
      ["margin" "0 0 0.55rem"]
      ["color" "var(--muted)"]
      ["font-size" "0.78rem"]
      ["font-weight" "700"]
      ["letter-spacing" "0"]
      ["text-transform" "uppercase"]
    )
    (rule ".rime-customizer-methods,\n.rime-customizer-layouts"
      ["grid-column" "auto"]
    )
    (rule ".rime-customizer-layouts"
      ["margin-top" "0"]
    )
    (rule ".rime-customizer-selector-form"
      ["display" "block"]
      ["margin" "0"]
    )
    (rule ".rime-customizer-select"
      ["width" "100%"]
      ["min-width" "0"]
      ["min-height" "2.45rem"]
      ["padding" "0.48rem 2rem 0.48rem 0.68rem"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "var(--radius-md)"]
      ["background" "var(--surface)"]
      ["color" "var(--fg)"]
      ["font-size" "0.9rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-customizer-select:hover,\n.rime-customizer-select:focus-visible"
      ["border-color" "var(--line-strong)"]
      ["outline" "none"]
    )
    (rule ".rime-customizer-preview"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["grid-column" "1 / -1"]
      ["grid-row" "auto"]
      ["gap" "0.65rem"]
      ["min-height" "0"]
    )
    (rule ".rime-customizer-preview-head"
      ["display" "flex"]
      ["align-items" "flex-start"]
      ["justify-content" "space-between"]
      ["gap" "0.75rem"]
    )
    (rule ".rime-customizer-preview-head .rime-back-link"
      ["margin-bottom" "0"]
    )
    (rule ".rime-customizer-targets"
      ["display" "grid"]
      ["grid-template-columns" "repeat(auto-fit, minmax(min(100%, 12rem), 1fr))"]
      ["gap" "0.55rem"]
      ["margin-top" "0.1rem"]
    )
    (rule ".rime-customizer-target-form"
      ["margin" "0"]
    )
    (rule ".rime-customizer .rime-detail-preview"
      ["grid-template-columns" "1fr"]
      ["flex" "1 1 auto"]
    )
    (rule ".rime-customizer .rime-detail-preview .keyboard-preview-svg-wrap"
      ["height" "clamp(15rem, 36svh, 25rem)"]
    )
    (rule ".rime-customizer .rime-target-preview"
      ["padding" "0.65rem"]
    )
    (rule ".rime-customizer .rime-target-download-form"
      ["display" "none"]
    )
    (rule ".rime-reference-section"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "0.85rem"]
      ["padding-top" "1rem"]
    )
    (rule ".rime-home-links"
      ["display" "flex"]
      ["justify-content" "flex-start"]
      ["padding-top" "0.25rem"]
    )
    (rule ".rime-home-links .rime-back-link"
      ["margin-bottom" "0"]
    )
    (rule ".rime-reference-head"
      ["display" "flex"]
      ["align-items" "center"]
      ["justify-content" "space-between"]
      ["gap" "1rem"]
    )
    (rule ".rime-schema-category"
      ["display" "grid"]
      ["grid-template-columns" "max-content minmax(0, 1fr)"]
      ["gap" "0.75rem 1rem"]
      ["align-items" "stretch"]
    )
    (rule ".rime-schema-category-title"
      ["display" "inline-flex"]
      ["align-items" "center"]
      ["margin" "0"]
      ["color" "var(--accent)"]
      ["font-size" "clamp(1.15rem, 1.55vw, 1.55rem)"]
      ["font-weight" "600"]
      ["line-height" "1"]
      ["letter-spacing" "0"]
      ["text-transform" "uppercase"]
      ["text-orientation" "sideways"]
      ["transform" "rotate(180deg)"]
      ["writing-mode" "vertical-rl"]
    )
    (rule ".rime-schema-category-title::after"
      ["content" "none"]
    )
    (rule "html:lang(zh-Hant) .rime-schema-category-title"
      ["text-transform" "none"]
      ["text-orientation" "mixed"]
      ["transform" "none"]
    )
    (rule ".rime-option-grid"
      ["display" "grid"]
      ["grid-template-columns" "repeat(auto-fill, minmax(min(100%, 15rem), 1fr))"]
      ["gap" "0.55rem"]
      ["justify-content" "start"]
    )
    (rule ".rime-option-card,\n.rime-exhibit-card,\n.rime-layout-card,\n.rime-build-button"
      ["border" "1px solid var(--line)"]
      ["border-radius" "var(--radius-md)"]
      ["color" "var(--fg)"]
    )
    (rule ".rime-build-button"
      ["appearance" "none"]
      ["background" "transparent"]
    )
    (rule ".rime-option-card.is-selected,\n.rime-option-card:has(.rime-option-input:checked),\n.rime-exhibit-card:hover"
      ["border-color" "var(--line-strong)"]
      ["background" "var(--accent-soft)"]
    )
    (rule ".rime-option-card,\n.rime-exhibit-card,\n.rime-layout-card"
      ["position" "relative"]
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "0.4rem"]
      ["padding" "0.55rem"]
      ["background" "transparent"]
      ["min-width" "0"]
    )
    (rule ".rime-exhibit-card"
      ["text-decoration" "none"]
    )
    (rule ".rime-option-card"
      ["cursor" "pointer"]
    )
    (rule ".rime-option-card.is-auto"
      ["cursor" "default"]
      ["border-style" "dashed"]
    )
    (rule ".rime-option-card .rime-option-copy"
      ["gap" "0.3rem"]
    )
    (rule ".rime-option-head"
      ["display" "flex"]
      ["align-items" "flex-start"]
      ["justify-content" "space-between"]
      ["gap" "0.75rem"]
    )
    (rule ".rime-option-action"
      ["color" "var(--accent)"]
      ["font-size" "0.8rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-option-input"
      ["position" "absolute"]
      ["width" "1px"]
      ["height" "1px"]
      ["margin" "0"]
      ["opacity" "0"]
      ["pointer-events" "none"]
    )
    (rule ".rime-platform-hint,\n.rime-inline-note"
      ["font-size" "0.82rem"]
    )
    (rule ".rime-option-title-row"
      ["display" "flex"]
      ["flex-wrap" "wrap"]
      ["align-items" "center"]
      ["gap" "0.45rem"]
    )
    (rule ".rime-platform-label,\n.rime-option-title"
      ["font-size" "1rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-inline-note"
      ["display" "none"]
      ["padding" "0.1rem 0.45rem"]
      ["border-radius" "999px"]
      ["background" "var(--inline-note-bg)"]
    )
    (rule ".rime-card-description"
      ["margin" "0"]
      ["color" "var(--muted)"]
      ["font-size" "0.92rem"]
      ["line-height" "1.45"]
    )
    (rule ".rime-option-card.is-auto .rime-inline-note"
      ["display" "inline-flex"]
    )
    (rule ".rime-build-button"
      ["width" "100%"]
      ["padding" "0.92rem 1rem"]
      ["cursor" "pointer"]
      ["background" "var(--fg)"]
      ["color" "var(--bg)"]
      ["font-weight" "600"]
    )
    (rule ".rime-build-button:hover"
      ["border-color" "var(--line-strong)"]
      ["background" "var(--accent)"]
      ["color" "var(--bg)"]
    )
    (rule ".rime-build-button-secondary"
      ["border-color" "var(--line-strong)"]
      ["background" "transparent"]
      ["color" "var(--fg)"]
    )
    (rule ".rime-build-button-secondary:hover"
      ["background" "var(--accent-soft)"]
      ["color" "var(--fg)"]
    )
    (rule ".rime-exhibit-download"
      ["min-width" "0"]
      ["width" "min(100%, 46rem)"]
    )
    (rule ".rime-definition-panel"
      ["display" "grid"]
      ["gap" "0.75rem"]
      ["width" "min(100%, 76rem)"]
      ["min-width" "0"]
      ["padding-top" "0.9rem"]
    )
    (rule ".rime-definition-code"
      ["overflow" "auto"]
      ["min-width" "0"]
      ["max-height" "24rem"]
      ["margin" "0"]
      ["padding" "0.85rem 0"]
      ["color" "var(--fg)"]
      ["font-family" "\"SFMono-Regular\", \"SF Mono\", Consolas, monospace"]
      ["font-size" "0.82rem"]
      ["line-height" "1.55"]
      ["white-space" "pre"]
    )
    (rule ".rime-detail-preview"
      ["display" "grid"]
      ["grid-template-columns" "repeat(auto-fit, minmax(min(100%, 21rem), 1fr))"]
      ["gap" "0.75rem"]
      ["min-width" "0"]
      ["width" "100%"]
    )
    (rule ".rime-target-preview"
      ["position" "relative"]
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "0.6rem"]
      ["min-width" "0"]
      ["margin" "0"]
      ["padding" "0.75rem"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "var(--radius-md)"]
      ["background" "color-mix(in oklab, var(--surface), transparent 20%)"]
    )
    (rule ".rime-target-preview-title"
      ["color" "var(--muted)"]
      ["font-size" "0.78rem"]
      ["font-weight" "650"]
      ["line-height" "1"]
      ["text-transform" "uppercase"]
    )
    (rule ".rime-detail-preview .keyboard-preview-svg-wrap"
      ["display" "flex"]
      ["height" "clamp(14rem, 28vw, 22rem)"]
      ["align-items" "center"]
      ["justify-content" "center"]
      ["margin-top" "0.35rem"]
      ["width" "100%"]
    )
    (rule ".rime-detail-preview .keyboard-preview-svg"
      ["width" "100%"]
      ["height" "100%"]
      ["object-fit" "contain"]
    )
    (rule ".rime-target-download-form"
      ["display" "flex"]
      ["position" "absolute"]
      ["top" "0.55rem"]
      ["right" "0.55rem"]
      ["margin" "0"]
    )
    (rule ".rime-target-add-button"
      ["display" "inline-flex"]
      ["width" "2.05rem"]
      ["height" "2.05rem"]
      ["align-items" "center"]
      ["justify-content" "center"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "999px"]
      ["appearance" "none"]
      ["background" "color-mix(in oklab, var(--surface), transparent 8%)"]
      ["color" "var(--fg)"]
      ["cursor" "pointer"]
      ["font-size" "1.45rem"]
      ["font-weight" "500"]
      ["line-height" "1"]
    )
    (rule ".rime-target-add-button:hover"
      ["border-color" "var(--line-strong)"]
      ["background" "var(--accent-soft)"]
    )
    (rule ".rime-target-add-button-secondary"
      ["border-color" "var(--line-strong)"]
    )
    (rule ".rime-artifact-form"
      ["display" "grid"]
      ["grid-template-columns" "minmax(11rem, 18rem) minmax(0, 1fr)"]
      ["gap" "0.65rem"]
      ["margin" "0"]
      ["align-items" "start"]
    )
    (rule ".rime-artifact-buttons"
      ["display" "grid"]
      ["grid-template-columns" "repeat(auto-fit, minmax(min(100%, 18rem), 1fr))"]
      ["gap" "0.65rem"]
      ["align-items" "start"]
    )
    (rule ".rime-artifact-action"
      ["display" "grid"]
      ["gap" "0.45rem"]
      ["min-width" "0"]
    )
    (rule ".rime-exhibit-download .rime-artifact-form"
      ["grid-template-columns" "minmax(0, 28rem)"]
      ["gap" "0.65rem"]
      ["align-self" "start"]
    )
    (rule ".rime-exhibit-download .rime-artifact-buttons .rime-build-button"
      ["width" "100%"]
      ["min-width" "0"]
    )
    (rule ".rime-variant-control"
      ["display" "inline-flex"]
      ["width" "fit-content"]
      ["max-width" "100%"]
      ["min-height" "2.7rem"]
      ["align-items" "center"]
      ["gap" "0.45rem"]
      ["padding" "0.36rem 0.5rem 0.36rem 0.7rem"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "999px"]
      ["background" "var(--surface)"]
    )
    (rule ".rime-variant-label"
      ["flex" "0 0 auto"]
      ["color" "var(--muted)"]
      ["font-size" "0.82rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-variant-select"
      ["width" "auto"]
      ["max-width" "min(9rem, 42vw)"]
      ["border" "0"]
      ["background" "transparent"]
      ["color" "var(--fg)"]
      ["font-size" "0.92rem"]
      ["font-weight" "600"]
    )
    (rule ".rime-variant-select:focus-visible"
      ["outline" "2px solid var(--line-strong)"]
      ["outline-offset" "2px"]
    )
    (rule ".rime-sticky-actions"
      ["position" "sticky"]
      ["bottom" "0.85rem"]
      ["z-index" "5"]
      ["display" "flex"]
      ["justify-content" "center"]
      ["margin-top" "1rem"]
      ["padding" "0.35rem 0"]
      ["pointer-events" "none"]
    )
    (rule ".rime-sticky-build-button"
      ["width" "auto"]
      ["min-width" "max-content"]
      ["min-height" "2.55rem"]
      ["padding" "0.68rem 1.05rem"]
      ["border-radius" "999px"]
      ["border-color" "var(--glass-button-border)"]
      ["background" "var(--glass-button-bg)"]
      ["box-shadow" "var(--glass-button-shadow)"]
      ["font-size" "0.96rem"]
      ["backdrop-filter" "blur(20px) saturate(1.55)"]
      ["-webkit-backdrop-filter" "blur(20px) saturate(1.55)"]
      ["pointer-events" "auto"]
      ["white-space" "nowrap"]
    )
    (rule ".rime-sticky-build-button:hover"
      ["border-color" "var(--line-strong)"]
      ["background" "var(--glass-button-bg-hover)"]
    )
    (rule ".rime-build-button.is-disabled,\n.rime-build-button:disabled"
      ["cursor" "not-allowed"]
      ["opacity" "0.5"]
    )
    (rule ".rime-footer"
      ["display" "grid"]
      ["grid-template-columns" "minmax(0, 1fr) auto"]
      ["align-items" "start"]
      ["gap" "0.75rem 1rem"]
      ["padding-top" "0.65rem"]
      ["border-top" "1px solid var(--line)"]
      ["color" "var(--muted)"]
      ["font-size" "0.82rem"]
    )
    (rule ".rime-category-heading,\n.rime-exhibit-section,\n.rime-layout-card"
      ["display" "flex"]
      ["flex-direction" "column"]
    )
    (rule ".rime-category-heading"
      ["align-items" "center"]
      ["gap" "0.65rem"]
      ["min-height" "100%"]
      ["padding-top" "0.2rem"]
    )
    (rule ".rime-category-heading::after"
      ["content" "\"\""]
      ["width" "1px"]
      ["min-height" "3.5rem"]
      ["flex" "1 1 auto"]
      ["background" "var(--line)"]
    )
    (rule ".rime-exhibit-section"
      ["gap" "0.7rem"]
    )
    (rule ".rime-layout-grid"
      ["display" "grid"]
      ["grid-template-columns" "repeat(auto-fill, minmax(min(100%, 24rem), 1fr))"]
      ["gap" "0.7rem"]
    )
    (rule ".rime-dependency-list"
      ["display" "flex"]
      ["flex-wrap" "wrap"]
      ["gap" "0.4rem"]
      ["margin" "0"]
      ["padding" "0"]
      ["list-style" "none"]
    )
    (rule ".rime-dependency-list code"
      ["display" "inline-flex"]
      ["padding" "0.12rem 0.45rem"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "999px"]
      ["color" "var(--muted)"]
    )
    (rule ".rime-footer a"
      ["color" "var(--accent)"]
      ["text-decoration" "none"]
    )
    (rule ".rime-footer-meta"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "0.35rem"]
      ["min-width" "0"]
    )
    (rule ".rime-footer-links"
      ["display" "flex"]
      ["flex-direction" "column"]
      ["gap" "0.25rem"]
      ["align-items" "flex-start"]
    )
    (rule ".rime-deps-section"
      ["padding-top" "0.95rem"]
    )
    (rule ".rime-footer-support"
      ["display" "flex"]
      ["align-items" "center"]
      ["gap" "0.5rem"]
      ["justify-content" "flex-end"]
      ["text-align" "right"]
    )
    (rule ".rime-footer-support-image"
      ["display" "block"]
      ["width" "5.6rem"]
      ["aspect-ratio" "1 / 1"]
      ["border" "1px solid var(--line)"]
      ["border-radius" "0.6rem"]
      ["background" "var(--qr-frame-bg)"]
    )
    (rule ".keyboard-preview"
      ["width" "100%"]
      ["margin" "0"]
    )
    (rule ".rime-schema-previews"
      ["display" "grid"]
      ["grid-template-columns" "minmax(0, 1fr)"]
      ["gap" "0.3rem"]
      ["margin-top" "0.1rem"]
      ["width" "100%"]
    )
    (rule ".rime-schema-preview,\n.rime-layout-preview"
      ["overflow" "hidden"]
      ["width" "100%"]
    )
    (rule ".keyboard-preview-svg"
      ["display" "block"]
      ["width" "100%"]
      ["height" "auto"]
    )
    (rule ".rime-exhibit-card .keyboard-preview-svg"
      ["width" "auto"]
      ["max-width" "100%"]
      ["margin" "0 auto"]
    )
    (rule ".keyboard-preview-svg-wrap"
      ["width" "100%"]
    )
    (rule ".rime-error-text"
      ["margin" "0"]
      ["color" "var(--error)"]
    )
    (rule ".rime-empty-state"
      ["font-size" "0.92rem"]
    )
    (rule ".rime-footer-credit"
      ["flex" "1 1 12rem"]
    )
    (media "(max-width: 860px)"
      (rule "#app"
        ["padding" "1.25rem 0.9rem 2.6rem"]
      )
      (rule ".rime-customizer-grid"
        ["grid-template-columns" "1fr"]
      )
      (rule ".rime-customizer"
        ["min-height" "0"]
      )
      (rule ".rime-customizer-methods,\n.rime-customizer-layouts,\n.rime-customizer-preview"
        ["grid-column" "auto"]
        ["grid-row" "auto"]
      )
      (rule ".rime-customizer-layouts"
        ["margin-top" "0"]
      )
      (rule ".rime-exhibit-download .rime-artifact-form"
        ["grid-template-columns" "1fr"]
      )
      (rule ".rime-exhibit-download .rime-artifact-buttons"
        ["grid-template-columns" "repeat(2, minmax(0, 1fr))"]
      )
      (rule ".rime-platform-grid"
        ["grid-template-columns" "1fr"]
      )
    )
    (media "(max-width: 640px)"
      (rule ".rime-footer"
        ["grid-template-columns" "minmax(0, 1fr) auto"]
        ["gap" "0.75rem"]
      )
      (rule ".rime-footer-support"
        ["justify-content" "flex-end"]
        ["text-align" "right"]
      )
      (rule ".rime-footer-support-image"
        ["width" "clamp(4.25rem, 22vw, 5.6rem)"]
      )
      (rule ".rime-schema-category"
        ["display" "flex"]
        ["flex-direction" "column"]
        ["gap" "0.75rem"]
      )
      (rule ".rime-category-heading"
        ["align-items" "stretch"]
        ["min-height" "0"]
        ["padding-top" "0"]
      )
      (rule ".rime-category-heading::after"
        ["content" "none"]
      )
      (rule ".rime-schema-category-title"
        ["display" "flex"]
        ["align-items" "center"]
        ["gap" "0.65rem"]
        ["font-size" "clamp(1.45rem, 7vw, 2rem)"]
        ["transform" "none"]
        ["text-transform" "none"]
        ["writing-mode" "horizontal-tb"]
      )
      (rule ".rime-schema-category-title::after"
        ["content" "\"\""]
        ["height" "1px"]
        ["flex" "1 1 auto"]
        ["background" "var(--line)"]
      )
      (rule ".rime-hero-card,\n  .rime-section,\n  .rime-notes-card"
        ["padding-left" "0"]
        ["padding-right" "0"]
      )
      (rule ".page-title"
        ["font-size" "clamp(2.1rem, 10vw, 3rem)"]
        ["white-space" "normal"]
        ["line-height" "1"]
      )
      (rule ".keyboard-preview"
        ["max-width" "none"]
      )
      (rule ".rime-sticky-actions"
        ["bottom" "0.65rem"]
      )
      (rule ".rime-sticky-build-button"
        ["max-width" "calc(100vw - 1.8rem)"]
        ["min-height" "2.75rem"]
        ["padding" "0.72rem 1rem"]
        ["overflow" "hidden"]
        ["text-overflow" "ellipsis"]
      )
      (rule ".rime-artifact-form"
        ["width" "100%"]
        ["grid-template-columns" "1fr"]
      )
      (rule ".rime-exhibit-download .rime-artifact-buttons"
        ["grid-template-columns" "1fr"]
      )
      (rule ".rime-artifact-buttons"
        ["grid-template-columns" "1fr"]
      )
      (rule ".rime-artifact-buttons .rime-build-button"
        ["min-width" "0"]
      )
    )))

(define app-css-text (styles->css app-css-rules))

(module+ main
  (display app-css-text))
