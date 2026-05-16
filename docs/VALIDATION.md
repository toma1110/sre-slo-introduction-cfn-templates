# ハンズオン検証レポート

## 対象

- リポジトリ: `toma1110/sre-slo-introduction-cfn-templates`
- スタック名: `slo-cfn-20260513-0719`
- リージョン: `us-east-1`
- 検証日: 2026-05-13

## 正とするファイル

- `README.md`
- `template.yaml`
- `validate.sh`
- `smoke_test.sh`
- `put_sample_metrics.sh`

## 作成したハンズオン範囲

- CloudWatch Custom Metrics
  - `Availability`
  - `Latency`
  - `RequestCount`
  - `ErrorCount`
- CloudWatch Alarm
  - 可用性SLOリスク
  - レイテンシSLOリスク
  - エラー率SLOリスク
  - 高速バーンレート
  - 低速バーンレート
- CloudWatch Dashboard
- SNS Topicと任意のメール通知
- オプションのApplication Signals SLO
- サンプルメトリクス投入スクリプト

## AWS公式ドキュメント確認

確認に使った検索語:

- `AWS::ApplicationSignals::ServiceLevelObjective CloudFormation service linked role SLO`
- `AWS::CloudWatch::Alarm MetricDataQuery Metrics math expression CloudFormation`
- `CloudWatch metric math IF expression error rate divide Errors Invocations`

確認結果:

- `AWS::ApplicationSignals::ServiceLevelObjective` でApplication Signals SLOを作成でき、CloudWatch Application Signalsのサービスリンクロールを作成または利用する場合があります。
- `AWS::CloudWatch::Alarm MetricDataQuery` はAlarm用のメトリクス演算式に対応しており、監視対象の式は単一時系列を返す必要があります。
- CloudWatch Metric Mathでは、エラー率計算のように複数メトリクスを組み合わせる式を利用できます。

参照URL:

- https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-applicationsignals-servicelevelobjective.html
- https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-cloudwatch-alarm-metricdataquery.html
- https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/using-metric-math.html

## 実行コマンド

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

追加の静的チェック:

```bash
# デフォルト値でFn::Sub相当の置換を行ったDashboardBodyをJSONとしてパースできることを確認。
```

## 結果

- shell構文チェック: 成功
- `aws cloudformation validate-template`: 成功
- `./validate.sh validate`: 成功
- DashboardBody JSONパース確認: 成功
- awsiac CloudFormationテンプレート検証: 成功
- スタック作成: 成功
- 正常サンプルメトリクス投入: 成功
- 作成後スモークテスト: 成功
- スタック更新: 成功
- 異常サンプルメトリクス投入: 成功
- 更新後スモークテスト: 成功
- スタック削除: 成功
- 削除後の `describe-stacks` 確認: 成功。スタックが存在しないことを確認

## 実行したAWSライフサイクル

```bash
STACK_NAME=slo-cfn-20260513-0719 \
PROJECT_NAME=slo-cfn-20260513-0719 \
SERVICE_NAME=sample-api \
AWS_REGION=us-east-1 \
./validate.sh full
```

タイムライン:

- 2026-05-13T09:52:23Z: テンプレート検証開始
- 2026-05-13T09:53:06Z: スタック作成完了
- 2026-05-13T09:53:32Z: 1回目のスモークテスト完了
- 2026-05-13T09:54:18Z: スタック更新完了
- 2026-05-13T09:54:44Z: 2回目のスモークテスト完了
- 2026-05-13T09:55:51Z: スタック削除完了

削除後確認:

```bash
aws cloudformation describe-stacks \
  --stack-name slo-cfn-20260513-0719 \
  --region us-east-1
```

結果: `ValidationError`。スタックは存在しません。

## README再現性

READMEには、コピーして実行できる以下の手順を記載しています。

- 環境変数設定
- テンプレート検証
- スタック作成
- 正常メトリクス投入
- スモークテスト
- 異常メトリクス投入
- スタック更新
- スタック削除
- Application Signalsの任意パス
- トラブルシューティング

状態: 実AWSライフサイクル実行で再現済みです。

## 日本語化後の確認

この日本語化では、公開説明文、CloudFormationのDescription、AlarmDescription、Dashboard表示ラベル、スクリプトのヘルプ表示を修正しました。

追加確認日: 2026-05-14

実行対象:

- `bash -n validate.sh`
- `bash -n smoke_test.sh`
- `bash -n put_sample_metrics.sh`
- `aws cloudformation validate-template --template-body file://template.yaml --region us-east-1`
- `./validate.sh validate`
- DashboardBody JSONパース確認

結果:

- shell構文チェック: 成功
- `aws cloudformation validate-template`: 成功
- `./validate.sh validate`: 成功
- DashboardBody JSONパース確認: 成功

スタック作成、更新、削除を伴う `./validate.sh full` はAWSリソースを作成するため、既存の2026-05-13実行結果を維持し、再実行は必要に応じて行います。

## ASCII Description Regression Fix

2026-05-16に、CloudFormation StackのDescription表示が一部環境で `????` に文字化けする事象を確認したため、CloudFormationテンプレート内のAWS表示対象文字列をASCII中心に戻しました。

変更対象:

- Template `Description`
- Parameter `Description` / `ConstraintDescription`
- Alarm `AlarmDescription`
- Dashboard title, markdown, metric label
- Output `Description`
- `validate.sh` のデフォルトDashboard title
- Dashboard text widgetのMarkdown改行は、CloudWatch上で `\n` が文字として表示されないよう、JSONの改行エスケープ1つに修正

追加確認日: 2026-05-16

実行対象:

- `bash -n validate.sh`
- `bash -n smoke_test.sh`
- `bash -n put_sample_metrics.sh`
- `aws cloudformation validate-template --template-body file://template.yaml --region us-east-1`
- `./validate.sh validate`
- テンプレート内の日本語文字列スキャン

結果:

- shell構文チェック: 成功
- `aws cloudformation validate-template`: 成功
- `./validate.sh validate`: 成功
- `template.yaml` 内の日本語文字列: 0件

スタック作成、更新、削除はAWSリソースを作成または変更するため、この修正確認では実行していません。

## 注意点

- デフォルト構成は、ハンズオンを小さく理解しやすくするためCloudWatch Custom Metricsのみを使います。
- Application Signals SLOは `ENABLE_APPLICATION_SIGNALS_SLO=true` の場合のみ作成します。
- Custom Metricsは即時削除できず、利用停止後に時間経過で表示されなくなります。
- SNSメール通知は受信者側の確認が必要です。

## ステータス

合格
