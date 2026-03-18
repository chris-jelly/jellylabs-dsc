## ADDED Requirements

### Requirement: Existing cloud resources are explicitly classified before management
The system SHALL classify discovered cloud resources before implementation as authoritative, deferred, legacy, or unmanaged.

#### Scenario: Adoption status is explicit
- **WHEN** an operator reviews the brownfield onboarding plan
- **THEN** each discovered resource is assigned an adoption status rather than being implicitly managed or ignored

### Requirement: Only intentional resources become authoritative
The system SHALL make only intentional retained resources authoritative in infrastructure-as-code.

#### Scenario: Unwanted inherited resources stay outside first-wave management
- **WHEN** a discovered resource is default cloud scaffolding or otherwise not part of the intended platform
- **THEN** that resource is excluded from first-wave authoritative management

### Requirement: AWS default networking remains unmanaged in the first wave
The system SHALL exclude the AWS default VPC from first-wave infrastructure management.

#### Scenario: Default VPC is not treated as managed foundation
- **WHEN** AWS first-wave scope is defined
- **THEN** the default VPC is classified as unmanaged or deferred rather than imported as authoritative infrastructure

### Requirement: Legacy resources remain tracked until retirement
The system SHALL keep legacy resources visible in planning artifacts until a later change migrates or retires them.

#### Scenario: Legacy resources have follow-up path
- **WHEN** a resource remains in use but is not part of the preferred future design
- **THEN** the resource is marked legacy and paired with a later migration or retirement path
