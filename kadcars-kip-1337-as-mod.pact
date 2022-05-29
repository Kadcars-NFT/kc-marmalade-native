(module kadcars-kip-1337-as-mod "kadcars-kip-1337-as-mod" "A kadena kars NFT Interoperability POC"

;; ------ Checkout @KadCarsNFT On Twitter for more! or visit us on our beta  ------
;; ------ https://kadcarsnft.app.runonflux.io/           - O.H               ------
    (defschema keyval
        @doc "regular nft table indexed by IDs"
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


    (deftable mutable-state:{mutable-state-schema})


    (defun mint-nft(owner:string nft-id:string)
        (let
            (
                (kvl:object{keyval} {'key:"speed", 'val:"100", 'type:"integer"})

            )
            (insert mutable-state nft-id {
                "owner-address":owner,
                "nft-id":nft-id,
                "stats":[kvl]
            })
        )
    )

    (defun add-stat (owner-address:string nft-id:string key:string value:string type-string:string)
        @doc "Adding Stat for NFT Id"

         (let
            (
                ;;check key doesn't exist
                (kvl:object{keyval} {'key:key, 'val:value, 'type:type-string})

            )
            (with-read mutable-state nft-id
                {"stats" := stats}
                (update mutable-state nft-id {
                    "stats": (+ stats [kvl])
                })
            )
            (format "NFT {} added new stat : {} {} "
                    [nft-id key value])
      )

    )


    (defun mod-stat (owner-address:string nft-id:string key:string operator:string operand:string)
        @doc "Modify Stat with Operand and Operation for NFT Id"

        (with-read mutable-state nft-id
                {"stats" := stats}
                (let*
                    (

                        (stat-val (take 1 (filter (where 'key (= key))  stats)))

                        ;;check if stat exists
                        ;; if exists : check if type matches
                        ;; if type matches check mod to perform
                        ;; if ADD mod + type match -> convert and add
                        ;;we assume only int here for now cause chill dude wtf
                        ;(type-string (at "type" stat-val))
                        ;(enforce (= (type-string) "integer"))
                        ;; BELOW IS FOR INT ONLY
                        (added-val-string (if (= operator "+") (map (add-val-int operand) stat-val)
                            (if (= operator "-") (map (sub-val-int operand) stat-val) (return-stat-val-from-singleton-list stat-val))))
                       ; (added-val-string (map (add-val-int operand) stat-val))
                        (dir (fold (+) 0 added-val-string))
                        (enforce (> 0) dir "Negative stats not supported yet cause Heskel lol")
                        ;(added-val-folded (fold (+) 0 (added-val-string)))
                        (dir-string (int-to-str 10 dir))
                        (new-stat:object{keyval} {'key:key, 'val:dir-string, 'type:"integer"})
                        (filtered-stats (filter-out-key-from-list stats key))
                        (final-stats (+ filtered-stats [new-stat]))
                        ;(folded-str (fold (add-val-int) operand stat-val))
                    )

                (update mutable-state nft-id {
                    "stats":final-stats
                })
                (format "added {} to stat {}, updated val {}" [operand key dir-string]))
        )
    )

    (defun rem-stat (owner-address:string nft-id:string filter-key:string)
        @doc "Removing Stat for NFT Id"

            (with-read mutable-state nft-id
                {"stats" := stats}
                (update mutable-state nft-id {
                    "stats": (filter-out-key-from-list stats filter-key)
                })
            )
            (format "NFT {} removed stat : {}"
                    [nft-id filter-key]
            )
    )

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


;kvls:object:{keyval}


    ;;;;;;;;;;;;; UTILS (to be moved) ;;;;;;;;;;;;;;;;;;


    (defun str-to-double(input-string:string)
        @doc "string to int"

        ;1 separate string to list
        ;2 reduction : left side x10 right side /10
        ;3 map
        (format "not implmeneted")
    )


)

;(create-table mutable-state)
