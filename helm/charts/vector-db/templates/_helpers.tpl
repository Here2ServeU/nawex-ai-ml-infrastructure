{{- define "vector-db.name" -}}{{ .Chart.Name }}{{- end -}}

{{- define "vector-db.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "vector-db.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "vector-db.labels" -}}
app.kubernetes.io/name: {{ include "vector-db.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: rag-platform
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "vector-db.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vector-db.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
