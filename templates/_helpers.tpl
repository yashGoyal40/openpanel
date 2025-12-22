{{/*
Common helper templates for OpenPanel chart
*/}}

{{/*
Build a full image reference, honoring global.imageRegistry if set.
Usage: {{ include "openpanel.image" (dict "root" . "image" .Values.api.image) }}
*/}}
{{- define "openpanel.image" -}}
{{- $image := .image -}}
{{- $registry := .root.Values.global.imageRegistry | default "" -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $image.repository $image.tag -}}
{{- else -}}
{{- printf "%s:%s" $image.repository $image.tag -}}
{{- end -}}
{{- end -}}

