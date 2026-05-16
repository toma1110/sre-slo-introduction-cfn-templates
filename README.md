# SRE SLO入門 CloudFormationテンプレート

AWS上でSLO監視の基本を学ぶための、CloudFormationハンズオン用テンプレートです。

このリポジトリでは、CloudWatch Custom Metrics、CloudWatch Alarm、CloudWatch Dashboard、SNSを使って、小さく再現しやすいSLO監視スタックを作成します。実際の本番アプリケーションを用意しなくても、SLI、SLO、エラーバジェット、バーンレートの考え方を手元で確認できます。

## 作成されるもの

- アラーム通知用のSNS Topic
- CloudWatch Alarm
  - 可用性SLOリスク
  - p99レイテンシSLOリスク
  - エラー率SLOリスク
  - 高速バーンレートリスク
  - 低速バーンレートリスク
- CloudWatch Dashboard
  - 上段: Availability attainment / Error budget remaining estimate / Current burn rate / Alarm state
  - 中段: Availability trend / Latency p99 trend / Error rate trend / Burn rate trend
  - 下段: Requests and Errors / Runbook and next action
- オプションのApplication Signals SLO
  - デフォルトでは作成しません
  - `ENABLE_APPLICATION_SIGNALS_SLO=true` を指定した場合のみ作成します

## コスト注意

このハンズオンでは、CloudWatch Alarm、Dashboard、Custom Metrics、SNS、オプションのApplication Signals SLOによりAWS料金が発生する場合があります。

検証後は必ずスタックを削除してください。

```bash
./validate.sh delete
```

CloudWatch Custom Metricsは手動で即時削除できません。利用を停止すると、時間経過後に表示されなくなります。

## 前提条件

- AWS CLI v2
- Bash
- 以下を操作できるAWS認証情報、またはIAMロール
  - CloudFormation
  - CloudWatch
  - SNS
  - Application Signals（オプションSLOを有効化する場合のみ）

AWSの認証情報を確認します。

```bash
aws sts get-caller-identity
```

## クイックスタート

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

作成後、CloudWatch Dashboardで以下のダッシュボードを開きます。

```text
sre-slo-intro-dev-dashboard
```

Dashboardは、セクション7の運用担当向けダッシュボードに合わせています。上段で現在の状態、中段で時系列の悪化、Alarm stateで発火理由、下段でRunbook / next actionを確認します。

次に、SLOを悪化させるサンプルメトリクスを投入します。

```bash
./validate.sh put-bad
```

Alarmの状態やDashboardのグラフ反映には数分かかる場合があります。

実サービスでは、Runbook / next actionからCPU、DB、キュー、外部依存などの内部メトリクスへ進む想定です。このハンズオンでは低コスト化のため、内部メトリクスは作成せず、Requests and Errorsを原因調査の入口として扱います。

## フルライフサイクルテスト

一意なスタック名を指定して実行してください。このコマンドは、テンプレート検証、スタック作成、正常メトリクス投入、スモークテスト、スタック更新、異常メトリクス投入、再スモークテスト、スタック削除までを一括で実行します。

```bash
export AWS_REGION=us-east-1
export STACK_NAME=sre-slo-intro-full
export PROJECT_NAME=sre-slo-intro-full
export SERVICE_NAME=sample-api

./validate.sh full
```

## コマンド

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

サンプルメトリクスのシナリオ:

```bash
SCENARIO=good ./validate.sh put-metrics
SCENARIO=warning ./validate.sh put-metrics
SCENARIO=bad ./validate.sh put-metrics
SCENARIO=recovery ./validate.sh put-metrics
```

## パラメータ

| 環境変数 | デフォルト | 説明 |
| --- | --- | --- |
| `STACK_NAME` | `aws-slo-adoption-dev-slo` | CloudFormationスタック名 |
| `AWS_REGION` | `us-east-1` | AWSリージョン |
| `PROJECT_NAME` | `udemy-slo-sample` | リソース名の接頭辞、CloudWatchメトリクスのディメンション |
| `SERVICE_NAME` | `sample-api` | サンプルサービス用のメトリクスディメンション |
| `NOTIFICATION_EMAIL` | 空 | 任意のSNSメール通知先 |
| `DASHBOARD_TITLE` | `SLO Adoption Dashboard` | Dashboardタイトル |
| `AVAILABILITY_SLO_TARGET` | `99.9` | 可用性SLO目標値（%） |
| `LATENCY_THRESHOLD_MS` | `300` | p99レイテンシしきい値 |
| `ERROR_RATE_THRESHOLD_PERCENT` | `1` | エラー率アラームしきい値 |
| `FAST_BURN_RATE_THRESHOLD` | `14` | 高速バーンレートしきい値 |
| `SLOW_BURN_RATE_THRESHOLD` | `2` | 低速バーンレートしきい値 |
| `ENABLE_APPLICATION_SIGNALS_SLO` | `false` | オプションのApplication Signals SLOを作成するか |

## オプション: Application Signals SLO

デフォルトのハンズオンではApplication Signals SLOを作成しません。有効化する場合は以下を指定します。

```bash
export ENABLE_APPLICATION_SIGNALS_SLO=true
./validate.sh create
```

注意:

- Application Signals SLOには料金が発生する場合があります。
- AWSが `AWSServiceRoleForCloudWatchApplicationSignals` サービスリンクロールを作成する場合があります。
- 意味のあるSLO評価には、実際に計装されたアプリケーションと十分なメトリクスデータが必要になる場合があります。

## トラブルシューティング

直近のCloudFormationイベントを確認します。

```bash
aws cloudformation describe-stack-events \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --max-items 20
```

Dashboardを確認します。

```bash
aws cloudwatch get-dashboard \
  --dashboard-name "$PROJECT_NAME-dashboard" \
  --region "$AWS_REGION"
```

Alarmを確認します。

```bash
aws cloudwatch describe-alarms \
  --alarm-names "$PROJECT_NAME-fast-burn-rate" \
  --region "$AWS_REGION"
```

よくある原因:

- `AWS_REGION` がスタックを作成したリージョンと異なる
- `PROJECT_NAME` がメトリクスのディメンションと一致していない
- CloudWatch MetricsやAlarmの反映にまだ時間がかかっている
- SNSメール通知の確認が完了していない
- 同じ `STACK_NAME` の失敗スタックが既に存在する

## 検証結果

テンプレートは以下で検証済みです。

- `aws cloudformation validate-template`
- cfn-lint系ツールによるIaC静的検証
- `us-east-1` での実AWSライフサイクルテスト

詳細は [docs/VALIDATION.md](docs/VALIDATION.md) を参照してください。
