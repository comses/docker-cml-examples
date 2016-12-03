extensions [r]
;;Required files: _normalAnnualWDischarge.txt, _maxWaterDemand.txt, _minWaterDemand.txt, _seqDemand.txt, _seqMinDemand.txt, _WaterDemand.txt,  

globals [
  x
  alpha                ; parameter of the yield function
  AnnualWDischarge
  normalAnnualWDischarge    ; daily water discharge (m3/sec) in one year     
  ava-wdischarge       ; wdischarge available for each sector
  avggini              ; gini coefficient
  beta                 ; parameter of the yield function
  current-demand       ; water demand
  eva                  ; evapotranspiration/leakage/seepage (m2/s)  
  gini-index-reserve   ; gini coefficient
  ipolicy              ; irrigation policy selected by adaptive agents
  oldipolicy           ; irrigation strategy the time step befor
  maxflow              ; maximum water flow in a normal year (m3/day)
  max-wdemand          ; maximum water demand
  min-wdemand          ; minimum water demand
  normaldischarge      ; water discharge (m3/sec) in one day
  pBreak               ; probability that the irrigation infrastructure will break
  repairflow           ; flow during the period the infrastructure is being repaired in the shock scenario 
  seqwdemand           ; water demand used in the sequential scenario
  seqminwdemand        ; water demand used in the optimized sequential scenario
  s1
  s2 
  s3
  s4
  s5
  switch
  time-shock           ; time step in which the cannal breaks
  totwdischarge        ; wdischarge
  totyield1            ; yield during stage 1
  totyield2            ; yield during stage 2
  totyield3            ; yield during stage 3
  totyield4            ; yield during stage 4
  totyield             ; total yield of six irrigation sectors
  wdemand              ; water demand
  wdischarge           ; actual water discharge (m3/day) in one day
  wreduction           ; water flow reduction perceived by agents
  wuse                 ; water used per time (m3/s) to irrigate a section 
]

turtles-own [
  area                 ; area of the sections (m2)
  cumwstress           ; cumulative water stress
  cumwstress1          ; cumulative water stress during stage 1 of the irrigation season
  cumwstress2          ; cumulative water stress during stage 2 of the irrigation season
  cumwstress3          ; cumulative water stress during stage 3 of the irrigation season
  cumwstress4          ; cumulative water stress during stage 4 of the irrigation season  
  diswater             ; distance to water source (m)
  irrigation-turn      ; turn to irrigate in the 12-hour and 24-hour policy
  myflow               ; water flow through the gates
  old-wheight          ; water height in the previous time step
  satisfied?           ; satisfied sectors
  yield                ; yield of each sector
  usedflow             ; water flow used by each irrigation sector
  wheight              ; water height (mm)
  wneed                ; water need each time step
  wstress1             ; water stress during stage 1 of the irrigation season
  wstress2             ; water stress during stage 2 of the irrigation season
  wstress3             ; water stress during stage 3 of the irrigation season
  wstress4             ; water stress during stage 4 of the irrigation season
] 

links-own [
  flow                 ; water discharge (m3/s)
]

to setup
  __clear-all-and-reset-ticks
  set s1 1 set s2 14 set s3 68 set s4 106 set s5 130 ; start of each stage
  set repairflow []
  set Time-shock 0
  set x 0
  set eva 0.02 
  set ava-wdischarge 0
  set wreduction 0
  set ipolicy "Open Flow"
  set avggini 0
  set maxflow 15.4703 ;maximum flow in a normal year (normalAnnualWDischarge) with adequate units
  set time-shock 0
  import-data  
  rain
  setup-sectors
  setup-canals
  update-outputs
  set-current-plot "Water Discharge"
  let m 0
  while [m < length annualWDischarge ] 
    [
      set-current-plot-pen "Current" plot item m annualWDischarge 
      set-current-plot-pen "Normal" plot item m normalAnnualWDischarge
      set m m + 1
    ] 
end

to setup-sectors
  set-default-shape turtles "square"
  crt 6 [
    set color white
    set label who + 1
    set area 11.67 * 10000 ; m2 ;; all the sectors have the same area
    set myflow 0
    set cumwstress 0
    set satisfied? false   
    set yield 0
    set wheight 0
    set irrigation-turn [0]    
    ask turtle 0 [ setxy min-pxcor + 1 0] 
    ask turtle 1 [ setxy min-pxcor + 3 0]
    ask turtle 2 [ setxy min-pxcor + 5 0]
    ask turtle 3 [ setxy min-pxcor + 7 0]
    ask turtle 4 [ setxy min-pxcor + 9 0]
    ask turtle 5 [ setxy min-pxcor + 11 0]
  ]
end

to setup-canals
  ask turtle 0 [ create-link-with turtle 1 ]
  ask turtle 1 [ create-link-with turtle 2 ]
  ask turtle 2 [ create-link-with turtle 3 ]
  ask turtle 3 [ create-link-with turtle 4 ]
  ask turtle 4 [ create-link-with turtle 5 ] 
  ask links [
    set flow 0
    set thickness  0.1
    set color gray
  ]
end

to go
  tick
  if ticks = 130 [ stop ] 
  calculate-wdischarge  
  calculate-pBreak
  determine-water-scarcity
  select-policy
  define-irrigation-turn
  determine-water-demand
  use-water
  irrigate
  calculate-water-stress
  calculate-yield
  calculate-gini
  ;; update view   
  ask turtles [set color scale-color blue wheight 300 30]
  update-outputs
end

to rain
  ;;Generate water discharge in R
  r:put "meanflow" 235 + Shift
  r:put "sdflow" sdflow
  r:eval "sim<-dnorm((1:365),mean=meanflow,sd=sdflow)"
  r:eval "minsim<-min(sim)"
  r:eval "sim<-0.7439 + (sim - minsim) * 1291.976" ; 1291.976 is the increment. 0.7439 is the minimum water flow in the river
  r:eval "sim<-sim[166:295]" ; Irrigation season (from June 15th to October 22th)
  set AnnualWDischarge r:get "sim" 
end

to calculate-wdischarge
  ;;Water discharge in a typical year 
  set normaldischarge (item (ticks ) normalAnnualWDischarge ) ; dayly water discharge with any reduction
  if normaldischarge > 6 [set normaldischarge 6] ; 6 is the maximum discharge that flows through the cannals
  set normaldischarge normaldischarge * 0.1 * 24 * 3600 ; discharge in m3/day/100 m

  ;;Actual water discharge   
  set wdischarge (item (ticks ) AnnualWDischarge ) ; dayly water discharge with any reduction
  if wdischarge > 6 [set wdischarge 6] ; 6 is the maximum discharge that flows through the cannals
  set wdischarge wdischarge * 0.1 * 24 * 3600 ; discharge in m3/day/100 m

  set wdischarge wdischarge - wdischarge * Discharge-reduction ; nominal flow is reduced Discharge-reduction 
  if wdischarge < 0 [set wdischarge 0]
  if wdischarge > 51840 [set wdischarge 51840]
end

to calculate-pBreak ;washout in the main water diversion structures
  let incflow (item (ticks ) AnnualWDischarge ) - maxflow      
  set pBreak 1 / (1 + exp(- incflow )) ; probability of a washout follows a sigmoid function
  if x < 1 [ ; cannals break once a year
    if pBreak > random-float 1 [
      set Time-shock ticks
      set x 1
      let fin 0
      ; after the necessary time to repair the cannal (5 or 8 days) is reached, flow increases steadily and by the 20th day, the canal flow is restored to the nominal flow capacity (0.6)
      ifelse shift >= 0 [set fin item (Shift + 20 ) AnnualWDischarge * 10 ] [set fin item (-1 * Shift + 20 ) AnnualWDischarge * 10 ]      
      if fin > 6 [set fin 6]
      let inte fin / (20 - Time-repair)
      let teller 0
      while [teller <= 20 - Time-repair] [ 
        set repairflow lput (inte * teller) repairflow
        set teller teller + 1
      ]
    ]
  ]
  if (ticks - Time-shock - Time-repair) < length repairflow [
    if Time-shock > 0 [
      ifelse ticks - Time-shock < Time-repair [
        set wdischarge 0
      ]
      [
        set wdischarge item (ticks - Time-shock - Time-repair ) repairflow 
        if wdischarge > 6 [set wdischarge 6] 
        set wdischarge wdischarge * 0.1 * 24 * 3600 
        set wdischarge wdischarge - wdischarge * Discharge-reduction 
        if wdischarge < 0 [set wdischarge 0]
        if wdischarge > 51840 [set wdischarge 51840]    
      ] ]
  ]   
end

to determine-water-demand 
  if ipolicy = "Sequential" or ipolicy = "24 Hour rotation" or ipolicy = "12 Hour rotation" [set current-demand item (ticks ) seqwdemand]
  if ipolicy = "Open Flow" [set current-demand item (ticks ) wdemand] 
  ask turtle 0 [ ifelse ipolicy = "Open Flow"[set diswater 366.6670] [set diswater 950]]; in OpenFlow diswater + 700 / 6
  ask turtle 1 [ ifelse ipolicy = "Open Flow"[set diswater 211.6670] [set diswater 950]]
  ask turtle 2 [ ifelse ipolicy = "Open Flow"[set diswater 711.6667] [set diswater 1450]]
  ask turtle 3 [ ifelse ipolicy = "Open Flow"[set diswater 211.6667] [set diswater 950]]
  ask turtle 4 [ ifelse ipolicy = "Open Flow"[set diswater 536.6667] [set diswater 1200]]
  ask turtle 5 [ ifelse ipolicy = "Open Flow"[set diswater 711.6667] [set diswater 1450]]
end

to determine-water-scarcity   ;; Agents perceive water scarcity
  set wreduction 1 - wdischarge / normaldischarge
  if wreduction < 0 [set wreduction 0]  
end

to select-policy ;; Agents select the irrigation strategy
  set oldipolicy ipolicy
  ifelse time-shock > 0 [
    let teller 0
    while [teller <= 20 - Time-repair] [
      ifelse Time-repair <= 5
        [set ipolicy "12 Hour rotation"]
        [set ipolicy "24 Hour rotation"]
      set teller teller + 1
    ]
    if ticks > time-shock + 20 + Time-repair [
      ifelse wreduction <= 0.6 
        [set ipolicy "Open Flow"]      
        [set ipolicy "Sequential"]
    ] 
  ]
  [
    ifelse wreduction <= 0.6 
      [set ipolicy "Open Flow"]      
      [set ipolicy "Sequential"]  
  ] 
  if ipolicy != oldipolicy [set switch switch + 1]
end

to use-water ; water is evaporated
  ask turtles [              
    set old-wheight wheight
    if old-wheight >= current-demand [set wneed 0]
    set wneed 0
    set wneed wneed + current-demand - old-wheight 
    if wneed < 0 [set wneed 0]
    set wheight wheight - wheight * eva 
    if wheight < 0 [set wheight 0]
  ]  
end
    
to irrigate        
  if ipolicy = "Open Flow" [
    foreach [0 1 2 3 4 5] [ 
      ask turtles with [who = ?] [
        set ava-wdischarge wdischarge / 6 ; water is equally shared by the 6 sectors 
        if ava-wdischarge < 0 [set ava-wdischarge 0]        
        set myflow ava-wdischarge
          if myflow < 0 [set myflow 0]
          set old-wheight wheight
          set wheight old-wheight + myflow / area * 1000
          if wheight > current-demand [set wheight current-demand ] 
          set usedflow (wheight - old-wheight) * area * 1000 
          if usedflow < 0 [set usedflow 0]
          set ava-wdischarge ava-wdischarge - usedflow
          if ava-wdischarge < 0 [set ava-wdischarge 0]
      ]
    ]
  ]
  
  ;;24 and 12 hour rotation policy
  if ipolicy = "24 Hour rotation"  or ipolicy = "12 Hour rotation" [ 
    set wuse 0
    foreach [0 1 2 3 4 5] [ 
      ask turtles with [who = ?] [
        ifelse (item (ticks) irrigation-turn) = 1 [
          ifelse ipolicy = "12 Hour rotation" [set ava-wdischarge wdischarge / 2 - wuse] [set ava-wdischarge wdischarge - wuse] 
          if ava-wdischarge < 0 [set ava-wdischarge 0]     
          set myflow ava-wdischarge 
          if myflow < 0 [set myflow 0]
          ifelse wneed > 0 [
            set wheight old-wheight + myflow / area * 1000
            if wheight > current-demand [set wheight current-demand ]         
            ifelse wheight > old-wheight [set usedflow (wheight - old-wheight) * area / 1000 ] [set usedflow 0]
            if usedflow < 0 [set usedflow 0]
            set ava-wdischarge ava-wdischarge - usedflow
            if ava-wdischarge < 0 [set ava-wdischarge 0]  
            set wuse 0
          ]
          [
            set myflow 0
            set wheight old-wheight + ((myflow ) / area) * 1000
            if wheight > current-demand [set wheight current-demand ]
          ]
        ]
        [
          set myflow 0
          if wheight > current-demand [ set wheight current-demand ] ; water is used. The wheight of the inactive turtles is updated     
        ]
      ]
    ]]
  
  ;;Sequential policy
  if ipolicy = "Sequential" [ 
    foreach [0 1 2 3 4 5] [ 
      ask turtles with [who = ?] [
        if who = 0 [ ; sector 1 is the first to irrigate, the water not used by sector 1 is used by sector 2 and so on
          set ava-wdischarge wdischarge     
          if ava-wdischarge < 0 [set ava-wdischarge 0] 
        ]
        ifelse satisfied? = true ; once a sector reached wdemand, it doesn't irrigate 
          [
            set usedflow 0              
            if wheight > current-demand [set wheight current-demand ]
          ]
          [ 
            set myflow ava-wdischarge 
            if myflow < 0 [set myflow 0]
            set wheight old-wheight + myflow / area * 1000 
            if wheight > current-demand [set wheight current-demand ]
            set usedflow (wheight - old-wheight) * area / 1000              
           if usedflow < 0 [set usedflow 0]
           set ava-wdischarge ava-wdischarge - usedflow
           if ava-wdischarge < 0 [set ava-wdischarge 0]  
          ]
      ]     
    ]
  ]
end

to calculate-water-stress ; water stress during drought periods
  ask turtles [
    if ticks < s2 [ 
      set wstress1 (item ticks min-wdemand) - wheight
      if wstress1 < 0 [set wstress1 0]
      set cumwstress1 cumwstress1 + wstress1
      if cumwstress1 < 0 [set cumwstress1 0]     
    ]
    if ticks >= s2 and ticks < s3 [
      set wstress2 (item ticks min-wdemand) - wheight
      if wstress2 < 0 [set wstress2 0]
      set cumwstress2 cumwstress2 + wstress2
      if cumwstress2 < 0 [set cumwstress2 0]  
    ]
    if ticks >= s3 and ticks < s4 [
      set wstress3 (item ticks min-wdemand) - wheight
      if wstress3 < 0 [set wstress3 0]
      set cumwstress3 cumwstress3 + wstress3
      if cumwstress3 < 0 [set cumwstress3 0]  
    ]
    if ticks >= s4 [
      set wstress4 (item ticks min-wdemand) - wheight
      if wstress4 < 0 [set wstress4 0]
      set cumwstress4 cumwstress4 + wstress4
      if cumwstress4 < 0 [set cumwstress4 0]  
    ]
  ]
end

to calculate-yield       
  ask turtles [  ;; each irrigation stage has a certain sensivility to drought defined by the values of alpha and beta    
    if ticks < s2  [set alpha 0.10 set beta 50 set cumwstress cumwstress1] ; Stage 1
    if ticks >= s2 and ticks < s3 [set alpha 0.05 set beta 300 set cumwstress cumwstress2] ; Stage 2
    if ticks >= s3 and ticks < s4 [set alpha 0.05 set beta 100 set cumwstress cumwstress3] ; Stage 3
    if ticks >= s4 [set alpha 0.05 set beta 500 set cumwstress cumwstress4] ; Stage 4
    ;;atan(-alpha*(cumwstress-beta)) ;; equation used to calculate yield. If cumwstress is 0, then yield is 100%
    let y (alpha * (cumwstress - beta))  
    if y < 0 [set y 0 - y] ; negative number
    set y (atan y 1 ) * pi / 180
    if (cumwstress > beta) [set y (0 - y)]  ; negative number
    let yo (atan (alpha * beta)  1) * pi / 180  
    set y (y + pi / 2) / (yo + pi / 2)
    set yield y
  ]
  if ticks < s2  [
    set totyield1 ([yield] of turtle 0 + [yield] of turtle 1 + [yield] of turtle 2 + [yield] of turtle 3 + [yield] of turtle 4 + [yield] of turtle 5) / 6
    set totyield totyield1 ]
  if ticks >= s2 and ticks < s3 [
    set totyield2 ([yield] of turtle 0 + [yield] of turtle 1 + [yield] of turtle 2 + [yield] of turtle 3 + [yield] of turtle 4 + [yield] of turtle 5) / 6
    set totyield totyield1 * totyield2 
  ]
  if ticks >= s3 and ticks < s4 [
    set totyield3 ([yield] of turtle 0 + [yield] of turtle 1 + [yield] of turtle 2 + [yield] of turtle 3 + [yield] of turtle 4 + [yield] of turtle 5) / 6
    set totyield totyield1 * totyield2 * totyield3
  ]
  if ticks >= s4 [
    set totyield4 ([yield] of turtle 0 + [yield] of turtle 1 + [yield] of turtle 2 + [yield] of turtle 3 + [yield] of turtle 4 + [yield] of turtle 5) / 6
    set totyield totyield1 * totyield2 * totyield3 * totyield4
  ]
end 
 
to calculate-gini
  let sorted-yields sort [yield] of turtles
  let total-yield sum sorted-yields
  let yield-sum-so-far 0
  let index 0
  set gini-index-reserve 0
  repeat (count turtles) [
    set yield-sum-so-far (yield-sum-so-far + item index sorted-yields)
    set index (index + 1)
    set gini-index-reserve
    gini-index-reserve +
    (index / (count turtles)) -
      (yield-sum-so-far / total-yield)
  ]
  let ini (gini-index-reserve / 6) / 0.5
  if ini < 0 [set ini 0]
  set avggini avggini + ini
end

to define-irrigation-turn
  ask turtles [set irrigation-turn [0]]
  ask turtles [ 
    if ipolicy = "Open Flow"[ 
      repeat 129 [set irrigation-turn lput 1 irrigation-turn]
    ]
  ]
  ask turtle 0 [
    if ipolicy = "Sequential" or ipolicy = "Optimized sequential" [ 
      repeat 129 [set irrigation-turn lput 1 irrigation-turn]
    ]
    if ipolicy = "24 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
    if ipolicy = "12 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
  ]
  ask turtle 1 [ 
    if ipolicy = "Sequential" or ipolicy = "Optimized sequential" [
      set irrigation-turn [0 0]
      repeat 128 [set irrigation-turn lput 1 irrigation-turn]
    ]
    if ipolicy = "24 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
    if ipolicy = "12 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
  ]
  ask turtle 2 [
    if ipolicy = "Sequential" or ipolicy = "Optimized sequential" [
      set irrigation-turn [0 0 0]
      repeat 127 [set irrigation-turn lput 1 irrigation-turn]
    ]
    if ipolicy = "24 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
    if ipolicy = "12 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
  ]
  ask turtle 3 [
    if ipolicy = "Sequential" or ipolicy = "Optimized sequential" [
      set irrigation-turn [0 0 0 0]
      repeat 126 [set irrigation-turn lput 1 irrigation-turn]
    ] 
    if ipolicy = "24 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
    if ipolicy = "12 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
      ]
    ]
  ] 
  ask turtle 4 [
    if ipolicy = "Sequential" or ipolicy = "Optimized sequential" [
      set irrigation-turn [0 0 0 0 0]
      repeat 125 [set irrigation-turn lput 1 irrigation-turn]
    ] 
    if ipolicy = "24 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
       ]
    ]
    if ipolicy = "12 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
      ]
    ]
  ]  
  ask turtle 5 [    
    if ipolicy = "Sequential" or ipolicy = "Optimized sequential" [
      set irrigation-turn [0 0 0 0 0 0]
      repeat 124 [set irrigation-turn lput 1 irrigation-turn]
    ]    
    if ipolicy = "24 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
      ]
    ]
    if ipolicy = "12 Hour rotation" [
      repeat 22 [
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 0 irrigation-turn
        set irrigation-turn lput 1 irrigation-turn
      ]
    ]
  ]
end

to import-data
  ;; Import water demand
  ifelse ( file-exists? "_WaterDemand.txt" )[   
    set wdemand []
    file-open "_WaterDemand.txt"
    while [ not file-at-end? ][ set wdemand sentence wdemand (list file-read)]
    file-close
  ]
  [ user-message "There is no WaterDemand.txt file in current directory!" ]
  
  ;; Import max water demand
  ifelse ( file-exists? "_maxWaterDemand.txt" )[
    set max-wdemand []
    file-open "_maxWaterDemand.txt"
    while [ not file-at-end? ][
      set max-wdemand sentence max-wdemand (list file-read)]
    file-close]
  [ user-message "There is no maxWaterDemand.txt file in current directory!" ]
  
  ;; Import min water demand
  ifelse ( file-exists? "_minWaterDemand.txt" )[
    set min-wdemand []
    file-open "_minWaterDemand.txt"
    while [ not file-at-end? ][
      set min-wdemand sentence min-wdemand (list file-read)]
    file-close]
  [ user-message "There is no minWaterDemand.txt file in current directory!" ]
  
  ;; Import sequential water demand
  ifelse ( file-exists? "_seqDemand.txt" )[
    set seqwdemand []
    file-open "_seqDemand.txt"
    while [ not file-at-end? ][
      set seqwdemand sentence seqwdemand (list file-read)]
    file-close]
  [ user-message "There is no seqDemand.txt file in current directory!" ]
  
    ;; Import sequential min water demand
  ifelse ( file-exists? "_seqMinDemand.txt" ) [
    set seqminwdemand []
    file-open "_seqMinDemand.txt"
    while [ not file-at-end? ][
      set seqminwdemand sentence seqminwdemand (list file-read)]
    file-close]
  [ user-message "There is no seqMinDemand.txt file in current directory!" ]
  
  ;; Import sequential min water demand
  ifelse ( file-exists? "_normalAnnualWDischarge.txt" )[
    set normalAnnualWDischarge []
    file-open "_normalAnnualWDischarge.txt"
    while [ not file-at-end? ][
      set normalAnnualWDischarge sentence normalAnnualWDischarge (list file-read)]
    file-close]
  [ user-message "There is no normalAnnualWDischarge.txt file in current directory!" ]
end

to update-outputs
  set-current-plot "Water depth"
  set-current-plot-pen "Sector 1" ifelse ticks > 0 [plot [wheight] of turtle 0] [plot 0]
  set-current-plot-pen "Sector 2" ifelse ticks > 0 [plot [wheight] of turtle 1] [plot 0]
  set-current-plot-pen "Sector 3" ifelse ticks > 0 [plot [wheight] of turtle 2] [plot 0]
  set-current-plot-pen "Sector 4" ifelse ticks > 0 [plot [wheight] of turtle 3] [plot 0]
  set-current-plot-pen "Sector 5" ifelse ticks > 0 [plot [wheight] of turtle 4] [plot 0]
  set-current-plot-pen "Sector 6" ifelse ticks > 0 [plot [wheight] of turtle 5] [plot 0]
  set-current-plot-pen "Maximum" ifelse ticks > 0 [plot item (ticks ) max-wdemand] [plot 0]  
  set-current-plot-pen "Minimum" ifelse ticks > 0 [plot item (ticks ) min-wdemand] [plot 0]   
  set-current-plot-pen "Demand" ifelse ticks > 0 [plot item (ticks) wdemand] [plot 0]   

  set-current-plot "% Yield"
  set-current-plot-pen "Sector 1" ifelse ticks > 0 [plot [yield * 100] of turtle 0] [plot 0]
  set-current-plot-pen "Sector 2" ifelse ticks > 0 [plot [yield * 100] of turtle 1] [plot 0]
  set-current-plot-pen "Sector 3" ifelse ticks > 0 [plot [yield * 100] of turtle 2] [plot 0]
  set-current-plot-pen "Sector 4" ifelse ticks > 0 [plot [yield * 100] of turtle 3] [plot 0]
  set-current-plot-pen "Sector 5" ifelse ticks > 0 [plot [yield * 100] of turtle 4] [plot 0]
  set-current-plot-pen "Sector 6" ifelse ticks > 0 [plot [yield * 100] of turtle 5] [plot 0]
  
  set-current-plot "Cumulative gini"
  set-current-plot-pen "default" plot avggini
end
@#$#@#$#@
GRAPHICS-WINDOW
295
15
973
200
6
1
51.4
1
10
1
1
1
0
1
1
1
-6
6
-1
1
1
1
1
ticks
30.0

BUTTON
49
15
112
48
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
116
15
179
48
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
1

BUTTON
183
15
246
48
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
1

SLIDER
49
56
246
89
Shift
Shift
-55
45
10
1
1
NIL
HORIZONTAL

PLOT
295
205
975
450
Water depth
Time
Water depth
0.0
130.0
0.0
300.0
true
true
"" ""
PENS
"Sector 1" 1.0 0 -13791810 true "" ""
"Sector 2" 1.0 0 -6459832 true "" ""
"Sector 3" 1.0 0 -8630108 true "" ""
"Sector 4" 1.0 0 -955883 true "" ""
"Sector 5" 1.0 0 -10899396 true "" ""
"Sector 6" 1.0 0 -1184463 true "" ""
"Maximum" 1.0 0 -7500403 true "" ""
"Minimum" 1.0 0 -7500403 true "" ""
"Demand" 1.0 0 -2674135 true "" ""

PLOT
638
453
976
603
% Yield
Time
% Yield
0.0
130.0
0.0
100.0
true
true
"" ""
PENS
"Sector 1" 1.0 0 -13345367 true "" ""
"Sector 2" 1.0 0 -6459832 true "" ""
"Sector 3" 1.0 0 -8630108 true "" ""
"Sector 4" 1.0 0 -955883 true "" ""
"Sector 5" 1.0 0 -10899396 true "" ""
"Sector 6" 1.0 0 -1184463 true "" ""

MONITOR
983
43
1091
88
Policy
ipolicy
0
1
11

MONITOR
983
92
1091
137
Total % yield
totyield * 100
2
1
11

PLOT
295
453
633
603
Cumulative gini
Time
Gini
0.0
130.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
12
241
284
391
Water discharge
Time
Water flow
0.0
130.0
0.0
6.0
true
true
"" ""
PENS
"Normal" 1.0 0 -13345367 true "" ""
"Current" 1.0 0 -11221820 true "" ""

SLIDER
49
92
246
125
sdflow
sdflow
0
200
50
5
1
NIL
HORIZONTAL

SLIDER
50
199
247
232
break-threshold
break-threshold
0
20
16
1
1
NIL
HORIZONTAL

PLOT
13
398
286
548
Water flow
NIL
NIL
0.0
130.0
0.0
7.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot wdischarge / 0.1 / 24 / 3600"

SLIDER
50
165
247
198
Time-repair
Time-repair
0
10
5
1
1
NIL
HORIZONTAL

SLIDER
49
129
247
162
Discharge-reduction
Discharge-reduction
-1
1
1
0.01
1
NIL
HORIZONTAL

MONITOR
983
140
1093
185
Policies used
switch
0
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="wred8" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>totyield</metric>
    <metric>avggini</metric>
    <metric>Time-shock</metric>
    <metric>switch</metric>
    <metric>[yield] of turtle 0</metric>
    <metric>[yield] of turtle 1</metric>
    <metric>[yield] of turtle 2</metric>
    <metric>[yield] of turtle 3</metric>
    <metric>[yield] of turtle 4</metric>
    <metric>[yield] of turtle 5</metric>
    <enumeratedValueSet variable="sdflow">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shift">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Discharge-reduction" first="-1" step="0.01" last="1"/>
    <enumeratedValueSet variable="Time-repair">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-threshold">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="shiftada" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>totyield</metric>
    <metric>avggini</metric>
    <metric>Time-shock</metric>
    <metric>switch</metric>
    <metric>[yield] of turtle 0</metric>
    <metric>[yield] of turtle 1</metric>
    <metric>[yield] of turtle 2</metric>
    <metric>[yield] of turtle 3</metric>
    <metric>[yield] of turtle 4</metric>
    <metric>[yield] of turtle 5</metric>
    <enumeratedValueSet variable="sdflow">
      <value value="35"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Shift" first="-45" step="1" last="45"/>
    <enumeratedValueSet variable="Discharge-reduction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Time-repair">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-threshold">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ada" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>totyield</metric>
    <metric>avggini</metric>
    <metric>Time-shock</metric>
    <metric>[yield] of turtle 0</metric>
    <metric>[yield] of turtle 1</metric>
    <metric>[yield] of turtle 2</metric>
    <metric>[yield] of turtle 3</metric>
    <metric>[yield] of turtle 4</metric>
    <metric>[yield] of turtle 5</metric>
    <enumeratedValueSet variable="sdflow">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Shift" first="-45" step="1" last="45"/>
    <enumeratedValueSet variable="Discharge-reduction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Time-repair">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-threshold">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="wred5" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>totyield</metric>
    <metric>avggini</metric>
    <metric>Time-shock</metric>
    <metric>switch</metric>
    <metric>[yield] of turtle 0</metric>
    <metric>[yield] of turtle 1</metric>
    <metric>[yield] of turtle 2</metric>
    <metric>[yield] of turtle 3</metric>
    <metric>[yield] of turtle 4</metric>
    <metric>[yield] of turtle 5</metric>
    <enumeratedValueSet variable="sdflow">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shift">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Discharge-reduction" first="-1" step="0.01" last="1"/>
    <enumeratedValueSet variable="Time-repair">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-threshold">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sdada" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>totyield</metric>
    <metric>avggini</metric>
    <metric>Time-shock</metric>
    <metric>switch</metric>
    <metric>[yield] of turtle 0</metric>
    <metric>[yield] of turtle 1</metric>
    <metric>[yield] of turtle 2</metric>
    <metric>[yield] of turtle 3</metric>
    <metric>[yield] of turtle 4</metric>
    <metric>[yield] of turtle 5</metric>
    <steppedValueSet variable="sdflow" first="10" step="1" last="60"/>
    <enumeratedValueSet variable="Shift">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Discharge-reduction">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Time-repair">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-threshold">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="all scenarios" repetitions="300" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>totyield</metric>
    <metric>avggini</metric>
    <metric>Time-shock</metric>
    <metric>switch</metric>
    <metric>[yield] of turtle 0</metric>
    <metric>[yield] of turtle 1</metric>
    <metric>[yield] of turtle 2</metric>
    <metric>[yield] of turtle 3</metric>
    <metric>[yield] of turtle 4</metric>
    <metric>[yield] of turtle 5</metric>
    <enumeratedValueSet variable="sdflow">
      <value value="20"/>
      <value value="0"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Shift">
      <value value="-10"/>
      <value value="0"/>
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Discharge-reduction" first="-1" step="0.1" last="1"/>
    <enumeratedValueSet variable="Time-repair">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="break-threshold">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
