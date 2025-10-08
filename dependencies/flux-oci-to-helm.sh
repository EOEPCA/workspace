#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <oci-src-ref> <base-name> --tag <semver> [--repo oci://...] [--push] [--variables VAR1,VAR2,...]"
  exit 1
fi
SRC_REF="$1"; shift
BASE_NAME="$1"; shift

TAG=""; REPO=""; DO_PUSH="no"; VARIABLES=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)        TAG="${2:-}"; shift 2;;
    --repo)       REPO="${2:-}"; shift 2;;
    --push)       DO_PUSH="yes"; shift;;
    --variables)  VARIABLES="${2:-}"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done
[[ -n "$TAG" ]] || { echo "--tag is required"; exit 1; }
if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  echo "--tag must be SemVer (e.g., 0.0.1). Got: $TAG" >&2; exit 1
fi
CHART_VERSION="$TAG"
CHART_NAME="dependencies-${BASE_NAME}"

command -v flux >/dev/null 2>&1 || { echo "flux CLI not found"; exit 1; }

WORK="$(mktemp -d)"
SRC_DIR="$WORK/src"
OUT_DIR="./out/charts/$CHART_NAME"
TPL_DIR="$OUT_DIR/templates"
CRDS_DIR="$OUT_DIR/crds"
mkdir -p "$SRC_DIR" "$TPL_DIR"

if ! flux pull artifact "$SRC_REF" --output "$SRC_DIR" 2>/dev/null; then
  ART="$WORK/artifact.tar"
  flux pull artifact "$SRC_REF" > "$ART"
  mkdir -p "$SRC_DIR"
  tar -xzf "$ART" -C "$SRC_DIR" 2>/dev/null || tar -xf "$ART" -C "$SRC_DIR"
fi

mkdir -p "$OUT_DIR"
cat > "$OUT_DIR/Chart.yaml" <<EOF
apiVersion: v2
name: $CHART_NAME
description: Minimal Helm wrapper generated from Flux OCI package
type: application
version: $CHART_VERSION
appVersion: "$CHART_VERSION"
EOF

: > "$TPL_DIR/manifest.yaml"
CRD_SEEN="no"
is_k8s_doc() {
  local f="$1"
  case "$(basename "$f" | tr '[:upper:]' '[:lower:]')" in
    kustomization.yaml|kustomization.yml|kustomization) return 1;;
  esac
  if grep -qE '^apiVersion:\s*kustomize\.config\.k8s\.io/' "$f"; then return 1; fi
  if ! grep -qE '^apiVersion:\s*' "$f"; then return 1; fi
  if ! grep -qE '^kind:\s*' "$f"; then return 1; fi
  return 0
}
mapfile -t FILES < <(find "$SRC_DIR" -type f \( -iname '*.yaml' -o -iname '*.yml' \) | sort)
[[ ${#FILES[@]} -gt 0 ]] || { echo "No YAML found in OCI artifact."; exit 1; }
mkdir -p "$CRDS_DIR"
for f in "${FILES[@]}"; do
  if ! is_k8s_doc "$f"; then continue; fi
  if grep -q -E '^apiVersion:\s*apiextensions.k8s.io/' "$f"; then
    cp "$f" "$CRDS_DIR/$(basename "$f")"; CRD_SEEN="yes"
  else
    printf "\n---\n# SOURCE: %s\n" "$f" >> "$TPL_DIR/manifest.yaml"
    cat "$f" >> "$TPL_DIR/manifest.yaml"
  fi
done
[[ "$CRD_SEEN" == "yes" ]] || rmdir "$CRDS_DIR" 2>/dev/null || true

if [[ -n "$VARIABLES" ]]; then
  SED_ARGS=()
  IFS=',' read -r -a VARS <<< "$VARIABLES"
  for VAR in "${VARS[@]}"; do
    case "$VAR" in
      NAMESPACE) SED_ARGS+=(-e 's|\${NAMESPACE}|{{ .Release.Namespace }}|g');;
      *) ;;
    esac
  done
  if [[ ${#SED_ARGS[@]} -gt 0 ]]; then sed -i "${SED_ARGS[@]}" "$TPL_DIR/manifest.yaml"; fi
fi

PKG_DIR="./out"; mkdir -p "$PKG_DIR"
if command -v helm >/dev/null 2>&1; then
  helm package "$OUT_DIR" --destination "$PKG_DIR"
  TGZ="$PKG_DIR/$CHART_NAME-$CHART_VERSION.tgz"
  if [[ "${DO_PUSH}" == "yes" ]]; then
    [[ -n "$REPO" ]] || { echo "--push requires --repo oci://…"; exit 1; }
    helm push "$TGZ" "$REPO"
  fi
else
  echo "helm not found; skipped package/push. Chart files at: $OUT_DIR"
fi
