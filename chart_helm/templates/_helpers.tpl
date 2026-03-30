{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart or a given name
If the value given is (.), it will use the chart name by default
*/}}
{{- define "gamerank.name" -}}
{{- /* If we send a direct text, it formats it and uses it */ -}}
{{- if typeIs "string" . -}}
  {{- . | trunc 63 | trimSuffix "-" -}}
{{- /* If we send the Helm context (.), it extracts the Chart.Name by default */ -}}
{{- else -}}
  {{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Combined chart name: name-version
Truncated to 63 characters because it is the limit of Kubernetes for labels
*/}}
{{- define "gamerank.chartWithVersion" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the image name
*/}}
{{- define "gamerank.image" -}}
{{- printf "%s:%s" .repository (default "latest" .tag) -}}
{{- end -}}

{{/*
Labels deployment fields
*/}}
{{- define "gamerank.deployment.labels" -}}
# app name (gamerank) -> deployment name in values.yaml
app: {{ include "gamerank.name" . }}
# chart name and version (gamerank-1.0.4) -> chartname-version
chart: {{ include "gamerank.chartWithVersion" . }}
# release name (my-app) -> helm install my-app ./chart
release: {{ .Release.Name }}
# helm release service (helm) -> helm install my-app ./chart
heritage: {{ .Release.Service }}
{{- end -}}

{{/*
Container fields
*/}}
{{- define "gamerank.deployment.container" -}}
# Container name
- name: {{ include "gamerank.name" .name }}
  # Docker image configuration
  # quote: adds quotes ("") around the image name ("result")
  image: {{ include "gamerank.image" .image | quote }}
  # Image pull policy
  imagePullPolicy: {{ default "IfNotPresent" .image.pullPolicy }}
  # Container ports
  {{- if .containerPort }}
  ports:
    # Port that Django listens on inside the container
    - containerPort: {{ .containerPort }}
  {{- end }}
  # Environment variables
  {{- with .env }}
  env:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  # Resource limits for the container (cpu and memory)
  {{- with .resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Service port fields
*/}}
{{- define "gamerank.service.port" -}}
# Protocol to use for the Service
- protocol: {{ default "TCP" .protocol }}
  # Port exposed by the Service inside the cluster (outside the Pod/container) -> connected to the ingress
  port: {{ .port }}
  # Port where the container is actually listening inside the Pod/container
  targetPort: {{ .targetPort }}
{{- end -}}

{{/*
Ingress path fields
*/}}
{{- define "gamerank.ingress.path" -}}
# Path that the Ingress should handle
- path: {{ .path.path }}
  # Prefix means that any request path starting with "/" matches this rule
  pathType: {{ .path.pathType }}
  # Backend configuration
  backend:
    service:
      # This does NOT point to the Pod or the containerPort
      # It points to the Kubernetes Service
      {{- if .path.backend.serviceName }}
      name: {{ .path.backend.serviceName }}
      {{- else }}
      name: {{ include "gamerank.name" .context }}
      {{- end }}
      port:
        # This must be the Service "port"
        # Not the Deployment containerPort
        {{- if .path.backend.servicePort }}
        number: {{ .path.backend.servicePort }}
        {{- else }}
        # (index .context.Values.service.ports 0).port -> takes the first port defined in .Values.service.ports (values.yaml)
        number: {{ (index .context.Values.service.ports 0).port }}
        {{- end }}
{{- end -}}

{{/*
Ingress rule fields
*/}}
{{- define "gamerank.ingress.rule" -}}
# Host that the Ingress should handle
- host: {{ .rule.host }}
  http:
    paths:
      {{- range .rule.paths }}
      {{- include "gamerank.ingress.path" (dict "path" . "context" $.context) | nindent 6 }}
      {{- end }}
{{- end -}}



{{/*
Explanation: Converts Kebab-case strings into UpperCamelCase formatting -> gamerank-deployment ó gamerank_deployment -> GamerankDeployment
Usefulness: Rarely used manually. Only useful if you strictly need dynamic camelcase injection.
*/}}
{{- define "gamerank.camelToKebab" -}}
{{- camelcase ( . | replace "-" "_" ) -}} 
{{- end -}}

{{/*
Explanation: Renders a value from values.yaml as if it were a Helm template itself.
Usefulness: Moderately useful. It allows you to write variables like `{{ .Release.Name }}` inside your `values.yaml` and have them dynamically interpreted during deployment.
*/}}
{{- define "gamerank.tplValue" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Explanation: Generates a fully qualified, non-colliding app name, supporting standard override methods.
Usefulness: HIGHLY USEFUL and strongly recommended by the Kubernetes community instead of basic name formatting. Standard production charts use this to prevent name collisions when installing a chart multiple times in the same cluster.
*/}}
{{- define "gamerank.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- include "gamerank.fullnameOverride" .  | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Explanation: Generates standard Kubernetes "Common Labels" to be attached to all kinds of resources (Deployment, Service, Ingress).
Usefulness: CRITICAL FOR CLEAN TEMPLATES! You should definitely use this. It allows you to replace 5-6 lines of repeated `app:`, `chart:`, `release:` labels in every YAML file with a single line: `{{ include "gamerank.labels" . }}`.
*/}}
{{- define "gamerank.labels" -}}
app.kubernetes.io/name: {{ include "gamerank.name" (default .Chart.Name .Values.deployment.name) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.deployment.image.tag }}
app.kubernetes.io/version: {{ .Values.deployment.image.tag | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "gamerank.chartWithVersion" . }}
{{- end -}}

{{/*
Explanation: Generates the labels required exclusively for matching Pods to Services and Deployments (selector labels).
Usefulness: CRITICAL FOR CLEAN TEMPLATES! Paired with common labels, this takes away the boilerplate from the `selector.matchLabels` block in your configurations.
*/}}
{{- define "gamerank.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gamerank.name" (default .Chart.Name .Values.deployment.name) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}


{{/*
Explanation: Validates via Regular Expressions that a manually provided fullnameOverride complies with DNS naming standards.
Usefulness: Good for validating user input in public Helm templates to avoid strange Kubernetes API errors.
*/}}
{{- define "gamerank.fullnameOverride" -}}
{{- if regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?([a-z0-9]([-a-z0-9]*[a-z0-9])?)*$" .Values.fullnameOverride }}
{{- .Values.fullnameOverride }}
{{- else }}
{{- fail "\n\nfullnameOverride is not valid. Must use only lowercase, numbers and dash(-)\n" }}
{{- end }}
{{- end -}}