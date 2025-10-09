#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 --tag <semver> [--repo oci://...] [--push] [--chart-name NAME] [--out DIR]"
  exit 1
fi

TAG=""; REPO=""; DO_PUSH="no"; CHART_NAME="workspace-pipeline"; OUTDIR="./dist"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) TAG="${2:-}"; shift 2;;
    --repo) REPO="${2:-}"; shift 2;;
    --push) DO_PUSH="yes"; shift;;
    --chart-name) CHART_NAME="${2:-}"; shift 2;;
    --out) OUTDIR="${2:-}"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

[[ -n "$TAG" ]] || { echo "--tag is required"; exit 1; }
if [[ ! "$TAG" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  echo "--tag must be SemVer (e.g., 1.0.0 or 1.0.0-rc.1)"; exit 1
fi

VALUES="values.yaml"
STORAGE_IN="configuration-storage.yaml"
DATALAB_IN="configuration-datalab.yaml"
ENVCFG_IN="environmentconfig.yaml"

for f in "$VALUES" "$STORAGE_IN" "$DATALAB_IN" "$ENVCFG_IN"; do
  [[ -f "$f" ]] || { echo "Missing required file: $f"; exit 1; }
done

command -v yq >/dev/null 2>&1 || { echo "yq not found"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm not found"; exit 1; }

mkdir -p "${OUTDIR}/rendered"

merge_annos() {
  local base="$1" gkey="$2" lkey="$3" tmp
  tmp="$(mktemp)"
  yq ea -o=json '. as $item ireduce ({}; . * $item )' \
    <(yq -o=json '.metadata.annotations // {}' "${base}") \
    <(yq -o=json "${gkey} // {}" "${VALUES}") \
    <(yq -o=json "${lkey} // {}" "${VALUES}") | yq -P > "${tmp}"
  echo "${tmp}"
}

bool_as_str() {
  local v
  v="$(yq -r "$1" "${VALUES}")"
  if [[ "${v}" == "true" ]]; then printf "true"; else printf "false"; fi
}

STORAGE_OUT="${OUTDIR}/rendered/config-storage.rendered.yaml"
cp "${STORAGE_IN}" "${STORAGE_OUT}"
TMP_A="$(merge_annos "${STORAGE_OUT}" '.globalAnnotations' '.storage.annotations')"
yq -i ".metadata.annotations = (load(\"${TMP_A}\"))" "${STORAGE_OUT}"
rm -f "${TMP_A}"

DATALAB_OUT="${OUTDIR}/rendered/config-datalab.rendered.yaml"
cp "${DATALAB_IN}" "${DATALAB_OUT}"
TMP_B="$(merge_annos "${DATALAB_OUT}" '.globalAnnotations' '.datalab.annotations')"
yq -i ".metadata.annotations = (load(\"${TMP_B}\"))" "${DATALAB_OUT}"
rm -f "${TMP_B}"

ENVCFG_OUT="${OUTDIR}/rendered/environmentconfig.rendered.yaml"
cp "${ENVCFG_IN}" "${ENVCFG_OUT}"
yq -i \
  ".data.iam.realm = \"$(yq -r '.environmentconfig.iam.realm' "${VALUES}")\" |
   .data.ingress.class = \"$(yq -r '.environmentconfig.ingress.class' "${VALUES}")\" |
   .data.ingress.domain = \"$(yq -r '.environmentconfig.ingress.domain' "${VALUES}")\" |
   .data.ingress.secret = \"$(yq -r '.environmentconfig.ingress.secret' "${VALUES}")\" |
   .data.storage.endpoint = \"$(yq -r '.environmentconfig.storage.endpoint' "${VALUES}")\" |
   .data.storage.force_path_style = \"$(bool_as_str '.environmentconfig.storage.forcePathStyle')\" |
   .data.storage.provider = \"$(yq -r '.environmentconfig.storage.provider' "${VALUES}")\" |
   .data.storage.region = \"$(yq -r '.environmentconfig.storage.region' "${VALUES}")\" |
   .data.storage.secretNamespace = \"$(yq -r '.environmentconfig.storage.secretNamespace' "${VALUES}")\" |
   .data.storage.type = \"$(yq -r '.environmentconfig.storage.type' "${VALUES}")\" |
   .data.network.serviceCIDR = \"$(yq -r '.environmentconfig.network.serviceCIDR' "${VALUES}")\"" \
   "${ENVCFG_OUT}"
TMP_C="$(merge_annos "${ENVCFG_OUT}" '.globalAnnotations' '.environmentconfig.annotations')"
yq -i ".metadata.annotations = (load(\"${TMP_C}\"))" "${ENVCFG_OUT}"
rm -f "${TMP_C}"

CHART_DIR="${OUTDIR}/chart/${CHART_NAME}"
PKG_DIR="${OUTDIR}/pkg"
mkdir -p "${CHART_DIR}/templates" "${PKG_DIR}"

cat > "${CHART_DIR}/Chart.yaml" <<EOF
apiVersion: v2
name: ${CHART_NAME}
description: ${CHART_NAME} chart
type: application
version: ${TAG}
appVersion: "${TAG}"
EOF

cp "${OUTDIR}/rendered/"*.yaml "${CHART_DIR}/templates/"
helm package "${CHART_DIR}" --destination "${PKG_DIR}"

if [[ "${DO_PUSH}" == "yes" ]]; then
  [[ -n "${REPO}" ]] || { echo "--push requires --repo oci://…"; exit 1; }
  FILE="${PKG_DIR}/${CHART_NAME}-${TAG}.tgz"
  helm push "${FILE}" "${REPO}"
fi

echo "${OUTDIR}/rendered"
echo "${CHART_DIR}"
echo "${PKG_DIR}"
