{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "netdata.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "netdata.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "netdata.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the target Kubernetes version
*/}}
{{- define "netdata.kubeVersion" -}}
{{- default .Capabilities.KubeVersion.Version .Values.kubeVersion -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "netdata.ingress.apiVersion" -}}
{{- if .Values.ingress.apiVersion -}}
{{- .Values.ingress.apiVersion -}}
{{- else if semverCompare "<1.14-0" (include "netdata.kubeVersion" .) -}}
{{- "extensions/v1beta1" -}}
{{- else if semverCompare "<1.19-0" (include "netdata.kubeVersion" .) -}}
{{- "networking.k8s.io/v1beta1" -}}
{{- else -}}
{{- "networking.k8s.io/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return a value indicating whether the restarter is enabled.
*/}}
{{- define "netdata.restarter.enabled" -}}
{{- if and .Values.restarter.enabled (eq .Values.image.pullPolicy "Always") (or .Values.parent.enabled .Values.child.enabled .Values.k8sState.enabled) }}
{{- "true" -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}
