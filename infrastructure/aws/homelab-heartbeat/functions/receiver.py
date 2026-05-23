import base64
import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3


dynamodb = boto3.resource("dynamodb")
secretsmanager = boto3.client("secretsmanager")
sns = boto3.client("sns")


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }


def _event_headers(event):
    return {str(key).lower(): value for key, value in (event.get("headers") or {}).items()}


def _auth_token(event):
    headers = _event_headers(event)
    auth = headers.get("authorization", "")
    if auth.lower().startswith("bearer "):
        return auth[7:].strip()
    return headers.get("x-heartbeat-token")


def _json_body(event):
    body = event.get("body") or "{}"
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")
    return json.loads(body)


def _now_iso():
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _bool_env(name, default=False):
    value = os.environ.get(name)
    if value is None:
        return default
    return value.lower() in {"1", "true", "yes", "on"}


def _expected_token():
    secret_arn = os.environ["HEARTBEAT_TOKEN_SECRET_ARN"]
    secret = secretsmanager.get_secret_value(SecretId=secret_arn)
    return secret["SecretString"]


def _publish_recovery(service_id, previous_status):
    topic_arn = os.environ.get("RECOVERY_TOPIC_ARN")
    if not topic_arn or previous_status != "stale" or not _bool_env("SEND_RECOVERY_NOTIFICATIONS"):
        return

    sns.publish(
        TopicArn=topic_arn,
        Subject=f"Homelab heartbeat recovered: {service_id}",
        Message=f"Heartbeat source {service_id} recovered after being marked stale.",
    )


def lambda_handler(event, context):
    expected_token = _expected_token()
    if _auth_token(event) != expected_token:
        return _response(401, {"ok": False, "error": "unauthorized"})

    try:
        body = _json_body(event)
    except (ValueError, json.JSONDecodeError):
        return _response(400, {"ok": False, "error": "invalid_json"})

    service_id = str(body.get("service_id", "")).strip()
    if not service_id:
        return _response(400, {"ok": False, "error": "missing_service_id"})

    table = dynamodb.Table(os.environ["HEARTBEAT_TABLE"])
    current = table.get_item(Key={"service_id": service_id}).get("Item", {})
    if not current:
        return _response(404, {"ok": False, "error": "unknown_service"})
    if current and current.get("enabled") is False:
        return _response(403, {"ok": False, "error": "service_disabled"})

    now = _now_iso()
    previous_status = current.get("status")
    stale_after = current.get("stale_after_seconds") or Decimal(os.environ.get("DEFAULT_STALE_AFTER_SECONDS", "900"))
    reminder = current.get("alert_reminder_seconds") or Decimal(os.environ.get("DEFAULT_REMINDER_SECONDS", "21600"))

    update_expression = (
        "SET last_seen_at = :now, #status = :healthy, enabled = if_not_exists(enabled, :enabled), "
        "stale_after_seconds = if_not_exists(stale_after_seconds, :stale_after), "
        "alert_reminder_seconds = if_not_exists(alert_reminder_seconds, :reminder)"
    )
    expression_values = {
        ":now": now,
        ":healthy": "healthy",
        ":enabled": True,
        ":stale_after": stale_after,
        ":reminder": reminder,
    }
    if previous_status == "stale":
        update_expression += ", last_recovered_at = :recovered"
        expression_values[":recovered"] = now
    update_expression += " REMOVE last_alerted_at"

    table.update_item(
        Key={"service_id": service_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames={"#status": "status"},
        ExpressionAttributeValues=expression_values,
    )

    _publish_recovery(service_id, previous_status)
    return _response(202, {"ok": True, "service_id": service_id, "last_seen_at": now})
