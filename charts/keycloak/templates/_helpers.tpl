{{- define "keycloak.name" -}}
keycloak
{{- end -}}

{{- define "keycloak.fullname" -}}
{{ include "keycloak.name" . }}
{{- end -}}