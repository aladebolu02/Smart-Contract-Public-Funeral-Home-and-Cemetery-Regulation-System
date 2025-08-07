# Smart Contract Public Funeral Home and Cemetery Regulation System

## Overview

This system provides a comprehensive blockchain-based solution for regulating funeral homes and cemeteries. It consists of five interconnected smart contracts that manage different aspects of the funeral industry regulation.

## Contracts

### 1. Funeral Director Licensing Contract (`funeral-director-licensing.clar`)
- Manages professional licenses for funeral directors
- Tracks continuing education requirements
- Handles license renewals and suspensions
- Maintains professional standards compliance

### 2. Embalming Facility Inspection Contract (`embalming-facility-inspection.clar`)
- Conducts health and safety inspections of funeral preparation facilities
- Records inspection results and compliance status
- Manages inspection schedules and requirements
- Tracks facility certifications

### 3. Cemetery Plot Management Contract (`cemetery-plot-management.clar`)
- Tracks burial plot sales and ownership
- Maintains comprehensive cemetery records
- Manages plot reservations and transfers
- Records burial information and genealogy data

### 4. Preneed Funeral Contract Oversight Contract (`preneed-funeral-oversight.clar`)
- Regulates prepaid funeral plans
- Protects consumer deposits through escrow management
- Ensures contract compliance and consumer protection
- Manages fund disbursements and refunds

### 5. Crematory Operation Monitoring Contract (`crematory-operation-monitoring.clar`)
- Ensures proper operation of crematoriums
- Monitors environmental compliance
- Tracks cremation records and permits
- Manages equipment certifications and maintenance

## Key Features

- **Decentralized Regulation**: All regulatory activities are recorded on the blockchain for transparency
- **Consumer Protection**: Built-in safeguards for preneed contracts and consumer deposits
- **Professional Standards**: Comprehensive licensing and continuing education tracking
- **Compliance Monitoring**: Automated inspection scheduling and compliance tracking
- **Record Keeping**: Permanent, tamper-proof records for all regulatory activities

## Data Types

The system uses various Clarity data types:
- `uint` for IDs, amounts, and timestamps
- `principal` for addresses and identities
- `(string-ascii 100)` for names and descriptions
- `bool` for status flags
- `(optional ...)` for nullable fields

## Error Codes

Each contract defines specific error codes:
- `u100-u199`: General errors (unauthorized, not found, etc.)
- `u200-u299`: Validation errors (invalid input, expired, etc.)
- `u300-u399`: Business logic errors (insufficient funds, already exists, etc.)

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute the test suite

## Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case testing for error conditions

## Deployment

Deploy contracts in the following order:
1. `funeral-director-licensing.clar`
2. `embalming-facility-inspection.clar`
3. `cemetery-plot-management.clar`
4. `preneed-funeral-oversight.clar`
5. `crematory-operation-monitoring.clar`

## Usage

Each contract provides public functions for:
- Registration and licensing
- Record management
- Compliance tracking
- Consumer protection
- Regulatory oversight

Refer to individual contract documentation for specific function details.
