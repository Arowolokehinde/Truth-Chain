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
