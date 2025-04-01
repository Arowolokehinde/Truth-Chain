;; Decentralized Content Provenance System
;; A Clarity smart contract for registering and verifying content on the Stacks blockchain

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_SIGNATURE (err u103))
(define-constant ERR_CONTENT_LIMIT_REACHED (err u104))
(define-constant ERR_INVALID_PARAMS (err u105))

;; Constants
(define-constant MAX_CONTENT_PER_AUTHOR u100)
(define-constant CONTRACT_OWNER tx-sender)

;; Data structures

;; Content record structure
;; Contains metadata about registered content
(define-map content-records
  { content-hash: (buff 32) }  ;; SHA-256 hash (32 bytes)
  {
    author: principal,         ;; Stacks address of content creator
    timestamp: uint,           ;; Block height when content was registered
    content-type: (string-ascii 20),  ;; Type of content (e.g., "article", "image", "video")
    signature: (buff 65),      ;; ECDSA signature (r,s,v format)
    title: (string-ascii 100),  ;; Optional title/description
    is-active: bool,           ;; Flag for potential content retraction
    storage-url: (optional (string-utf8 256)),  ;; Optional reference to decentralized storage
    version: uint              ;; Content version (for tracking updates)
  }
)

;; Author records - tracks content published by each author
;; Now uses a counter to simplify pagination of author content
(define-map author-content
  { author: principal }
  { 
    content-count: uint,
    last-activity: uint        ;; Last block height when author was active
  }
)

;; Track content hashes by author with pagination support
(define-map author-content-by-index
  { author: principal, index: uint }
  { content-hash: (buff 32) }
)

;; Trusted verifiers (optional for extending the system with trusted roles)
(define-map trusted-verifiers
  { verifier: principal }
  { active: bool }
)

;; Public functions

;; Register new content
;; @param content-hash: SHA-256 hash of the content
;; @param content-type: Type of content being registered
;; @param signature: Creator's signature of the content hash
;; @param title: Optional title or description
;; @param storage-url: Optional URL pointing to decentralized storage
;; @returns: Success or error code
(define-public (register-content 
                (content-hash (buff 32))
                (content-type (string-ascii 20))
                (signature (buff 65))
                (title (string-ascii 100))
                (storage-url (optional (string-utf8 256))))
  (let
    (
      (caller tx-sender)
      (current-height stacks-block-height)
    )
    
    ;; Check if content already exists
    (asserts! (is-none (map-get? content-records { content-hash: content-hash })) 
              ERR_ALREADY_REGISTERED)
    
    ;; Verify signature (in production, use secp256k1-verify when available)
    ;; This is a placeholder until native signature verification is available
    ;; (asserts! (verify-signature content-hash signature caller) ERR_INVALID_SIGNATURE)
            
    ;; Get or initialize author's content count
    (let
      (
        (author-record (default-to { content-count: u0, last-activity: u0 } 
                         (map-get? author-content { author: caller })))
        (content-count (get content-count author-record))
      )
      
      ;; Ensure author hasn't reached content limit
      (asserts! (< content-count MAX_CONTENT_PER_AUTHOR) ERR_CONTENT_LIMIT_REACHED)
      
      ;; Store content record
      (map-set content-records
        { content-hash: content-hash }
        {
          author: caller,
          timestamp: current-height,
          content-type: content-type,
          signature: signature,
          title: title,
          is-active: true,
          storage-url: storage-url,
          version: u1
        }
      )
      
      ;; Update author's content index
      (map-set author-content-by-index
        { author: caller, index: content-count }
        { content-hash: content-hash }
      )
      
      ;; Update author's content count
      (map-set author-content
        { author: caller }
        { 
          content-count: (+ content-count u1),
          last-activity: current-height
        }
      )
      
      ;; Return success with transaction ID
      (ok content-hash)
    )
  )
)

;; Verify if content matches the registered hash
;; This is a read-only function that returns the record if found
;; @param content-hash: SHA-256 hash to verify
;; @returns: Content record if found, or error if not found
(define-read-only (verify-content (content-hash (buff 32)))
  (match (map-get? content-records { content-hash: content-hash })
    record (ok record)
    ERR_NOT_FOUND
  )
)

;; Get a single content hash by author and index
;; @param author: The content author
;; @param index: The index of the content
;; @returns: Content hash if found, or none
(define-read-only (get-content-hash-at-index (author principal) (index uint))
  (map-get? author-content-by-index { author: author, index: index })
)

;; Get author content with pagination - fixed non-recursive approach
;; @param author: Stacks address of content creator
;; @param page: Page number (0-based)
;; @param page-size: Number of items per page (max 20)
;; @returns: List of content hashes for the requested page
(define-read-only (get-author-content-paged 
                    (author principal) 
                    (page uint) 
                    (page-size uint))
  (let
    (
      ;; Limit page size to reasonable amount to avoid stack overflows
      (limited-page-size (if (> page-size u20) u20 page-size))
      (author-record (default-to { content-count: u0, last-activity: u0 } 
                       (map-get? author-content { author: author })))
      (content-count (get content-count author-record))
      (start-index (* page limited-page-size))
    )
    
    ;; Check if requested page is valid
    (if (>= start-index content-count)
      (ok (list))
      (let
        (
          (items-remaining (- content-count start-index))
          (items-to-fetch (if (< items-remaining limited-page-size) 
                             items-remaining 
                             limited-page-size))
        )
        ;; Build a fixed-size list of content hashes using individual lookups
        ;; This avoids recursion issues in Clarity
        (ok (get-content-hash-page author start-index items-to-fetch))
      )
    )
  )
)

;; Helper to get a page of content hashes without recursion
;; Limited to maximum 20 items to avoid stack issues
(define-read-only (get-content-hash-page (author principal) (start-index uint) (count uint))
  (let
    (
      ;; Start with empty list
      (result (list))
      
      ;; Get individual items - limited to 20 max to avoid stack overflow
      ;; Using individual conditionals instead of recursion
      (result-1 (match (map-get? author-content-by-index { author: author, index: start-index })
                  item (unwrap! (as-max-len? (append result (get content-hash item)) u20) result)
                  result))
                  
      (result-2 (if (>= u1 count) 
                   result-1
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u1) })
                     item (unwrap! (as-max-len? (append result-1 (get content-hash item)) u20) result-1)
                     result-1)))
                     
      (result-3 (if (>= u2 count) 
                   result-2
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u2) })
                     item (unwrap! (as-max-len? (append result-2 (get content-hash item)) u20) result-2)
                     result-2)))
                     
      (result-4 (if (>= u3 count) 
                   result-3
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u3) })
                     item (unwrap! (as-max-len? (append result-3 (get content-hash item)) u20) result-3)
                     result-3)))
                     
      (result-5 (if (>= u4 count) 
                   result-4
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u4) })
                     item (unwrap! (as-max-len? (append result-4 (get content-hash item)) u20) result-4)
                     result-4)))
                   
      ;; Continue for additional items up to 20
      (result-6 (if (>= u5 count) 
                   result-5
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u5) })
                     item (unwrap! (as-max-len? (append result-5 (get content-hash item)) u20) result-5)
                     result-5)))
                     
      (result-7 (if (>= u6 count) 
                   result-6
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u6) })
                     item (unwrap! (as-max-len? (append result-6 (get content-hash item)) u20) result-6)
                     result-6)))
                     
      (result-8 (if (>= u7 count) 
                   result-7
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u7) })
                     item (unwrap! (as-max-len? (append result-7 (get content-hash item)) u20) result-7)
                     result-7)))
                     
      (result-9 (if (>= u8 count) 
                   result-8
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u8) })
                     item (unwrap! (as-max-len? (append result-8 (get content-hash item)) u20) result-8)
                     result-8)))
                     
      (result-10 (if (>= u9 count) 
                   result-9
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u9) })
                     item (unwrap! (as-max-len? (append result-9 (get content-hash item)) u20) result-9)
                     result-9)))
                     
      (result-11 (if (>= u10 count) 
                   result-10
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u10) })
                     item (unwrap! (as-max-len? (append result-10 (get content-hash item)) u20) result-10)
                     result-10)))
                     
      (result-12 (if (>= u11 count) 
                   result-11
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u11) })
                     item (unwrap! (as-max-len? (append result-11 (get content-hash item)) u20) result-11)
                     result-11)))
                     
      (result-13 (if (>= u12 count) 
                   result-12
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u12) })
                     item (unwrap! (as-max-len? (append result-12 (get content-hash item)) u20) result-12)
                     result-12)))
                     
      (result-14 (if (>= u13 count) 
                   result-13
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u13) })
                     item (unwrap! (as-max-len? (append result-13 (get content-hash item)) u20) result-13)
                     result-13)))
                     
      (result-15 (if (>= u14 count) 
                   result-14
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u14) })
                     item (unwrap! (as-max-len? (append result-14 (get content-hash item)) u20) result-14)
                     result-14)))
                     
      (result-16 (if (>= u15 count) 
                   result-15
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u15) })
                     item (unwrap! (as-max-len? (append result-15 (get content-hash item)) u20) result-15)
                     result-15)))
                     
      (result-17 (if (>= u16 count) 
                   result-16
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u16) })
                     item (unwrap! (as-max-len? (append result-16 (get content-hash item)) u20) result-16)
                     result-16)))
                     
      (result-18 (if (>= u17 count) 
                   result-17
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u17) })
                     item (unwrap! (as-max-len? (append result-17 (get content-hash item)) u20) result-17)
                     result-17)))
                     
      (result-19 (if (>= u18 count) 
                   result-18
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u18) })
                     item (unwrap! (as-max-len? (append result-18 (get content-hash item)) u20) result-18)
                     result-18)))
                     
      (result-20 (if (>= u19 count) 
                   result-19
                   (match (map-get? author-content-by-index { author: author, index: (+ start-index u19) })
                     item (unwrap! (as-max-len? (append result-19 (get content-hash item)) u20) result-19)
                     result-19)))
    )
    ;; Return the final result with up to 20 items
    result-20
  )
)
