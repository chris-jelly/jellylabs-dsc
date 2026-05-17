import importlib.util
import json
import os
import pathlib
import unittest
from decimal import Decimal
from unittest.mock import MagicMock, patch


FUNCTIONS_DIR = pathlib.Path(__file__).resolve().parents[1] / "functions"


def load_function(name):
    spec = importlib.util.spec_from_file_location(name, FUNCTIONS_DIR / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    with patch.dict("sys.modules", {"boto3": MagicMock()}):
        spec.loader.exec_module(module)
    return module


class ReceiverTests(unittest.TestCase):
    def setUp(self):
        self.receiver = load_function("receiver")
        self.table = MagicMock()
        self.receiver.dynamodb.Table.return_value = self.table
        self.receiver.secretsmanager.get_secret_value.return_value = {"SecretString": "secret"}

    def test_rejects_invalid_token_without_update(self):
        with patch.dict(os.environ, {"HEARTBEAT_TOKEN_SECRET_ARN": "secret-arn", "HEARTBEAT_TABLE": "table"}):
            result = self.receiver.lambda_handler(
                {"headers": {"authorization": "Bearer wrong"}, "body": json.dumps({"service_id": "homelab-cluster"})},
                None,
            )

        self.assertEqual(result["statusCode"], 401)
        self.table.update_item.assert_not_called()
        self.receiver.secretsmanager.get_secret_value.assert_called_once_with(SecretId="secret-arn")

    def test_valid_heartbeat_updates_state(self):
        self.table.get_item.return_value = {"Item": {"service_id": "homelab-cluster", "status": "healthy"}}
        env = {
            "HEARTBEAT_TOKEN_SECRET_ARN": "secret-arn",
            "HEARTBEAT_TABLE": "table",
            "DEFAULT_STALE_AFTER_SECONDS": "900",
            "DEFAULT_REMINDER_SECONDS": "21600",
        }

        with patch.dict(os.environ, env):
            result = self.receiver.lambda_handler(
                {"headers": {"authorization": "Bearer secret"}, "body": json.dumps({"service_id": "homelab-cluster"})},
                None,
            )

        self.assertEqual(result["statusCode"], 202)
        self.table.update_item.assert_called_once()

    def test_unknown_service_is_rejected_without_update(self):
        self.table.get_item.return_value = {}
        env = {
            "HEARTBEAT_TOKEN_SECRET_ARN": "secret-arn",
            "HEARTBEAT_TABLE": "table",
            "DEFAULT_STALE_AFTER_SECONDS": "900",
            "DEFAULT_REMINDER_SECONDS": "21600",
        }

        with patch.dict(os.environ, env):
            result = self.receiver.lambda_handler(
                {"headers": {"authorization": "Bearer secret"}, "body": json.dumps({"service_id": "new-service"})},
                None,
            )

        self.assertEqual(result["statusCode"], 404)
        self.table.update_item.assert_not_called()

    def test_recovery_notification_is_configurable(self):
        self.table.get_item.return_value = {"Item": {"service_id": "homelab-cluster", "status": "stale"}}
        env = {
            "HEARTBEAT_TOKEN_SECRET_ARN": "secret-arn",
            "HEARTBEAT_TABLE": "table",
            "DEFAULT_STALE_AFTER_SECONDS": "900",
            "DEFAULT_REMINDER_SECONDS": "21600",
            "RECOVERY_TOPIC_ARN": "arn:aws:sns:test:123:topic",
            "SEND_RECOVERY_NOTIFICATIONS": "true",
        }

        with patch.dict(os.environ, env):
            result = self.receiver.lambda_handler(
                {"headers": {"x-heartbeat-token": "secret"}, "body": json.dumps({"service_id": "homelab-cluster"})},
                None,
            )

        self.assertEqual(result["statusCode"], 202)
        self.receiver.sns.publish.assert_called_once()


class CheckerTests(unittest.TestCase):
    def setUp(self):
        self.checker = load_function("checker")
        self.table = MagicMock()
        self.checker.dynamodb.Table.return_value = self.table

    def test_fresh_heartbeat_stays_quiet(self):
        self.table.scan.return_value = {
            "Items": [
                {
                    "service_id": "homelab-cluster",
                    "enabled": True,
                    "last_seen_at": "2999-01-01T00:00:00Z",
                    "stale_after_seconds": Decimal("900"),
                    "status": "healthy",
                }
            ]
        }

        with patch.dict(os.environ, {"HEARTBEAT_TABLE": "table", "UPTIME_TOPIC_ARN": "topic"}):
            result = self.checker.lambda_handler({}, None)

        self.assertEqual(result["healthy"], 1)
        self.checker.sns.publish.assert_not_called()

    def test_first_stale_detection_alerts(self):
        self.table.scan.return_value = {
            "Items": [
                {
                    "service_id": "homelab-cluster",
                    "enabled": True,
                    "last_seen_at": "2000-01-01T00:00:00Z",
                    "stale_after_seconds": Decimal("900"),
                }
            ]
        }

        with patch.dict(os.environ, {"HEARTBEAT_TABLE": "table", "UPTIME_TOPIC_ARN": "topic"}):
            result = self.checker.lambda_handler({}, None)

        self.assertEqual(result["alerted"], 1)
        self.checker.sns.publish.assert_called_once()

    def test_repeated_stale_detection_is_suppressed(self):
        self.table.scan.return_value = {
            "Items": [
                {
                    "service_id": "homelab-cluster",
                    "enabled": True,
                    "last_seen_at": "2000-01-01T00:00:00Z",
                    "last_alerted_at": "2999-01-01T00:00:00Z",
                    "stale_after_seconds": Decimal("900"),
                    "alert_reminder_seconds": Decimal("21600"),
                }
            ]
        }

        with patch.dict(os.environ, {"HEARTBEAT_TABLE": "table", "UPTIME_TOPIC_ARN": "topic"}):
            result = self.checker.lambda_handler({}, None)

        self.assertEqual(result["suppressed"], 1)
        self.checker.sns.publish.assert_not_called()


if __name__ == "__main__":
    unittest.main()
