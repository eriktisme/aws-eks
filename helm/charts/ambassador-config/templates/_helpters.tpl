{{- define "host.name" }}
{{- default .Values.ambassador.hostname | replace "." "-" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "resolver.address" -}}
{{- printf "consul-server.%s.svc.cluster.local:%s" .Values.consul.namepace .Values.consul.port -}}
{{- end -}}
