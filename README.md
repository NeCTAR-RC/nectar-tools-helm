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

The tools read `/etc/nectar/tools.ini`.

- **Vault (production, `vault.enabled: true`)**: the Vault agent
  injector renders the file from the `tools.ini` key of
  `vault.settings_secret`, which holds the entire ini file verbatim.
  `secret-volume-path` is set to `/etc/nectar` so no `-c` flag is
  needed. The kubernetes-auth role is bound to the chart's service
  account name.
- **Fallback (`vault.enabled: false`)**: a Secret is rendered from
  `conf.toolsIni` and mounted at `/etc/nectar`.

Leave `[logging] log_dir` unset so logs go to stdout for Kubernetes
to capture. Set `[sentry] dsn` to report errors to GlitchTip.

## Monitoring

There is no equivalent of the old `job_prometheus_wrapper.py`
node_exporter textfiles: alert on CronJob/Job status via
kube-state-metrics, and on errors via GlitchTip.
