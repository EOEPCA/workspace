#!/usr/bin/env bash
# flux-oci-to-helm-chart.sh
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
  echo "--tag must be SemVer (e.g., 0.0.1 or 2.0.0-rc.2). Got: $TAG" >&2; exit 1
fi

command -v flux >/dev/null 2>&1 || { echo "flux CLI not found"; exit 1; }

CHART_VERSION="$TAG"
CHART_NAME="workspace-dependencies-${BASE_NAME}"

WORK="$(mktemp -d)"
SRC_DIR="$WORK/src"
OUT_DIR="./out/charts/$CHART_NAME"
TPL_DIR="$OUT_DIR/templates"
CRDS_DIR="$OUT_DIR/crds"
mkdir -p "$SRC_DIR" "$TPL_DIR"

echo ">> Pulling OCI with Flux: $SRC_REF"
if ! flux pull artifact "$SRC_REF" --output "$SRC_DIR" 2>/dev/null; then
  ART="$WORK/artifact.tar"
  flux pull artifact "$SRC_REF" > "$ART"
  mkdir -p "$SRC_DIR"
  tar -xzf "$ART" -C "$SRC_DIR" 2>/dev/null || tar -xf "$ART" -C "$SRC_DIR"
fi

echo ">> Scaffolding chart at $OUT_DIR (version: $CHART_VERSION)"
mkdir -p "$OUT_DIR"
cat > "$OUT_DIR/Chart.yaml" <<EOF
apiVersion: v2
name: $CHART_NAME
description: Minimal Helm wrapper generated from Flux OCI package
type: application
version: $CHART_VERSION
appVersion: "$CHART_VERSION"
EOF

echo ">> Collecting Kubernetes manifests (skip Kustomize files)"
: > "$TPL_DIR/manifest.yaml"

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
CRD_SEEN="no"
for f in "${FILES[@]}"; do
  if ! is_k8s_doc "$f"; then continue; fi
  if grep -q -E '^apiVersion:\s*apiextensions.k8s.io/' "$f"; then
    cp "$f" "$CRDS_DIR/$(basename "$f")"
    CRD_SEEN="yes"
  else
    printf "\n---\n# SOURCE: %s\n" "$f" >> "$TPL_DIR/manifest.yaml"
    cat "$f" >> "$TPL_DIR/manifest.yaml"
  fi
done
[[ "$CRD_SEEN" == "yes" ]] || rmdir "$CRDS_DIR" 2>/dev/null || true

if [[ -n "$VARIABLES" ]]; then
  echo ">> Replacing variables: ${VARIABLES}"
  SED_ARGS=()
  IFS=',' read -r -a VARS <<< "$VARIABLES"
  for VAR in "${VARS[@]}"; do
    case "$VAR" in
      NAMESPACE)                     SED_ARGS+=(-e 's|\${NAMESPACE}|{{ .Release.Namespace }}|g');;
      CLUSTER_INGRESS_DOMAIN)        SED_ARGS+=(-e 's|\${CLUSTER_INGRESS_DOMAIN}|{{ .Values.clusterIngressDomain }}|g');;
      CLUSTER_INGRESS_CLASS)         SED_ARGS+=(-e 's|\${CLUSTER_INGRESS_CLASS}|{{ .Values.clusterIngressClass }}|g');;
      TLS_CERTIFICATE_REF_NAMESPACE) SED_ARGS+=(-e 's|\${TLS_CERTIFICATE_REF_NAMESPACE}|{{ .Values.tlsCertificateRef.namespace }}|g');;
      TLS_CERTIFICATE_REF_NAME)      SED_ARGS+=(-e 's|\${TLS_CERTIFICATE_REF_NAME}|{{ .Values.tlsCertificateRef.name }}|g');;
      *) echo ">> Skipping unknown variable mapping: $VAR" >&2;;
    esac
  done
  if [[ ${#SED_ARGS[@]} -gt 0 ]]; then sed -i "${SED_ARGS[@]}" "$TPL_DIR/manifest.yaml"; fi
fi

echo ">> Escaping non-Helm template braces"
python3 - "$TPL_DIR/manifest.yaml" << 'PY'
import io, re, sys
p = sys.argv[1]
with io.open(p, 'r', encoding='utf-8') as f:
    s = f.read()
pattern = re.compile(r'{{-?\s*(.+?)\s*-?}}', re.S)
def looks_like_helm(expr: str) -> bool:
    tokens = ('include','tpl','if','else','end','range','with','define',
              '.Values','.Release','.Chart','.Capabilities','required','default',
              'quote','nindent','indent','toYaml','printf','lookup','ternary')
    return any(t in expr for t in tokens)
def should_escape(expr: str) -> bool:
    if 'request' in expr or 'variables' in expr:
        return True
    if '(' in expr and not looks_like_helm(expr):
        return True
    return False
def repl(m):
    inner = m.group(1)
    return '{{"{{"}}' + inner + '{{"}}"}}' if should_escape(inner) else m.group(0)
s = pattern.sub(repl, s)
with io.open(p, 'w', encoding='utf-8', newline='\n') as f:
    f.write(s)
PY

PKG_DIR="./out"; mkdir -p "$PKG_DIR"
if command -v helm >/dev/null 2>&1; then
  echo ">> Packaging chart"
  helm package "$OUT_DIR" --destination "$PKG_DIR"
  TGZ="$PKG_DIR/$CHART_NAME-$CHART_VERSION.tgz"
  echo ">> Package: $TGZ"
  if [[ "${DO_PUSH}" == "yes" ]]; then
    [[ -n "$REPO" ]] || { echo "--push requires --repo oci://…"; exit 1; }
    echo ">> Pushing to $REPO"
    helm push "$TGZ" "$REPO"
  fi
else
  echo "helm not found; skipped package/push. Chart files at: $OUT_DIR"
fi

echo "Done."
