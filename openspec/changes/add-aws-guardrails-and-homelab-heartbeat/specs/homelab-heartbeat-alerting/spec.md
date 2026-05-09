## ADDED Requirements

### Requirement: Heartbeat alerting detects internal homelab liveness
The heartbeat alerting system SHALL detect whether the homelab is alive enough to run a scheduled Kubernetes job and send an outbound heartbeat to AWS.

#### Scenario: Homelab heartbeat is received
- **WHEN** the homelab CronJob sends a valid heartbeat for `homelab-cluster`
- **THEN** AWS records the latest heartbeat time for `homelab-cluster`

#### Scenario: Public reachability is not required
- **WHEN** heartbeat alerting is configured
- **THEN** it does not require AWS to reach public homelab services, Cloudflare Tunnel, Traefik, or application ingresses

### Requirement: Heartbeat registry supports multiple services
The heartbeat alerting system SHALL maintain a reusable registry of enabled heartbeat sources keyed by service identifier.

#### Scenario: Initial service is registered
- **WHEN** the heartbeat registry is provisioned
- **THEN** it includes or supports registering `homelab-cluster` as the first heartbeat source

#### Scenario: Later services can reuse the registry
- **WHEN** a later heartbeat source is added with its own service identifier and stale threshold
- **THEN** the same receiver, registry, checker, and alerting path can monitor that source without creating a separate monitoring stack

### Requirement: Heartbeat receiver authenticates requests
The heartbeat receiver SHALL reject heartbeat writes that do not include a valid shared secret or equivalent authentication mechanism.

#### Scenario: Valid heartbeat is accepted
- **WHEN** a heartbeat request includes valid authentication and a known service identifier
- **THEN** the receiver updates that service's latest heartbeat state

#### Scenario: Invalid heartbeat is rejected
- **WHEN** a heartbeat request omits authentication or includes an invalid token
- **THEN** the receiver does not update heartbeat state

### Requirement: Stale heartbeat checker publishes uptime alerts
The heartbeat alerting system SHALL run on a schedule and publish an uptime alert when an enabled heartbeat source has not reported within its configured stale window.

#### Scenario: Fresh heartbeat stays quiet
- **WHEN** an enabled service has a latest heartbeat inside its stale window
- **THEN** the checker does not publish an outage alert for that service

#### Scenario: Stale heartbeat sends alert
- **WHEN** an enabled service has no latest heartbeat inside its stale window
- **THEN** the checker publishes an outage alert identifying the stale service

### Requirement: Uptime alerts use SNS email and SMS
The heartbeat alerting system SHALL publish operational uptime alerts to an SNS topic configured for email and SMS delivery.

#### Scenario: Outage alert fans out
- **WHEN** the checker publishes an outage alert
- **THEN** SNS delivers the alert to configured email and SMS subscribers

#### Scenario: Mobile push is excluded
- **WHEN** uptime notification subscriptions are configured
- **THEN** mobile push subscriptions are not required

### Requirement: Repeated outage alerts are suppressed
The heartbeat alerting system SHALL avoid publishing repeated outage alerts on every checker run for the same ongoing outage.

#### Scenario: First stale detection alerts
- **WHEN** a service first transitions from healthy to stale
- **THEN** the checker publishes an outage alert and records alert state

#### Scenario: Ongoing outage is suppressed
- **WHEN** a service remains stale after an outage alert has already been recorded
- **THEN** the checker does not publish another outage alert unless a configured reminder interval has elapsed

### Requirement: Recovery can be detected after outage
The heartbeat alerting system SHALL detect when a stale service resumes valid heartbeats and update its status back to healthy.

#### Scenario: Stale service recovers
- **WHEN** a valid heartbeat is received for a service that was marked stale
- **THEN** the heartbeat state records that the service is healthy again

#### Scenario: Recovery notification is configurable
- **WHEN** a stale service recovers
- **THEN** the system can publish a recovery notification according to the configured notification policy

### Requirement: Homelab sender runs as a CronJob
The homelab heartbeat sender SHALL run as a Kubernetes CronJob managed by the homelab GitOps workflow.

#### Scenario: CronJob sends periodic heartbeat
- **WHEN** Flux applies the homelab heartbeat sender configuration
- **THEN** a Kubernetes CronJob periodically sends the `homelab-cluster` heartbeat to AWS

#### Scenario: CronJob uses managed secret configuration
- **WHEN** the CronJob sends a heartbeat
- **THEN** it obtains endpoint and authentication configuration from the homelab secret-management pattern rather than hard-coded manifest values
