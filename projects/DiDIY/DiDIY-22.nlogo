extensions [table profiler factbase rnd string reflection]

breed [things thing]
breed [centres centre]

globals [
    resources      ;; a list of things found in the environment
    resources-disp ;; a sorted list of the resources for display purposes
    resource-costs ;; table from things -> their cost of obtaining from environment
    target-values  ;; table from things -> their use value to an agent
    targets        ;; list of those things of use to an agent
    targets-disp   ;; a sorted list of the targets for display purposes
    basic-elements ;; the basic building blocks from which things are built (as labels)
    elements       ;; list of the basic building blocks from which things are built plus ">" and "&"
    agents         ;; list of patches that are active agents
    action-types   ;; list of derivation kinds
    disp-cols      ;; list of colours for kinds
    str-table      ;; table of str -> thing-list

    default-plans  ;; list of default action plans all agents start with
    rand-actions   ;; the list of actions in default-plans
    num-targets-each num-resources-each ;; calcualted from parameters
    poss-elements  ;; to hold the list of possible elements (actual ones used depends on parameter)
    bignum negbignum ;; useful default numbers
    temp           ;; useful for trying stuff in the command line
    secs av-secs   ;; used in timing of ticks

    ;; lists of stats one entry per agent
     num-things-list num-tools-list num-distinct-things-list av-length-list num-get-list num-buy-list
     num-sell-list num-join-list num-split-left-list num-split-right-list num-apply-list num-realise-list
     num-plans-list num-for-sale-list max-plan-value-list income-list money-list
  ]

things-own [
    tool?     ;; whether the item is a tool
    disp-type ;; "apply" "split" "join" "get" "buy"
    used?     ;; temporary marker in do-plan
  ]

patches-own [
    agent?       ;; "empty" "agent" - determined at the start
    money last-money       ;; the money/last money it has/had
    my-resources ;; a list of resource strings that are available
    my-targets   ;; a list of strings that can be directly realised
    plan-num     ;; an integer that is incremented every plan that is remembered

    plan-table     ;; a table of name-of thing -> its plan id
    rev-plan-table ;; a table of plan id -> list of things
    plan-id-table  ;; from plan-id -> plan (the tree itself)

    my-plans     ;; factbase of: str, id, value, plan  ;; where value is net worth of plan (value of results - costs)
                 ;; plan is one of the following lists:
                   ;;     str get
                   ;;     str buy  agent
                   ;;     str realise itm1-plan
                   ;;     str sell itm1-plan agent
                   ;;     str apply tl-plan itm-plan
                   ;;     str split itm1-plan
                   ;;     str join itm1-plan itm2-plan

                 ;; plus the random plans: "" val plan
                   ;; -1 [buy-random]
                   ;; -1 [get-random]
                   ;; 0 [split-random]
                   ;; 0 [join-random]
                   ;; 0 [apply-random]
                   ;; 1 [realise-random]
                   ;; 1 [sell-random]

     cost-table  ;; table of name-of thing -> its making cost

     max-val    ;; maximum value in my-plans
     min-rand-action-val ;; smallest value of random plan

     for-sale    ;; record of items offered and available for sale, agents must check this
                 ;; itm price ;;  possibly in future could be market agents

     can-buy     ;; information (maybe fallible) about items agent could buy
                 ;; itm price agent  ;;  possibly in future could be market agents

     ;; statistics - each is a list of numbers per agent, used as av num-things or sd num-things etc. in output
     num-things num-tools num-distinct-things av-length num-get num-buy num-sell num-join income
     num-split-left num-split-right num-apply num-realise num-plans num-for-sale max-plan-value
  ]

;;;;;;;;;;;;;;;;;;;
;;; setup stuff ;;;
;;;;;;;;;;;;;;;;;;;
to A-SETUP end

to setup
  _db "" "" ""
  ;; setup various lists and parameters
  clear-all
  set bignum 999999999 set negbignum -1 * bignum
  set action-types ["apply" "split-left" "split-right" "join" "get" "buy" "sell" "realise" "use"]
  set disp-cols [red green green blue brown orange magenta violet grey] ;; for "apply" "split-left" "split-right" "join" "get" "buy" "sell" "realise"]
  ;; the default actions and their values that are used to initiate exploration of random actions
  set default-plans [[-2 "get-random"] [-0.75 "apply-random"] [-0.5 "realise-random"] [-0.5 "sell-random"] [-2 "buy-random"] [-1.5 "split-random"] [-1 "join-random"]] ;;
  set rand-actions map [second ?] default-plans
  ;; the universe of possible elements that strings can be made of, which are used are a limited subset of this as given by num-elements
  set poss-elements ["A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"]
  set basic-elements sublist poss-elements 0 num-elements ;; only a limited number of elements used
  set resources map [maybe-add-join-str ?] n-values num-resources [random-item-str len-resources] ;; add some joins to the resources
  let nat-tools n-values round (prop-nat-tools * num-resources) [rand-nat-tool-str len-resources] ;; make the tools available
  set secs 0 set av-secs secs ;; initialise timer

  ;; decide extraction cost of resources, ATM no relationship between size and cost
  set resource-costs table:make
  foreach resources [
    table:put resource-costs ? 1 + random-poisson (cost-resources - 1)
  ]

  ;; decide extraction costs of tools, including tool premium -- is this needed?
  foreach nat-tools [
    table:put resource-costs ? 1 + random-poisson (cost-resources - 1)
  ]
  set resources table:keys resource-costs
  set resources-disp disp-list sort-by [length ?1 < length ?2] sort resources

  ;; initialise target, values and associated tables
  set target-values table:make
  repeat num-targets [
    table:put target-values (maybe-add-join-str random-item-str len-targets) 1 + random-poisson (value-targets - 1)
  ]
  set targets table:keys target-values
  set targets-disp disp-list sort-by [length ?1 < length ?2] sort targets
  set str-table table:make

  ;; initialise world of agents
  let world-size ceiling sqrt num-agents
  set-patch-size 500 / world-size
  resize-world 0 (world-size - 1) 0 (world-size - 1)
  ask patches [set agent? false]
  set agents n-of num-agents patches
  set num-targets-each min list length targets (ceiling prop-targets-each * num-targets)
  set num-resources-each min list length resources (ceiling prop-resources-each * num-resources)
  let target-subset [] let resource-subset []

  ;; initialise each agent
  ask agents [
    set agent? true
    set pcolor brown - 3 - check-col-adj
    set money 0 set last-money 0
    set my-targets n-of num-targets-each targets
    set my-resources n-of num-resources-each resources
    set plabel-color yellow
    set max-val negbignum
    set plan-num 0
    set plan-table table:make
    set rev-plan-table table:make
    set cost-table table:make
    set plan-id-table table:make
    set my-plans factbase:create ["str" "id" "value" "plan" "plan-hash"]
    foreach default-plans [ ;; load in default plans to my-plans
      store-plan (list nothing first ? (list "" second ?))
    ]
    set for-sale factbase:create ["str" "itm" "price"]
    set can-buy factbase:create ["str" "itm" "price" "agent"]
    sprout-centres 1 [ ;; used to enable the arrows to be displayed when items are passed to another
      set shape "circle"
      set size 0.05
      ht
    ]
  ]

  reset-ticks   ;; initialises the simulation time system and graphs
end

;; procedure for creating random stuff used in setup

to-report random-item-str [len-param]
  ;; produces a random string for use in making things
  _db len-param "" ""
  let str ""
  repeat 1 + floor random-poisson len-param [
    set str (word str one-of basic-elements)
  ]
  report str
end

to-report maybe-add-join-str [str]
  ;; probibilistically adds a join into a string
  _db str "" ""
  let len length str
  if len < 2 [report str]
  if prob prop-breaks [
    report insert "&" (1 + random (len - 2)) str
  ]
  report str
end

to-report rand-nat-tool-str [len-param]
  ;; makes a random tool - ATM no meta-tools
  _db len-param "" ""
  let pre-ant random-item-str len-param
  let ant maybe-add-join-str pre-ant
  let con maybe-add-join-str shuffle-str subset pre-ant
  report (word ant ">" con)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; the main simulation loop ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to A-GO end

to go
  _db "" "" ""
  ;; _ra "_________________ new" "tick _________________"
  reset-timer

  let plns [] let pln [] let tries 0 let num-th 0 let str-list []
  let succeed? false
  let itm nothing
  ask links [die]

  ask agents [
    if stats? [zero-stats]
    set last-money money
    set money money + 0.1 ;; all have a tiny income so they can get/buy things to get started
    set num-th count things-here
    set tries max-tries  ;; prevents infinite loop when no plan is possible
    set succeed? false
    set str-list str-choice-list ;; list compiled to speed up choice of plans, used in choose-plans
    ;; the main loop of finding doable plans and doing them
    while [tries > 0 and not succeed?] [
      set plns choose-plans num-th str-list
      while [not empty? plns and not succeed?] [
        set pln first plns
        set plns but-first plns
        if first possible-to-do? pln money items [
          ask things-here [set used? false]
          set itm do-plan pln
          set succeed? (itm != nothing or member? second pln ["sell" "realise" "sell-random" "realise-random"])
          if succeed? [_ra "done plan" pln]
        ]
      ]
      set tries tries - 1
    ]
    maybe-forget-plan
  ]

  ask agents [
    set plabel round money
    factbase:retract-all can-buy [? = nothing] ["itm"] ;; necessary to clear out entries for dead things
  ]

  if stats? [ ;; collate statistics
    ask agents [do-agent-stats]
    make-stats-lists
  ]

  ;; consitency checks
  if checks? [_do-checks]

  tick
  if max-time > 0 [
    if ticks > max-time [stop]
  ]

  ;; timer stuff for the per/tick display
  let smooth-fact 0.99
  set secs timer
  set av-secs smooth-fact * av-secs + (1 - smooth-fact) * secs
end

to-report choose-one-resource-str
  ;; pick a random resource in the environment that one can afford
  _db "" "" ""
  foreach shuffle my-resources [
    if table:get resource-costs ? < money [report ?]
  ]
  report ""
end

;;;;;;;;;;;;;;;;;;;
;; basic actions ;;
;;;;;;;;;;;;;;;;;;;
to A-ACTIONS end

;; the basic actions that an agent could do

to-report get [str]
  ;; extract an item afforded by the environment
  _db str "" ""
  _ct str "string"
  if checks? and str = "" [error "Can't get an item for the empty string!"]
  let itm make-item str "get"
  let step-cost 0 - (table:get resource-costs str) - action-cost
  set money money + step-cost
  add-step itm "get" step-cost self []
  set num-get num-get + 1
  _ra "got new resource" name-of itm
  report itm
end

to-report realise [itm]
  ;; realise the value of an item by using it (except as a tool)
  _db name-of itm "" ""
  _ct itm "thing"
  if checks? and not got? itm [error (word "Not got " name-of itm " to realise!")]
  let step-cost realise-value-of str-of itm - action-cost
  set money money + step-cost
  add-step nothing "realise" step-cost self (list itm)
  set num-realise num-realise + 1
  _ra "realised the value of" name-of itm
  lose-item itm
  report nothing
end

to-report join [itm-lst]
  ;; soft-joins two things together
  ;; for moment only join two things!
  _db name-of first itm-lst name-of second itm-lst ""
  _ct itm-lst "list"
  if checks? [
    if length itm-lst != 2 [error (word itm-lst " is not of length 2 in join!")]
    if first itm-lst = nothing or second itm-lst = nothing [error (word "Can't join " names-of itm-lst " due to at least one being nothing!")]
    if not got-all? itm-lst [error (word "Not got all of " names-of itm-lst " to join!")]
    if first itm-lst = second itm-lst [report nothing] ;;; cant join an item to itself !
  ]
  let str join-str map [str-of ?] itm-lst
  let itm make-item str "join"
  set money money - action-cost
  add-step itm "join" (0 - action-cost) self itm-lst
  set num-join num-join + 1
  _ra "joined" (word names-of itm-lst " into " name-of itm)
  lose-items itm-lst
  report itm
end

to-report apply [tl itm]
  ;; applies a tool to an item
  _db name-of tl name-of itm ""
  _ct tl "thing"
  _ct itm "thing"
  if checks? [
    if not got? tl [error (word "Not got tool: " name-of tl " to apply!")]
    if not got? itm [error (word "Not got " name-of itm " for apply!")]
    if tl = itm [report nothing] ;; cant apply a tool to itself !
  ]
  let new-str apply-once str-of tl str-of itm
  if new-str != "" [
    let new-itm make-item new-str "apply"
    let step-cost 0 - tool-use-cost - action-cost
    set money money + step-cost
    add-step new-itm "apply" step-cost self (list tl itm)
    set num-apply num-apply + 1
    _ra "applied tool" (word name-of tl " to " name-of itm)
    lose-item itm
  ]
  report itm
end

;; should split actions have to discard unused part and pay a little for this cost?!!

to-report split-left [itm]
  ;; splits an item at a soft join and uses the left side
  _db name-of itm "" ""
  _ct itm "thing"
  if checks? and not got? itm [error (word "Not got itm " name-of itm " to split!")]
  let itm-strs split-once str-of itm
  let itms make-items itm-strs "split-left"
  let left-item first itms
  let right-item second itms
  set money money - action-cost
  if left-item != nothing [
    add-step left-item "split-left" (0 - action-cost) self (list itm) ;; at the moment attributes the cost to each split item!!
  ]
  if right-item != nothing [
    add-step right-item "split-right" (0 - action-cost) self (list itm) ;; at the moment attributes the cost to each split item!!
  ]
  set num-split-left num-split-left + 1
  _ra "split item" name-of itm
  lose-item itm
  report left-item
end

to-report split-right [itm]
  ;; splits an item at a soft join and uses the right side
  _db name-of itm "" ""
  _ct itm "thing"
  if checks? [
    if itm = nothing [error "Can't split nothing!"]
    if not got? itm [error (word "Not got itm " name-of itm " to split!")]
  ]
  let itm-strs split-once str-of itm
  let itms make-items itm-strs "split-left"
  let left-item first itms
  let right-item second itms
  set money money - action-cost
  if left-item != nothing [
    add-step left-item "split-left" (0 - action-cost) self (list itm) ;; at the moment attributes the cost to each split item!!
  ]
  if right-item != nothing [
    add-step right-item "split-right" (0 - action-cost) self (list itm) ;; at the moment attributes the cost to each split item!!
  ]
  set num-split-right num-split-right + 1
  _ra "split item" name-of itm
  lose-item itm
  report right-item
end

;;; market actions

to-report buy [str agent]
  ;; buy an item for sale from another agent
  _db str agent ""
  _ct str "string"
  _ct agent "agent"
  let lst [] let price 0 let itm-lst [] let itm nothing
  let me self
  ;; try agent in plan for item, but failing that the same item from any agent
  let buy1-lst factbase:retrieve can-buy [?1 = str and ?2 = agent] ["str" "agent"]
  foreach buy1-lst [
    set agent fourth ?
    set lst [factbase:retrieve for-sale [? = str] ["str"]] of agent
    ifelse not empty? lst [
      ask agent [
        set itm-lst one-of lst  ;; choose any
        set itm second itm-lst
        set price third itm-lst
        set money money + price - action-cost
        factbase:retract for-sale itm-lst
        add-step nothing "sell" price - action-cost me (list itm)
        ask itm [
          move-to me
          set disp-type "buy"
          disp-thing
        ]
        set num-sell num-sell + 1
        _ra "sold" itm
      ]
      set money money - price - action-cost
      add-step itm "buy" (0 - price - action-cost) agent []
      set num-buy num-buy + 1
      _ra "bought" (word name-of itm " from " agent)
      ask centre-of agent [create-link-to centre-of me]
      report itm
    ] [
      factbase:retract-all can-buy [?1 = str and ?2 = agent] ["str" "agent"]
    ]
  ]
  report nothing
end

to-report sell [itm]
  ;; put an item on sale
  _db name-of itm "" ""
  _ct itm "thing"
  let oth other agents
  if any? oth [
    report sell-to itm one-of other agents
  ]
  report nothing
end

;; more specific versionf of the sell action

to-report sell-at [itm price]
  _db name-of itm price ""
  _ct itm "thing"
  _ct price "number"
  let oth other agents
  if any? oth [
    report sell-at-to itm price one-of other agents
  ]
  report nothing
end

to-report sell-to [itm agent]
  _db name-of itm agent ""
  _ct itm "thing"
  _ct agent "agent"
  report sell-at-to itm offer-price-for itm agent ;; not a great algorithm for price!!
end

to-report sell-to-these [itm agentset]
  _db itm sort agentset ""
  _ct itm "thing"
  _ct agentset "agentset"
  if checks? and not is-agentset? agentset [error (word agentset " is not an agentset in sell-to-these!")]
  if not any? agentset [report nothing]
  let price offer-price-for itm
  report offer-sale itm price agentset
end

to-report sell-at-to [itm price agent]
  _db name-of itm price agent
  _ct itm "thing"
  _ct price "number"
  _ct agent "agent"
  if checks? and not member? agent agents [error (word "Cant sell-at-to " agent " since it is not an agent!")]
  report offer-sale itm price patch-set agent
end

;;;;;;;;;;;;;;;;;;;;;
;;; market stuff! ;;;
;;;;;;;;;;;;;;;;;;;;;
to A-MARKET end

to-report purchaseable-items
  ;; returns a list of things could maybe buy
  _db "" "" ""
  report map [first ?] factbase:retrieve can-buy [? <= money] ["price"] ;; (word "price <= " money)
end

to-report offer-price-for [itm]
  ;; return an offer price for a thing one want to buy
  _ct itm "thing"
  report with-profit base-price-for itm ;; does not ensure the cost of production is covered
end

to-report base-price-for [itm]
  ;; the greater of the production value and direct realisable value
  _ct itm "thing"
  let plan-val cost-of itm
  let realise-val realise-value-of itm
  report max list plan-val realise-val
end

to-report with-profit [nm]
  ;; the level of profit added to sale price - very basic ATM!
  _db nm "" ""
  _ct nm "number"
  report 1 + random-poisson 1 + nm
end

to-report offer-sale [itm price agent-set]
  ;; put an item on offer for sale
  _db name-of itm sort agent-set ""
  _ct itm "thing"
  _ct price "number"
  _ct agent-set "agentset"
  if checks? and not got? itm [error (word "Not got item: " name-of itm " to offer for sale!")]
  if empty? factbase:retrieve for-sale [? = itm] ["itm"] [  ;; only one entry for each item, may need to change if price alternatives are possible
    factbase:assert for-sale (list str-of itm itm price)
    ask agent-set [
      factbase:assert can-buy (list str-of itm itm price myself)
    ]
    _ra "offer to sell" (word name-of itm " at price " price " to " sort agent-set)
  ]
  report nothing
end

to-report centre-of [ag]
  _db ag "" ""
  _ct ag "agent"
  let cent nobody
  ask ag [set cent one-of centres-here]
  report cent
end

to-report centre-here
  report centre-of self
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; my-plans stuff! ;;;
;;;;;;;;;;;;;;;;;;;;;;;
to A-PLANS end

;;; my-plans: "str" "id" "value" "plan" "plan-has"
;; plan is one of the following forms of list:
    ;; str ("") and one of: "buy-random" "get-random" "split-random" "join-random" "apply-random" "realise-random" "sell-random"
    ;; str "get"
    ;; str "buy" agent
    ;; str "realise" itm-plan
    ;; str "sell" itm-plan agent
    ;; str "split" itm-plan
    ;; str "apply" itm-plan itm2-plan
    ;; str "join" itm-plan itm2-plan
    ;; use "str"

to add-step [itm step step-cost agent itm-list]
  ;; compiles and adds a step as a plan in the plan library
  ;; itm - is what is produced by the step
  ;; step - is the kind of step done
  ;; step-cost is the cost by the step itself (not due to ingrediants) (negative if cost positive if gain)
  ;; agent is the other whith whom this action is done (buying and selling), if needed
  ;; itm-list - is a list of items needed to do the action (if needed)
  _db name-of itm step (list step-cost agent itm-list)
  _ct itm "thing"
  _ct step "action"
  _ct step-cost "number"
  _ct agent "agent"
  _ct itm-list "list"
  let lst [] let val 0
  let str str-of itm
  if step = "use" [
    set val step-cost
    set lst (list itm val (list str "use"))
  ]
  if step = "get" [
    set val step-cost
    set lst (list itm val (list str "get"))
  ]
  if step = "buy" [
    set val step-cost
    set lst  (list itm val (list str "buy" agent))
  ]
  if step = "realise" [
    set val (step-cost + cost-of first itm-list)
    set lst (list nothing val (list "" "realise" plan-of first itm-list))
  ]
  if step = "sell" [
    set val (step-cost + cost-of first itm-list)
    set lst (list nothing val (list "" "sell" plan-of first itm-list agent))
  ]
  if step = "split-left" [
    set val (step-cost + cost-of first itm-list)  ;; assumes whole costs apply equally to both split bits !!
    set lst (list itm val (list str "split-left" plan-of first itm-list))
  ]
  if step = "split-right" [
    set val (step-cost + cost-of first itm-list) ;; assumes whole costs apply equally to both split bits !!
    set lst (list itm val (list str "split-right" plan-of first itm-list))
  ]
  if step = "join" [
    set val (step-cost + cost-of first itm-list + cost-of second itm-list)
    set lst (list itm val (list str "join" plan-of first itm-list plan-of second itm-list))
  ]
  if step = "apply" [
    set val (step-cost + cost-of second itm-list)
    set lst (list itm val (list str "apply" plan-of first itm-list plan-of second itm-list))
  ]
  let depth-plan max-depth last lst
  store-plan lst
;;  if not empty? factbase:retrieve my-plans [?1 = str and ?2 = val and (max-depth ?3 != depth-plan)] ["str" "value" "plan"] [_p]
end

to store-plan [lst] ;; [itm val plan]
  ;; ATM this stores plans however idiotic they are and however low value!!
  _db lst "" ""
  _ct lst "list"
  _ct first lst "thing"
  _ct second lst "number"
  _ct third lst "list"
  let old-plan-id 0
  let itm first lst
  let str str-of itm
  let val second lst
  let plan third lst
  let plan-hash hash plan
  let exist-plans factbase:retrieve my-plans [? = plan-hash] ["plan-hash"]
  ifelse empty? exist-plans [
    factbase:assert my-plans (list str-of itm plan-num val plan plan-hash)
    table:put plan-id-table plan-num plan
    if itm != nothing [
      put-plan-table itm plan-num
    ]
    set plan-num plan-num + 1
  ] [
    set old-plan-id second one-of exist-plans
    if itm != nothing [
      table:put plan-table name-of itm old-plan-id
      put-plan-table itm old-plan-id
    ]
  ]
  table:put cost-table name-of itm val
  if val > max-val [set max-val val]
end

to-report possible-to-do? [plan money-left item-set]
  ;; checks if a plan is possible to do before trying it
  ;; returns money after costs/value are subtracted/added and subtracts what items are left
  ;; _db "possible-to-do?" plan money-left item-set
  _ct plan "list"
  _ct money-left "number"
  _ct item-set "agentset"

  let agent nobody let tl-plan [] let tl nothing let tl-str "" let itm-plan [] let cst 0 let res []
  let itm nobody let itms no-turtles let itm-str ""

  if checks? and empty? plan [error "Empty plan given to possible-to-do?"]
  let str first plan
  let step second plan
  set money-left money-left - action-cost
  if money-left < 0 [report (list false money-left item-set)]

  ;; at moment just tries a random plan without checking if it will work before
  if member? step rand-actions [
    report (list true money-left item-set)
  ]

  let args but-first but-first plan

  ;; if step is realise directly get its value and the itm is destroyed
  if step = "realise" [   ;; str realise itm-tree
    set itm-plan first args
    set str first itm-plan
    set res possible-to-do? first args money-left item-set
    report (list first res (second res + realise-value-of str) third res)
  ]

  ;;
  if step = "sell" [ ;; str sell itm-tree agent
    set itm-plan first args
    set str first itm-plan
    set res possible-to-do? itm-plan money-left item-set
    report (list first res (second res + sale-value-of str) third res)
  ]

    ;; if step is use use an existing one
  if step = "use" [
      set itms item-set with [label = str]
      if any? itms [
        set itm one-of itms ;; do we want to include the (sunk) cost of the item?
        report (list true money-left (remove-one itm item-set))
      ]
  ]

  ;; if an itm with string str already exists use that one !!
  set itms item-set with [label = str]
  if any? itms [
    set itm one-of itms ;; do we want to include the (sunk) cost of the item?
    report (list true money-left (remove-one itm item-set))
  ]

  ;; if step is get, get one from the environment
  if step = "get" [ ;; str get
    if member? str my-resources [
      set cst table:get resource-costs str
      if money-left >= cst [
        report (list true (money-left - cst) item-set)
      ]
    ]
  ]

  ;; if step is buy, buy from agent
  if step = "buy" [ ;; str buy agent
    set agent first args
    if can-buy-from? str agent [  ;; do we want to just buy from anywhere or from a particular agent?
      ask agent [set cst buy-cost-of str]
      if money-left >= cst [
        report (list true (money-left - cst) item-set)
      ]
    ]
    ;; if we cant buy from a particular agent, do we want to check if we can buy it elsewhere?
  ]

  ;;
  if step = "split-left" or step = "split-right" [   ;; str split itm-plan
    ;; check split is possible?
    set itm-plan first args
    set itm-str first itm-plan
    if not member? "&" itm-str [
      report (list false money-left item-set)
    ]
    report possible-to-do? first args money-left item-set
  ]

  ;;
  if step = "apply" [   ;; str apply tl-tree itm-plan
    set tl-plan first args
    set tl-str first tl-plan
    set itm-plan second args
    set itm-str first itm-plan
    if not can-apply? tl-str itm-str [
      report (list false money-left item-set)
    ]
    set res possible-to-do? tl-plan money-left item-set
    if first res [
      set money-left second res
      set item-set third res

      report possible-to-do? itm-plan (money-left - tool-use-cost) item-set
    ]
  ]

  ;;
  if step = "join" [  ;; str join itm-plan itm2-plan
    set res possible-to-do? first args money-left item-set
    if first res [
      set money-left second res
      set item-set third res
      set itm-plan second args
      report possible-to-do? itm-plan money-left item-set
    ]
  ]

  ;;
  report (list false money-left item-set)
end

to-report have-item-str? [str]
  _ct str "string"
  report any? things-here with [label = str and not used?]
end

to-report can-buy-from? [str agent]
  _ct str "string"
  _ct agent "agent"
  report [not empty? factbase:retrieve for-sale [? = str] ["str"]] of agent
end

to-report can-sell-to? [itm agent]
  _ct itm "thing"
  _ct agent "agent"
  report not empty? factbase:retrieve for-sale [? = itm] ["itm"]
end

to-report got? [itm]
  _ct itm "thing"
  report member? itm things-here
end

to-report got-all? [itm-lst]
  _ct itm-lst "list"
  if is-agentset? itm-lst [set itm-lst sort itm-lst]
  foreach itm-lst [
    if not got? ? [report false]
  ]
  report true
end

to-report have-str? [str]
  _ct str "string"
  report any? things-here with [label = str]
end

to-report do-plan [plan]
  ;; recursively called on plan to enact it
  _db plan "" ""
  _ct plan "non-empty-list"
  let str first plan
  let step second plan
  let args but-first but-first plan
  let lst [] let ant "" let itm-plan [] let itm2-plan [] let itm2 nothing let others no-turtles
  let itm-lst [] let itms no-turtles let itm nothing let itm1 nothing let maxv 0 let agent nobody

  if step = "buy-random" [
    set lst sort-by [third ?1 < third ?2] factbase:retrieve can-buy [true] []
    ifelse not empty? lst [
      set maxv max map [third ?] lst
      set itm-lst rnd:weighted-one-of lst [1 / (1 + maxv - third ?)] ;; bias towards cheaper items!!
      _ra "tried to buy one of" itm-lst
      set itm second itm-lst
      set agent last itm-lst
      if empty? [factbase:retrieve for-sale [? = itm] ["itm"]] of agent [
        report nothing
      ]
      ask itm [set used? true]
      report buy str-of itm last itm-lst
    ] [
      report nothing
    ]
  ]
  if step = "get-random" [
    set str choose-one-resource-str
    ifelse str != "" [
      set itm get str
      ask itm [set used? true]
      report itm
    ]  [
      report nothing
    ]
  ]
  if step = "split-random" [
    ;; bias towards spliting long items
    set lst things-here with [not tool? and member? "&" label]  ;; note tools are not split by this
    ifelse any? lst [
      ifelse prob 0.5 [
        report split-left rnd:weighted-one-of lst [length str-of ?]
      ] [
        report split-right rnd:weighted-one-of lst [length str-of ?]
      ]
    ]  [
      report nothing
    ]
  ]
  if step = "join-random" [
  ;; biased towards joining shorter items
    ifelse count things-here with [not tool?] >= 2 [
      report join rnd:weighted-n-of 2 (sort things-here with [not tool?]) [scale (-1 * length str-of ?) 0]
    ] [
      report nothing
    ]
  ]
  if step = "apply-random" [
    set itms things-here with [tool?]
    ifelse any? itms [
      set itm one-of itms
      set ant ant-of str-of itm
      set itms things-here with [label = ant]
      ifelse any? itms [
        set ant one-of itms
        report apply itm ant
      ] [
        report nothing
      ]
    ] [
      report nothing
    ]
  ]
  if step = "realise-random" [
    set lst things-here with [member? label my-targets]
    ifelse any? lst [
      report realise one-of lst
    ] [
      report nothing
    ]
  ]
  if step = "sell-random" [
    set lst things-here with [not tool?]
    set others other agents
    if checks? and not is-agentset? others [error (word others " is not an agentset whilst trying to sell-random in do-plan!")]
    ifelse any? lst and any? others [
      set itm one-of lst
      _ra "sell-random" list itm others
      report sell-to-these itm others
    ] [
      report nothing
    ]
  ]

  ;; step - "use"
  if step = "use" [
    set lst things-here with [label = str and not used?]
    ifelse any? lst [
      set itm one-of lst
      ask itm [set used? true]
      _ra "used existing item: " itm
      report itm
    ] [
      report nothing
    ]
  ]

  ;; if have already got an item don't recurse further down but use it
  ;; but how to stop it being tried to be used twice?
  ;; does result in much cleaner inventories but leads to subtle errors as intermediate things are used in do-plan recursion!!
  ;; needs to recognise difference between items that exist before executing a plan and those produced during it
  if have-item-str? str [
    set itm one-of things-here with [label = str and not used?]
    ask itm [set used? true]
    _ra "used existing item: " itm
    report itm
  ]

  if step = "get" [ ;; str get
    set itm get str
    ask itm [set used? true]
    report itm
  ]
  if step = "buy" [ ;; str "buy" agent
    set itm buy str first args
    if itm != nothing [
     ask itm [set used? true]
    ]
    report itm
  ]

  ;; actions with an itm-plan to realise
  if checks? and empty? args [error (word "Not enough arguments for do plan " plan "!")]
  set itm-plan first args
  if first itm-plan = nothing [report nothing]
  set itm1 do-plan itm-plan
  if itm1 = nothing [report nothing]

  if step = "realise" [ ;; str "realise" itm-plan
    report realise itm1
  ]
  if step = "split-right" [  ;; str "split" itm-plan
    report split-right itm1
  ]
  if step = "split-left" [  ;; str "split" itm-plan
    report split-left itm1
  ]

  ;; actions with two additional arguments

  if checks? and length args < 2 [error (word "Not enough arguments (" args ") for do plan " plan "!")]
  if step = "sell" [ ;; str "sell" itm-plan agent
    report sell-to itm1 last args ;; sell-to needs to report nothing
  ]
  set itm2-plan last args
  if first itm2-plan = nothing [report nothing]
  ask itm1 [set used? true] ;; temporarily mark itm1 as used so it does not get prematurely used up whilst doing itm2's plan
  set itm2 do-plan itm2-plan
  ask itm1 [set used? false] ;; make itm1 available for use again in apply and join
  if itm2 = nothing [report nothing]

  if step = "apply" [ ;; str "apply" itm-plan itm2-plan
    report apply itm1 itm2
  ]
  if step = "join" [ ;; str "join" itm-plan itm2-plan
    report join (list itm1 itm2)
  ]
  error "Got to end of do plan without kind of action being processed!"
end

to-report str-choice-list
  ;;  just compiles list: str prb plan-id
  ;; used in go loop, compilies a list for speeding up choose-plans (makes the "clist")
  report map
          [(list
            first ?
            scale (third ? - (dup-discount * count things-here with [label = first ?])) max-val
            second ?)]
          but-first factbase:to-list my-plans
end

to-report choose-plans [num-th clist] ;; choose a sting in the plans then list the others
;;  _db "choose-plans" "" "" ""
  _ct num-th "number"
  let str first rnd:weighted-one-of clist [second ?]
  let alts filter [first ? = str] clist
  let num min list num-alternatives length alts
  let lst rnd:weighted-n-of num alts [second ?]
  report map [find-plan third ?] lst
;;  let str first rnd:weighted-one-of clist [second ?]
;;  let lst factbase:retrieve my-plans [? = str] ["str"]
;;  let num min list length lst num-alternatives
;;  report map [fourth ?] sort-by [third ?1 > third ?2] rnd:weighted-n-of num lst [scale third ? max-val]
end

to-report find-plan [plid]
  ;; if can store fact numbers might be able to do this faster!!
  report table:get plan-id-table plid
;;  report first factbase:retrieve my-plans [? = plid] ["id"]
end

to-report scale [nm maxv]
  report 1 / ((1 + maxv - nm) ^ choice-bias)
end

to-report my-resource? [itm]
  _ct itm "thing"
  report member? itm my-resources
end

to-report my-target? [itm]
  _ct itm "thing"
  report member? itm my-targets
end

to-report plan-of [itm]
  _db name-of itm "" ""
  _ct itm "thing"
;;  find the plan that resulted in this itm
  if checks? and itm = nothing [error "Can't find a plan of nothing!"]
  if table:has-key? plan-table name-of itm [
    let id table:get plan-table name-of itm
    let lst factbase:retrieve my-plans [? = id] ["id"]
    if checks? and empty? lst [error (word "No plan for id " id " in plan-of but is in plan-table!")]
    report fourth one-of lst
  ]
  let str str-of itm
  let lst factbase:retrieve my-plans [? = str] ["str"]
  if not empty? lst [
    report fourth one-of lst
  ]
  report list str "use"
end

to-report realise-value-of [str]
  _db str "" ""
  if is-a-thing? str [set str str-of str]
  if checks? and str = "" [error "Can't find a realise value of nothing!"]
  if not member? str my-targets [report 0]
  report table:get target-values str
end

to-report sale-value-of [str]
  ;; used by possible-to-do? sale step for estimating value
  _db str "" ""
  _ct str "non-empty-string"
  let res factbase:retrieve for-sale [? = str] ["str"]
  if not empty? res [
    report third one-of res
  ]
  if member? str my-resources [
    report (table:get resource-costs str) - 1
  ]
  report 0 ;; no known sale value
end

to-report cost-of [itm]
  _db name-of itm "" ""
  _ct itm "thing"
  if checks? and not table:has-key? cost-table name-of itm [error (word itm " is not in cost-table in cost-of!")]
  report table:get cost-table name-of itm
end

to-report buy-cost-of [str]
  _db str "" ""
  _ct str "string"
  let res sort-by [third ?1 > third ?2] factbase:retrieve for-sale [?1 = str] ["str"]
  if empty? res [report bignum] ;; should this be a negative big num?
  report third first res
end

to maybe-forget-plan
  ;; need s-curve prob of forgetting a plan, then based on value
  _db "" "" ""
  let lst [] let pln [] let str "" let id 0
  if prob s-curve (factbase:size my-plans - num-plans-remembered) 5 2 [
    set lst but-first factbase:retrieve my-plans [? < min-rand-action-val] ["value"]
    if not empty? lst [
      set pln rnd:weighted-one-of lst [scale third ? max-val]
      set id second pln
      _ra "forgotten plan" pln
      factbase:retract my-plans pln
      remove-plan-id id ;; from both plan-table and rev-plan-table
    ]
  ]
end

to-report s-curve [nm steep-before steep-after]
  ifelse nm > 0 [
    set nm steep-after * nm
  ] [
    set nm steep-before * nm
  ]
  report 1 / (1 + e ^ (-1 * nm))
end

to-report name-of-id [id]
  _db id "" ""
  _ct id "number"
  report (word "(thing " id ")=" str-of thing id)
end

;; plan-table and rev-plan-table are used to speed up choosing plans and deleting them

to put-plan-table [thg id]
  _db thg id ""
  _ct thg "thing"
  _ct id "number"
  let lst []
  table:put plan-table name-of thg id
  ifelse table:has-key? rev-plan-table id [
    set lst table:get rev-plan-table id
    if not member? name-of thg lst [
      table:put rev-plan-table id fput name-of thg lst
    ]
  ] [
    table:put rev-plan-table id (list name-of thg)
  ]
  if checks? [_check-plan-tables]
end

to remove-plan-id [id]
  _db id "" ""
  _ct id "number"
  let lst []
  if table:has-key? rev-plan-table id [
    set lst table:get rev-plan-table id
    table:remove rev-plan-table id
    foreach lst [
      table:remove plan-table ?
    ]
  ]
  if checks? [_check-plan-tables]
end

to-report isa-plan-for? [itm]
  _db name-of itm "" ""
  _ct itm "thing"
  report table:has-key? plan-table name-of itm
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; inspect/show stuff!  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to A-INSPECT-SHOW end

to it [thnm]
  inspect thing thnm
end

to ip [xc yc]
  inspect patch xc yc
end

to sp
  show "******************************************************"
  ask agents [show-plans]
end

to sfs
  show "******************************************************"
  ask agents [show-for-sale]
end

to scb
show "******************************************************"
  ask agents [show-can-buy]
end

to show-for-sale
  show word self "_______________"
  foreach sort-by [length first ?1 < length first ?2] factbase:retrieve for-sale [true] [] [
    print (word first ? " (" second ? "), value " third ?)
  ]
end

to show-can-buy
  show word self "_______________"
  foreach sort-by [length first ?1 < length first ?2] factbase:retrieve can-buy [true] [] [
    print (word first ? " (" second ? "), value " third ? " from " last ?)
  ]
end

to show-plans
  show word self "_______________"
  foreach sort-by [third ?1 > third ?2] factbase:retrieve my-plans [true] [] [
    print (word second ? " (" first ? "), value " third ? ": " fourth ?)
  ]
end

to show-things [agset]
  if is-agentset? agset [set agset sort agset]
  if empty? agset [stop]
  let f first agset
  let r but-first agset
  ifelse empty? r [
    print name-of f
  ] [
    type (word f ", ")
  ]
  show-things r
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; manipulation stuff!  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to A-STRING-MANIPULATION end

;; the string manipulations used by the actions

to-report apply-once [tool str]
  _db str tool ""
  _ct tool "string"
  _ct str "string"
  if not member? ">" tool [report str]
  let ant ant-of tool
  if not member? ant str [report str]
  let pos position ant str
  let con con-of tool
  report replace-str-once ant con str
end

to-report can-apply? [tool str]
  _db tool str ""
  _ct tool "string"
  _ct str "string"
  if not member? ">" tool [report false]
  let ant ant-of tool
  if not member? ant str [report false]
  report true
end

to-report apply-all [tool str]
  _db str tool ""
  _ct tool "string"
  _ct str "string"
  let res apply-once str tool
  if res = str [report str]
  if not member? ">" tool [report str]
  let ant ant-of tool
  if not member? ant res [report res]
  report apply-all tool res
end

to-report ant-of [str]
  _db str "" ""
  if not member? ">" str [report ""]
  let pos position ">" str
  report substring str 0 pos
end

to-report con-of [str]
  _db str "" ""
  _ct str "string"
  if checks? and not member? ">" str [error (word "No > symbol in " str "!")]
  let pos position ">" str
  report substring str (pos + 1) length str
end

to-report join-str [str-list]
;;  _db "join-str" str-list "" ""
  _ct str-list "non-empty-list"
  if length str-list < 2 [report first str-list]
  report (word
            first str-list
            "&"
            join-str but-first str-list)
end

to-report split-once [str]
  _db str "" ""
  _ct str "string"
  if empty? str [report (list "")]
  if not member? "&" str [report (list str)]
  if length str = 1 [report ""]
  let pos position "&" str
  if pos = 0 [report (list but-first str)]
  let len length str
  if pos >= len - 1 [report (list but-last str)]
  report list
           substring str 0 pos
           substring str (pos + 1) length str
end

to-report split-all [str]
  _db str "" ""
  _ct str "string"
  if str = "" [report []]
  if not member? "&" str [report (list str)]
  let res-list split-once str
  if empty? res-list [report []]
  if length res-list < 2 [report split-all first res-list]
  report flatten sentence
           split-all first res-list
           map [split-all ?] but-first res-list
end

to-report disp [str]
;;  _db "disp" str "" ""
  _ct str "string"
  if empty? str [report ""]
  report strip-ends remove " " (word flatten str)
end

to-report disp-list [str-list]
;;  _db "disp-list" str-list "" ""
  if is-string? str-list [report str-list]
  if empty? str-list [report ""]
  if length str-list < 2 [report disp first str-list]
  report disp-list (word disp first str-list disp-list "; " disp-list but-first str-list)
end

;;;;;;;;;;;;;;;;;
;; THING stuff ;;
;;;;;;;;;;;;;;;;;
to A-THING end

;; things are agents, below are properties for using them

to-report items
  report things-here with [not tool?]
end

to-report tools
  report things-here with [tool?]
end

to-report nothing
  report nobody ;; syntactic sugar for the null item
end

to disp-thing
;;  _db "display-thing" self "" ""
   let am 0.45
   set color item (position disp-type action-types) disp-cols
   ifelse tool? [
     set shape "x"
     set size 0.075
     setxy
       pxcor + 1 / 6 + random-float (am * 2 / 3)
       pycor - 1 / 6 + random-float (am * 4 / 3)
   ] [
     set shape "circle"
     set size 0.05
     setxy
       pxcor - random-float am
       pycor - am + random-float (am * 2)
   ]
end

to-report str-of [itm]
  if itm = nothing [report ""]
  report [label] of itm
end

to set-str [itm str]
  ask itm [
    set label str
  ]
end

to lose-item [itm]
  _db name-of itm "" ""
  _ct itm "thing"
  if checks? and itm = nobody [error "You can't lose nothing!"]
  factbase:retract-all for-sale [? = itm] ["itm"] ;; (word "itm == \"" name-of itm "\"")
  ask itm [die]
end

to lose-items [lst]
  _db lst "" ""
  _ct lst "list"
  foreach lst [lose-item ?]
end

to-report make-items [lst kind]
  _db lst kind ""
  _ct lst "list"
  _ct kind "action"
  if empty? lst [report lst]
  report map [make-item ? kind] lst
end

to-report make-item [str kind]
  _db str "" ""
  _ct str "string"
  _ct kind "action"
  let itm nobody
  if str = "" [report nothing]
  let t? member? ">" str
  sprout-things 1 [
    set label str
    set tool? t?
    set used? false
    set disp-type kind
    set itm self
    move-to myself
    disp-thing
  ]
  addto-str-table str itm
  report itm
end

to addto-str-table [str itm]
  _db str itm ""
  _ct str "string"
  _ct itm "thing"
  ifelse table:has-key? str-table str [
    let lst table:get str-table str
    if not member? itm lst [
      table:put str-table str fput itm lst
    ]
  ] [
    table:put str-table str (list itm)
  ]
end

to-report is-a-thing? [itm]
  report is-thing? itm or itm = nothing
end

to-report name-of [itm]
  _ct itm "thing"
  if itm = nothing [
    report "nothing"
  ]
  report [(word self "=" label)] of itm
end

to-report names-of [agent-set]
  ;;  _db "names-of" agent-set "" ""
  if is-agentset? agent-set
    [set agent-set sort agent-set]
  if agent-set = [] [report "[]"]
  let op "["
  if not empty? agent-set [
    foreach but-last agent-set [
      set op (word name-of ? " " op)
    ]
    set op word op name-of last agent-set
  ]
  report word op "]"
end

;;;;;;;;;;;;;;;;;
;; stats stuff ;;
;;;;;;;;;;;;;;;;;
to A-STATS end

;; statistics only done if stats? is set to true

to do-agent-stats
  _db "" "" ""
  set num-things count things-here
  set num-tools count things-here with [tool?]
  ifelse any? things-here [
    set num-distinct-things length remove-duplicates [label] of things-here
    set av-length mean [length label] of things-here
  ] [
    set num-distinct-things 0
    set av-length 0
  ]
  set num-plans factbase:size my-plans
  set num-for-sale factbase:size for-sale
  set max-plan-value third first sort-by [third ?1 > third ?2] factbase:retrieve my-plans [true] []
  set income money - last-money
end

to make-stats-lists
  _db "" "" ""
  set num-things-list [num-things] of agents
  set num-tools-list [num-tools] of agents
  set num-distinct-things-list [num-distinct-things] of agents
  set av-length-list [av-length] of agents
  set num-get-list [num-get] of agents
  set num-buy-list [num-buy] of agents
  set num-sell-list [num-sell] of agents
  set num-join-list [num-join] of agents
  set num-split-left-list [num-split-left] of agents
  set num-split-right-list [num-split-right] of agents
  set num-apply-list [num-apply] of agents
  set num-realise-list [num-realise] of agents
  set num-plans-list [num-plans] of agents
  set num-for-sale-list [num-for-sale] of agents
  set max-plan-value-list [max-plan-value] of agents
  set income-list [income] of agents
  set money-list [money] of agents
end

to zero-stats
  _db "" "" ""
  set num-things 0
  set num-tools 0
  set num-distinct-things 0
  set av-length 0
  set num-get 0
  set num-buy 0
  set num-sell 0
  set num-join 0
  set num-split-left 0
  set num-split-right 0
  set num-apply 0
  set num-realise 0
  set num-plans 0
  set num-for-sale 0
  set max-plan-value 0
  set income 0
end

to-report av [lst]
  if not is-list? lst [report 0]
  if empty? lst [report 0]
  report mean lst
end

to-report sd [lst]
  if not is-list? lst [report 0]
  if length lst < 2 [report 0]
  report standard-deviation lst
end

to ss
  show num-things-list
  show num-tools-list
  show num-distinct-things-list
  show av-length-list
  show num-get-list
  show num-buy-list
  show num-sell-list
  show num-join-list
  show num-split-left-list
  show num-split-right-list
  show num-apply-list
  show num-realise-list
  show num-plans-list
  show num-for-sale-list
  show max-plan-value-list
  show income-list
  show money-list
end

;;;;;;;;;;;;;;;;;;;;;
;; debugging stuff ;;
;;;;;;;;;;;;;;;;;;;;;
to A-DEBUG end

;; procedures to aid debugging, added into code where needed

to _ct [val typen]
  ;; checks type of arguments but only if "checks?" is true/on
  if not checks? [stop]
  let types-checked ["string" "number" "thing" "action" "agent" "list" "agentset" "non-empty-list" "non-empty-string"]
  ;; but check own arguments first :-)
  if not is-string? typen [_te typen "string"]
  if not member? typen types-checked [_te val "checked type"]
  ;; now other checking
  if typen = "string" [if not is-string? val [_te val typen]]
  if typen = "number" [if not is-number? val [_te val typen]]
  if typen = "thing" [if not is-a-thing? val [_te val typen]]
  if typen = "action" [if not member? val action-types [_te val typen]]
  if typen = "agent" [if not member? val agents [_te val typen]]
  if typen = "list" [if not is-list? val [_te val typen]]
  if typen = "agentset" [if not is-agentset? val [_te val typen]]
  if typen = "non-empty-list" [
    _ct val "list"
    if empty? val [_te val typen]
  ]
  if typen = "non-empty-string" [
    _ct val "string"
    if val = "" [_te val typen]
  ]
;;  if typen = "kind" [if not member? val XX []]
end

to _te [val typen ]
  ;; used by _ct as a generic error message to shorten its code
  error (word val " is not of type " typen " in procedure " third reflection:callers "!")
end

to _ra [action itm]
  ;; reports an action on the output
  if not trace? or _not_show? [stop]
  let tck 0 let id ""
  carefully [set tck ticks] [set tck "set-up"]
  carefully [set id (word runresult "self")] [set id "Observer"]
  let op (word "*** " id " at " tck " has " action " " itm)
  if (blank? filter-string) or (member? filter-string op) [output-print op]
end

to _db [arg1 arg2 arg3]
  ;; debugging - allows reporting of calling of procedures with (up to three args) to show on output when selected
  if not debug? or _not_show? [stop]
  let tck 0 let id "" let caller ""
  carefully [set tck ticks] [set tck "set-up"]
  carefully [set id (word runresult "self")] [set id "Observer"]
  carefully [set caller string:lower-case (word third reflection:callers)] [set caller "the command line"]
  let op (word id " at " tck " called from " caller ": " second reflection:callers " " arg1 " " arg2 " " arg3)
  if (blank? filter-string) or (member? filter-string op) [output-print op]
end

to _p
  ;; useful for inserting a pause into code, but only works when pause? is on
  if pause? and (not user-yes-or-no? "Continue?" or _not_show?) [ error "Simulation halted by user!" ]
end

to-report _sp [vl]
  ;; transparently reports a value to the output
  let tck 0 let id ""
  carefully [set tck ticks] [set tck "set-up"]
  carefully [set id (word runresult "self")] [set id "Observer"]
  let op (word "--> " id " at " tck ": value passed was: " vl)
  if (blank? filter-string) or (member? filter-string op) [output-print op]
  report vl
end

to-report _spt [vl]
  ;; transparently reports a thing to the output
  let tck 0 let id "" let op ""
  if not is-a-thing? vl [error (word vl " is not a thing in _spt!")]
  carefully [set tck ticks] [set tck "set-up"]
  carefully [set id (word runresult "self")] [set id "Observer"]
  ifelse vl = nothing [
    set op (word "--> " id " at " tck ": thing passed was: " vl)
  ] [
    set op (word "--> " id " at " tck ": thing passed was: " vl " with st ring " str-of vl " and value " cost-of vl)
  ]
  if (blank? filter-string) or (member? filter-string op) [output-print op]
  report vl
end

to-report _spno [vl]
  ;; transparently reports the name-of a thing to the output
  let tck 0 let id ""
  carefully [set tck ticks] [set tck "set-up"]
  carefully [set id (word runresult "self")] [set id "Observer"]
  let op (word "--> " id " at " tck ": value passed was: " name-of vl)
  if (blank? filter-string) or (member? filter-string op) [output-print op]
  report vl
end

to _m [str]
  ;; outputs a set message to the output
  output-print str
end

to _do-checks
  ;; some consistency checks that are done each tick if checks? is true
  if not checks? and _not_show? [stop]
  ask agents [
    foreach map [second ?] factbase:retrieve for-sale [true] [] [
      if not member? ? things-here [error (word ? " is for sale but patch does not have it!")]
    ]
    _check-plan-tables
  ]
end

to _check-plan-tables
  ;; check consistency of plan-table and rev-plan-table
  let anid 0
  foreach table:keys rev-plan-table [
    set anid ?
    if not factbase:exists? my-plans [?1 = anid] ["id"] [error (word "Plan id " anid " is in rev-plan-table but not in myplans!")]
    foreach table:get rev-plan-table anid [
      if not member? ? table:keys plan-table [error (word "Thing " ? " is a value in rev-plan-table but not a key of plan-table!")]
    ]
  ]
  foreach table:keys plan-table [
    set anid  table:get plan-table ?
    if not member? anid table:keys rev-plan-table [error (word "Id " anid " is a value of plan-table but not a key of rev-plan-table!")]
  ]
end

to-report _fstub
  error "_fstub called but it's just a reporter stub!"
  report 0
end

to _stub
  error "_stub called but it's just an action stub!"
end

to-report _not_show?
  report aft-go? and _before-setup?
end

to-report _before-setup?
  let t 0
  carefully [set t ticks] [set t -1]
  report t < 0
end

;;;;;;;;;;;;;;;;;;;;;;;
;; general utilities ;;
;;;;;;;;;;;;;;;;;;;;;;;
to A-GEN_UTILS end

;; standard utilities imported in for use in code

to-report blank? [str]
  report string:trim str = ""
end

to-report hash [val]
  ;; reports a hash value for the object (or strictly the printed form of the object)
  report string:hash-code (word val)
end

to-report max-depth [tree]
  ;; reports maximum depth of tree, non-lists are 0, empty list 1 etc.
  if not is-list? tree [report 0]
  if empty? tree [report 1]
  report 1 + max map [max-depth ?] tree
end

to-report all-members? [lst1 lst2]
  ;; checks if all members of lst1 are in lst2
  if empty? lst2 [report false]
  if empty? lst1 [report true]
  if not member? first lst1 lst2 [report false]
  report all-members? but-first lst1 remove-one first lst1 lst2
end

to-report check-col-adj
  ;; for "checkerboarding" patches
  report (pxcor + pycor) mod 2
end

to-report remove-one [itm lst]
  ;; removes one itm from the lst
  _db itm lst ""
  if is-list? lst [
    if not member? itm lst [report lst]
    report remove-item (position itm lst) lst
  ]
  if is-agentset? lst [
    if not member? itm lst [report lst]
    report lst with [self != itm]
  ]
  error (word lst " is not a list of agentset in remove-one!")
end

to-report replace-str-once [targ repl str]
  ;; reports a list where all occurences of targ are replaced with repl within str
  _db targ repl str
  if targ = "" [error (word "Cant replace null label in: replace-str-once " targ " " repl " " str "!")]
  if length str < length targ [report str]
  if not member? targ str [report str]
  let pos position targ str
  report (word
            substring str 0 pos
            repl
            substring str (pos + length targ) length str)
end

to-report insert [itm pos str]
  ;; reports a list where itm is inserted at position pos in str
  _db itm pos str
  report (word
            substring str 0 pos
            itm
            substring str pos length str)
end

to-report subset [str]
  ;; reports a string with probibilistically missing letters (on average missing one letter)
  _db str "" ""
  let len length str
  report str-filter ((len - 1) / len) str
end

to-report str-filter [prb str]
  ;; reports a string where each letter retained with probablity prb
  _db prb str ""
  if str ="" [report ""]
  ifelse prob prb
    [report word first str str-filter prb but-first str]
    [report str-filter prb but-first str]
end

to-report shuffle-str [str]
  ;; shuffles a string
  report string:from-list shuffle string:explode str
end

to-report delete [pos str]
  ;; reports a string where the item at position pos is removed
  _db pos str ""
  if pos < 0 or pos > length str - 1 [report str]
  report (word
            substring str 0 pos
            substring str (pos + 1) length str)
end

to-report union [lst1 lst2]
  ;; forms the union of two lists without repeats
  _db lst1 lst2 ""
  report remove-duplicates sentence lst1 lst2
end

to-report intersect [lst1 lst2]
  ;; reports the list of those in both lists
  _db lst1 lst2 ""
  ifelse length lst2 < length lst1
    [report intersect0 lst2 lst1]
    [report intersect0 lst1 lst2]
end

;; used by intersect
;; might be less inefficient if lst2 is much shorter than lst1
to-report intersect0 [lst1 lst2]
  if empty? lst1 [report []]
  ifelse member? first lst1 lst2
    [report fput first lst1 intersect0 but-first lst1 lst2]
    [report intersect0 but-first lst1 lst2]
end

to-report prob [num]
  ;; returns value "TRUE" with probability determined by input
  report random-float 1 < num
end

to spread
  ;; used to randomly shift items around within the patch
  let am 0.45
  setxy
    pxcor - am + random-float (am * 2)
    pycor - am + random-float (am * 2)
end

to-report remove-list [lis rem-lis]
  ;; removes all items in lis from rem-lis
  _db lis rem-lis ""
  if empty? rem-lis [report lis]
  report remove first rem-lis (remove-list lis but-first rem-lis)
end

to-report second [ls]
  ;; reports the second in the list
  report first but-first ls
end

to-report third [ls]
  ;; reports the third in the list
  report first but-first but-first ls
end

to-report fourth [lst]
  ;; reports the fourth in the list
  report item 3 lst
end

to-report flatten [lst]
  ;; flattens complex lists of lists to just a list of leaf items
  if empty? lst [report []]
  ifelse is-list? first lst
    [report sentence flatten first lst flatten but-first lst]
    [report sentence first lst flatten but-first lst]
end

to-report strip-ends [str]
  ;; removes first and last characters
  if length str < 2 [report str]
  report but-first but-last str
end
@#$#@#$#@
GRAPHICS-WINDOW
184
11
694
542
-1
-1
250.0
1
9
1
1
1
0
0
0
1
0
1
0
1
1
1
1
ticks
30.0

BUTTON
122
11
177
44
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
6
10
61
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
64
11
119
44
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
696
12
787
45
debug?
debug?
1
1
-1000

SLIDER
6
47
178
80
num-agents
num-agents
1
100
4
1
1
NIL
HORIZONTAL

SLIDER
6
116
178
149
num-resources
num-resources
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
6
151
178
184
cost-resources
cost-resources
0
10
3
1
1
NIL
HORIZONTAL

SLIDER
6
327
178
360
num-targets
num-targets
0
100
50
1
1
NIL
HORIZONTAL

SLIDER
6
362
178
395
value-targets
value-targets
0
10
4
1
1
NIL
HORIZONTAL

SLIDER
5
434
177
467
prop-targets-each
prop-targets-each
0
1
0.66
0.01
1
NIL
HORIZONTAL

SLIDER
697
477
817
510
max-tries
max-tries
1
20
20
1
1
NIL
HORIZONTAL

SLIDER
698
512
817
545
num-alternatives
num-alternatives
1
10
2
1
1
NIL
HORIZONTAL

SLIDER
4
186
178
219
len-resources
len-resources
1
10
2
0.5
1
NIL
HORIZONTAL

SLIDER
5
398
177
431
len-targets
len-targets
1
20
5
1
1
NIL
HORIZONTAL

SLIDER
6
81
178
114
num-elements
num-elements
1
26
2
1
1
NIL
HORIZONTAL

MONITOR
954
10
1251
55
resources
resources-disp
0
1
11

MONITOR
954
63
1250
108
targets
targets-disp
0
1
11

SLIDER
6
256
178
289
prop-breaks
prop-breaks
0
1
0.4
0.01
1
NIL
HORIZONTAL

SLIDER
6
291
178
324
prop-nat-tools
prop-nat-tools
0
1
0.25
0.01
1
NIL
HORIZONTAL

SWITCH
696
46
787
79
trace?
trace?
1
1
-1000

OUTPUT
697
115
1249
472
13

BUTTON
883
78
950
111
Clear
clear-output
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
820
478
940
511
tool-use-cost
tool-use-cost
0
10
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
5
221
177
254
prop-resources-each
prop-resources-each
0
1
0.66
0.01
1
NIL
HORIZONTAL

SWITCH
696
80
799
113
stats?
stats?
1
1
-1000

SWITCH
788
46
878
79
checks?
checks?
1
1
-1000

INPUTBOX
880
12
951
72
filter-string
NIL
1
0
String

SWITCH
789
12
879
45
aft-go?
aft-go?
0
1
-1000

SLIDER
819
512
940
545
choice-bias
choice-bias
0
4
1.5
0.1
1
NIL
HORIZONTAL

SLIDER
942
512
1057
545
action-cost
action-cost
0
0.5
0.25
0.01
1
NIL
HORIZONTAL

SWITCH
788
80
878
113
pause?
pause?
1
1
-1000

INPUTBOX
1123
474
1186
534
max-time
0
1
0
Number

MONITOR
1189
474
1246
519
Num.Th.
count things
0
1
11

SLIDER
942
478
1057
511
dup-discount
dup-discount
0
5
1.5
0.1
1
NIL
HORIZONTAL

MONITOR
1060
476
1117
521
s/tick
av-secs
3
1
11

SLIDER
5
469
178
502
num-plans-remembered
num-plans-remembered
10
100
40
1
1
NIL
HORIZONTAL

@#$#@#$#@
# A Model of Making

The purpose of this model is to provide the simulation infrastructure needed in order to model the activity of making. That is individuals using resources they can find in their environment plus other things that other individuals might sell or give them, to design, construct and deconstruct items, some of which will be of direct use to themselves, some of which they might sell or give to others and some of which might be used as a tool to help in these activities. It explicitly represents plans and complex objects as separate entities in the model – embedding the “Atoms – Bits” distinction highlighted within the DiDIY project. This allows plans to be shared between agents which give the steps of how to make objects of use – either on a commercial or a free basis.

The framework is intended as a basis upon which many, more specific, models could be constructed, allowing the exploration of a variety of “what if” or counterfactual possibilities and thus give a concrete but dynamic and complex instantiation of the issues and situations discussed within the DiDIY project. In a sense this model is a “bits” representation of the ideas discussed – hopefully these will converge!

## CREDITS AND REFERENCES

Designed and implemented by Bruce Edmonds, Centre for Policy Modelling, Manchester Metropolitan University (http://cfpm.org)

This code of this model and this documentation are freely available [1]. Netlogo to run it is freely available at [2] and the necessary extensions at [3]. Some slides introducing the model [4].

The model was developed under the DiDIY Project funded from the European Union’s Horizon  2020 research and innovation programme under grant agreement No 644344. The views expressed in this paper do not necessarily reflect the views of the EC. More information about this project can be found at http://didiy.eu

### References
1. Edmonds, Bruce (2016). "A Model of Making". CoMSES Computational Model Library. Retrieved from: http://www.openabm.org/model/4871
1. Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.
1. Netlogo Extensions, http://github.com/NetLogo/NetLogo/wiki/Extensions, accessed 5th Feb 2016.
1. Edmonds, B. (2016) A Model of Making, Slides from the DiDIY Project meeting, Thessaloniki, Greece. http://slideshare.net/BruceEdmonds/a-model-of-making
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="base" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>av num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>av money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="base 10" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="num-agents" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-agents" first="1" step="1" last="16"/>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="action-cost" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <steppedValueSet variable="action-cost" first="0" step="0.125" last="2"/>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="choice-bias" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="choice-bias" first="0.5" step="0.25" last="3"/>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="cost resources" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="cost-resources" first="0" step="0.5" last="5"/>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="len resources" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="cost-resources" first="0" step="0.5" last="4"/>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="len targets" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="len-targets" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-tries">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="max tries" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>av num-things-list</metric>
    <metric>sd num-things-list</metric>
    <metric>av num-tools-list</metric>
    <metric>sd num-tools-list</metric>
    <metric>av num-distinct-things-list</metric>
    <metric>sd num-distinct-things-list</metric>
    <metric>av av-length-list</metric>
    <metric>sd av-length-list</metric>
    <metric>av num-get-list</metric>
    <metric>sd num-get-list</metric>
    <metric>av num-buy-list</metric>
    <metric>sd num-buy-list</metric>
    <metric>av num-sell-list</metric>
    <metric>sd num-sell-list</metric>
    <metric>av num-join-list</metric>
    <metric>sd num-join-list</metric>
    <metric>av num-split-left-list</metric>
    <metric>sd num-split-left-list</metric>
    <metric>av num-split-right-list</metric>
    <metric>sd num-split-right-list</metric>
    <metric>av num-apply-list</metric>
    <metric>sd num-apply-list</metric>
    <metric>av num-realise-list</metric>
    <metric>sd num-realise-list</metric>
    <metric>av num-plans-list</metric>
    <metric>sd num-plans-list</metric>
    <metric>av num-for-sale-list</metric>
    <metric>sd num-for-sale-list</metric>
    <metric>av max-plan-value-list</metric>
    <metric>sd max-plan-value-list</metric>
    <metric>av income-list</metric>
    <metric>sd income-list</metric>
    <metric>av money-list</metric>
    <metric>sd money-list</metric>
    <enumeratedValueSet variable="action-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="aft-go?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="av-income">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="choice-bias">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter-string">
      <value value="&quot;&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filter?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-resources">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="len-targets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-time">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-tries" first="2" step="2" last="40"/>
    <enumeratedValueSet variable="nat-tool-premium">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-alternatives">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elements">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-resources">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-targets">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pause?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-breaks">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-nat-tools">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-resources-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-targets-each">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="storage-cost">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tool-use-cost">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trace?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="value-targets">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
