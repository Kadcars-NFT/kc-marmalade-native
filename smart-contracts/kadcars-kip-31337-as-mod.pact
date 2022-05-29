(module kadcars-kip-31337-as-mod 'kadcars "A kadena kars NFT Interoperability POC"

(use kadcars-kip-1337-as-mod)
;; ------ Checkout @KadCarsNFT On Twitter for more! or visit us on our beta  ------
;; ------ https://kadcarsnft.app.runonflux.io/           - O.H               ------


    ;;;;;;;;;;;;;;;;;;;  CONSTANTS  ;;;;;;;;;;;;;;;;;;;


    (defconst ADMIN_ADDRESS "k:ccf45d4b9e7a05b1f8ae03e362fac9502610d239191a3215774c5251a662c1eb")
    (defconst BURN_ADDRESS "k:kaaaaaaaaaaaaaaaaaaaaaaaaaadddddddddddddddddddddddddddeeeeeeeeeeennnnnnnnnnaaaaaaa")

    (defconst ADMIN_KEYSET (read-keyset 'kadcars))

;;;;;;;;;;;;;;;;;;;  SCEHEMAS  ;;;;;;;;;;;;;;;;;;;

    (defschema keyval
        @doc "Open data model to allow for any typed stat"
        key:string
        val:string
        type:string ;; simplified way to bring type into scope :ideally schema'ed type
    )


    (defschema data-mod
        @doc "Open data model to allow for any typed stat"
        key:string          ;KEY to modify for
        operand:string      ;OPERAND or value for mod
        operation:string    ;OPERATION to perform + - supported rn
        lock:bool        ;Is LOCK required for this NFT in order to perform mod
        burn:bool        ;Is BURN required for this NFT in order to perform mod
    )

    (defschema mutable-state-schema
        @doc "regular nft table indexed by IDs"
        owner-address:string
        nft-id:string
        stats:[object:{keyval}]
    )

    (defschema mod-def-schema
        @doc "describes modifications it can perform and when"
        nft-id:string
        owner-address:string
        data-mod-list:[object:{data-mod}]
    )

    (defschema protected-state-schema
        @doc "schema with protected access and should hold id and ownership"
        nft-id:string
        owner-address:string
    )

    (deftable mutable-state:{mutable-state-schema})
    (deftable mod-def:{mod-def-schema})



;;;;;;;;;;;;;;;;;;; capabilities temporary ;;;;;;;;;;;;;;;;;;;



    (defcap ADMIN() ; Used for admin functions
        @doc "Only allows admin to call these"
        (enforce-keyset  ADMIN_KEYSET)
        (compose-capability (PRIVATE))
        (compose-capability (ACCOUNT_GUARD ADMIN_ADDRESS))
    )

    (defcap PRIVATE ()
        @doc "can only be called from a private context"
        true
    )

    (defcap ACCOUNT_GUARD(account:string)
        @doc "Verifies account meets format and belongs to caller"
        (enforce (= "k:" (take 2 account)) "For security, only support k: accounts")
        (enforce-guard
            (at "guard" (coin.details account))
        )
    )

    (defcap OWNER (account:string nft-id:string)
        @doc "Enforces that an account owns that car"
        (let
            (
                (nft-owner (at "owner-address" (read mutable-state nft-id ['owner-address] )))
            )
            (enforce (= nft-owner account) "Account is not owner of the NFT")
            (compose-capability (ACCOUNT_GUARD account))
        )
    )
;;;;;;;;;;;;;;;
    (defun mint-nft(owner:string nft-id:string)
        @doc "Temporary testing mint function with default stat"
        (with-capability (ADMIN)
            (let
                (
                    (mod-a:object{data-mod} {'key:"speed", 'operand:"10000", 'operation:"+", 'lock:true, 'burn:false} )
                    (mod-b:object{data-mod} {'key:"speed", 'operand:"999", 'operation:"-", 'lock:true, 'burn:false} )
                    (mod-c:object{data-mod} {'key:"weight", 'operand:"200", 'operation:"+", 'lock:false, 'burn:true} )
                )
            (insert mod-def nft-id {
                "owner-address":owner,
                "nft-id":nft-id,
                "data-mod-list":[mod-a mod-b mod-c]
            })
            (insert mutable-state nft-id {
                "owner-address":owner,
                "nft-id":nft-id,
                "stats":[]
            })


            )

        )
    )

;;;;;;;;;;;;;;;;; THE badboi ;) ;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;; module specific 31337 methods
    (defun attach-to-kadcar(mnft-id:string unft-id:string)
        @doc "Method that calls external module to initiate attachment"
        ;;might need a defpact here for burn
        (let
            (
                (stat-modifications (at "data-mod-list" (read mod-def unft-id ['data-mod-list] )))
                (nft-owner (at "owner-address" (read mutable-state unft-id ['owner-address] )))



            )
            (kadcars-kip-1337-as-mod.attach-on stat-modifications mnft-id unft-id nft-owner)
            ;1. protected state nft-id
            ;2 remove unneeded ones bruh
            (update mutable-state unft-id {
                        "owner-address":BURN_ADDRESS
            })
            (update mod-def unft-id {
                        "owner-address":BURN_ADDRESS
            })
        )
    )
    (defun get-states()
        (keys mutable-state)
    )

    (defun get-ids-for-owner (owner-address:string)
        @doc "Returns all KadCar Ids owned by owner"
        (select mutable-state ["nft-id"] (where "owner-address" (= owner-address)))
    )

    (defun get-nft-upgrades(nft-id:string)
        (read mod-def nft-id)
    )

    (defun get-nft(nft-id:string)
        (read mutable-state nft-id)
    )
)
;;;;;;;;;;;;;;;;; PUBLIC MODIFIERS ;;;;;;;;;;;;;;;;;;;;;;;;
