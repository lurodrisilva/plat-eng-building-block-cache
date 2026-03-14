# Helm Chart Templates: Getting Started Summary

This note summarizes the key template concepts covered in the Helm Chart Template Guide
"Getting Started" page.

## Chart Structure and Template Inputs

- Chart layout includes `Chart.yaml`, `values.yaml`, `templates/`, and optional `charts/`.
- `templates/` holds files that Helm renders with its template engine before sending to
Kubernetes.
- `values.yaml` provides default values; users can override them via `helm install` or
`helm upgrade`.
- `Chart.yaml` describes the chart and is available inside templates.
- `charts/` can include subcharts, which affect template rendering later in the guide.

## Starter Chart and Templates

- `helm create mychart` scaffolds a chart with common templates.
- Default templates include `NOTES.txt`, `deployment.yaml`, `service.yaml`, and
`_helpers.tpl`.
- For learning, the guide removes these files to build templates from scratch.

## First Template Example (ConfigMap)

- A plain YAML file in `templates/` is valid and will be rendered as-is.
- Example resource: a minimal `ConfigMap` with `apiVersion`, `kind`, `metadata`, and
`data`.
- Installing the chart (`helm install`) renders and applies the templates.
- `helm get manifest <release>` shows the rendered YAML and the source template path.
- `helm uninstall <release>` removes the release.

## Template Directives and Built-in Objects

- Template directives use `{{ ... }}` blocks inside YAML.
- `.Release.Name` injects the release name and is a built-in object.
- Using `.Release.Name` avoids hard-coding resource names and keeps them release-specific.
- Template data is accessed via dot-delimited namespaces (e.g., `.Release.Name`).

## Dry Runs and Debugging Output

- `helm install --debug --dry-run <release> ./mychart` renders templates without
installing.
- The output includes computed values and the rendered manifest, useful for iteration.
- A successful dry run does not guarantee Kubernetes will accept the resources.

## Practical Tips

- Prefer `.yaml` for manifest templates and `.tpl` for helper templates.
- Resource names should stay within Kubernetes DNS label limits (63 chars); Helm release
names are limited to 53 chars for this reason.
