{{/*
Expand the name of the chart.
*/}}
{{- define "nectar-tools.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name, truncated at 63 chars.
*/}}
{{- define "nectar-tools.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "nectar-tools.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nectar-tools.labels" -}}
helm.sh/chart: {{ include "nectar-tools.chart" . }}
{{ include "nectar-tools.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nectar-tools.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nectar-tools.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nectar-tools.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nectar-tools.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Vault agent annotations. Only the secret config values live in Vault,
under individual keys of settings_secret; they render as an
oslo.config drop-in at /etc/nectar-tools/nectar-tools.conf.d/secrets.conf,
which the tools read automatically and which overrides
nectar-tools.conf.
Init-container only (agent-pre-populate-only): a sidecar would stop
the Jobs from ever completing.
*/}}
{{- define "nectar-tools.vaultAnnotations" -}}
vault.hashicorp.com/role: "{{ .Values.vault.role }}"
vault.hashicorp.com/agent-inject: "true"
vault.hashicorp.com/agent-pre-populate-only: "true"
vault.hashicorp.com/agent-inject-status: "update"
vault.hashicorp.com/secret-volume-path-secrets.conf: /etc/nectar-tools/nectar-tools.conf.d
vault.hashicorp.com/agent-inject-secret-secrets.conf: "{{ .Values.vault.settings_secret }}"
vault.hashicorp.com/agent-inject-template-secrets.conf: |
  {{ print "{{- with secret \"" .Values.vault.settings_secret "\" -}}" }}
  {{ print "{{- if .Data.data.transport_url }}" }}
  {{ print "[DEFAULT]" }}
  {{ print "transport_url={{ .Data.data.transport_url }}" }}
  {{ print "{{- end }}" }}
  {{ print "[service_auth]" }}
  {{ print "password={{ .Data.data.keystone_password }}" }}
  {{ print "{{- if .Data.data.freshdesk_key }}" }}
  {{ print "[freshdesk]" }}
  {{ print "key={{ .Data.data.freshdesk_key }}" }}
  {{ print "{{- end }}" }}
  {{ print "{{- if .Data.data.jupyterhub_token }}" }}
  {{ print "[jupyterhub]" }}
  {{ print "token={{ .Data.data.jupyterhub_token }}" }}
  {{ print "{{- end }}" }}
  {{ print "{{- if .Data.data.kubernetes_token }}" }}
  {{ print "[kubernetes_client]" }}
  {{ print "token={{ .Data.data.kubernetes_token }}" }}
  {{ print "{{- end }}" }}
  {{ print "{{- if .Data.data.sentry_dsn }}" }}
  {{ print "[sentry]" }}
  {{ print "dsn={{ .Data.data.sentry_dsn }}" }}
  {{ print "{{- end }}" }}
  {{ print "{{- end -}}" }}
{{- end }}
