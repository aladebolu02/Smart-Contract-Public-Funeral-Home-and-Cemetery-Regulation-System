;; Crematory Operation Monitoring Contract
;; Ensures proper operation and environmental compliance of crematoriums

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-INPUT (err u200))
(define-constant ERR-PERMIT-EXPIRED (err u201))
(define-constant ERR-EQUIPMENT-NOT-CERTIFIED (err u202))
(define-constant ERR-EMISSION-VIOLATION (err u203))
(define-constant ERR-CAPACITY-EXCEEDED (err u204))

;; Data Variables
(define-data-var next-crematory-id uint u1)
(define-data-var next-cremation-id uint u1)
(define-data-var next-inspection-id uint u1)
(define-data-var emission-limit uint u50) ;; parts per million

;; Data Maps
(define-map crematories
  { crematory-id: uint }
  {
    name: (string-ascii 100),
    operator: principal,
    address: (string-ascii 200),
    license-number: (string-ascii 50),
    permit-expiry: uint,
    daily-capacity: uint,
    status: (string-ascii 20),
    equipment-count: uint
  }
)

(define-map cremations
  { cremation-id: uint }
  {
    crematory-id: uint,
    deceased-name: (string-ascii 100),
    cremation-date: uint,
    permit-number: (string-ascii 50),
    funeral-director: principal,
    temperature: uint,
    duration: uint,
    remains-collected: bool
  }
)

(define-map equipment
  { crematory-id: uint, equipment-id: uint }
  {
    equipment-type: (string-ascii 50),
    manufacturer: (string-ascii 100),
    model: (string-ascii 50),
    installation-date: uint,
    last-maintenance: uint,
    certification-expiry: uint,
    status: (string-ascii 20)
  }
)

(define-map environmental-inspections
  { inspection-id: uint }
  {
    crematory-id: uint,
    inspector: principal,
    inspection-date: uint,
    emission-level: uint,
    temperature-compliance: bool,
    equipment-status: (string-ascii 20),
    violations: (list 5 (string-ascii 100)),
    corrective-actions: (list 5 (string-ascii 200))
  }
)

(define-map daily-operations
  { crematory-id: uint, date: uint }
  {
    cremations-performed: uint,
    total-duration: uint,
    average-temperature: uint,
    emissions-recorded: uint,
    incidents: (list 3 (string-ascii 200))
  }
)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT-OWNER)
)

(define-private (is-valid-crematory-status (status (string-ascii 20)))
  (or (is-eq status "active")
      (is-eq status "suspended")
      (is-eq status "maintenance")
      (is-eq status "closed"))
)

(define-private (is-valid-equipment-status (status (string-ascii 20)))
  (or (is-eq status "operational")
      (is-eq status "maintenance")
      (is-eq status "repair")
      (is-eq status "decommissioned"))
)

;; Public Functions

;; Register crematory
(define-public (register-crematory
  (name (string-ascii 100))
  (operator principal)
  (address (string-ascii 200))
  (license-number (string-ascii 50))
  (permit-expiry uint)
  (daily-capacity uint))
  (let ((crematory-id (var-get next-crematory-id)))
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (asserts! (> permit-expiry block-height) ERR-INVALID-INPUT)
    (asserts! (> daily-capacity u0) ERR-INVALID-INPUT)

    (map-set crematories
      { crematory-id: crematory-id }
      {
        name: name,
        operator: operator,
        address: address,
        license-number: license-number,
        permit-expiry: permit-expiry,
        daily-capacity: daily-capacity,
        status: "active",
        equipment-count: u0
      }
    )

    (var-set next-crematory-id (+ crematory-id u1))
    (ok crematory-id)
  )
)

;; Add equipment
(define-public (add-equipment
  (crematory-id uint)
  (equipment-id uint)
  (equipment-type (string-ascii 50))
  (manufacturer (string-ascii 100))
  (model (string-ascii 50))
  (certification-expiry uint))
  (let ((crematory-data (unwrap! (map-get? crematories { crematory-id: crematory-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get operator crematory-data)) ERR-UNAUTHORIZED)
    (asserts! (> certification-expiry block-height) ERR-INVALID-INPUT)

    (map-set equipment
      { crematory-id: crematory-id, equipment-id: equipment-id }
      {
        equipment-type: equipment-type,
        manufacturer: manufacturer,
        model: model,
        installation-date: block-height,
        last-maintenance: block-height,
        certification-expiry: certification-expiry,
        status: "operational"
      }
    )

    (map-set crematories
      { crematory-id: crematory-id }
      (merge crematory-data {
        equipment-count: (+ (get equipment-count crematory-data) u1)
      })
    )

    (ok true)
  )
)

;; Record cremation
(define-public (record-cremation
  (crematory-id uint)
  (deceased-name (string-ascii 100))
  (permit-number (string-ascii 50))
  (funeral-director principal)
  (temperature uint)
  (duration uint))
  (let ((crematory-data (unwrap! (map-get? crematories { crematory-id: crematory-id }) ERR-NOT-FOUND))
        (cremation-id (var-get next-cremation-id))
        (today (/ block-height u144)) ;; approximate daily blocks
        (daily-ops (default-to
          { cremations-performed: u0, total-duration: u0, average-temperature: u0, emissions-recorded: u0, incidents: (list) }
          (map-get? daily-operations { crematory-id: crematory-id, date: today }))))

    (asserts! (is-eq tx-sender (get operator crematory-data)) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status crematory-data) "active") ERR-UNAUTHORIZED)
    (asserts! (> (get permit-expiry crematory-data) block-height) ERR-PERMIT-EXPIRED)
    (asserts! (>= temperature u1400) ERR-INVALID-INPUT) ;; minimum temperature
    (asserts! (>= duration u60) ERR-INVALID-INPUT) ;; minimum duration in minutes
    (asserts! (< (get cremations-performed daily-ops) (get daily-capacity crematory-data)) ERR-CAPACITY-EXCEEDED)

    (map-set cremations
      { cremation-id: cremation-id }
      {
        crematory-id: crematory-id,
        deceased-name: deceased-name,
        cremation-date: block-height,
        permit-number: permit-number,
        funeral-director: funeral-director,
        temperature: temperature,
        duration: duration,
        remains-collected: false
      }
    )

    ;; Update daily operations
    (map-set daily-operations
      { crematory-id: crematory-id, date: today }
      {
        cremations-performed: (+ (get cremations-performed daily-ops) u1),
        total-duration: (+ (get total-duration daily-ops) duration),
        average-temperature: (/ (+ (* (get average-temperature daily-ops) (get cremations-performed daily-ops)) temperature)
                                (+ (get cremations-performed daily-ops) u1)),
        emissions-recorded: (get emissions-recorded daily-ops),
        incidents: (get incidents daily-ops)
      }
    )

    (var-set next-cremation-id (+ cremation-id u1))
    (ok cremation-id)
  )
)

;; Conduct environmental inspection
(define-public (conduct-environmental-inspection
  (crematory-id uint)
  (inspector principal)
  (emission-level uint)
  (temperature-compliance bool)
  (equipment-status (string-ascii 20))
  (violations (list 5 (string-ascii 100)))
  (corrective-actions (list 5 (string-ascii 200))))
  (let ((crematory-data (unwrap! (map-get? crematories { crematory-id: crematory-id }) ERR-NOT-FOUND))
        (inspection-id (var-get next-inspection-id)))
    (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
    (asserts! (<= emission-level u100) ERR-INVALID-INPUT)

    (map-set environmental-inspections
      { inspection-id: inspection-id }
      {
        crematory-id: crematory-id,
        inspector: inspector,
        inspection-date: block-height,
        emission-level: emission-level,
        temperature-compliance: temperature-compliance,
        equipment-status: equipment-status,
        violations: violations,
        corrective-actions: corrective-actions
      }
    )

    ;; Suspend if emissions exceed limit
    (if (> emission-level (var-get emission-limit))
      (map-set crematories
        { crematory-id: crematory-id }
        (merge crematory-data { status: "suspended" })
      )
      true
    )

    (var-set next-inspection-id (+ inspection-id u1))
    (ok inspection-id)
  )
)

;; Update equipment maintenance
(define-public (update-equipment-maintenance
  (crematory-id uint)
  (equipment-id uint)
  (maintenance-type (string-ascii 50)))
  (let ((crematory-data (unwrap! (map-get? crematories { crematory-id: crematory-id }) ERR-NOT-FOUND))
        (equipment-data (unwrap! (map-get? equipment { crematory-id: crematory-id, equipment-id: equipment-id }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get operator crematory-data)) ERR-UNAUTHORIZED)

    (map-set equipment
      { crematory-id: crematory-id, equipment-id: equipment-id }
      (merge equipment-data {
        last-maintenance: block-height,
        status: "operational"
      })
    )
    (ok true)
  )
)

;; Mark remains collected
(define-public (mark-remains-collected (cremation-id uint))
  (let ((cremation-data (unwrap! (map-get? cremations { cremation-id: cremation-id }) ERR-NOT-FOUND))
        (crematory-data (unwrap! (map-get? crematories { crematory-id: (get crematory-id cremation-data) }) ERR-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get operator crematory-data)) ERR-UNAUTHORIZED)

    (map-set cremations
      { cremation-id: cremation-id }
      (merge cremation-data { remains-collected: true })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get crematory
(define-read-only (get-crematory (crematory-id uint))
  (map-get? crematories { crematory-id: crematory-id })
)

;; Get cremation
(define-read-only (get-cremation (cremation-id uint))
  (map-get? cremations { cremation-id: cremation-id })
)

;; Get equipment
(define-read-only (get-equipment (crematory-id uint) (equipment-id uint))
  (map-get? equipment { crematory-id: crematory-id, equipment-id: equipment-id })
)

;; Get environmental inspection
(define-read-only (get-environmental-inspection (inspection-id uint))
  (map-get? environmental-inspections { inspection-id: inspection-id })
)

;; Get daily operations
(define-read-only (get-daily-operations (crematory-id uint) (date uint))
  (map-get? daily-operations { crematory-id: crematory-id, date: date })
)

;; Check crematory compliance
(define-read-only (is-crematory-compliant (crematory-id uint))
  (match (map-get? crematories { crematory-id: crematory-id })
    crematory-data (and
      (is-eq (get status crematory-data) "active")
      (> (get permit-expiry crematory-data) block-height)
    )
    false
  )
)

;; Check equipment certification
(define-read-only (is-equipment-certified (crematory-id uint) (equipment-id uint))
  (match (map-get? equipment { crematory-id: crematory-id, equipment-id: equipment-id })
    equipment-data (and
      (is-eq (get status equipment-data) "operational")
      (> (get certification-expiry equipment-data) block-height)
    )
    false
  )
)
