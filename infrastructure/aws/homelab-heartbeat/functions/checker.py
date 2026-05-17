import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3


dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")


def _now():
    return datetime.now(timezone.utc).replace(microsecond=0)


def _parse_time(value):
    if not value:
        return None
    return datetime.fromisoformat(str(value).replace("Z", "+00:00"))


def _seconds(value, default):
    if value is None:
        return default
    if isinstance(value, Decimal):
        return int(value)
    return int(value)


def _should_alert(item, now, reminder_seconds):
    last_alerted_at = _parse_time(item.get("last_alerted_at"))
    if last_alerted_at is None:
        return True
    return (now - last_alerted_at).total_seconds() >= reminder_seconds


def _publish_outage(topic_arn, service_id, last_seen_at, stale_after_seconds):
    last_seen = last_seen_at or "never"
    sns.publish(
        TopicArn=topic_arn,
        Subject=f"Homelab heartbeat stale: {service_id}",
        Message=(
            f"Heartbeat source {service_id} is stale. "
            f"Last seen: {last_seen}. Stale threshold: {stale_after_seconds} seconds."
        ),
    )


def _handle_item(table, topic_arn, item, now):
    if item.get("enabled") is False:
        return "disabled"

    service_id = item["service_id"]
    last_seen_at = item.get("last_seen_at")
    last_seen = _parse_time(last_seen_at)
    stale_after_seconds = _seconds(item.get("stale_after_seconds"), 900)
    reminder_seconds = _seconds(
        item.get("alert_reminder_seconds"),
        int(os.environ.get("DEFAULT_REMINDER_SECONDS", "21600")),
    )
    is_stale = last_seen is None or (now - last_seen).total_seconds() > stale_after_seconds

    if not is_stale:
        if item.get("status") != "healthy":
            table.update_item(
                Key={"service_id": service_id},
                UpdateExpression="SET #status = :healthy",
                ExpressionAttributeNames={"#status": "status"},
                ExpressionAttributeValues={":healthy": "healthy"},
            )
        return "healthy"

    if _should_alert(item, now, reminder_seconds):
        _publish_outage(topic_arn, service_id, last_seen_at, stale_after_seconds)
        table.update_item(
            Key={"service_id": service_id},
            UpdateExpression="SET #status = :stale, last_alerted_at = :now",
            ExpressionAttributeNames={"#status": "status"},
            ExpressionAttributeValues={":stale": "stale", ":now": now.isoformat().replace("+00:00", "Z")},
        )
        return "alerted"

    table.update_item(
        Key={"service_id": service_id},
        UpdateExpression="SET #status = :stale",
        ExpressionAttributeNames={"#status": "status"},
        ExpressionAttributeValues={":stale": "stale"},
    )
    return "suppressed"


def lambda_handler(event, context):
    table = dynamodb.Table(os.environ["HEARTBEAT_TABLE"])
    topic_arn = os.environ["UPTIME_TOPIC_ARN"]
    now = _now()
    counts = {"healthy": 0, "alerted": 0, "suppressed": 0, "disabled": 0}

    scan_kwargs = {}
    while True:
        response = table.scan(**scan_kwargs)
        for item in response.get("Items", []):
            outcome = _handle_item(table, topic_arn, item, now)
            counts[outcome] += 1
        if "LastEvaluatedKey" not in response:
            break
        scan_kwargs["ExclusiveStartKey"] = response["LastEvaluatedKey"]

    return counts
