{{/*
Create the name of the service account to use.
Uses myorg.fullname from plat-eng-commons-package for consistent naming.
*/}}
{{- define "cache.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "myorg.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
