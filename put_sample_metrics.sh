#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-udemy-slo-sample}"
SERVICE_NAME="${SERVICE_NAME:-sample-api}"
SCENARIO="${SCENARIO:-good}"

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

require_aws() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLIが見つかりません。AWS CLI v2をインストールしてください。" >&2
    exit 1
  fi
}

case "$SCENARIO" in
  good)
    AVAILABILITY="99.95"
    LATENCY_MS="120"
    REQUEST_COUNT="1000"
    ERROR_COUNT="1"
    ;;
  warning)
    AVAILABILITY="99.70"
    LATENCY_MS="260"
    REQUEST_COUNT="1000"
    ERROR_COUNT="5"
    ;;
  bad)
    AVAILABILITY="98.80"
    LATENCY_MS="650"
    REQUEST_COUNT="1000"
    ERROR_COUNT="25"
    ;;
  recovery)
    AVAILABILITY="99.99"
    LATENCY_MS="90"
    REQUEST_COUNT="1000"
    ERROR_COUNT="0"
    ;;
  *)
    echo "SCENARIOは good / warning / bad / recovery のいずれかにしてください: ${SCENARIO}" >&2
    exit 1
    ;;
esac

require_aws

log "CloudWatch Custom Metricsへ投入します"
log "ProjectName=${PROJECT_NAME}, Service=${SERVICE_NAME}, Scenario=${SCENARIO}"
log "Availability=${AVAILABILITY}%, Latency=${LATENCY_MS}ms, Requests=${REQUEST_COUNT}, Errors=${ERROR_COUNT}"

aws cloudwatch put-metric-data \
  --namespace "UdemyAICompany/SLO" \
  --region "$AWS_REGION" \
  --metric-data \
    "MetricName=Availability,Dimensions=[{Name=ProjectName,Value=${PROJECT_NAME}},{Name=Service,Value=${SERVICE_NAME}}],Value=${AVAILABILITY},Unit=Percent" \
    "MetricName=Latency,Dimensions=[{Name=ProjectName,Value=${PROJECT_NAME}},{Name=Service,Value=${SERVICE_NAME}}],Value=${LATENCY_MS},Unit=Milliseconds" \
    "MetricName=RequestCount,Dimensions=[{Name=ProjectName,Value=${PROJECT_NAME}},{Name=Service,Value=${SERVICE_NAME}}],Value=${REQUEST_COUNT},Unit=Count" \
    "MetricName=ErrorCount,Dimensions=[{Name=ProjectName,Value=${PROJECT_NAME}},{Name=Service,Value=${SERVICE_NAME}}],Value=${ERROR_COUNT},Unit=Count"

log "投入が完了しました。CloudWatch AlarmとDashboardへの反映には数分かかる場合があります。"
