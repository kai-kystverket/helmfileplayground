[private]
default:
  just --list -u

# render a specific helm chart
r HELMFILE ENV:
  helmfile --environment={{ENV}} lint --args --quiet --skip-deps --skip-refresh -f helmfile.d/{{HELMFILE}}
  -helmfile list --file helmfile.d/{{HELMFILE}} --output json | jq .[].name -r | xargs -I {} rm -r _rendered/{{ENV}}/{}
  helmfile --environment={{ENV}} template -q --output-dir-template="../_rendered/{{ENV}}/{{{{.Release.Name }}" -f helmfile.d/{{HELMFILE}} --skip-deps --skip-refresh

# Use git diff to render just uncommitted charts
render-diff ENV="test":
  git status --porcelain helmfile.d/ | grep -E '\.(yaml|gotmpl)$' |sed 's/.*helmfile.d\///' \
  | xargs -P 20 -I {} just r {} {{ENV}}

# Render charts for one environment
render ENV="test":
  ls helmfile.d/*.yaml  helmfile.d/*.gotmpl | sed 's/helmfile.d\///' | xargs -P 20 -I {} just r {} {{ENV}}

# Render all available environments
render-all:
  just render test
  just render prod

# Quick command to render everything and show the diff
rad:
  just render-all
  git diff _rendered

# Fetch one chart
f HELMFILE CHART:
  -cat {{HELMFILE}} |  grep -o -E "_charts\/[^\/]*" | xargs -I {} rm helmfile.d/{} -r
  helmfile --environment test fetch --file={{HELMFILE}} --chart={{CHART}} --output-dir-template _charts/{{{{.Release.Name}}

# Fetch all helm charts to local _charts folder
fetch:
  just f ./helmfile.d/cert-manager.gotmpl jetstack/cert-manager
  just f ./helmfile.d/external-dns.gotmpl bitnami/external-dns
  just f ./helmfile.d/loki.gotmpl grafana/loki
  just f ./helmfile.d/opentelemetry-operator.gotmpl open-telemetry/opentelemetry-operator

act EVENT="pull_request":
  act {{EVENT}} -e event.json  -W update.yaml
