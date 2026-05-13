# Hands-on Validation Report

## Target

- Repository: `toma1110/sre-slo-introduction-cfn-templates`
- Stack Name: `slo-cfn-20260513-0719`
- Region: `us-east-1`
- Validation Date: 2026-05-13

## Source of Truth

- `README.md`
- `template.yaml`
- `validate.sh`
- `smoke_test.sh`
- `put_sample_metrics.sh`

## Created Hands-on Scope

- CloudWatch Custom Metrics
  - `Availability`
  - `Latency`
  - `RequestCount`
  - `ErrorCount`
- CloudWatch Alarm
  - Availability SLO risk
  - Latency SLO risk
  - Error-rate SLO risk
  - Fast burn-rate
  - Slow burn-rate
- CloudWatch Dashboard
- SNS Topic and optional email subscription
- Optional Application Signals SLO
- Sample metric publishing script

## AWS Documentation Checks

Search terms:

- `AWS::ApplicationSignals::ServiceLevelObjective CloudFormation service linked role SLO`
- `AWS::CloudWatch::Alarm MetricDataQuery Metrics math expression CloudFormation`
- `CloudWatch metric math IF expression error rate divide Errors Invocations`

Confirmed:

- `AWS::ApplicationSignals::ServiceLevelObjective` can create an Application Signals SLO and may create/use the CloudWatch Application Signals service-linked role.
- `AWS::CloudWatch::Alarm MetricDataQuery` supports metric math expressions for alarms, and the watched expression must return a single time series.
- CloudWatch Metric Math supports expressions that combine metrics, including error-rate style calculations.

Reference URLs:

- https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-applicationsignals-servicelevelobjective.html
- https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-cloudwatch-alarm-metricdataquery.html
- https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html

## Commands

```bash
bash -n validate.sh
bash -n smoke_test.sh
bash -n put_sample_metrics.sh
aws cloudformation validate-template \
  --template-body file://template.yaml \
  --region us-east-1
./validate.sh validate
STACK_NAME=slo-cfn-20260513-0719 \
PROJECT_NAME=slo-cfn-20260513-0719 \
SERVICE_NAME=sample-api \
AWS_REGION=us-east-1 \
./validate.sh full
```

Additional static check:

```bash
# DashboardBody after default Fn::Sub values was parsed as JSON.
```

## Results

- shell syntax validate: pass
- `aws cloudformation validate-template`: pass
- `./validate.sh validate`: pass
- DashboardBody JSON parse with default substitutions: pass
- awsiac CloudFormation template validation: pass
- stack create: pass
- good sample metrics publish: pass
- smoke test after create: pass
- stack update: pass
- bad sample metrics publish: pass
- smoke test after update: pass
- stack delete: pass
- post-delete describe-stacks check: pass, stack no longer exists

## Executed AWS Lifecycle

```bash
STACK_NAME=slo-cfn-20260513-0719 \
PROJECT_NAME=slo-cfn-20260513-0719 \
SERVICE_NAME=sample-api \
AWS_REGION=us-east-1 \
./validate.sh full
```

Timeline:

- 2026-05-13T09:52:23Z: template validation started
- 2026-05-13T09:53:06Z: stack create completed
- 2026-05-13T09:53:32Z: first smoke test completed
- 2026-05-13T09:54:18Z: stack update completed
- 2026-05-13T09:54:44Z: second smoke test completed
- 2026-05-13T09:55:51Z: stack delete completed

Post-delete check:

```bash
aws cloudformation describe-stacks \
  --stack-name slo-cfn-20260513-0719 \
  --region us-east-1
```

Result: `ValidationError`, stack does not exist.

## README Reproduction

README contains copyable steps for:

- environment setup
- template validation
- stack creation
- good metric publishing
- smoke test
- bad metric publishing
- stack update
- stack delete
- Application Signals optional path
- troubleshooting

Status: reproduced with AWS lifecycle execution.

## Notes

- Default path uses CloudWatch Custom Metrics only to keep the hands-on small and understandable.
- Application Signals SLO is opt-in via `ENABLE_APPLICATION_SIGNALS_SLO=true`.
- Custom Metrics do not delete immediately; they age out after use.
- SNS email subscriptions require recipient confirmation.

## Status

Pass
