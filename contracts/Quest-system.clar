;; Quest System Smart Contract
;; Supports quest creation, joining, completion, and reward claiming (FT or NFT).

;; --------------------------------------------
;; Constants / Error Codes
;; --------------------------------------------

(define-constant ERR-QUEST-NOT-FOUND u100)
(define-constant ERR-QUEST-EXISTS u101)
(define-constant ERR-NOT-AUTHORIZED u102)
(define-constant ERR-QUEST-INACTIVE u103)
(define-constant ERR-QUEST-EXPIRED u104)
(define-constant ERR-NOT-JOINED u105)
(define-constant ERR-ALREADY-JOINED u106)
(define-constant ERR-ALREADY-COMPLETED u107)
(define-constant ERR-NOT-COMPLETED u108)
(define-constant ERR-ALREADY-CLAIMED u109)
(define-constant ERR-FT-MINT u110)
(define-constant ERR-NFT-MINT u111)

;; --------------------------------------------
;; Data Maps
;; --------------------------------------------

(define-map quests
  { quest-id: uint }
  {
    description: (string-ascii 100),
    reward-type: uint,    ;; 1 = FT, 2 = NFT
    reward-amount: uint,
    active: bool,
    expiry: uint
  }
)

(define-map quest-participants
  { quest-id: uint, user: principal }
  {
    joined: bool,
    completed: bool,
    claimed: bool
  }
)

;; --------------------------------------------
;; Tokens
;; --------------------------------------------

(define-fungible-token GOLD)
(define-non-fungible-token BADGE uint)

(define-data-var next-badge-id uint u1)

;; --------------------------------------------
;; Helpers
;; --------------------------------------------

(define-read-only (is-admin (who principal))
  (ok (is-eq who tx-sender))
)

;; --------------------------------------------
;; Public Functions
;; --------------------------------------------

(define-public (create-quest (quest-id uint) (description (string-ascii 100)) (reward-type uint) (reward-amount uint) (expiry uint))
  (begin
    (asserts! (is-eq tx-sender tx-sender) (err ERR-NOT-AUTHORIZED))
    ;; Validate reward-type: must be u1 (FT) or u2 (NFT)
    (asserts! (or (is-eq reward-type u1) (is-eq reward-type u2)) (err ERR-NOT-AUTHORIZED))
    ;; Validate reward-amount: must be > 0
    (asserts! (> reward-amount u0) (err ERR-NOT-AUTHORIZED))
    ;; Validate expiry: must be > 0
    (asserts! (> expiry u0) (err ERR-NOT-AUTHORIZED))
    ;; Validate description: must not be empty
    (asserts! (> (len description) u0) (err ERR-NOT-AUTHORIZED))
    (let ((existing-quest (map-get? quests { quest-id: quest-id })))
      (if (is-some existing-quest)
        (err ERR-QUEST-EXISTS)
        (begin
          (map-set quests { quest-id: quest-id }
            {
              description: description,
              reward-type: reward-type,
              reward-amount: reward-amount,
              active: true,
              expiry: expiry
            })
          (ok quest-id)
        )
      )
    )
  )
)

(define-public (join-quest (quest-id uint))
  (begin
    ;; Validate quest-id > 0
    (asserts! (> quest-id u0) (err ERR-QUEST-NOT-FOUND))
    (match (map-get? quests { quest-id: quest-id }) q
      (begin
        (asserts! (get active q) (err ERR-QUEST-INACTIVE))
        (match (map-get? quest-participants { quest-id: quest-id, user: tx-sender }) p
          (err ERR-ALREADY-JOINED)
          (begin
            (map-set quest-participants { quest-id: quest-id, user: tx-sender }
              { joined: true, completed: false, claimed: false })
            (ok true)
          )
        )
      )
      (err ERR-QUEST-NOT-FOUND)
    )
  )
)

(define-public (complete-quest (quest-id uint) (user principal))
  (begin
    (asserts! (is-eq tx-sender tx-sender) (err ERR-NOT-AUTHORIZED))
    ;; Validate quest-id > 0
    (asserts! (> quest-id u0) (err ERR-NOT-JOINED))
    (match (map-get? quest-participants { quest-id: quest-id, user: user })
      p
        (if (get completed p)
          (err ERR-ALREADY-COMPLETED)
          (begin
            (map-set quest-participants { quest-id: quest-id, user: user }
              { joined: true, completed: true, claimed: false })
            (ok true)
          )
        )
      (err ERR-NOT-JOINED)
    )
  )
)

(define-public (claim-reward (quest-id uint))
  (begin
    ;; Validate quest-id > 0
    (asserts! (> quest-id u0) (err ERR-NOT-JOINED))
    (match (map-get? quest-participants { quest-id: quest-id, user: tx-sender }) p
      (begin
        (asserts! (get completed p) (err ERR-NOT-COMPLETED))
        (asserts! (not (get claimed p)) (err ERR-ALREADY-CLAIMED))
        (match (map-get? quests { quest-id: quest-id }) q
          (let ((rtype (get reward-type q))
                (ramount (get reward-amount q)))
            (if (is-eq rtype u1)
              ;; FT reward path
              (let ((mint-result (ft-mint? GOLD ramount tx-sender)))
                (if (is-ok mint-result)
                  (begin
                    (map-set quest-participants { quest-id: quest-id, user: tx-sender }
                      { joined: (get joined p), completed: (get completed p), claimed: true })
                    (ok {
                      status: true,
                      method: "ft ",
                      amount: (some ramount),
                      token-id: none
                    })
                  )
                  (err ERR-FT-MINT)
                )
              )
              ;; NFT reward path
              (let ((next-id (var-get next-badge-id)))
                (let ((nft-result (nft-mint? BADGE next-id tx-sender)))
                  (if (is-ok nft-result)
                    (begin
                      (var-set next-badge-id (+ next-id u1))
                      (map-set quest-participants { quest-id: quest-id, user: tx-sender }
                        { joined: (get joined p), completed: (get completed p), claimed: true })
                      (ok {
                        status: true,
                        method: "nft",
                        amount: none,
                        token-id: (some next-id)
                      })
                    )
                    (err ERR-NFT-MINT)
                  )
                )
              )
            )
          )
          (err ERR-QUEST-NOT-FOUND)
        )
      )
      (err ERR-NOT-JOINED)
    )
  )
)

;; --------------------------------------------
;; Read-Only Functions
;; --------------------------------------------

(define-read-only (get-quest (quest-id uint))
  (map-get? quests { quest-id: quest-id })
)

(define-read-only (get-user-quest (quest-id uint) (user principal))
  (map-get? quest-participants { quest-id: quest-id, user: user })
)
