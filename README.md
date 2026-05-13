# SRE SLO Introduction CloudFormation Templates

CloudFormation templates for a hands-on introduction to SLO monitoring on AWS.

This repository builds a small, reproducible SLO monitoring stack using CloudWatch custom metrics, CloudWatch alarms, a dashboard, and SNS. It is intended for learning SLI/SLO/error-budget/burn-rate concepts without requiring a real production application.

## What This Creates

- SNS Topic for alarm notifications
- CloudWatch Alarms
  - Availability SLO risk
  - p99 latency SLO risk
  - Error-rate SLO risk
  - Fast burn-rate risk
  - Slow burn-rate risk
- CloudWatch Dashboard
  - Availability
  - Latency p99
  - Error rate
  - Burn rate
  - Requests and errors
- Optional Application Signals SLO
  - Disabled by default
  - Enabled only with `ENABLE_APPLICATION_SIGNALS_SLO=true`

## Cost Warning

This hands-on can incur AWS charges for CloudWatch alarms, dashboards, custom metrics, SNS, and optional Application Signals SLOs.

Delete the stack after testing:

```bash
./validate.sh delete
```

CloudWatch custom metrics cannot be manually deleted immediately; they stop appearing after they age out.

## Prerequisites

- AWS CLI v2
- Bash
- AWS credentials or an IAM role with permission to use:
  - CloudFormation
  - CloudWatch
  - SNS
  - Application Signals, only if optional SLO is enabled

Check your AWS identity:

```bash
aws sts get-caller-identity
```

## Quick Start

```bash
git clone https://github.com/toma1110/sre-slo-introduction-cfn-templates.git
cd sre-slo-introduction-cfn-templates

export AWS_REGION=us-east-1
export STACK_NAME=sre-slo-intro-dev
export PROJECT_NAME=sre-slo-intro-dev
export SERVICE_NAME=sample-api

./validate.sh validate
./validate.sh create
./validate.sh put-good
./smoke_test.sh
```

Open the CloudWatch dashboard named:

```text
sre-slo-intro-dev-dashboard
```

Then publish an unhealthy sample:

```bash
./validate.sh put-bad
```

Alarm state and dashboard graphs can take a few minutes to update.

## Full Lifecycle Test

Use a unique stack name. This command validates, creates, publishes good metrics, runs smoke tests, updates the stack, publishes bad metrics, runs smoke tests again, and deletes the stack.

```bash
export AWS_REGION=us-east-1
export STACK_NAME=sre-slo-intro-full
export PROJECT_NAME=sre-slo-intro-full
export SERVICE_NAME=sample-api

./validate.sh full
```

## Commands

```bash
./validate.sh validate
./validate.sh create
./validate.sh put-good
./validate.sh put-bad
./validate.sh smoke
./validate.sh update
./validate.sh delete
./validate.sh full
```

Sample metric scenarios:

```bash
SCENARIO=good ./validate.sh put-metrics
SCENARIO=warning ./validate.sh put-metrics
SCENARIO=bad ./validate.sh put-metrics
SCENARIO=recovery ./validate.sh put-metrics
```

## Parameters

| Environment variable | Default | Description |
| --- | --- | --- |
| `STACK_NAME` | `aws-slo-adoption-dev-slo` | CloudFormation stack name |
| `AWS_REGION` | `us-east-1` | AWS Region |
| `PROJECT_NAME` | `udemy-slo-sample` | Resource name prefix and metric dimension |
| `SERVICE_NAME` | `sample-api` | Metric dimension for the sample service |
| `NOTIFICATION_EMAIL` | empty | Optional SNS email subscription |
| `DASHBOARD_TITLE` | `SLO Adoption Dashboard` | Dashboard title |
| `AVAILABILITY_SLO_TARGET` | `99.9` | Availability SLO target percentage |
| `LATENCY_THRESHOLD_MS` | `300` | p99 latency threshold |
| `ERROR_RATE_THRESHOLD_PERCENT` | `1` | Error-rate alarm threshold |
| `FAST_BURN_RATE_THRESHOLD` | `14` | Fast burn-rate threshold |
| `SLOW_BURN_RATE_THRESHOLD` | `2` | Slow burn-rate threshold |
| `ENABLE_APPLICATION_SIGNALS_SLO` | `false` | Create optional Application Signals SLO |

## Optional Application Signals SLO

The default hands-on does not create an Application Signals SLO. To enable it:

```bash
export ENABLE_APPLICATION_SIGNALS_SLO=true
./validate.sh create
```

Notes:

- Application Signals SLOs can incur charges.
- AWS may create the `AWSServiceRoleForCloudWatchApplicationSignals` service-linked role.
- A real instrumented application and enough metric data may be required for meaningful SLO evaluation.

## Troubleshooting

View recent CloudFormation events:

```bash
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --max-items 20
```

Check a dashboard:

```bash
aws cloudwatch get-dashboard \
  --dashboard-name "$PROJECT_NAME-dashboard" \
  --region "$AWS_REGION"
```

Check an alarm:

```bash
aws cloudwatch describe-alarms \
  --alarm-names "$PROJECT_NAME-fast-burn-rate" \
  --region "$AWS_REGION"
```

Common causes:

- `AWS_REGION` differs from where the stack was created.
- `PROJECT_NAME` does not match the metric dimensions.
- CloudWatch metrics and alarms have not updated yet.
- SNS email subscription has not been confirmed.
- A failed stack with the same `STACK_NAME` already exists.

## Validation

The template was validated with:

- `aws cloudformation validate-template`
- IaC validation through cfn-lint tooling
- A real AWS lifecycle test in `us-east-1`

See [docs/VALIDATION.md](docs/VALIDATION.md).
