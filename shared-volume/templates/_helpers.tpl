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
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "shared-volume.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shared-volume.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
NFS Server labels
*/}}
{{- define "shared-volume.nfsServer.labels" -}}
helm.sh/chart: {{ include "shared-volume.chart" . }}
{{ include "shared-volume.nfsServer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: nfs-server-controller
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
NFS Server selector labels
*/}}
{{- define "shared-volume.nfsServer.selectorLabels" -}}
app.kubernetes.io/name: nfs-server-controller
app.kubernetes.io/instance: {{ .Release.Name }}
control-plane: controller-manager
{{- end }}

{{/*
Shared Volume labels
*/}}
{{- define "shared-volume.sharedVolume.labels" -}}
helm.sh/chart: {{ include "shared-volume.chart" . }}
{{ include "shared-volume.sharedVolume.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: shared-volume-controller
{{- with .Values.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Shared Volume selector labels
*/}}
{{- define "shared-volume.sharedVolume.selectorLabels" -}}
app.kubernetes.io/name: shared-volume-controller
app.kubernetes.io/instance: {{ .Release.Name }}
control-plane: controller-manager
{{- end }}

{{/*
Create the name of the service account to use for NFS Server
*/}}
{{- define "shared-volume.nfsServer.serviceAccountName" -}}
{{- if .Values.nfsServer.serviceAccount.create }}
{{- default "nfs-server-controller-controller-manager" .Values.nfsServer.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.nfsServer.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for Shared Volume
*/}}
{{- define "shared-volume.sharedVolume.serviceAccountName" -}}
{{- if .Values.sharedVolume.serviceAccount.create }}
{{- default "shared-volume-controller-controller-manager" .Values.sharedVolume.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.sharedVolume.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
NFS Server image
*/}}
{{- define "shared-volume.nfsServer.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.nfsServer.image.registry -}}
{{- printf "%s/%s:%s" $registry .Values.nfsServer.image.repository (.Values.nfsServer.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Shared Volume image
*/}}
{{- define "shared-volume.sharedVolume.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.sharedVolume.image.registry -}}
{{- printf "%s/%s:%s" $registry .Values.sharedVolume.image.repository (.Values.sharedVolume.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Image pull secrets
*/}}
{{- define "shared-volume.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
