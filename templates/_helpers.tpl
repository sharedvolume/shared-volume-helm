{{/*
Expand the name of the chart.
*/}}
{{- define "shared-volume.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "shared-volume.fullname" -}}
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
{{- define "shared-volume.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "shared-volume.labels" -}}
helm.sh/chart: {{ include "shared-volume.chart" . }}
{{ include "shared-volume.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "shared-volume.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shared-volume.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "shared-volume.serviceAccountName" -}}
{{- if .Values.sharedVolume.serviceAccount.create }}
{{- default (printf "%s-controller-manager" (include "shared-volume.fullname" .)) .Values.sharedVolume.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.sharedVolume.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the image name
*/}}
{{- define "shared-volume.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.sharedVolume.image.registry -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry .Values.sharedVolume.image.repository (.Values.sharedVolume.image.tag | default .Chart.AppVersion) }}
{{- else }}
{{- printf "%s:%s" .Values.sharedVolume.image.repository (.Values.sharedVolume.image.tag | default .Chart.AppVersion) }}
{{- end }}
{{- end }}

{{/*
Create webhook service name
*/}}
{{- define "shared-volume.webhookServiceName" -}}
{{- printf "%s-webhook-service" (include "shared-volume.fullname" .) }}
{{- end }}

{{/*
Create metrics service name
*/}}
{{- define "shared-volume.metricsServiceName" -}}
{{- printf "%s-metrics-service" (include "shared-volume.fullname" .) }}
{{- end }}
