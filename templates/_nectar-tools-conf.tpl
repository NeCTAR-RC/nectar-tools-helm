{{/*
nectar-tools.conf rendered from the conf values: each key under conf is an ini
section, each entry under a section becomes an option = value line.
Secrets never belong here; in production they arrive via the
Vault-rendered secrets.conf drop-in (see nectar-tools.vaultAnnotations).
*/}}
{{- define "nectar-tools-conf" -}}
{{- range $section, $options := .Values.conf }}
[{{ $section }}]
{{- range $name, $value := $options | default dict }}
{{ $name }} = {{ $value }}
{{- end }}
{{ end -}}
{{- end }}
