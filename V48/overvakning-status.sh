#!/bin/bash
# overvakning-status.sh - Visar monitoreringen som text, for dokumentationen.
# Kor i Git Bash pa din dator:  bash V48/overvakning-status.sh

REGION="eu-north-1"
PREFIX="novatrix"
ASG="$PREFIX-web-asg"

echo "=== Larm och tillstand ==="
aws cloudwatch describe-alarms --alarm-name-prefix "$PREFIX-" --region "$REGION" \
  --query "MetricAlarms[].[AlarmName,StateValue,MetricName,Statistic,Threshold]" --output table

echo ""
echo "=== SNS-prenumeration (ska vara bekraftad, inte PendingConfirmation) ==="
TOPIC=$(aws sns list-topics --region "$REGION" --query "Topics[?ends_with(TopicArn,':$PREFIX-larm')].TopicArn" --output text | tr -d '\r')
aws sns list-subscriptions-by-topic --topic-arn "$TOPIC" --region "$REGION" \
  --query "Subscriptions[].[Protocol,SubscriptionArn]" --output table

echo ""
echo "=== Minne och disk for hela gruppen, senaste 15 minuterna (Maximum) ==="
START=$(date -u -d '-15 min' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-15M +%Y-%m-%dT%H:%M:%SZ)
END=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for M in mem_used_percent disk_used_percent; do
  echo "--- $M"
  aws cloudwatch get-metric-statistics --namespace CWAgent --metric-name "$M" \
    --dimensions Name=AutoScalingGroupName,Value="$ASG" --statistics Maximum --period 300 \
    --start-time "$START" --end-time "$END" --region "$REGION" \
    --query "sort_by(Datapoints,&Timestamp)[].[Timestamp,Maximum]" --output table
done

echo ""
echo "=== Log groups med lagringstid ==="
aws logs describe-log-groups --region "$REGION" --query "logGroups[?contains(logGroupName,'$PREFIX')].[logGroupName,retentionInDays,storedBytes]" --output table

echo ""
echo "=== Log streams i access-loggen, en per server ==="
MSYS_NO_PATHCONV=1 aws logs describe-log-streams --log-group-name "/$PREFIX/httpd/access" --region "$REGION" \
  --order-by LastEventTime --descending --max-items 6 \
  --query "logStreams[].[logStreamName]" --output table

echo ""
echo "=== Senaste sajtkollen (Lambda) ==="
aws lambda invoke --function-name "$PREFIX-sajtkoll" --region "$REGION" /tmp/sajtkoll.json >/dev/null && cat /tmp/sajtkoll.json && echo ""