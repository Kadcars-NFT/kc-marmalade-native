(module kadcars-nft-collection "kadcars-nft-collection-keyset" "A kadena kars NFT project"

;; ------ Checkout @KadCarsNFT On Twitter for more! or visit us on our beta  ------
;; ------ https://kadcarsnft.app.runonflux.io/                               ------


    ;;;;;;;;;;;; INIT STATE ;;;;;;;;;;;;
    (defconst ADMIN_ADDRESS "k:ccf45d4b9e7a05b1f8ae03e362fac9502610d239191a3215774c5251a662c1eb")
    (defconst ADMIN_KEYSET (read-keyset 'kadcars-nft-collection-keyset))
    (defconst K1_ACCELERATION_ZTH 3.3)
    (defconst K1_HORSE_POWER_EQUIV 890)
    (defconst K1_TOP_SPEED_KMPH 300)
    (defconst K1_NAME_LABEL "name")
    (defconst K1_REPUTAION 0.0)
    (defconst K1_HANDLING 75)
    (defconst K1_PRICE_KEY "k1-price-key")
    (defconst K2_PRICE_KEY "k2-price-key")
    (defconst K1_TOTAL_COUNT_KEY "k1-total-count-key")
    (defconst K1_MAX_COUNT 6999)

    ; temporary schema for testing
    (defschema nft-schema
        @doc "Stores the owner information for each nft"

        ;; --- Identifier Fields ---
        owner-address:string
        nft-id:string
        name:string
        model:string
        ;; --- Model Related Stats
        acceleration-zth:decimal
        horse-power-equiv:integer
        top-speed-kmph:integer
        handling :integer
        ;; --- NFT Specific Stats
        reputation:decimal
        manufacture-date:time
        ;;downforce
        ;; --- NFT Audit/History Stats ---
        sales-history:list
        ;;parts-ref-history:object for upgrades ;)
    )

    (defschema price-schema
        @doc "Prices schema"
        price:decimal
    )
    (defschema counts-schema
        @doc "Basic schema used for counting things"
        count:integer
    )
    (defschema k1-blueprint
        @doc "Stores the owner information of K1 model ;) "

        ;; -- TODO Add constants --
    )

    (defschema allow-list-schema
        @doc "Stores the owner information of K1 model ;) "
        address:string
        guaranteed-amount:integer
        max-amount:integer
        amount-left:integer
        guard:guard
        ;; -- TODO Add constants --
    )

    (deftable allow-list:{allow-list-schema})
    (deftable price:{price-schema})
    (deftable nfts:{nft-schema})
    (deftable counts:{counts-schema})
    ;;;;;;;;;;;; ACCESS CONTROL ;;;;;;;;;;;;
    (defcap PRIVATE ()
        @doc "can only be called from a private context"
        true
    )


    (defcap WL(account:string)
        @doc "Verified account is allow listed for mint"
        (let
            (
                (amount-allowed (at "amount-left" (read allow-list account ['amount-left] )))
            )
            (enforce (>= amount-allowed 0) "Account has no more cars to mint")
        )
        (compose-capability (PRIVATE))
        (compose-capability (ACCOUNT_GUARD))
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
                (nft-owner (at "owner-address" (read nfts nft-id ['owner-address] )))
            )
            (enforce (= nft-owner account) "Account is not owner of the NFT")
            (compose-capability (ACCOUNT_GUARD account))
        )
    )

    (defcap ADMIN() ; Used for admin functions
        @doc "Only allows admin to call these"
        (enforce-keyset  ADMIN_KEYSET)
        (compose-capability (PRIVATE))
        (compose-capability (ACCOUNT_GUARD ADMIN_ADDRESS))
    )


    ;;;;;;;;;;;; STATE MODIFIERS ;;;;;;;;;;;;

    ; method serves as admin/testing defacto mint for now
    ; TODO make collection dependant
    (defun set-owner(owner-address:string nft-id:string)
        @doc "Set the owner of an NFT - only available for admin"
        ; This function enforces that the caller of this function
        ; is you (by checking the keyset)
        (enforce-keyset  (read-keyset "kadcars-nft-collection-keyset"))
        (insert nfts nft-id {
          "owner-address": owner-address,
          "nft-id":nft-id,
          "name":K1_NAME_LABEL,
          "model":"K1",
          "acceleration-zth":K1_ACCELERATION_ZTH,
          "horse-power-equiv":K1_HORSE_POWER_EQUIV,
          "top-speed-kmph":K1_TOP_SPEED_KMPH,
          ; exp starts at 0
          "reputation":K1_REPUTAION,
          "manufacture-date":(at "block-time" (chain-data)),
          "handling":K1_HANDLING,
          ;; TODO "sale-history":object
          "sales-history":(make-list (at "block-time" (chain-data)) 1)
          })
    )

    (defun manufacture(owner-address:string car-model:string number:integer )
        @doc "Manufactures a new call"
        (enforce (= (car-model "K1")) "The Car model is not being manufactured right now!")

        (enforce (= number 1) "mint only 1 for now")
        (let(
            (total_k1_cars (get-count K1_TOTAL_COUNT_KEY))

            )
        (enforce (<= (+ total_k1_cars number) K1_MAX_COUNT) "CANNOT PRODUCE ANY MORE CARS")
        )
    )

    (defun manufacture-k1:string (owner-address:string number:integer)
        @doc "Manufactures a new K1 model car"
        (enforce (= number 1) "mint only 1 for now")
        (let (
                (total_k1_cars (get-count K1_TOTAL_COUNT_KEY))

            )
            (enforce (<= (+ total_k1_cars number) K1_MAX_COUNT) "CANNOT PRODUCE ANY MORE CARS")
        )
        (if
            (!= owner-address ADMIN_ADDRESS)
            (coin.transfer owner-address ADMIN_ADDRESS (* (get-price) number))
            "Admin account exempted from transfer"
        )
        (with-capability (ACCOUNT_GUARD owner-address)
            (with-capability (PRIVATE)
                (let (
                        (nft-id (id-for-new-k1))
                     )
                (insert nfts nft-id {
                  "owner-address": owner-address,
                  "nft-id":nft-id,
                  "name":K1_NAME_LABEL,
                  "model":"K1",
                  "acceleration-zth":K1_ACCELERATION_ZTH,
                  "horse-power-equiv":K1_HORSE_POWER_EQUIV,
                  "top-speed-kmph":K1_TOP_SPEED_KMPH,
                  ; exp starts at 0
                  "reputation":K1_REPUTAION,
                  "manufacture-date":(at "block-time" (chain-data)),
                  "handling":K1_HANDLING,
                  "sales-history":(make-list 1 (at "block-time" (chain-data)))
                  })
                (increase-count K1_TOTAL_COUNT_KEY)
                (format "minted : {}!" [nft-id])
                )
            )
        )
    )






    (defun initialize ()
        @doc "Initialize state on first time it's loaded "
        (insert counts K1_TOTAL_COUNT_KEY {"count": 0})
        (insert price K1_PRICE_KEY {"price": 1.0})
        (insert price K2_PRICE_KEY {"price": 1.0})

    )


    (defun id-for-new-k1 ()
        @doc "Returns an id for K1 minted next"
        (require-capability (PRIVATE))
        (+ (+ (curr-chain-id) ":") (int-to-str 10 (get-count K1_TOTAL_COUNT_KEY)))
    )

    (defun curr-chain-id ()
        @doc "Current chain id"
        (at "chain-id" (chain-data))
    )

    (defun increase-count(key:string)
        @doc "Increases count of a key in a table by 1"
        (require-capability (PRIVATE))
        (update counts key
            {"count": (+ 1 (get-count key))}
        )
    )



    (defun transfer:string
        ( nft-id:string
          sender:string
          receiver:string
        )
        @doc " Transfer to an account, failing if the account to account does not exist. "
        ; BEFORE OPENING TO PUBLIC (enforce-account-has-car owner)
        ; AND/OR enforce account reciever exists
        ;(with-capability (EXISTS receiver)
            (with-capability (OWNER sender nft-id)
                (coin.transfer sender ADMIN_ADDRESS 0.69)
                ;;;; TODO : EXPERIENCE SHOULD BE INCREASED HERE
                (update nfts nft-id {"owner-address": receiver})
            )
        ;)
    )

    ;;;;;;;;;;;; STATE ACCESSORS ;;;;;;;;;;;;

    (defun get-all-cars ()
        @doc "Returns all the ids"
        (keys nfts)
    )

    (defun get-price()
        (at "price" (read price K1_PRICE_KEY ["price"]))
    )


    (defun get-count (key:string)
        @doc "Gets count for key"
        (at "count" (read counts key ['count]))
    )

    (defun get-owner (nft-id:string)
        @doc "Gets the owner of an NFT"
        ; This returns the owner-address field by reading it from the table
        (at "owner-address" (read nfts nft-id ['owner-address] ))
    )

    (defun get-ids-for-owner (owner-address:string)
        @doc "Returns all KadCar Ids owned by owner"
        (select nfts ["nft-id"] (where "owner-address" (= owner-address)))
    )

    (defun get-kadcars-for-owner (owner-address:string)
        @doc "Returns all KadCar Ids owned by owner"
        (select nfts (where "owner-address" (= owner-address)))
    )

    (defun get-kadcar-for-nft-id (nft-id:string)
        @doc "Returns all KadCar Ids owned by owner"
        (select nfts (where "nft-id" (= nft-id)))
    )

    (defun get-kadcars ()
        @doc "Returns all KadCar Ids owned by owner"
        (select nfts )
    )


    ; This is the function to get the image of your NFT
    ; it takes an ID as the input and returns its URL
    ; PS - this is the same function as on the current Marmalade standard :)
    (defun uri:string (id:string)
        ;; TODO Correct implementation for entire collection (as opposed to 1 nft)
        @doc
        " Give URI for ID. If not supported, return \"\" (empty string)."

        ; This will take the url of the website you uplaoded your image to
        ; and then add the id and .jpg to the end of it
        ; For example if your website is "https://my-cool-website/" and the
        ; id is "1" then this will return "https://my-cool-website/1.jpg"

        ;; ---- TODO These will tie tie to our art ----
        (+ "https://cdn.pixabay.com/photo/2017/08/15/02/43/car-2642600_1280"
            ; replace .jpg with whatever format your NFTs are
            (+ ".jpg"))
    )

)

; Creating tables must be done outside of the module, just how it works
; Note if you end up re-deploying the code, you must delete this line or
; it will try to recreate the table and fail since it already exists(

;(create-table nfts)
;  (create-table counts)
 ; (create-table price)
