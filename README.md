# nectar-tools-helm

Runs the [nectar-tools](https://github.com/NeCTAR-RC/nectar-tools)
operational commands (expiry, provisioning, SU reports and audits) as
Kubernetes CronJobs, replacing the root crontab and wrapper scripts on
the cron host. Follows the same pattern as
[nectar-metrics-helm](https://github.com/NeCTAR-RC/nectar-metrics-helm).

## Jobs

Each entry in `jobs` in `values.yaml` becomes one CronJob, carrying
over the old crontab entry's schedule (interpreted in
`timeZone`, default Australia/Melbourne). Multi-command entries are
the old `/usr/local/sbin/*.sh` wrapper scripts inlined: every command
runs even if an earlier one fails, and any failure marks the Job
failed.

### Dry run

All nectar-tools commands default to dry run and only act when passed
`-y`. Commands in `values.yaml` reference a literal `$yes` token:

- `dryRun: true` (chart default) renders `yes=''`, so nothing acts.
- `dryRun: false` (production) renders `yes='-y'`.
- A per-job `dryRun` overrides the chart-wide value; the weekly audit
  jobs pin `dryRun: true` and omit `$yes`, so they can never act.

## Configuration

nectar-tools uses oslo.config: the commands read
`/etc/nectar-tools/nectar-tools.conf` (the default config path, so no
`-c` flag is needed) plus any drop-ins under
`/etc/nectar-tools/nectar-tools.conf.d/` (oslo.config's default config
dir), with the drop-ins taking precedence.

- **nectar-tools.conf** is rendered from the `conf` values into a
  ConfigMap and mounted at `/etc/nectar-tools/nectar-tools.conf`. Each
  key under `conf` is an ini section; each entry under a section
  becomes an `option = value` line. It holds no secrets.
- **Secrets (production, `vault.enabled: true`)**: the Vault agent
  injector renders `secrets.conf` into
  `/etc/nectar-tools/nectar-tools.conf.d/` from individual keys of
  `vault.settings_secret`:

  | Vault key          | Rendered option              |
  |--------------------|------------------------------|
  | `keystone_password` | `[service_auth] password`   |
  | `transport_url`    | `[DEFAULT] transport_url` (optional) |
  | `freshdesk_key`    | `[freshdesk] key` (optional) |
  | `jupyterhub_token` | `[jupyterhub] token` (optional) |
  | `kubernetes_token` | `[kubernetes_client] token` (optional) |
  | `trove_rabbitmq_password` | `[trove] rabbitmq_password` (optional) |
  | `sentry_dsn`       | `[sentry] dsn` (optional)    |

  The kubernetes-auth role is bound to the chart's service account
  name.
- **Fallback (`vault.enabled: false`, dev/test)**: only
  nectar-tools.conf is present, so any secrets the commands need must
  be put in `conf`,
  where they end up in a world-readable ConfigMap. Dev/test clusters
  only.

Leave oslo.log's `log_dir`/`log_file` unset in `[DEFAULT]` so logs go
to stderr for Kubernetes to capture. Set the `sentry_dsn` Vault key to
report errors to GlitchTip.

The weekly database audit's `clean_stale_guestagent_queues` check
deletes queues from the trove RabbitMQ vhost through the broker's
management API. It needs `rabbitmq_url`, `rabbitmq_username` and
optionally `rabbitmq_vhost` (default `trove`) under `conf.trove`, plus
the `trove_rabbitmq_password` Vault key. Without them the check fails
with a configuration error and the rest of the job carries on.

## Monitoring

There is no equivalent of the old `job_prometheus_wrapper.py`
node_exporter textfiles: alert on CronJob/Job status via
kube-state-metrics, and on errors via GlitchTip.
