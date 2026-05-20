#lang racket/base

;;; Stable public facade for build helpers.

(require "build/paths.rkt"
         "build/schema.rkt"
         "build/keyboard.rkt"
         "build/profile.rkt"
         "build/upload.rkt"
         "build/deploy.rkt")

(provide (all-from-out "build/paths.rkt")
         generated-config-ids
         schema-module-ref
         keyboard-layout-module-ref
         skin-module-ref
         read-schema-deps
         read-schema-artifacts
         read-schema-keyboard-layouts
         read-schema-mobile-skins
         list-static-schema-ids
         schema-keyboard-layout-module-path
         schema-mobile-skin-module-path
         list-keyboard-layout-items
         list-mobile-skin-items
         read-schema-name-from-yaml
         read-schema-description
         profile-artifact
         build-profile!
         build-profile-from-hash!
         build-profile-keyboard-layout-directories!
         build-profile-skin-directories!
         build-output!
         build-bundle!
         zip-profile-path!
         zip-profile!
         do-upload!
         deploy-desktop!
         build-preview-keyboard-layouts!
         build-preview-skins!)
