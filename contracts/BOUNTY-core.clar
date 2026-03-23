;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BOUNTY VAULT REGISTRY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ==========================================================
;; SECTION 1 - OWNERSHIP
;; ==========================================================

(define-data-var contract-owner principal tx-sender)

;; ==========================================================
;; SECTION 2 - ADMIN MANAGEMENT
;; ==========================================================

(define-map admins
  { admin: principal }
  { enabled: bool }
)

;; ==========================================================
;; SECTION 3 - GLOBAL CONTROL
;; ==========================================================

(define-data-var paused bool false)

;; ==========================================================
;; SECTION 4 - BOUNTY STORAGE
;; ==========================================================

(define-map bounties
  { id: uint }
  {
    creator: principal,
    reward: uint,
    open: bool,
    winner: (optional principal),
    created-at: uint
  }
)

(define-map submissions
  { bounty-id: uint, user: principal }
  {
    submitted: bool,
    approved: bool
  }
)

(define-data-var bounty-count uint u0)

;; ==========================================================
;; SECTION 5 - CONSTANTS & ERRORS
;; ==========================================================

(define-constant ERR-UNAUTHORIZED      (err u100))
(define-constant ERR-PAUSED            (err u101))
(define-constant ERR-INVALID-AMOUNT    (err u102))
(define-constant ERR-BOUNTY-NOT-FOUND  (err u103))
(define-constant ERR-BOUNTY-CLOSED     (err u104))
(define-constant ERR-ALREADY-SUBMITTED (err u105))
(define-constant ERR-NOT-SUBMITTED     (err u106))
(define-constant ERR-ALREADY-PAID      (err u107))

;; ==========================================================
;; SECTION 6 - INTERNAL HELPERS
;; ==========================================================

(define-private (is-owner (who principal))
  (is-eq who (var-get contract-owner))
)

(define-private (is-admin (who principal))
  (or
    (is-owner who)
    (default-to false
      (get enabled (map-get? admins { admin: who }))
    )
  )
)

(define-private (not-paused)
  (not (var-get paused))
)

(define-private (get-bounty (id uint))
  (map-get? bounties { id: id })
)

;; ==========================================================
;; SECTION 7 - READ ONLY FUNCTIONS
;; ==========================================================

(define-read-only (get-bounty-info (id uint))
  (get-bounty id)
)

(define-read-only (get-submission (id uint) (user principal))
  (map-get? submissions { bounty-id: id, user: user })
)

(define-read-only (get-bounty-count)
  (var-get bounty-count)
)

(define-read-only (is-paused)
  (var-get paused)
)

;; ==========================================================
;; SECTION 8 - BOUNTY CREATION
;; ==========================================================

(define-public (create-bounty (reward uint))
  (begin
    (asserts! (not-paused) ERR-PAUSED)
    (asserts! (> reward u0) ERR-INVALID-AMOUNT)

    (let ((id (+ (var-get bounty-count) u1)))

      (map-set bounties
        { id: id }
        {
          creator: tx-sender,
          reward: reward,
          open: true,
          winner: none,
          created-at: burn-block-height
        }
      )

      (var-set bounty-count id)

      (ok id)
    )
  )
)

;; ==========================================================
;; SECTION 9 - SUBMISSIONS
;; ==========================================================

(define-public (submit-work (id uint))
  (let (
        (bounty (unwrap! (get-bounty id) ERR-BOUNTY-NOT-FOUND))
       )

    (asserts! (get open bounty) ERR-BOUNTY-CLOSED)

    (asserts!
      (is-none (map-get? submissions { bounty-id: id, user: tx-sender }))
      ERR-ALREADY-SUBMITTED
    )

    (map-set submissions
      { bounty-id: id, user: tx-sender }
      {
        submitted: true,
        approved: false
      }
    )

    (ok true)
  )
)

;; ==========================================================
;; SECTION 10 - APPROVAL & PAYOUT
;; ==========================================================

(define-public (approve-submission (id uint) (user principal))
  (let (
        (bounty (unwrap! (get-bounty id) ERR-BOUNTY-NOT-FOUND))
        (submission (unwrap!
                      (map-get? submissions { bounty-id: id, user: user })
                      ERR-NOT-SUBMITTED))
       )

    (asserts!
      (or (is-eq tx-sender (get creator bounty))
          (is-admin tx-sender))
      ERR-UNAUTHORIZED
    )

    (asserts! (get open bounty) ERR-BOUNTY-CLOSED)
    (asserts! (not (get approved submission)) ERR-ALREADY-PAID)

    ;; Transfer reward from creator to winner
    (try! (stx-transfer? (get reward bounty) (get creator bounty) user))

    (map-set submissions
      { bounty-id: id, user: user }
      (merge submission { approved: true })
    )

    (map-set bounties
      { id: id }
      (merge bounty {
        open: false,
        winner: (some user)
      })
    )

    (ok true)
  )
)

;; ==========================================================
;; SECTION 11 - ADMIN MANAGEMENT
;; ==========================================================

(define-public (add-admin (admin principal))
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (map-set admins { admin: admin } { enabled: true })
    (ok true)
  )
)

(define-public (remove-admin (admin principal))
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (map-delete admins { admin: admin })
    (ok true)
  )
)

;; ==========================================================
;; SECTION 12 - EMERGENCY CONTROLS
;; ==========================================================

(define-public (pause)
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (var-set paused true)
    (ok true)
  )
)

(define-public (unpause)
  (begin
    (asserts! (is-owner tx-sender) ERR-UNAUTHORIZED)
    (var-set paused false)
    (ok true)
  )
)