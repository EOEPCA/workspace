{{/*
Build merged annotations map: global < local
*/}}
{{- define "wp.annotations.map" -}}
{{- $global := default (dict) .global -}}
{{- $local  := default (dict) .local  -}}
{{- $merged := merge (deepCopy $global) $local -}}
{{- toYaml $merged -}}
{{- end -}}

{{/*
Render annotations block if non-empty
*/}}
{{- define "wp.annotations.block" -}}
{{- $m := include "wp.annotations.map" . | fromYaml -}}
{{- if $m }}
annotations:
{{ toYaml $m | nindent 2 }}
{{- else -}}
annotations: {}
{{- end -}}
{{- end -}}
