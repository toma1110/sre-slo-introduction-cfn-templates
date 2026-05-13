#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${TEMPLATE_FILE:-${SCRIPT_DIR}/template.yaml}"
STACK_NAME="${STACK_NAME:-aws-slo-adoption-dev-slo}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-udemy-slo-sample}"
SERVICE_NAME="${SERVICE_NAME:-sample-api}"
NOTIFICATION_EMAIL="${NOTIFICATION_EMAIL:-}"
DASHBOARD_TITLE="${DASHBOARD_TITLE:-SLO Adoption Dashboard}"
AVAILABILITY_SLO_TARGET="${AVAILABILITY_SLO_TARGET:-99.9}"
LATENCY_THRESHOLD_MS="${LATENCY_THRESHOLD_MS:-300}"
ERROR_RATE_THRESHOLD_PERCENT="${ERROR_RATE_THRESHOLD_PERCENT:-1}"
FAST_BURN_RATE_THRESHOLD="${FAST_BURN_RATE_THRESHOLD:-14}"
SLOW_BURN_RATE_THRESHOLD="${SLOW_BURN_RATE_THRESHOLD:-2}"
ENABLE_APPLICATION_SIGNALS_SLO="${ENABLE_APPLICATION_SIGNALS_SLO:-false}"
ACTION="${1:-validate}"

log() {
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

require_aws() {
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLIが見つかりません。AWS CLI v2をインストールしてください。" >&2
    exit 1
  fi
}

stack_exists() {
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    >/dev/null 2>&1
}

validate_template() {
  log "CloudFormationテンプレートを検証します: ${TEMPLATE_FILE}"
  aws cloudformation validate-template \
    --template-body "file://${TEMPLATE_FILE}" \
    --region "$AWS_REGION" \
    >/dev/null
}

deploy_stack() {
  local mode="$1"

  log "CloudFormationスタックを${mode}します: ${STACK_NAME}"
  aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --region "$AWS_REGION" \
    --parameter-overrides \
      "ProjectName=${PROJECT_NAME}" \
      "ServiceName=${SERVICE_NAME}" \
      "NotificationEmail=${NOTIFICATION_EMAIL}" \
      "DashboardTitle=${DASHBOARD_TITLE}" \
      "AvailabilitySloTarget=${AVAILABILITY_SLO_TARGET}" \
      "LatencyThresholdMs=${LATENCY_THRESHOLD_MS}" \
      "ErrorRateThresholdPercent=${ERROR_RATE_THRESHOLD_PERCENT}" \
      "FastBurnRateThreshold=${FAST_BURN_RATE_THRESHOLD}" \
      "SlowBurnRateThreshold=${SLOW_BURN_RATE_THRESHOLD}" \
      "EnableApplicationSignalsSlo=${ENABLE_APPLICATION_SIGNALS_SLO}" \
    --tags \
      "Course=aws-slo-adoption-course" \
      "ManagedBy=ai-company-v1" \
    --no-fail-on-empty-changeset
}

create_stack() {
  if stack_exists; then
    echo "スタックは既に存在します。更新する場合は './validate.sh update' を使ってください: ${STACK_NAME}" >&2
    exit 1
  fi

  deploy_stack "作成"
}

update_stack() {
  if ! stack_exists; then
    echo "スタックが存在しません。先に './validate.sh create' を実行してください: ${STACK_NAME}" >&2
    exit 1
  fi

  deploy_stack "更新"
}

put_metrics() {
  local scenario="${1:-${SCENARIO:-good}}"

  log "サンプルSLIメトリクスを投入します: scenario=${scenario}"
  STACK_NAME="$STACK_NAME" \
    AWS_REGION="$AWS_REGION" \
    PROJECT_NAME="$PROJECT_NAME" \
    SERVICE_NAME="$SERVICE_NAME" \
    SCENARIO="$scenario" \
    "${SCRIPT_DIR}/put_sample_metrics.sh"
}

smoke_test() {
  log "smoke testを実行します"
  STACK_NAME="$STACK_NAME" AWS_REGION="$AWS_REGION" ENABLE_APPLICATION_SIGNALS_SLO="$ENABLE_APPLICATION_SIGNALS_SLO" "${SCRIPT_DIR}/smoke_test.sh"
}

delete_stack() {
  if ! stack_exists; then
    log "スタックは存在しません。削除をスキップします: ${STACK_NAME}"
    return 0
  fi

  log "CloudFormationスタックを削除します: ${STACK_NAME}"
  aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"

  aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"
}

full_validation() {
  if stack_exists; then
    echo "fullはcreate/update/deleteを含むため、既存スタックでは実行しません。別のSTACK_NAMEを指定してください: ${STACK_NAME}" >&2
    exit 1
  fi

  validate_template
  create_stack
  put_metrics good
  smoke_test
  DASHBOARD_TITLE="${DASHBOARD_TITLE} Updated"
  update_stack
  put_metrics bad
  smoke_test
  delete_stack
}

usage() {
  cat <<USAGE
Usage: $0 [validate|create|update|put-metrics|put-good|put-bad|smoke|delete|full]

Environment variables:
  STACK_NAME                       Default: aws-slo-adoption-dev-slo
  AWS_REGION                       Default: us-east-1
  PROJECT_NAME                     Default: udemy-slo-sample
  SERVICE_NAME                     Default: sample-api
  NOTIFICATION_EMAIL               Default: empty
  DASHBOARD_TITLE                  Default: SLO Adoption Dashboard
  AVAILABILITY_SLO_TARGET          Default: 99.9
  LATENCY_THRESHOLD_MS             Default: 300
  ERROR_RATE_THRESHOLD_PERCENT     Default: 1
  FAST_BURN_RATE_THRESHOLD         Default: 14
  SLOW_BURN_RATE_THRESHOLD         Default: 2
  ENABLE_APPLICATION_SIGNALS_SLO   Default: false
  SCENARIO                         Default for put-metrics: good
  TEMPLATE_FILE                    Default: ./template.yaml
USAGE
}

require_aws

case "$ACTION" in
  validate)
    validate_template
    ;;
  create)
    validate_template
    create_stack
    ;;
  update)
    validate_template
    update_stack
    ;;
  put-metrics)
    put_metrics "${SCENARIO:-good}"
    ;;
  put-good)
    put_metrics good
    ;;
  put-bad)
    put_metrics bad
    ;;
  smoke)
    smoke_test
    ;;
  delete)
    delete_stack
    ;;
  full)
    full_validation
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

log "完了しました: ${ACTION}"
