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

{{/*
Return the configmap data for the parent configuration. Configmap is the default choice for storing configuration.
*/}}
{{- define "netdata.parent.configs.configmap" -}}
{{- range $name, $config := .Values.parent.configs -}}
{{- $found := false -}}
{{- if and $config.enabled (eq $config.storedType "configmap") -}}
{{- $found = true -}}
{{- else if and $config.enabled (ne $config.storedType "secret") -}}
{{- $found = true -}}
{{- else if and $config.enabled (not $config.storedType) -}}
{{- $found = true -}}
{{- end -}}
{{- if $found }}
{{ $name }}: {{ tpl $config.data $ | toYaml | indent 4 | trim }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the configmap data for the child configuration. Configmap is the default choice for storing configuration.
*/}}
{{- define "netdata.child.configs.configmap" -}}
{{- range $name, $config := .Values.child.configs -}}
{{- $found := false -}}
{{- if and $config.enabled (eq $config.storedType "configmap") -}}
{{- $found = true -}}
{{- else if and $config.enabled (ne $config.storedType "secret") -}}
{{- $found = true -}}
{{- end -}}
{{- if $found }}
{{ $name }}: {{ tpl $config.data $ | toYaml | indent 4 | trim }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the configmap data for the k8s state configuration. Configmap is the default choice for storing configuration.
*/}}
{{- define "netdata.k8sState.configs.configmap" -}}
{{- range $name, $config := .Values.k8sState.configs -}}
{{- $found := false -}}
{{- if and $config.enabled (eq $config.storedType "configmap") -}}
{{- $found = true -}}
{{- else if and $config.enabled (ne $config.storedType "secret") -}}
{{- $found = true -}}
{{- end -}}
{{- if $found }}
{{ $name }}: {{ tpl $config.data $ | toYaml | indent 4 | trim }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret data for the parent configuration, when you setup storedType as a secret.
*/}}
{{- define "netdata.parent.configs.secret" -}}
{{- range $name, $config := .Values.parent.configs -}}
{{- if and $config.enabled (eq $config.storedType "secret") }}
{{ $name }}: {{ tpl $config.data $ | b64enc }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret data for the child configuration, when you setup storedType as a secret.
*/}}
{{- define "netdata.child.configs.secret" -}}
{{- range $name, $config := .Values.child.configs -}}
{{- if and $config.enabled (eq $config.storedType "secret") }}
{{ $name }}: {{ tpl $config.data $ | b64enc }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret data for the k8s state configuration, when you setup storedType as a secret.
*/}}
{{- define "netdata.k8sState.configs.secret" -}}
{{- range $name, $config := .Values.k8sState.configs -}}
{{- if and $config.enabled (eq $config.storedType "secret") }}
{{ $name }}: {{ tpl $config.data $ | b64enc }}
{{- end -}}
{{- end -}}
{{- end -}}
