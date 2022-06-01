(define-keyset 'kadcars-keyset (read-keyset "kadcars-keyset"))

(module kadcars-kip-1337-as-mod 'kadcars-keyset "A kadena kars NFT Interoperability POC"

;; ------ Checkout @KadCarsNFT On Twitter for more! or visit us on our beta  ------
;; ------ https://kadcarsnft.app.runonflux.io/           - O.H               ------


;;;;;;;;;;;;;;;;;;;  CONSTANTS  ;;;;;;;;;;;;;;;;;;;


    (defconst ADMIN_ADDRESS "k:ccf45d4b9e7a05b1f8ae03e362fac9502610d239191a3215774c5251a662c1eb")
    (defconst ADMIN_KEYSET (read-keyset 'kadcars-keyset))

;;;;;;;;;;;;;;;;;;;  SCEHEMAS  ;;;;;;;;;;;;;;;;;;;


    (defschema data-mod
        @doc "Open data model to allow for any typed stat"
        key:string          ;KEY to modify for
        operand:string      ;OPERAND or value for mod
        operation:string    ;OPERATION to perform + - supported rn
        lock:bool        ;Is LOCK required for this NFT in order to perform mod
        burn:bool        ;Is BURN required for this NFT in order to perform mod
    )

    (defschema keyval
        @doc "Open data model to allow for any typed stat"
        key:string
        val:string
        type:string ;; simplified way to bring type into scope :ideally schema'ed type
    )

    (defschema mutable-state-schema
        @doc "regular nft table indexed by IDs"
        owner-address:string
        nft-id:string
        stats:[object:{keyval}]
    )

    (defschema controlled-state-schema
        @doc "immutable protected fields"
        nft-id:string
        nft-history:list
        nft-refs:list
    )

    (deftable mutable-state:{mutable-state-schema})



;;;;;;;;;;;;;;;;;;; capabilities temporary ;;;;;;;;;;;;;;;;;;;


    ;
    ; (defcap ADMIN() ; Used for admin functions
    ;     @doc "Only allows admin to call these"
    ;     (enforce-keyset  ADMIN_KEYSET)
    ;     (compose-capability (PRIVATE))
    ;     (compose-capability (ACCOUNT_GUARD ADMIN_ADDRESS))
    ; )

    (defcap PRIVATE ()
        @doc "can only be called from a private context"
        true
    )

    (defcap ACCOUNT_GUARD (account:string)
        @doc "Verifies account meets format and belongs to caller"
        (enforce (= "k:" (take 2 account)) "For security, only support k: accounts")
        (enforce-guard
            (at "guard" (coin.details account))
        )
    )
    ;
    ; (defcap OWNER (account:string nft-id:string)
    ;     @doc "Enforces that an account owns that car"
    ;     (let
    ;         (
    ;             (nft-owner (at "owner-address" (read mutable-state nft-id ['owner-address] )))
    ;         )
    ;         (enforce (= nft-owner account) "Account is not owner of the NFT")
    ;         (compose-capability (ACCOUNT_GUARD account))
    ;     )
    ; )




;;;;;;;;;;;;;;;

    ; (defun mint-nft(owner:string nft-id:string)
    ;     @doc "Temporary testing mint function with default stat"
    ;     (with-capability (ADMIN)
    ;         (let
    ;             (
    ;                 (kvl:object{keyval} {'key:"speed", 'val:"100", 'type:"integer"})
    ;
    ;             )
    ;             (insert mutable-state nft-id {
    ;                 "owner-address":owner,
    ;                 "nft-id":nft-id,
    ;                 "stats":[kvl]
    ;             })
    ;         )
    ;     )
    ; )
;
;
; ;;;;;;;;;;;;;;;;; PUBLIC MODIFIERS ;;;;;;;;;;;;;;;;;;;;;;;;
    ; (defun attach-on(stat-modifications:list mnft-id:string unft-id:string owner:string)
    ;     (with-capability (ADMIN)
    ;         (with-capability (OWNER owner mnft-id)
    ;             (map (extract-data-and-call-mod mnft-id owner) stat-modifications)
    ;         )
    ;     )
    ; )
;
    ; (defun extract-data-and-call-mod(mnft-id:string owner:string mod:object{data-mod})
    ;     @doc ""
    ;     ; mod-stat (owner-address:string nft-id:string key:string operator:string operand:string)
    ;     (mod-stat owner mnft-id (at "key" mod) (at "operation" mod) (at "operand" mod))
    ;
    ; )
;
;
;
;
;
;
;
;
;
;;;;;;;;;;;;;;;;; PRIVATE STATE MODIFIERS ;;;;;;;;;;;;;;;;;;;;;;;;
;; These are just for test ofcourse chill, but some notes:
;; Should only Access mutable states
;; Should only be Accessed internally
;; Validation should come before

    ; (defun add-stat (owner-address:string nft-id:string key:string value:string type-string:string)
    ;     @doc "Adding Stat for NFT Id"
    ;     ;;TODO This should likely be require-capability, as its far down in the call stack, and also enforce private call here
    ;     (with-capability (OWNER owner-address nft-id)
    ;         (let
    ;             (
    ;                 ;;check key doesn't exist
    ;                 (kvl:object{keyval} {'key:key, 'val:value, 'type:type-string})
    ;
    ;             )
    ;             (with-read mutable-state nft-id
    ;                 {"stats" := stats}
    ;                 (update mutable-state nft-id {
    ;                     "stats": (+ stats [kvl])
    ;                 })
    ;             )
    ;             (format "NFT {} added new stat : {} {} "
    ;                     [nft-id key value])
    ;         )
    ;     )
    ; )


    ; (defun mod-stat (owner-address:string nft-id:string key:string operator:string operand:string)
    ;     @doc "Modify Stat with Operand and Operation for NFT Id"
    ;     (with-capability (ADMIN)
    ;         (with-read mutable-state nft-id
    ;                 {"stats" := stats}
    ;                 (let*
    ;                     (
    ;
    ;                         (stat-val (take 1 (filter (where 'key (= key))  stats)))
    ;
    ;                         ;;check if stat exists
    ;                         ;; if exists : check if type matches
    ;                         ;; if type matches check mod to perform
    ;                         ;; if ADD mod + type match -> convert and add
    ;                         ;;we assume only int here for now cause chill dude wtf
    ;                         ;(type-string (at "type" stat-val))
    ;                         ;(enforce (= (type-string) "integer"))
    ;                         ;; BELOW IS FOR INT ONLY
    ;                         (resultantVal (if (= operator "+") (map (add-val-int operand) stat-val)
    ;                             (if (= operator "-") (map (sub-val-int operand) stat-val) (return-stat-val-from-singleton-list stat-val))))
    ;                        ; (added-val-string (map (add-val-int operand) stat-val))
    ;                         (dir (fold (+) 0 resultantVal))
    ;                         ;(added-val-folded (fold (+) 0 (added-val-string)))
    ;                         (dir-string (int-to-str 10 dir))
    ;                         (new-stat:object{keyval} {'key:key, 'val:dir-string, 'type:"integer"})
    ;                         (filtered-stats (filter-out-key-from-list stats key))
    ;                         (final-stats (+ filtered-stats [new-stat]))
    ;                         ;(folded-str (fold (add-val-int) operand stat-val))
    ;                     )
    ;
    ;                 (update mutable-state nft-id {
    ;                     "stats":final-stats
    ;                 })
    ;                 (format "modified nft {}, stat {}, new val {}" [nft-id key dir-string]))
    ;         )
    ;     )
    ; )

    ; (defun rem-stat (owner-address:string nft-id:string filter-key:string)
    ;     @doc "Removing Stat for NFT Id"
    ;     (with-capability (ADMIN)
    ;         (with-read mutable-state nft-id
    ;             {"stats" := stats}
    ;             (update mutable-state nft-id {
    ;                 "stats": (filter-out-key-from-list stats filter-key)
    ;             })
    ;         )
    ;         (format "NFT {} removed stat : {}"
    ;                 [nft-id filter-key]
    ;         )
    ;     )
    ; )

    (defun filter-out-key-from-list (list-to-filter:list filter-key:string)

        (filter (where 'key (!= filter-key)) list-to-filter)
    )

    (defun get()
        (keys mutable-state)
    )
    (defun get-nft(nft-id:string)
        (read mutable-state nft-id)
    )

    (defun add-val-int(lhs:string new-stat:object{keyval})
        (let*
            (
                (rhs (at 'val new-stat))
                (rhs-int (str-to-int rhs))
                (lhs-int (str-to-int lhs))
            )

            (+ rhs-int lhs-int)
        )
    )

    (defun sub-val-int(lhs:string new-stat:object{keyval})
        (let*
            (
                (rhs (at 'val new-stat))
                (rhs-int (str-to-int rhs))
                (lhs-int (str-to-int lhs))
            )
            ;; TODO FIX NEGATIVE -> fails on conversion back to string.
            (enforce (> rhs-int lhs-int ) "Negative stats not supported yet cause Heskel lol")
            (- rhs-int lhs-int )

        )
    )

    (defun return-stat-val-from-singleton-list(stat-list:list)

        (let*
            (

                (val-single-list (take 1(map (get-val-single-list) stat-list)))
                (dir (fold (+) 0 val-single-list))
            )
        (dir)
        )
    )

    (defun get-val-single-list(stat:object{keyval})
    ;;TODO enforce 1 size
        (let*
            (

                (val (at "val" stat))
            )
        (str-to-int val)
        )
    )

    ;;;;;;;;;;;;; UTILS (to be moved) ;;;;;;;;;;;;;;;;;;
    (defun get-first(list:list)
        (format "not implmeneted")
    )
    (defun get-last(list:list)
        (format "not implmeneted")
    )

    (defun pop:list(list:list)
        (format "not implmeneted")
    )
    (defun push:list(object)
        (format "not implmeneted")
    )

    (defun str-to-double(input-string:string)
        @doc "string to int"

        ;1 separate string to list
        ;2 reduction : left side x10 right side /10
        ;3 map
        (format "not implmeneted")
    )


)

;(create-table mutable-state)
