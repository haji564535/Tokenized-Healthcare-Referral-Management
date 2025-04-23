;; Provider Verification Contract
;; Validates credentials of medical professionals

(define-data-var admin principal tx-sender)

;; Provider status: 0 = unverified, 1 = verified, 2 = suspended
(define-map providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    specialty: (string-utf8 100),
    license-number: (string-utf8 50),
    status: uint,
    verification-date: uint
  }
)

;; Add a new provider (admin only)
(define-public (register-provider
    (provider-id principal)
    (name (string-utf8 100))
    (specialty (string-utf8 100))
    (license-number (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? providers { provider-id: provider-id })) (err u100))
    (ok (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        specialty: specialty,
        license-number: license-number,
        status: u0,
        verification-date: u0
      }
    ))
  )
)

;; Verify a provider (admin only)
(define-public (verify-provider (provider-id principal))
  (let ((provider (unwrap! (map-get? providers { provider-id: provider-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set providers
      { provider-id: provider-id }
      (merge provider {
        status: u1,
        verification-date: block-height
      })
    ))
  )
)

;; Suspend a provider (admin only)
(define-public (suspend-provider (provider-id principal))
  (let ((provider (unwrap! (map-get? providers { provider-id: provider-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set providers
      { provider-id: provider-id }
      (merge provider { status: u2 })
    ))
  )
)

;; Check if a provider is verified
(define-read-only (is-provider-verified (provider-id principal))
  (let ((provider (map-get? providers { provider-id: provider-id })))
    (if (is-some provider)
      (is-eq (get status (unwrap! provider false)) u1)
      false
    )
  )
)

;; Get provider details
(define-read-only (get-provider-details (provider-id principal))
  (map-get? providers { provider-id: provider-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
