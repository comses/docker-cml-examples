;The simulation always runs form first of January to first of January.
extensions [
            time
            r
            ]
breed[persons person]
breed[households household]

persons-own[id
            sex ; 10 is male, 20 is female
            fert ; 0, 1, 2
            marital;3 is NM, 4 is M, 5 is D, 6 is W
            dead; 0 is alive, 1 is dead
            income
            birthdate
            birthdateNeg
            state
            location
            household
            migrationstage ; 0: no intention, 1: intention, 2: planning, 3: preparation, 4: migration
            timeinstage
            attitude
            socialnorm
            PBC
            intention
            selfscheduled
            popforlogo-private
            parent
            spouse
            child
            retired
            retirementticks
            migrant
            marriagestamp
            inmarriagemarket
            timesmatch
            entryyear
            entrymonth
            dayofmonth
            dayasnumber
            counted
            marriageyear
            marriagemonth
            currentmarriage
            marriagedistance
            candidate
            compatibility
            indicator
            indicator2
            timetomarriage
            unborn
            NoMoreTransitions
            AlreadyHighMortality
            migrationticks
            migrationAttempt ;1 if succeeded, 2 if failed
            migrationcostTotal
            migrantkid
            migrationeventticks
            institution
            searchattempts
            currentchooser
            incomestartticks
            initialwealth
            waitingtime1
            waitingtime2
            AgeYearEnd]

households-own[capital
              members
              indicator
              highmortality
              capitallist
              ]

globals[results
        measure
        transitions
        transitionsMig
        current-time
        mylist
        newstatus
        initPopLogo
        initPopLogoMig
        popforlogo-global
        currentitem
        timeslist
        initChildrenLogo
        initChildrenLogoFinal
        bornChildren
        bornChildrenMig
        preliminary-start-time
        additional
        correct-starttime
        correct-endtime
        additionalEnd
        lasttransition
        myChild
        initialmigrants
        marriedpersons
        marrieddates
        pop
        poplist
        popMig
        popMiglist
        warndate
        entries
        potentialpartner
        endticks
        startcapital
        migrationsperyear
        ageprofile
        ageprofilecohort
        marriageError
        foundNoPartner
        file1
        file2
        file3
        file4
        file5
        consumptionSen
        consumptionFra
        incomeSen
        incomeFra
        MeanIncomeSenegal
        GiniSenegal
        MeanIncomeEurope
        GiniEurope
        GiniWealth
        MonthlyConsumptionAdults
        ;MonthlyConsumptionChildren ;This version: same consumption for everyone
        MonthlyConsumptionAdultsMig
        ;MonthlyConsumptionChildrenMig
        growthSen
        growthFra
        growthEurope
        growthSenegal
        wealth1980
        borderEnforcement
        border
        migrationcost
        pcMigrationCost
        PeopleatAge
        PeopleatAgePerYear
        MigrantsatAge
        MigrantsatAgePerYear
        MigrantsInYear
        MigrantsTotal
        FemaleMigrantsInYear
        FemaleMigrantsTotal
        ]

to setup
__clear-all-and-reset-ticks
r:clear
;print ""
;print "================================================"
;print ""
set preliminary-start-time time:create "1970-01-01 00:00"
set additional startyear - 1970
set additionalEnd endyear - 1970
set correct-starttime time:plus preliminary-start-time additional "years"
set correct-endtime time:plus preliminary-start-time additionalEnd "years"
set current-time time:anchor-to-ticks correct-starttime 1 "day"
time:anchor-schedule current-time 1 "day" ;automatically update current-time with ticks
;print current-time
create-persons numberindividuals [setxy random-xcor random-ycor
                       set color red
                       set size 3
                       set waitingtime1[]
                       set waitingtime2[]
                       set migrant 0
                       set migrantkid 0]
set initialmigrants round (numberindividuals * initialHost)
ask n-of initialmigrants persons with [who > (numberindividuals - initialmigrants - 1) ]
    [set color pink
      set migrant 1
      ]
set results []
set migrationsperyear 0
set foundNoPartner 0
set ageprofile[]
set ageprofilecohort[]
set PeopleatAge []
set PeopleatAgePerYear []
set MigrantsatAge []
set MigrantsatAgePerYear []
set MigrantsInYear []
set MigrantsTotal []
set FemaleMigrantsInYear []
set FemaleMigrantsTotal []
set marriageError[0]; otherwise the mean can't be formed
set measure 0
;r:eval ".libPaths(c('C:/Users/bainb184/Documents/R/win-library/3.0',.libPaths()))"
;r:eval ".libPaths(c('C:/Users/klabunde/Documents/R/win-library/3.1',.libPaths()))"
;r:eval ".libPaths(c('C:/Program Files/R/R-3.2.1/library',.libPaths()))"
r:eval ".libPaths(c('%R_HOME%/library',.libPaths()))"

r:eval "library(MicSim)"
r:eval "library(car)"
;r:eval "source('Y:/02_Abteilung_2/02_Methoden/01_MA-Restricted/SZ/ANNA/rfunctionToNetLogo.r')"
;r:eval "source('Y:/02_Abteilung_2/02_Methoden/01_MA-Restricted/SZ/ANNA/micSimABM.r')";load the needed function
;r:eval "source('N:/MAFE/R_Codes/Anna/transitions10_ZLM_03212016.r')"
r:eval "source('N:/MAFE/R_Codes/Anna/rfunctionToNetLogo.r')"
r:eval "source('N:/MAFE/R_Codes/Anna/micSimABM.r')";load the needed function
;r:eval "source('N:/MAFE/R_Codes/Anna/micSim4.r')";load the needed function
;r:eval "source('N:/MAFE/R_Codes/Anna/function_samplingf_f.r')"
;r:eval "source('N:/MAFE/R_Codes/Anna/function_samplingf_f_mig.r')"
r:eval "set.seed(678)"
r:eval "dak.tot<- read.table('N:/MAFE/R_Codes/Anna/Dakar_sampling.csv',sep=',',header=T)"
r:eval "france.tot<- read.table('N:/MAFE/R_Codes/Anna/France1982.csv',sep=',',header=T)"
;r:eval "dak.tot<- read.table('Y:/02_Abteilung_2/02_Methoden/01_MA-Restricted/SZ/ANNA/inputDataSim/Dakar_sampling.csv',sep=',',header=T)"
;r:eval "france.tot<- read.table('Y:/02_Abteilung_2/02_Methoden/01_MA-Restricted/SZ/ANNA/inputDataSim/France1982.csv',sep=',',header=T)"
random-seed 678
;read in input time series
load-data
data-update
set GiniSenegal 0.4
r:put "GiniSenegal" GiniSenegal
set GiniEurope 0.3
r:put "GiniEurope" GiniEurope
set GiniWealth 0.7
r:put "GiniWealth" GiniWealth
set wealth1980 700
r:put "wealth1980" wealth1980
;set pcMigrationCost 175
;######################################################################
;First: initial population. Part of it is in host country

r:put "N" numberindividuals - initialmigrants
r:put "currentTime" ticks
r:put "additional" additional
r:eval "starttime<-timetransform(currentTime, additional)" ;transform to Micsim time format
r:put "additionalEnd" additionalEnd
r:eval "endtime<-timetransform(currentTime, additionalEnd)"


; this is actually the old version, without the initial population from the census
;r:eval "initPop<-initialpopulation(N, starttime, endtime)"
; FROM THE CENSUS
r:eval "initPop<-init_pop_f(N)"

;separately for initial migrants

r:put "Nmig" initialmigrants
r:eval "initPopMig<-init_pop_f_mig(Nmig)"

;Output has to be transformed so that turtles can read their state variables

r:eval "initPopLogo<-netlogoInitpop(initPop)"
r:eval "initPopLogoMig<-netlogoInitpop(initPopMig)" ;for initial migrants

set initPopLogo r:get "initPopLogo"
set initPopLogoMig r:get "initPopLogoMig"
foreach sort persons with [color = red] [ask ? [set id item who (item 0 initPopLogo)
                                         set birthdate item who (item 1 initPopLogo)
                                         set sex item who (item 2 initPopLogo)
                                         set fert item who (item 3 initPopLogo)
                                         set marital item who (item 4 initPopLogo)
                                         set parent []
                                         set child []
                                         set retired 0
                                         r:eval "initialwealth<-lognormalrandom(wealth1980, GiniWealth)"
                                         set initialwealth r:get "initialwealth"
                                         if initialwealth <= 0 [set initialwealth 1]
                                         set migrationeventticks 0
                                         set marriagestamp []
                                               ]
                                       ]
;same for migrants. Initial migrants also have IDs starting from 1, otherwise they would not be recognizable from Micsim, where IDs always start with 1. If this creates problems
;at some point, a work-around will be created.

foreach sort persons with [color = pink][ask ? [set id item (who - (numberindividuals - initialmigrants)) (item 0 initPopLogoMig)
                                         set birthdate item (who - (numberindividuals - initialmigrants)) (item 1 initPopLogoMig)
                                         set sex item (who - (numberindividuals - initialmigrants)) (item 2 initPopLogoMig)
                                         set fert item (who - (numberindividuals - initialmigrants)) (item 3 initPopLogoMig)
                                         set marital item (who - (numberindividuals - initialmigrants)) (item 4 initPopLogoMig)
                                         set parent []
                                         set child []
                                         set retired 0
                                         r:eval "initialwealth<-lognormalrandom(wealth1980, GiniWealth)"
                                         set initialwealth r:get "initialwealth"
                                         if initialwealth <= 0 [set initialwealth 1]
                                         set migrationeventticks 0
                                         set marriagestamp []
                                         set migrationticks 0 ;migrants right from the start
                                               ]
                                       ]

;run initital micsim for all events that can already be determined

initialMicsim
;print (word "People with inititalwealth <= 0: " count persons with [initialwealth <= 0 and birthdate - (additional * 365.25) < ticks])
;ask persons [print (word who " initial wealth" initialwealth)]
initialMarriage
initialAdoption
initialNetwork
ask persons with [marital != 15 and parent = [] and birthdate - (additional * 365.25) < ticks] [form-single-household]
; check all households
;ask households[print (word "I am household " who ", my capital is " capital ", my members are " members) ]
;print "Households without capital:"
;print [who] of households with [capital <= 0]

;ask persons [if not any? households with [member? myself members = true] and birthdate - (additional * 365.25) < ticks
 ;            [print (word "I am not part of a household. My who is " who)
  ;           ]
   ;         ]
;print (word "People with initial wealth > 0:" count persons with [initialwealth > 0 and birthdate - (additional * 365.25) < ticks])
;#######################################################################
schedule-events
;#######################################################################;
go
;#######################################################################

end


to load-data
ifelse (file-exists? "N:/MAFE/R_Codes/Anna/consumptionSen.txt")
   [
     set consumptionSen []
     file-open "N:/MAFE/R_Codes/Anna/consumptionSen.txt"
     while [not file-at-end?]
        [set consumptionSen lput file-read consumptionSen
        ]
    file-close
   ]
   [user-message "There is no consumptionSen.txt file in current directory!"
   ]

ifelse (file-exists? "N:/MAFE/R_Codes/Anna/consumptionFra.txt")
   [
     set consumptionFra []
     file-open "N:/MAFE/R_Codes/Anna/consumptionFra.txt"
     while [not file-at-end?]
        [set consumptionFra lput file-read consumptionFra
        ]
    file-close
   ]
   [user-message "There is no consumptionFra.txt file in current directory!"
   ]

ifelse (file-exists? "N:/MAFE/R_Codes/Anna/IncomeSenNEW.txt")
   [
     set incomeSen []
     file-open "N:/MAFE/R_Codes/Anna/IncomeSenNEW.txt"
     while [not file-at-end?]
        [set incomeSen lput file-read incomeSen
        ]
    file-close
   ]
   [user-message "There is no incomeSen.txt file in current directory!"
   ]

ifelse (file-exists? "N:/MAFE/R_Codes/Anna/IncomeFraNEW.txt")
   [
     set incomeFra []
     file-open "N:/MAFE/R_Codes/Anna/IncomeFraNEW.txt"
     while [not file-at-end?]
        [set incomeFra lput file-read incomeFra
        ]
    file-close
   ]
   [user-message "There is no incomeFra.txt file in current directory!"
   ]


ifelse (file-exists? "N:/MAFE/R_Codes/Anna/growthSen.txt")
   [
     set growthSen []
     file-open "N:/MAFE/R_Codes/Anna/growthSen.txt"
     while [not file-at-end?]
        [set growthSen lput file-read growthSen
        ]
    file-close
   ]
   [user-message "There is no growthSen.txt file in current directory!"
   ]

ifelse (file-exists? "N:/MAFE/R_Codes/Anna/growthFra.txt")
   [
     set growthFra []
     file-open "N:/MAFE/R_Codes/Anna/growthFra.txt"
     while [not file-at-end?]
        [set growthFra lput file-read growthFra
        ]
    file-close
   ]
   [user-message "There is no growthSen.txt file in current directory!"
   ]

ifelse (file-exists? "N:/MAFE/R_Codes/Anna/border.txt")
   [
     set border []
     file-open "N:/MAFE/R_Codes/Anna/border.txt"
     while [not file-at-end?]
        [set border lput file-read border
        ]
    file-close
   ]
   [user-message "There is no border.txt file in current directory!"
   ]

ifelse (file-exists? "N:/MAFE/R_Codes/Anna/migrationcost.txt")
   [
     set migrationcost []
     file-open "N:/MAFE/R_Codes/Anna/migrationcost.txt"
     while [not file-at-end?]
        [set migrationcost lput file-read migrationcost
        ]
    file-close
   ]
   [user-message "There is no migrationcost.txt file in current directory!"
   ]




;print (word "consumption Senegal: "consumptionSen )
;print (word " consumption France: " consumptionFra)
;print (word " income Senegal " incomeSen )
;print (word " income France " incomeFra)
;print (word " growth Senegal " growthSen )
;print (word " growth France " growthFra)
;print (word " border enforcement " border)

end

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
to initialMicsim
r:eval "pop<-newlife(initPop, starttime, endtime)"
; Netlogo gets confused when there are two time-series. Thus, migrants schedule their events individually at the beginning.See below.


;CHECK OUT HIGHEST ID; THIS IS THE NUMBER OF CHILDREN THAT HAS TO BE CREATED ADDITIONALLY
r:eval "totalIndividuals<-length(unique(pop$ID))"
set bornChildren r:get "totalIndividuals" - (numberindividuals - initialmigrants)
;Create children to be later activated. Put them in a corner.
create-persons bornChildren [setxy 0 0
                       set color blue
                       set size 3
                       set migrant 0
                       set migrantkid 0
                       set waitingtime1[]
                       set waitingtime2[]]
;Read in their initial status already from the pop file.
;First, shorten the pop file so that it contains only the children
r:eval "popShort<- subset(pop, ID > N)"
r:eval "initChildrenLogo<-initChildren(popShort)"
set initChildrenLogo r:get "initChildrenLogo"
foreach sort persons with [color = blue][ask ? [set id item (who - numberindividuals) (item 0 initChildrenLogo)
                                         set birthdate item (who - numberindividuals) (item 1 initChildrenLogo)
                                         set sex item (who - numberindividuals) (item 2 initChildrenLogo)
                                         set fert 0
                                         set marital 14
                                         set parent []
                                         set child []
                                         set retired 0
                                         set migrationeventticks 0
                                         set marriagestamp []
                                         ]
                            ]

;transform output so that it can be read into time-series object in order to be scheduled by the time extension
r:eval "popforlogo<-netlogoOutput(pop)"

file-open (word a1 a2 a3 a4 a5 a6 a7 rho1 ".csv")
file-print "" ; to create the file
r:put "filename" (word a1 a2 a3 a4 a5 a6 a7 rho1 ".csv")
r:eval "savePopforlogo(popforlogo, filename)"
;Read time-series object into Netlogo

set transitions time:ts-load (word a1 a2 a3 a4 a5 a6 a7 rho1 ".csv")
;print transitions
file-close
end
;##################################################################################################################################
to initialMarriage
;print "These are initially married people: "
;print count persons with [marital = 15]
;distinguish migrants and non-migrants.
if any? persons with [marital = 15 and migrant = 1]
  [ ask persons with [marital = 15 and migrant = 1] [set indicator2 1]
    ;print "Migrants with indicator2= 1:"
    ;print count persons with [indicator2 = 1]
    while [count persons with [indicator2 = 1] > 0]
     [ask one-of persons with [indicator2 = 1]
       [ifelse any? persons with [indicator2 = 1 and sex != [sex] of myself ]
          [ set currentchooser 1
            ask persons with [indicator2 = 1 and sex != [sex] of myself ]
              [compute-compatibility
              ]
              set potentialpartner one-of persons with [indicator2 = 1 and sex != [sex] of myself ] with-max [compatibility]
              let randomdraw random-float 1
               ;print (word "randomdraw  " randomdraw "vs compatibility score" [compatibility] of potentialpartner)
               ifelse randomdraw < [compatibility] of potentialpartner
                    [
                      ask potentialpartner
                         [
                           set spouse myself
                           ;print who
                           ;print (word "gender: " sex)
                           ;print "got married"
                          set indicator2 0
                          ]
                     set spouse potentialpartner
                     create-link-with potentialpartner
                     ;print who
                     ;print (word "gender: " sex)
                     ;print "got married"
                     ;print (word "new marriagestamp: " marriagestamp)
                     form-household
                     set currentchooser 0
                     set indicator2 0
                    ]
                    [; not successful random draw
                      set currentchooser 0
                    ]
                    ;print "persons with indicator2 = 1: "
                    ;print count persons with [indicator2 = 1]
          ]
          [; no potential partners in the market. Create partner like during run
             hatch-persons 1
                [set size 3
                  set waitingtime1[]
                  set waitingtime2[]
                 set id 0
                 set migrant 1
                 set migrantkid 0
                 set color pink
                 set selfscheduled 1
                 set birthdate [birthdate] of myself
                 set spouse myself
                 set indicator2 0
                 ifelse [sex] of myself = 10
                              [set sex 20]
                              [set sex 10]
                 set fert 0
                 set marital 15
                 r:eval "initialwealth<-lognormalrandom(wealth1980, GiniWealth)"
                 set initialwealth r:get "initialwealth"
                 if initialwealth <= 0 [set initialwealth 1]
                 set parent []
                 set child []
                 set retired 0
                 set migrationeventticks 0
                 set marriagestamp []
                 set state 15
                 set popforlogo-private [] ; otherwise, the spouse inherits that of the partner
                 ;print (word who " set popforlog-private []")
                 ;print who
                 ;print (word "gender: " sex)
                 ;print "was created as spouse"
                 schedule-event-Mig
                 draw-income
                 set candidate 1

                ]
             let myspouse one-of persons with [candidate = 1]
             create-link-with myspouse
             set spouse myspouse
             ask myspouse [set candidate 0]
             form-household
             set currentchooser 0
             set indicator2 0
             ;print "persons with indicator2 = 1: "
          ;print count persons with [indicator2 = 1]
         ]
      ]
    ]
  ]

if any? persons with [marital = 15 and migrant = 0]
  [ ask persons with [marital = 15 and migrant = 0] [set indicator2 1]
    ;print "Non-migrants with indicator2= 1:"
    ;print count persons with [indicator2 = 1]
    while [count persons with [indicator2 = 1] > 0]
     [ask one-of persons with [indicator2 = 1]
       [ifelse any? persons with [indicator2 = 1 and sex != [sex] of myself ]
          [ set currentchooser 1
            ask persons with [indicator2 = 1 and sex != [sex] of myself ]
              [compute-compatibility
              ]
              set potentialpartner one-of persons with [indicator2 = 1 and sex != [sex] of myself ] with-max [compatibility]
              let randomdraw random-float 1
               ;print (word "randomdraw  " randomdraw "vs compatibility score" [compatibility] of potentialpartner)
               ifelse randomdraw < [compatibility] of potentialpartner
                    [
                      ask potentialpartner
                         [
                           set spouse myself
                           ;print who
                           ;print (word "gender: " sex)
                           ;print "got married"
                          set indicator2 0
                          ]
                     set spouse potentialpartner
                     create-link-with potentialpartner
                     ;print who
                     ;print (word "gender: " sex)
                     ;print "got married"
                     ;print (word "new marriagestamp: " marriagestamp)
                     form-household
                     set currentchooser 0
                     set indicator2 0
                    ]
                    [; not successful random draw
                      set currentchooser 0
                      ;person can choose again
                    ]
          ;print "persons with indicator2 = 1: "
          ;print count persons with [indicator2 = 1]
          ]
          [; no potential partners in the market.
             hatch-persons 1
                [set size 3
                  set waitingtime1[]
                  set waitingtime2[]
                 set id 0
                 set migrant 1
                 set migrantkid 0
                 set selfscheduled 1
                 set birthdate [birthdate] of myself
                 set spouse myself
                 set indicator2 0
                 ifelse [sex] of myself = 10
                              [set sex 20]
                              [set sex 10]
                 set fert 0
                 set marital 15
                 set parent []
                 set child []
                 set retired 0
                 r:eval "initialwealth<-lognormalrandom(wealth1980, GiniWealth)"
                 set initialwealth r:get "initialwealth"
                 if initialwealth <= 0 [set initialwealth 1]
                 set migrationeventticks 0
                 set marriagestamp []
                 set state 15
                 set popforlogo-private [] ; otherwise, the spouse inherits that of the partner
                 ;print (word who " set popforlog-private []")
                 ;print who
                 ;print (word "gender: " sex)
                 ;print "was created as spouse"
                 schedule-event-Mig
                 draw-income
                 set candidate 1

                ]
             let myspouse one-of persons with [candidate = 1]
             create-link-with myspouse
             set spouse myspouse
             ask myspouse [set candidate 0]
             form-household
             set currentchooser 0
             set indicator2 0
             ;print "persons with indicator2 = 1: "
          ;print count persons with [indicator2 = 1]
         ]
      ]
    ]
  ]



end

;######################################################################################################################################################################

to initialAdoption
; identify children under the age of 16 who are already born at the beginning of the simulation
;!!!!!!!!!!!!!!!!!!!!!!NOCH UNTERSCHEIDEN NACH MIGRANTEN UND NICHTMIGRANTEN!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;First: assign one child to all mothers starting with the youngest children and youngest mothers. Then fill up starting again with the yet-unassigned youngest
;children and the mothers with fertility larger than 1.
let childrenpool []
let ChildMigrant 0
let ChildNonMigrant 0
ask persons [let sixteenth birthdate + 365.25 * 16
             let sixteenticks sixteenth - (additional * 365.25)
             ; but person also has to be born already at tick = 0
             let birthdayticks birthdate - (additional * 365.25)
             if ticks < sixteenticks and birthdayticks < ticks
             [set childrenpool lput self childrenpool
               ifelse migrant = 0
               [set ChildNonMigrant ChildNonMigrant + 1]
               [set ChildMigrant ChildMigrant + 1]
              ]
            ]
;print "Childrenpool:"
;print childrenpool
;print (word "Total number non-migrant children" ChildNonMigrant)
;print (word "Total number migrant children" ChildMigrant)
let motherpool[]
let motherpoolMig []
let totalnumberchildren 0
let migrantchildren 0
ask persons with [sex = 20][; mothers have to be born already at tick = 0 and should not be oder than 50 to be assigned an under-age child
                            let birthdayticks birthdate - (additional * 365.25)
                            let fiftyth birthdate + 365.25 * 50
                            let fiftythticks fiftyth - (additional * 365.25)
                             if fert > 0 and birthdayticks < ticks and ticks < fiftythticks
                            [ifelse migrant = 0
                             [set motherpool lput self motherpool
                              set totalnumberchildren totalnumberchildren + fert
                              ]
                             [set motherpoolMig lput self motherpoolMig
                             set migrantchildren migrantchildren + fert]
                            ]
                            ]
;print "Motherpool:"
;print motherpool
;print (word "Total number non-migrant according to fert" totalnumberchildren)
;print (word "Total number migrant according to fert" migrantchildren)
ask turtle-set childrenpool [set birthdateNeg (-1 * birthdate)]
ask turtle-set motherpool [set birthdateNeg (-1 * birthdate)]
ask turtle-set motherpoolMig [set birthdateNeg (-1 * birthdate)]
;Assign children to mothers. Start with youngest children and assign to youngest mothers.
foreach sort-on [birthdateNeg] turtle-set childrenpool
  [let CurrentChild ?
    ask ?
    [let lowestnumber 0
     let lowestnumberMig 0
      ;print (word "I am child" who ", my migrant status is " migrant ", my color is" color  ", I look for my mother")
      ifelse motherpool != []
        [set lowestnumber min [length child] of turtle-set motherpool]
        [;print "There are no mothers left for me"
         if migrant = 0 [stop]
        ]
      ifelse motherpoolMig != []
        [set lowestnumberMig min [length child] of turtle-set motherpoolMig ]
        [;print "There are no mothers left for me"
         if migrant = 1 [stop]
        ]

      ;print (word "The lowest number of children in the motherpool is " lowestnumber)
      ;print (word "The lowest number among migrants is " lowestnumberMig)

      let chosenmother nobody
      ifelse migrant = 0
      [set chosenmother one-of persons with [member? self motherpool = true] with [length child = lowestnumber] with-min [birthdateNeg]]
      [set chosenmother one-of persons with [member? self motherpoolMig = true]  with [length child = lowestnumberMig] with-min [birthdateNeg]]
      ask chosenmother
      [set child lput CurrentChild child
       ;print (word "I am the mother, my who is" who ", my fert is " fert ", my children are now"  child)
      ]
     set parent lput chosenmother parent
     move-to chosenmother
     ask other persons-here with [color = [color] of myself][create-link-with myself]
     ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
     ; siblings are automatically taken care of with this because they necessarily are in the same spot as the mother in the beginning
     if [spouse] of chosenmother != 0 [set parent lput [spouse] of chosenmother parent
                                        let myfather [spouse] of chosenmother
                                        ask myfather [set child lput CurrentChild child]
                                        create-link-with myfather
                                       ]


     ifelse any? households with [member? chosenmother members = true]
                 [ifelse any? households with [member? Currentchild members = true]
                            [ask households with [member? Currentchild members = true]
                              [set members remove Currentchild members
                                ;print (word "I, " [who] of Currentchild " , left the household " who)
                                set capitallist []
                                ifelse members = []
                                 [;print (word "no members left, thus I, household " who " can die")
                                   let newinitialwealth capital
                                   ask Currentchild [set initialwealth newinitialwealth]
                                   die
                                   ]
                                 [;print (word "There are still members in the old household " who " left. They are " members)
                                   let newinitialwealth (capital / (length members + 1))
                                   ask Currentchild [set initialwealth newinitialwealth]
                                   set capital capital - newinitialwealth
                                 ]
                               ]
                               ;print (word Currentchild ", my child, is leaving the old household")
                              ]
                            [;print "no old household to leave for my child"
                            ]

                   ;print (word "I, the mother, live in household " [who] of one-of households with [member? chosenmother members = true] )
                  ask one-of households with [member? chosenmother members = true]
                       [;print (word "I, household " who "welcome my new member " CurrentChild)
                        set members lput CurrentChild members
                        ;print (word "I, " [who] of CurrentChild " , joint the household " who)
                        set capitallist []
                        set capital capital + [initialwealth] of Currentchild
                        ]

                  set initialwealth 0
                  ]
                  [;print (word "I, the mother, am not part of a household")
                  ]

     ask chosenmother  [ifelse  length child = fert
                          [ifelse migrant = 0
                            [set motherpool remove self motherpool]
                            [set motherpoolMig remove self motherpoolMig ]
                         ;print (word "I, " who ", remove myself from the motherpool.")
                        ]
                        [;print "I stay in the motherpool for now."
                        ]
                      ]
    ; children who already have children of their own need to make sure that their child moves with them
    if child != []
    [let mychildren child
    ask one-of households with [member? CurrentChild members = true]
               [ foreach mychildren
                 [set members lput ? members
                   ;print (word "I, " [who] of ? " , joint the household " who)
                   set capitallist []
                   set capital capital + [initialwealth] of ?
                 ask ?
                  [set initialwealth 0
                    move-to CurrentChild]
                 ]

               ]

    ]
    ]
  ]

end
;########################################################################################################################################################################

to initialNetwork

;ask persons [if any? persons-here [ask other persons-here [create-link-with myself]]
;             if any? persons-on neighbors [ask persons-on neighbors [create-link-with myself]]
;             ]
;ask persons with [migrant = 1 and color = pink] [if not any? link-neighbors with [migrant = 0] [create-link-with one-of persons with [migrant = 0 and color = red]]]



; Aus den HH, die aus Nicht-Migranten bestehen, je 2.6%, 0.35%, 0.35% und 0.09% raussuchen (auf ganze Zahlen aufrunden)
; Alle members des HH fragen, zu einem (oder zwei, oder drei, oder vier) zuf�llig ausgew�hlten Migranten einen Link zu kn�pfen.
ask households[set indicator 0
               let mymembers turtle-set members
               if not any? mymembers with [migrant = 1]
               [set indicator 1]
               ]

ask n-of ceiling (0.026 * count households) households with [indicator = 1]
              [let mymembers turtle-set members
                let migrantfriend one-of persons with [migrant = 1 and color = pink]
                ask mymembers
                 [create-link-with migrantfriend]
               ]

ask n-of ceiling (0.0035 * count households) households with [indicator = 1]
              [let mymembers turtle-set members
                let migrantfriends []
                ask n-of 2 persons with [migrant = 1]
                [set migrantfriends lput self migrantfriends]
                ask mymembers
                 [foreach migrantfriends
                   [create-link-with ?]
                  ]
               ]

ask n-of ceiling (0.0035 * count households) households with [indicator = 1]
              [let mymembers turtle-set members
                let migrantfriends []
                ask n-of 3 persons with [migrant = 1]
                [set migrantfriends lput self migrantfriends]
               ask mymembers
                 [foreach migrantfriends
                   [create-link-with ?]
                  ]
               ]
ask n-of ceiling (0.0009 * count households) households with [indicator = 1]
              [let mymembers turtle-set members
                let migrantfriends []
                ask n-of 4 persons with [migrant = 1]
                [set migrantfriends lput self migrantfriends]
                ask mymembers
                 [foreach migrantfriends
                   [create-link-with ?]
                  ]
               ]


ask households [set indicator 0]

ask persons [ask other persons-here [create-link-with myself]
             ask persons-on neighbors [create-link-with myself]
             ]


end



;#######################################################################################################################################################################
to schedule-events
;create temporary list out of the time column for non-migrants
let datetimes time:ts-get-range transitions correct-starttime correct-endtime "LOGOTIME"
;print datetimes
foreach datetimes [
  ;print one-of persons with [id = time:ts-get transitions ? "ID" and migrant = 0] ;to make sure it is working as intended
  time:schedule-event one-of persons with [id = time:ts-get transitions ? "ID" and migrant = 0] task perform-transition ?
  ]
;generate life courses of initial migrants individually
ask persons with [migrant = 1] [schedule-event-Mig]
ask persons [schedule-retirement]
ask persons [schedule-income]
schedule-incomepayment ; observer does this
schedule-consumption
ask persons with [migrant = 0][schedule-migrationstart]
give-marriagestamp
schedule-output
schedule-data-updates
;print "----------------------------------------------------------"
;print "Everyone alive:"
;foreach sort persons [ask ? [print (word "Who: " who "  Marriagestamp: " marriagestamp " birthdate: " birthdate " migrant " migrant )]]
;print "-----------------------------------------------------------"
;pay income once at the start so that people do not go bankrupt right away
payday
;ask persons [print (word "Who: " who " income:" income)]
end

;#######################################################################################################################################################################
to schedule-retirement
let retirementday birthdate + 365.25 * 65 ;day of 65th birthday in days since 1st Jan 1970
            ; transform to ticks
            set retirementticks retirementday - (additional * 365.25)
            ifelse retirementticks > ticks
            [time:schedule-event self task retirement retirementticks]
            [retirement] ; person is already retired

end

to schedule-migrationstart ; Only for those people who are in the home country
;let migrationstartday birthdate + 365.25 * 17 ;day of 17th birthday in days since 1st Jan 1970
let migrationstartday birthdate + 365.25 * random-normal 25 3 ; normal distribution of starting times
;print (word "migrationstartday: " migrationstartday)
            ; transform to ticks
let migrationstartticks migrationstartday - (additional * 365.25)
;print (word "migrationstartticks:" migrationstartticks " This is " ((migrationstartticks - ticks) / 365.25) " years from now")
;print (word "I will be " ((migrationstartticks - (birthdate - additional * 365.25)) / 365.25) " years old")
ifelse migrationstartticks > ticks
[time:schedule-event self task migrationstart migrationstartticks]
[set migrationeventticks 0 ; Schedule migrationstart for after the first wage payment at ticks 30.4375
 time:schedule-event self task migrationstart 31
]

end

to schedule-income
let incomestartday birthdate + 365.25 * 16
set incomestartticks incomestartday - (additional * 365.25)
;print (word "incomestartticks:" incomestartticks " This is " ((incomestartticks - ticks) / 365.25) " years from now")
;print (word "I will be " ((incomestartticks - (birthdate - additional * 365.25)) / 365.25) " years old")
ifelse incomestartticks > ticks
[time:schedule-event self task draw-income incomestartticks]
[draw-income];do it right away
end


to draw-income
ifelse migrant = 1
[r:eval "income<-lognormalrandom(MeanIncomeEurope, GiniEurope)"
 set income r:get "income"
 ]
[r:eval "income<-lognormalrandom(MeanIncomeSenegal, GiniSenegal)"
 set income r:get "income"
  ]
if income < 0 [set income 1]
end

to schedule-incomepayment
;First, create a list of all wage payment dates as ticks. Payment must happen every 30.4375 ticks.

;print "666666666666666666666666666666666666666666666666666666666666666666666666666666"
;print "Scheduling income payment"
let counter 30.4375
r:eval "endDay<-floor((additionalEnd - additional) * 365.25)"
let endcount r:get "endDay"
while [counter < endcount]
[;print counter
 ;print "payday"
    time:schedule-event "observer" task payday counter
   set counter counter + 30.4375
]
end

to schedule-consumption
 ;update of consumption happens every day
let counter 1
r:eval "endDay<-floor((additionalEnd - additional) * 365.25)"
let endcount r:get "endDay"
while [counter < endcount]
[
   time:schedule-event "observer" task consumption counter
   set counter counter + 1
]
end


to schedule-output
;Measure output once a year
;let counter 365.25
;let endcount r:get "endDay"
;while [counter < endcount]
;[;print counter
; ;print "payday"
;    time:schedule-event "observer" task write-to-file counter
;   set counter counter + 365.25
;]
time:schedule-event "observer" task externalstop 24800
;;set file1 user-new-file
;if is-string? file1
;[if file-exists? file1
;  [file-delete file1]
;
;]
;set file2 user-new-file
;if is-string? file2
;[if file-exists? file2
;  [file-delete file2]
;
;]
;set file3 user-new-file
;if is-string? file3
;[if file-exists? file3
;  [file-delete file3]
;
;]
;
;set file4 user-new-file
;if is-string? file4
;[if file-exists? file4
;  [file-delete file4]
;
;]
end

to externalstop
set measure 1

end


to write-to-file

;if ticks > 24700 [set measure 1]
;if measure = 1
;[

let thisyear 1970 + (ticks / 365.25) + additional

file-open (word "Output " a1 a2 a3 a4 a5 a6 a7 rho1 ".txt")
file-print (word "Current time: " thisyear   " MigrantAgesSofar: " ageprofile " All ages so far " PeopleatAgePerYear " Total number migrants so far " MigrantsTotal " Total number female migrants so far " FemaleMigrantsTotal
            " a1 " a1 " a2 " a2 " a3 " a3 " a4 " a4 " a5 " a5 " a6 " a6 " a7 " a7 " rho1 " rho1 " rho2 " rho2 )
file-close

;print (word "Current time: " thisyear   " MigrantAgesSofar: " ageprofile " All ages so far " PeopleatAgePerYear " Total number migrants so far " MigrantsTotal " Total number female migrants so far " FemaleMigrantsTotal
;            " a1 " a1 " a2 " a2 " a3 " a3 " a4 " a4 " a5 " a5 " a6 " a6 " a7 " a7 " rho1 " rho1 " rho2 " rho2 )
;export-output (word "output a1" a1 "a2" a2 "a3"a3 "a4"a4"a5"a5 "a6"a6"a7" a7 "rho1"rho1".txt")
;]


end


to schedule-data-updates
let counter 0
let endcount r:get "endDay"
while [counter < endcount]
[
  time:schedule-event "observer" task data-update counter
  set counter counter + 365.25
]


end

to data-update
set MeanIncomeSenegal item ((ticks / 365.25) + (additional - 10)) IncomeSen
r:put "MeanIncomeSenegal" MeanIncomeSenegal
set MeanIncomeEurope item ((ticks / 365.25) + (additional - 10)) IncomeFra
r:put "MeanIncomeEurope" MeanIncomeEurope
set growthSenegal item ((ticks / 365.25) + (additional - 10)) growthSen
r:put "MeanIncomeSenegal" MeanIncomeSenegal
set growthEurope item ((ticks / 365.25) + (additional - 10)) growthFra
r:put "MeanIncomeEurope" MeanIncomeEurope

set borderEnforcement item ((ticks / 365.25) + (additional - 10)) border


; migration cost grows in line with French income growth after 2016
ifelse time:is-after current-time (time:create "2017-01-01 12:00")
[set pcMigrationCost pcMigrationCost + pcMigrationCost * growthEurope
]
[
set pcMigrationCost item ((ticks / 365.25) + (additional - 10)) migrationcost
]

ifelse time:is-after current-time (time:create "2015-01-01 12:00")
[set MonthlyConsumptionAdults MonthlyConsumptionAdults + MonthlyConsumptionAdults * growthSenegal
;set MonthlyConsumptionChildren MonthlyConsumptionAdults * 0.5
set MonthlyConsumptionAdultsMig MonthlyConsumptionAdultsMig + MonthlyConsumptionAdultsMig * growthEurope
;set MonthlyConsumptionChildrenMig MonthlyConsumptionAdultsMig * 0.5
]
[set MonthlyConsumptionAdults item ((ticks / 365.25) + (additional - 10)) ConsumptionSen
;set MonthlyConsumptionChildren item ((ticks / 365.25) + (additional - 10)) ConsumptionSen * 0.5
set MonthlyConsumptionAdultsMig item ((ticks / 365.25) + (additional - 10)) ConsumptionFra
;set MonthlyConsumptionChildrenMig item ((ticks / 365.25) + (additional - 10)) ConsumptionFra * 0.5
; consumption growth in line with income growth after 2014
]


ask persons with [income > 0] [ifelse migrant = 1
                                [set income income + income * growthEurope]
                                [set income income + income * growthSenegal]
                              ]

;update measurements
let thisyear 1970 + (ticks / 365.25) + additional

set PeopleatAgePerYear lput thisyear PeopleatAgePerYear

ask persons with [dead = 0 and unborn = 0][set AgeYearEnd (ticks / 365.25) - (birthdate / 365.25) + additional]
ask persons with [dead = 1 or unborn = 1] [set AgeYearEnd 99999]
let counter 0
while [counter < 101]
 [
   set PeopleatAge lput counter PeopleatAge
   set PeopleatAge lput count persons with [floor AgeYearEnd = round counter ] PeopleatAge
  set counter counter + 1
  ]

set PeopleatAgePerYear lput PeopleatAge PeopleatAgePerYear
set PeopleatAge [] ; empty again for next year


set MigrantsatAgePerYear lput thisyear MigrantsatAgePerYear
set MigrantsatAgePerYear lput MigrantsatAge MigrantsatAgePerYear

set MigrantsTotal lput thisyear MigrantsTotal
set MigrantsTotal lput length MigrantsatAge MigrantsTotal

set FemaleMigrantsTotal lput thisyear FemaleMigrantsTotal
set FemaleMigrantsTotal lput length FemaleMigrantsInYear FemaleMigrantsTotal

set MigrantsatAge []
set FemaleMigrantsInYear []


set marriageError[0]; otherwise the mean can't be formed
set foundNoPartner 0
set migrationsperyear 0 ; set back to 0 to start counting again in the new year

end


to consumption
;observer
;if ticks > 5000 [print (word"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC  " current-time "   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC  ")
 ;                 print "consumption"]
if any? households and ticks > 32 [ ; in the final version, everyone will live in a household
;let example-household one-of households
;ask example-household [print (word "who: " who "capital before consumption: " capital "members: " members )]
;let example-peoplelist [members] of example-household
;let example-turtleset turtle-set example-peoplelist

;ask example-turtleset [let adulthood birthdate + 365.25 * 16
 ;                      let adulthoodticks adulthood - (additional * 365.25)
  ;                     ifelse ticks < adulthoodticks
   ;                      [print (word "I am part of this household, my who is " who " my birthdate is " birthdate "and I am a child, thus will now consume "  (MonthlyConsumptionChildren / 30.4375))
    ;                     ]
     ;                    [print (word "I am part of this household, my who is " who " my birthdate is " birthdate "and I am an adult, thus will now consume " (MonthlyConsumptionAdults / 30.4375))
      ;                   ]

       ;                ]
ask households [  ;let count-adults 0
;                 let count-kids 0
                 let TotalConsumptionNeed 0
                 let mymembers turtle-set members
                  ask mymembers
                   [
;                    let adulthood birthdate + 365.25 * 16
;                    let adulthoodticks adulthood - (additional * 365.25)
;                    ifelse ticks < adulthoodticks
;                         [set count-kids count-kids + 1
;                        ifelse migrant = 1
;                           [set TotalConsumptionNeed TotalConsumptionNeed + (MonthlyConsumptionChildrenMig / 30.4375)]
;                           [set TotalConsumptionNeed TotalConsumptionNeed + (MonthlyConsumptionChildren / 30.4375)]
;                         ]
;                         [set count-adults count-adults + 1
                         ifelse migrant = 1
                           [set TotalConsumptionNeed TotalConsumptionNeed + (MonthlyConsumptionAdultsMig / 30.4375)]
                           [set TotalConsumptionNeed TotalConsumptionNeed + (MonthlyConsumptionAdults / 30.4375)]
                   ]

                  ifelse capital / 30.4375 > TotalConsumptionNeed
                   [
                     ask mymembers
                     [
                       ;let adulthood birthdate + 365.25 * 16
                       ;let adulthoodticks adulthood - (additional * 365.25)
                      ;ifelse ticks < adulthoodticks
                       ;  [ifelse migrant = 1
                        ;   [ask myself [set capital capital - (MonthlyConsumptionChildrenMig / 30.4375)]]
                         ;  [ask myself [set capital capital - (MonthlyConsumptionChildren / 30.4375)]]
                         ;]
                         ;[
                           ifelse migrant = 1
                           [ask myself [set capital capital - (MonthlyConsumptionAdultsMig / 30.4375)]]
                           [ask myself [set capital capital - (MonthlyConsumptionAdults / 30.4375)]]
                         ]
                   ]

                   [; otherwise, distribute capital such that it does not fall below 0 and increase mortality
                   ;print "Too poor"
                   ;print (word "Total cosumption need: " TotalConsumptionNeed)
                   ;print (word "Capital per day: " (capital / 30.4375) )
                   ifelse any? mymembers with [retired = 0]
                   [set capital capital - (capital / 30.4375)
                   ;print (word "Capital after consumption is now" capital)
                   if highmortality = 0
                   [;print "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
                     ;print (word "I, household " who " am too poor. My members are " members " and my capital is " capital)
                     ask mymembers [if sex = 20 and selfscheduled = 1  and AlreadyHighMortality != 1
                                       [;print "I am a poor woman"
                                         ;times have to be created first with "time-create"
                                         ;shorten popforlogo-private to only future events
                                         ;print (word "Popforlogo-private: " popforlogo-private)
                                         ifelse noMoreTransitions = 1
                                         [; we do not need to check if children have to be killed
                                         ]
                                         [set timeslist[]
                                         foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
                                         (foreach timeslist (item 2 popforlogo-private)
                                             [ifelse time:is-before ?1 current-time ; if the event has already passed, we don't need to worry about it
                                              [;print (word ?1 " has already passed")
                                                ]
                                              [ifelse ?2 < 14
                                                 [;print (word "Time: " ?1 " state: " ?2 " a child")
                                                  let timeTilBirthday time:difference-between current-time ?1 "days"
                                                   r:eval "roundedDay<-additional * 365.25"
                                                   let roundedDay r:get "roundedDay"
                                                   let UnbornBirthday roundedDay + ticks + timeTilBirthDay
                                                   ;print (word "birthday of baby would have been: " UnbornBirthday)
                                                   ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [ ;print "No blue persons left"
                                                 ]
                                                 ]
                                                 [;print (word "state: " ?2 " ,not a child")
                                                 ]
                                              ]
                                             ])

                                         ]
                                        set popforlogo-private []
                                        ;print (word who " set popforlog-private []")
                                       ]

                                     ifelse migrant = 1 [ ;print (word "I am " who " My income is " income "My migrantstatus is " migrant "My birthdate is " birthdate )
                                                         higher-mortality-Mig]
                                                       [;print (word "I am " who " My income is " income "My migrantstatus is " migrant "My birthdate is " birthdate )
                                                         higher-mortality]
                                   ]
                   set highmortality 1
                   ]
                  ]
                   [;only retired people
                     ;print "Only retired people"
                     set capital 0
                     ask mymembers [care]
                     die
                   ]
                ]
]
;ask example-household [print (word "who: " who "capital after consumption: " capital "members: " members ) ]
]

end



to payday
;observer
;print (word"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$  " current-time "   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$  ")
;print "payday"
if any? households [ ; in the final version, everyone will live in a household
;let example-household one-of households
;ask example-household [print (word "who: " who "capital before payment: " capital "members: " members )]
;let example-peoplelist [members] of example-household
;let example-turtleset turtle-set example-peoplelist
;ask example-turtleset [print (word "I am part of this household, my who is " who " and my income is " income "and my retirement status is " retired)]
ask households [ let mymembers turtle-set members
                 let paying-members mymembers with [retired = 0]
                 set capital capital + sum [income] of paying-members
                 set capitallist lput capital capitallist
                ]
;ask example-household [print (word "who: " who "capital after payment: " capital "members: " members ) ]
]
end

to give-marriagestamp
let datetimes time:ts-get-range transitions correct-starttime correct-endtime "LOGOTIME"
set marriedpersons []
set marrieddates []
   foreach datetimes [
   if time:ts-get transitions ? "newstate" = 15
     [
     set marriedpersons lput one-of persons with [migrant = 0 and id = time:ts-get transitions ? "ID"] marriedpersons
     set marrieddates lput ? marrieddates
      ]
                      ]

(foreach marriedpersons marrieddates [ask ?1 [ set marriagestamp lput ?2 marriagestamp]])

ask persons with [marriagestamp != [] and migrant = 0] [enter-marriagemarket]



end


to retirement
set retired 1
if dead = 1 [stop]
ifelse any? households with [member? myself members = true]
[; retired people in a household are taken care of in "Consumption"
]
[care
]
end

to care
;print "CARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARECARE"
;print (word "I, person " who "have to get some care")
ask persons [set indicator 0]
ifelse child = []
   [ifelse any? link-neighbors with [dead = 0 and color = [color] of myself]
     [
      ask link-neighbors with [dead = 0 and color = [color] of myself][ifelse any? households with [member? self members = true]
                            [let myhousehold one-of households with [member? self members = true]
                              set indicator [capital] of myhousehold
                          ]
                          [set indicator income
                          ]
                         ]
      let favoritefriend one-of link-neighbors with-max [indicator]
      move-to favoritefriend
      ifelse any? households with [member? favoritefriend members = true]
       [ask one-of households with [member? favoritefriend members = true]
          [set members lput myself members
           ;print (word "I, " [who] of myself " , joint the household " who)
          ]
        ;print (word "I moved in with my favorite friend " favoritefriend)
        ask other persons-here with [color = [color] of myself] [create-link-with myself]
        ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
        ]
       [; found a new household with the friend
         form-single-household
         let myhousehold one-of households with [member? myself members = true]
         ask myhousehold [set members lput favoritefriend members
                         ;print (word "I, " [who] of favoritefriend " , joint the household " who)
                         ]
         ;print (word "I formed a household with my favorite friend" favoritefriend)

        ]
     ]
     [set institution 1
       ;print "I moved to an institution"
     ]
   ]
   [let myKids turtle-set child
     ifelse any? myKids with [dead = 0 and color = [color] of myself]
     [ask myKids with [dead = 0 and color = [color] of myself][ifelse any? households with [member? self members = true]
                  [let myhousehold one-of households with [member? self members = true]
                   set indicator [capital] of myhousehold
                  ]
                  [set indicator income
                  ]
                ]
      let favoritekid one-of myKids with-max [indicator]
      move-to favoritekid

      ifelse any? households with [member? favoritekid members = true]
       [ask one-of households with [member? favoritekid members = true]
          [set members lput myself members
           ;print (word "I, " [who] of myself " , joint the household " who)
           ]
          ask other persons-here with [color = [color] of myself][create-link-with myself]
          ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]

        ;print (word "I moved in with my favorite kid " favoritekid)
        ]
       [; found a new household with the kid
         form-single-household
         let myhousehold one-of households with [member? myself members = true]
         ask myhousehold [set members lput favoritekid members]
        ;print (word "I, " [who] of favoritekid " , joint the household " who)
        ;print (word "I formed a household with my favorite kid " favoritekid)
        ]

   ]
     [set institution 1
       ;print "I moved to an institution"
     ]

   ]
ask persons [set indicator 0]
end


to enter-marriagemarket
foreach marriagestamp [set marriageyear time:get "year" ?
                       set marriagemonth time:get "month" ?
                       ifelse marriagemonth > 6
                             [set entryyear marriageyear
                              set entryyear (word entryyear)
                              set entrymonth marriagemonth - 6
                              ifelse entrymonth = 2 [set warndate 2  ;pay attention that some months do not have 31 days; if the wedding day is the 31st, the entry day must be set to the 30th
                                                    ]
                                                    [if entrymonth = 4 or entrymonth = 6
                                                        [set warndate 1]
                                                    ]

                              set entrymonth (word entrymonth)
                             ]
                             [set entryyear marriageyear - 1
                              set entryyear (word entryyear)
                              set entrymonth 6 + marriagemonth
                              if entrymonth = 9 or entrymonth = 11
                               [set warndate 1]
                              set entrymonth (word entrymonth)
                             ]
                       ;transform marriagedate to string
                       let marriagedate time:show ? "yyyy-MM-dd HH:mm:ss.SSS"
                       ;replace elements in string
                       let entrydate replace-item 0 marriagedate item 0 entryyear
                       set entrydate replace-item 1 entrydate item 1 entryyear
                       set entrydate replace-item 2 entrydate item 2 entryyear
                       set entrydate replace-item 3 entrydate item 3 entryyear
                       ifelse length entrymonth > 1
                        [set entrydate replace-item 5 entrydate item 0 entrymonth
                          set entrydate replace-item 6 entrydate item 1 entrymonth
                        ]
                        [set entrydate replace-item 5 entrydate (word 0)
                         set entrydate replace-item 6 entrydate item 0 entrymonth
                        ]
                       set dayofmonth (word item 8 marriagedate item 9 marriagedate);take care of long month issue
                       ;print (word "dayofmonth: " dayofmonth)
                       set dayasnumber read-from-string dayofmonth
                       ;print dayasnumber
                       ifelse warndate = 2;February
                                          [if dayasnumber > 28 [set dayasnumber 28
                                                                set dayofmonth (word 28)
                                                                set entrydate replace-item 8 entrydate item 0 dayofmonth
                                                                set entrydate replace-item 9 entrydate item 1 dayofmonth
                                                                ]

                                          ]
                                          [if warndate = 1 and dayasnumber = 31 [set dayasnumber 30
                                                                                 set dayofmonth (word 30)
                                                                                 set entrydate replace-item 8 entrydate item 0 dayofmonth
                                                                                 set entrydate replace-item 9 entrydate item 1 dayofmonth
                                                                                 ]
                                          ]

                       ;print entrydate
                       ; transform back to date
                       let entrytime time:create entrydate
                       ;print entrytime
                       ;check if entrytime is actually AFTER the current moment. If the current moment is after entrytime, then enter the marriage market right away
                       ifelse time:is-before current-time entrytime
                       [time:schedule-event self task marriagemarket entrytime
                        ;print (word who " schedules entry in marriagemarket at" entrytime)
                        ]
                       [marriagemarket ;entry right away
                         ;print (word who "enters marriage-market now at" current-time)
                       ]

                       ]

set warndate 0
end

to marriagemarket
;print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
;print (word who "enters marriagemarket")
;print current-time
ifelse marriagestamp = []
[;print (word "No marriagestamp, this must be canceled. Marital: " marital "Unborn? " unborn)
  set timetomarriage 9999999999999
  ]
[set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
;print (word "time to marriage: " timetomarriage " marital: " marital)
]
; we have to make sure that only people who are currently still planning to get married do get married, i.e., we also have to take care of cancelled marriage-market entries
ifelse marital != 15 and timetomarriage <= 185 and migrant = 0 ; only non-migrants get married through the marriage market
[set inmarriagemarket 1
 set searchattempts 0
 ;print "mating procedure"

                    ask persons with [inmarriagemarket = 1]
                                       [set counted 0
                                        set compatibility 0
                                        set currentmarriage item 0 marriagestamp
                                        ;print (word "Who: " who "  Currentmarriage:" currentmarriage "  Gender: " sex " birthdate: " birthdate " searchattempts " searchattempts)
                                        set marriageyear time:get "year" currentmarriage
                                        set marriagemonth time:get "month" currentmarriage
                                        let marriagedate time:show currentmarriage "yyyy-MM-dd HH:mm:ss.SSS"
                                        set dayofmonth (word item 8 marriagedate item 9 marriagedate)
                                        set dayasnumber read-from-string dayofmonth

                                       ]

                                    let minyear [marriageyear] of one-of persons with [inmarriagemarket = 1] with-min [marriageyear]
                                    let selection1 persons with [inmarriagemarket = 1 and marriageyear = minyear]
                                    ;print selection1
                                    ;print [who] of persons with [member? self selection1 = true]
                                    let minmonth [marriagemonth] of one-of persons with [member? self selection1 = true] with-min [marriagemonth]
                                    let selection2 persons with [member? self selection1 = true and marriagemonth = minmonth]
                                    ;print selection2
                                    ;print [who] of persons with [member? self selection2 = true]
                                    ask one-of selection2 with-min [dayasnumber]
                                                  [;print (word who "makes selection")
                                                    set counted 1
                                                    set currentchooser 1
                                                    set searchattempts searchattempts + 1
                                                    ifelse sex = 10
                                                           [if any? persons with [sex = 20 and color = [color] of myself and inmarriagemarket = 1 and counted = 0 and (parent != [parent] of myself or parent = []) and abs (birthdate - [birthdate] of myself) < 7300 and member? myself parent = false and member? myself child = false ]; if no people of the other gender are in the marriage market, nothing happens
                                                             ;first look for people with marriage date within one year. If person with next-earliest marriage date
                                                             ; has their marriage date more than 6 months after mine, consider everyone because everyone coming later will have an even later
                                                             ; marriage date
                                                              [;print "IF was answered with YES"
                                                                ask persons with [sex = 20 and color = [color] of myself and inmarriagemarket = 1 and counted = 0 and (parent != [parent] of myself or parent = []) and abs (birthdate - [birthdate] of myself) < 7300 and member? myself parent = false and member? myself child = false ]
                                                                    [set candidate 1

                                                                      set marriagedistance time:difference-between [currentmarriage] of myself currentmarriage "months"
                                                                     set marriagedistance abs marriagedistance
                                                                    ]
                                                               let selection3 persons with [candidate = 1 and marriagedistance < 7]
                                                               ifelse any? selection3
                                                                 [ask selection3 [compute-compatibility
                                                                                  ]
                                                                  set potentialpartner one-of selection3 with-max [compatibility]

                                                                  let peopleinmarket count persons with [inmarriagemarket = 1]
                                                                  if searchattempts > peopleinmarket
                                                                                      [ask potentialpartner
                                                                                        [set compatibility 1
                                                                                        ]
                                                                                       ]
                                                                  let randomdraw random-float 1
                                                                  ;print (word "randomdraw  " randomdraw "vs compatibility score" [compatibility] of potentialpartner)
                                                                  if randomdraw < [compatibility] of potentialpartner
                                                                    [
                                                                      set searchattempts 0
                                                                      set marital 15
                                                                      set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                      set MarriageError lput timetomarriage MarriageError
                                                                      set spouse potentialpartner
                                                                      create-link-with potentialpartner
                                                                      set marriagestamp but-first marriagestamp
                                                                      set inmarriagemarket 0
                                                                      ;print who
                                                                      ;print (word "gender: " sex)
                                                                      ;print current-time
                                                                      ;print "got married"
                                                                      ;print (word "new marriagestamp: " marriagestamp)
                                                                      ;print (word "Parents:" parent)
                                                                      ask potentialpartner; A man is getting married. Women (arbitrarily) form the household
                                                                                 [set marital 15
                                                                                   set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                                  set MarriageError lput timetomarriage MarriageError
                                                                                  set spouse myself
                                                                                  set searchattempts 0
                                                                                 ;married couple delete their first entry of "marriagestamp" and exit the marriagemarket
                                                                                  set marriagestamp but-first marriagestamp
                                                                                  set inmarriagemarket 0
                                                                                  ;print who
                                                                                  ;print (word "gender: " sex)
                                                                                  ;print current-time
                                                                                  ;print "got married"
                                                                                  ;print (word "new marriagestamp: " marriagestamp)
                                                                                  ;print (word "Parents:" parent)
                                                                                  form-household
                                                                                  if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                    [set migrationeventticks ticks
                                                                                      migrationstart]
                                                                                  ]
                                                                    if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                 [set migrationeventticks ticks
                                                                                   migrationstart
                                                                                   ]
                                                                    ]

                                                                 ]
                                                                 [;consider everyone
                                                                   ask persons with [candidate = 1] [compute-compatibility]
                                                                   set potentialpartner one-of persons with [candidate = 1] with-max [compatibility]

                                                                  let peopleinmarket count persons with [inmarriagemarket = 1]
                                                                  if searchattempts > peopleinmarket
                                                                                      [ask potentialpartner
                                                                                        [set compatibility 1
                                                                                        ]
                                                                                       ]
                                                                   let randomdraw random-float 1
                                                                   ;print (word "randomdraw  " randomdraw "vs compatibility score" [compatibility] of potentialpartner)
                                                                    if randomdraw < [compatibility] of potentialpartner
                                                                    [
                                                                      set searchattempts 0
                                                                      set marital 15
                                                                      set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                      set MarriageError lput timetomarriage MarriageError
                                                                      set spouse potentialpartner
                                                                      create-link-with potentialpartner
                                                                      set marriagestamp but-first marriagestamp
                                                                      set inmarriagemarket 0
                                                                      ;print who
                                                                      ;print (word "gender: " sex)
                                                                      ;print current-time
                                                                      ;print "got married"
                                                                      ;print (word "new marriagestamp: " marriagestamp)
                                                                      ;print (word "Parents:" parent)
                                                                      ask potentialpartner
                                                                                 [set marital 15
                                                                                   set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                                   set MarriageError lput timetomarriage MarriageError
                                                                                  set spouse myself
                                                                                  set searchattempts 0
                                                                                  ;married couple delete their first entry of "marriagestamp" and exit the marriagemarket
                                                                                  set marriagestamp but-first marriagestamp
                                                                                  set inmarriagemarket 0
                                                                                  ;print who
                                                                                  ;print (word "gender: " sex)
                                                                                  ;print current-time
                                                                                  ;print "got married"
                                                                                  ;print (word "new marriagestamp: " marriagestamp)
                                                                                  ;print (word "Parents:" parent)
                                                                                  form-household

                                                                                 if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                 [set migrationeventticks ticks
                                                                                   migrationstart
                                                                                   ]
                                                                                 ]

                                                                    if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                 [set migrationeventticks ticks
                                                                                   migrationstart
                                                                                   ]
                                                                    ]

                                                                 ]

                                                              ]
                                                           ];now for women
                                                           [if any? persons with [sex = 10 and color = [color] of myself and inmarriagemarket = 1 and counted = 0 and (parent != [parent] of myself or parent = []) and abs (birthdate - [birthdate] of myself) < 7300 and member? myself parent = false and member? myself child = false ]; if no people of the other gender are in the marriage market, nothing happens
                                                             ;first look for people with marriage date within one year. If person with next-earliest marriage date
                                                             ; has their marriage date more than 6 months after mine, consider everyone because everyone coming later will have an even later
                                                             ; marriage date
                                                              [;print "IF was answered with YES"
                                                                ask persons with [sex = 10 and color = [color] of myself and inmarriagemarket = 1 and counted = 0 and (parent != [parent] of myself or parent = []) and abs (birthdate - [birthdate] of myself) < 7300 and member? myself parent = false and member? myself child = false ]
                                                                    [set candidate 1
                                                                      set marriagedistance time:difference-between [currentmarriage] of myself currentmarriage "months"
                                                                     set marriagedistance abs marriagedistance
                                                                    ]
                                                               let selection3 persons with [candidate = 1 and marriagedistance < 7]
                                                               ifelse any? selection3
                                                                 [ask selection3 [compute-compatibility
                                                                                  ]
                                                                  set potentialpartner one-of selection3 with-max [compatibility]

                                                                  let peopleinmarket count persons with [inmarriagemarket = 1]
                                                                  if searchattempts > peopleinmarket
                                                                                      [ask potentialpartner
                                                                                        [set compatibility 1
                                                                                        ]
                                                                                       ]
                                                                  let randomdraw random-float 1
                                                                  ;print (word "randomdraw  " randomdraw "vs compatibility score" [compatibility] of potentialpartner)
                                                                  if randomdraw < [compatibility] of potentialpartner
                                                                    [ask potentialpartner
                                                                                 [set marital 15
                                                                                  set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                                  set MarriageError lput timetomarriage MarriageError
                                                                                  set spouse myself
                                                                                  set searchattempts 0
                                                                                  ;married couple delete their first entry of "marriagestamp" and exit the marriagemarket
                                                                                  set marriagestamp but-first marriagestamp
                                                                                  set inmarriagemarket 0
                                                                                  ;print who
                                                                                  ;print (word "gender: " sex)
                                                                                  ;print current-time
                                                                                  ;print "got married"
                                                                                 ;print (word "new marriagestamp: " marriagestamp)
                                                                                 ;print (word "Parents:" parent)
                                                                                 ]

                                                                      set marital 15
                                                                      set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                      set MarriageError lput timetomarriage MarriageError
                                                                      set spouse potentialpartner
                                                                      create-link-with potentialpartner
                                                                      set marriagestamp but-first marriagestamp
                                                                      set inmarriagemarket 0
                                                                      set searchattempts 0
                                                                      ;print who
                                                                      ;print (word "gender: " sex)
                                                                      ;print current-time
                                                                      ;print "got married"
                                                                     ;print (word "new marriagestamp: " marriagestamp)
                                                                     ;print (word "Parents:" parent)
                                                                     form-household

                                                                    if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                 [set migrationeventticks ticks
                                                                                   migrationstart]
                                                                    ask potentialpartner [if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                             [set migrationeventticks ticks
                                                                                               migrationstart]
                                                                                          ]
                                                                    ]

                                                                 ]
                                                                 [;consider everyone
                                                                   ask persons with [candidate = 1] [compute-compatibility]
                                                                   set potentialpartner one-of persons with [candidate = 1] with-max [compatibility]

                                                                  let peopleinmarket count persons with [inmarriagemarket = 1]
                                                                  if searchattempts > peopleinmarket
                                                                                      [ask potentialpartner
                                                                                        [set compatibility 1
                                                                                        ]
                                                                                       ]
                                                                   let randomdraw random-float 1
                                                                   ;print (word "randomdraw  " randomdraw "vs compatibility score" [compatibility] of potentialpartner)
                                                                    if randomdraw < [compatibility] of potentialpartner
                                                                    [ask potentialpartner
                                                                                 [
                                                                                   set searchattempts 0
                                                                                   set marital 15
                                                                                   set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                                   set MarriageError lput timetomarriage MarriageError
                                                                                  set spouse myself
                                                                                  set marriagestamp but-first marriagestamp
                                                                                  set inmarriagemarket 0
                                                                                  ;print who
                                                                                  ;print (word "gender: " sex)
                                                                                  ;print current-time
                                                                                  ;print "got married"
                                                                                  ;print (word "new marriagestamp: " marriagestamp)
                                                                                  ;print (word "Parents:" parent)
                                                                                  ]
                                                                      set searchattempts 0
                                                                      set marital 15
                                                                      set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
                                                                      set MarriageError lput timetomarriage MarriageError
                                                                      set spouse potentialpartner
                                                                      create-link-with potentialpartner
                                                                      set marriagestamp but-first marriagestamp
                                                                      set inmarriagemarket 0
                                                                      ;print who
                                                                      ;print (word "gender: " sex)
                                                                      ;print current-time
                                                                      ;print "got married"
                                                                      ;print (word "new marriagestamp: " marriagestamp)
                                                                     ;print (word "Parents:" parent)
                                                                     form-household
                                                                     if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                 [set migrationeventticks ticks
                                                                                   migrationstart]
                                                                     ask potentialpartner [if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                                                                             [set migrationeventticks ticks
                                                                                               migrationstart
                                                                                               ]
                                                                                          ]
                                                                     ]

                                                                 ]

                                                               ]

                                                           ]
                                                  set currentchooser 0
                                                  ]







ask persons with [candidate = 1] [set candidate 0]
; people drop out of the marriage market if their schedueled marriage date has passed more than a year ago.The event is then cancelled and a new event is simulated.
ask persons with [inmarriagemarket = 1]
   [set timetomarriage time:difference-between current-time item 0 marriagestamp "days"
    if abs timetomarriage > 365
      [;print (word "I am " who " and my time since marriage is " timetomarriage)
       set inmarriagemarket 0
       set marriagestamp []
       set indicator 1
       set state 14
      ]

   ]
ask persons with [indicator = 1 ] ; these people get a new life
       [ set foundNoPartner foundNoPartner + 1
         ifelse AlreadyHighMortality = 1
        [set AlreadyHighMortality 0 ; otherwise, no new life is scheduled
          set indicator 0
          higher-mortality
          ]
        [set indicator 0
          schedule-event
          ]
       ]
]
[;print (word "who: " who "migrant: " migrant "marital:" marital " does not get married through the marriage market")
]

end

;########################################################################################################################
to compute-compatibility
let myage ((ticks - birthdate) / 365.25) +  additional
let personaskingme one-of persons with [currentchooser = 1]
let agepartner ((ticks - [birthdate] of personaskingme) / 365.25) +  additional
let agedifferenceCoefficient 0
ifelse sex = 10 ;AUF ALTER ACHTEN
 [ let agedifference myage - agepartner ; from man's perspective. If this value is positive, man is older
    ifelse agedifference < -10
      [set agedifferenceCoefficient -2.295514945
      ]
      [ifelse agedifference >= -10 and agedifference < -5
        [set agedifferenceCoefficient -2.403313133
        ]
        [ifelse agedifference >= -5 and agedifference < -1
          [set agedifferenceCoefficient -1.299496013
          ]
          [ifelse agedifference >= -1 and agedifference < 1
            [set agedifferenceCoefficient 0
            ]
            [ifelse agedifference >= 1 and agedifference < 6
              [set agedifferenceCoefficient 1.26919998
              ]
              [ifelse agedifference >= 6 and agedifference < 10
                [set agedifferenceCoefficient 1.686455806
                ]
                [ifelse agedifference >= 10 and agedifference < 20
                  [ set agedifferenceCoefficient 1.289031736
                  ]
                  [set agedifferenceCoefficient 0.392676886
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
   ;difference between initial marriage market and marriage market during run: age of man is not included during run
   let odds 0
   ifelse ticks > 0
   [set odds exp(-0.490129556 + -0.01301431 * myage + agedifferenceCoefficient)]
   [set odds exp(-0.490129556 +  agedifferenceCoefficient)]
   set compatibility (odds / (1 + odds))
 ]
 [; jetzt das gleiche umgekehrt fuer Frauen
   let agedifference agepartner - myage ; from woman's perspective. If this value is positive, man is older. So we can use the same coefficients.
    ifelse agedifference < -10
      [set agedifferenceCoefficient -2.295514945
      ]
      [ifelse agedifference >= -10 and agedifference < -5
        [set agedifferenceCoefficient -2.403313133
        ]
        [ifelse agedifference >= -5 and agedifference < -1
          [set agedifferenceCoefficient -1.299496013
          ]
          [ifelse agedifference >= -1 and agedifference < 1
            [set agedifferenceCoefficient 0
            ]
            [ifelse agedifference >= 1 and agedifference < 6
              [set agedifferenceCoefficient 1.26919998
              ]
              [ifelse agedifference >= 6 and agedifference < 10
                [set agedifferenceCoefficient 1.686455806
                ]
                [ifelse agedifference >= 10 and agedifference < 20
                  [ set agedifferenceCoefficient 1.289031736
                  ]
                  [set agedifferenceCoefficient 0.392676886
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
   let odds exp(-0.490129556 + -0.01301431 * agepartner + agedifferenceCoefficient)
   set compatibility (odds / (1 + odds))

 ]

end


;#################################################################################################################################################################################
to form-household
;delete previous household memberships
ifelse any? households with [member? myself members = true]
    [ask households with [member? myself members = true]
      [set members remove myself members
        ;print (word "I, " [who] of myself " , left the household " who)
       set capitallist [] ;HH composition changes, so capitallist must be set to 0
       ifelse members = []
         [;print (word "no members left, thus I, household " who " can die")
           let newinitialwealth capital
           ask myself [set initialwealth newinitialwealth]
           die
          ]
         [;print (word "There are still members in the old household " who " left. They are " members)
          ; take my own proportion of the household capital with me
          let newinitialwealth (capital / (length members + 1))
          ask myself [set initialwealth newinitialwealth]
          set capital capital - newinitialwealth
          ]
         ]
     ;print (word who " is leaving the old household")
    ]
    [;print "no old household to leave"
    ]
rt 45
fd 5
hatch-households 1 [;print (word "A new household was created, its who is " who)
                   set members []
                   set members lput myself members
                   ;print (word "I, " [who] of myself " , joint the household " who)
                   set shape "house"
                   set color green
                   set indicator 1

                   set highmortality 0
                   set capitallist []

                   ]
       ask other persons-here with [color = [color] of myself][create-link-with myself]
       ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
let myPartner [spouse] of self
;print (word "my Partner: " myPartner )
ask myPartner  [move-to myself
                ask other persons-here with [color = [color] of myself] [create-link-with myself]
                ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
                ]
ifelse any? households with [member? myPartner members = true]
                            [ask households with [member? myPartner members = true]
                              [set members remove myPartner members
                                ;print (word "I, " [who] of myPartner " , left the household " who)
                                set capitallist []
                               ifelse members = []
                                 [;print (word "no members left, thus I, household " who " can die")
                                  let newinitialwealth capital
                                  ask myPartner [set initialwealth newinitialwealth]
                                  die
                                  ]
                                 [;print (word "There are still members in the old household " who " left. They are " members)
                                  let newinitialwealth (capital / (length members + 1))
                                   ask myPartner [set initialwealth newinitialwealth]
                                   set capital capital - newinitialwealth
                                  ]
                              ]
                               ;print (word myPartner " is leaving the old household")
                              ]
                            [;print "no old household to leave for my partner"
                            ]
ask households with [indicator = 1][set members lput myPartner members
                                    ;print (word "I, " [who] of myPartner " , joint the household " who)
                                    ]


;check if the woman already has children and if they are under the age of 16 and unmarried
ifelse any? persons with [member? myself parent = true and birthdate - additional * 365.25 + 16 * 365.25 > ticks and marital = 14   ]
    [;print "YES THERE ARE KIDDOS HERE"
      ask persons with [member? myself parent = true and birthdate - additional * 365.25 + 16 * 365.25 > ticks and marital = 14]
        [move-to myself
        ask other persons-here with [color = [color] of myself][create-link-with myself]
        ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
         set indicator 1]
     while [any? persons with [indicator = 1]]
         [let currentchild one-of persons with [indicator = 1]
           ifelse any? households with [member? currentchild members = true]
                            [ask households with [member? currentchild members = true]
                              [set members remove currentchild members
                                ;print (word "I, " [who] of currentchild " , left the household " who)
                                set capitallist []
                                ifelse members = []
                                 [;print (word "no members left, thus I, household " who " can die")
                                   let newinitialwealth capital
                                   ask currentchild [set initialwealth newinitialwealth]
                                   die
                                   ]
                                 [;print (word "There are still members in the old household " who " left. They are " members)
                                   let newinitialwealth (capital / (length members + 1))
                                   ask currentchild [set initialwealth newinitialwealth]
                                   set capital capital - newinitialwealth
                                 ]
                               ]
                               ;print (word currentchild ", my child, is leaving the old household")
                              ]
                            [;print "no old household to leave for my child"
                            ]
           ask households with [indicator = 1] [set members lput currentchild members
                                               ;print (word "I, " [who] of currentchild " , joint the household " who)
                                               ]
           ask currentchild [if migrantkid = 0 [set parent lput myPartner parent
                                                create-link-with myPartner]

                             ]
           ask myPartner [ if [migrantkid] of currentchild = 0 [set child lput currentchild child
                                                                ;print (word who " adopted " currentchild)
                                                                ]
                          ]
           ask currentchild [set indicator 0
                             set migrantkid 0
                             ]
         ]

    ]
    [;print "I DO NOT HAVE UNDERAGE KIDS"
    ]

ask households with [indicator != 0][set capital sum [initialwealth] of turtle-set members
                                     ask turtle-set members [set initialwealth 0]
                                     ;print (word "I, " who ", am a new household, my members are: " members " , my capital is " capital)
                                     set indicator 0]
ask persons with [indicator != 0][set indicator 0]
end


to form-single-household
rt 45
fd 5
hatch-households 1 [;print (word "A new household was created, its who is " who)
                   set members []
                   set members lput myself members
                   ;print (word "I, " [who] of myself " , joint the household " who)
                   set shape "house"
                   set color green
                   set indicator 1
                   set capitallist []

                   ]
        ask other persons-here with [color = [color] of myself] [create-link-with myself]
        ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
;check if it is a woman and if she already has children and if they are under the age of 16 and unmarried
ifelse sex = 20 and any? persons with [member? myself parent = true and birthdate - additional * 365.25 + 16 * 365.25 > ticks and marital = 14   ]
    [;print (word "Yes there are kids and my gender is " sex)
      ask persons with [member? myself parent = true and birthdate - additional * 365.25 + 16 * 365.25 > ticks and marital = 14]
        [move-to myself
         set indicator 1]
     while [any? persons with [indicator = 1]]
         [let currentchild one-of persons with [indicator = 1]
           ifelse any? households with [member? currentchild members = true]
                            [ask households with [member? currentchild members = true]
                              [set members remove currentchild members
                                ;print (word "I, " [who] of currentchild " , left the household " who)
                                set capitallist []
                                ifelse members = []
                                 [;print (word "no members left, thus I, household " who " can die")
                                   let newinitialwealth capital
                                   ask currentchild [set initialwealth newinitialwealth]
                                   die
                                   ]
                                 [;print (word "There are still members in the old household " who " left. They are " members)
                                   let newinitialwealth (capital / (length members + 1))
                                   ask currentchild [set initialwealth newinitialwealth]
                                   set capital capital - newinitialwealth
                                 ]
                                ]
                               ;print (word currentchild ", my child, is leaving the old household and moving to my new household.")
                              ]
                            [;print "no old household to leave for my child"
                            ]
           ask households with [indicator = 1] [set members lput currentchild members
                                                ;print (word "I, " [who] of currentchild " , joint the household " who)
                                                ]

           ask currentchild [set indicator 0
                             ask other persons-here with [color = [color] of myself][create-link-with myself]
                             ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
                             ]
         ]

    ]
    [;ifelse sex = 10 [print "I am a man and thus no children move with me"
      ;               ]
       ;              [print "I DO NOT HAVE UNDERAGE KIDS"
        ;             ]
    ]

ask households with [indicator != 0][set capital sum [initialwealth] of turtle-set members

                                    ;print (word "I, " who ", am a new household, my members are: " members " , my capital is " capital)
                                    set indicator 0
                                    ask turtle-set members [set initialwealth 0]
                                    ]
ask persons with [indicator != 0][set indicator 0]
ask persons [set migrantkid 0]
end



;#################################################################################################################################################################################
to perform-transition
set timesmatch []
;print "#####################################################################################################################"
;print (word "who: " who)
;print (word "ID: " id)
;print current-time

if unborn = 1 [;print "UNBORN PERSON"
               ifelse id = time:ts-get transitions current-time "ID"  and abs(time:difference-between current-time item 0 (time:ts-get transitions current-time "all") "minutes") < 1 ;this is then a cancelled event, don't do anything
                [;print "normal event was cancelled"
                 ;print id
                 ;print time:ts-get transitions current-time "ID"
                 if sex = 20
                    [let cancelledevent time:ts-get transitions current-time "newstate"
                      ;print (word "The cancelled event is " cancelledevent)
                      if cancelledevent < 14
                      [
                        let UnbornBirthday additional * 365.25 + ticks

                         ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]
                   ];if it is a woman, children who are not being born are killed
                ]
                ]
                [;print "Unborn person would have experienced self-scheduled event";times have to be created first with "time-create"
               set state 9999
               ;print (word "popforlogo-private: " popforlogo-private)
               if noMoreTransitions = 1 [
                                         stop]
               set timeslist[]
               foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
               ;print timeslist
               (foreach timeslist (item 2 popforlogo-private)
              [ifelse time:difference-between ?1 current-time "minutes" < 1 and time:difference-between ?1 current-time "minutes" > -1
              [set state ?2
                ;print (word "new state would have been " state)
                set timesmatch lput 1 timesmatch
                ;print timesmatch
               ]
              [;print "state not found"
               ;print timesmatch
              ]
              ] )           ; this is a self-scheduled event. Check in your own private popforlogo list, what your new state is
               if state < 14
                     [
                        let UnbornBirthday additional * 365.25 + ticks

                         ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]
                   ]


               ]
             stop
             ]


 ifelse selfscheduled = 1
 [ ;print "selfscheduled"
   ;print (word "actual current time: " current-time " versus current-time on transitions list: " item 0 (time:ts-get transitions current-time "all"))
   ifelse id = time:ts-get transitions current-time "ID" and abs(time:difference-between current-time item 0 (time:ts-get transitions current-time "all") "minutes") < 1 ;this is then a cancelled event, don't do anything
      [;print "normal event was cancelled"
       ;print id
       ;print time:ts-get transitions current-time "ID"

       if sex = 20
        [let cancelledevent time:ts-get transitions current-time "newstate"
         ;print (word "The cancelled event is " cancelledevent)
         if cancelledevent < 14
   [
                        let UnbornBirthday additional * 365.25 + ticks

                         ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]
                   ]
          ];if it is a woman, children who are not being born are killed

      ]
      [if NoMoreTransitions = 1 [stop]
        if dead = 1 [;print "I am already dead"
                      stop
                     ]
        ;times have to be created first with "time-create"
        set timeslist[]
        foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
        ;print timeslist
        (foreach timeslist (item 2 popforlogo-private)
         [ifelse time:difference-between ?1 current-time "minutes" < 1 and time:difference-between ?1 current-time "minutes" > -1
              [set state ?2
                ;print (word "new state " state)
                set timesmatch lput 1 timesmatch
                ;print timesmatch
               ]
              [;print "state not found"
               ;print timesmatch
              ]
              ] )           ; this is a self-scheduled event. Check in your own private popforlogo list, what your new state is

      ]
 ]
 [;print "normal event"
   set state time:ts-get transitions current-time "newstate"; only those who still use the inititally scheduled stuff have to read it in
  ;print state
 ]
  ifelse (selfscheduled = 1 and id = time:ts-get  transitions current-time "ID"  and abs(time:difference-between current-time item 0 (time:ts-get transitions current-time "all") "minutes") < 1) or (selfscheduled = 1 and timesmatch = [])  ;make sure that events that have been "overwritten" by self-scheduled events are no longer executed;don't do anything
  [ ;print "Self-scheduled event was cancelled"
  ]
  [ ifelse state < 14[set fert state
                      ;print "fert changed"
                   let roundedDay additional * 365.25
                     ;print (word "Birthdate should now approximately be" round(roundedDay + ticks))
                     ifelse any? persons with [birthdate = round (roundedDay + ticks) and color = blue]
                       [set myChild one-of persons with [birthdate = round(roundedDay + ticks) and color = blue] ; identify children born on that day and unite with them
                        ]
                        [ ifelse any? persons with [color = blue]
                          [set myChild one-of persons with [color = blue] with-min [birthdate]]
                          [;print "No blue persons left"
                           stop
                           ] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                        ]
                      ask myChild
                        [ifelse [migrant] of myself = 1
                          [set color pink]
                          [set color red
                           set birthdate floor (roundedDay + ticks)
                           ]
                         ;print (word "I am the child, who-number: " who ", ID: " id ", birthdate: " birthdate)
                         move-to myself
                         set parent lput myself parent
                         ask other persons-here with [color = [color] of myself][create-link-with myself]
                         ask persons-on neighbors [if color = [color] of myself [create-link-with myself]]
                         ]

                         let siblings 0
                         if child != 0 and child != []
                          [set siblings turtle-set child
                           ask siblings [create-link-with myChild]
                           ]


                     ifelse any? households with [member? myself members = true]
                          [;print (word "I, the mother, live in household " [who] of one-of households with [member? myself members = true] )
                           ask one-of households with [member? myself members = true]
                            [;print (word "I, household " who "welcome my new member " myChild)
                              set members lput myChild members
                              ;print (word "I, " [who] of myChild " , joint the household " who)
                              set capitallist []
                            ]
                           ]
                           [;print (word "I, the mother, am not part of a household")
                           ]
                     set child lput myChild child
                     ifelse marital = 15
                     [ask [spouse] of self [set child lput myChild child
                                            create-link-with myChild
                                            ;print (word "new father with married mother:" who)
                                            ]
                     ]
                     [;print (word "I am a single mother, my marital state is " marital )
                     ]
                   if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                     [set migrationeventticks ticks
                       migrationstart]
                   ]
                   [ifelse state = 15
                     [;Marriage is organized by the marriagemarket for non-migrants
                      ifelse migrant = 1
                       [
                         set marital 15 ;person is created for the migrant to marry.
                         set marriagestamp but-first marriagestamp
                         hatch-persons 1
                           [set size 3
                             set waitingtime1[]
                             set waitingtime2[]
                            set id 0
                            set migrant 1
                            set migrantkid 0
                            set selfscheduled 1
                            set birthdate [birthdate] of myself
                            set spouse myself
                            set indicator 0
                            ifelse [sex] of myself = 10
                              [set sex 20]
                              [set sex 10]
                            set fert 0
                            set marital 15
                            set parent []
                            set child []
                            set retired 0
                            set migrationeventticks 0
                            set marriagestamp []
                            set state 15
                            set popforlogo-private [] ; otherwise, the spouse inherits that of the partner
                            ;print (word who " set popforlog-private []")
                            draw-income
                            ;print who
                            ;print (word "gender: " sex)
                            ;print current-time
                            ;print "was created as spouse"
                            schedule-event-Mig
                           set indicator 1
                           set searchattempts 0
                           ]
                          ;print (word "These are the people with indicator > 0: ")
                          ;ask persons with [indicator > 0] [print (word "I have indicator > 0, my who is " who)]
                          let myspouse one-of persons with [indicator = 1]
                          create-link-with myspouse
                          set spouse myspouse
                          ask myspouse [set indicator 0]
                         form-household
                         ]
                        [;print "Marriage is now organized by the marriagemarket"
                         ]
                     ]
                     [ifelse state = 16
                       [ifelse marital = 15
                         [set marital 16
                         ;print (word "got divorced, my spouse was" spouse)
                         ask link-with spouse [die]
                         form-single-household
                         if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                         [set migrationeventticks ticks
                           migrationstart]
                         ask spouse [set spouse []
                                     set marital 16
                                     ;print "*****************************************************"
                                     ;print (word "I AM A MAN GETTING DIVORCED, my who is: " who)
                                     ;move out of the household, form new household
                                     ifelse migrant = 1
                                     [schedule-event-Mig
                                     ]
                                     [schedule-event
                                     ]
                                     form-single-household
                                     if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                        [set migrationeventticks ticks
                                          migrationstart]
                                     ]
                         set spouse []
                         ]
                         [; state = 16 even though the person is not married can happen if the person is still in the marriagemarket and has not found anyone.
                          ;We assume the marriage happened really fast and is now already over. This should hopefully not occur too frequently.
                          ;it also happens when the person is widowed.
                           set marital 16
                           set inmarriagemarket 0
                             set marriagestamp but-first marriagestamp
                            ;print "widowed or did not have time to get married"
                            ;print (word "new marriagestamp: " marriagestamp)
                           ]


                       ]
                       [set dead  1 ; when state = 17
                          set color grey
                          let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                          move-to cemetary
                          ask my-links [die]
                          set inmarriagemarket 0
                          ;delete previous household memberships
                           ifelse any? households with [member? myself members = true]
                           [ask households with [member? myself members = true]
                             [set members remove myself members
                              ;print (word "I, " [who] of myself " , left the household " who)
                               set capitallist []
                              ifelse members = []
                                 [;print (word "no members left, thus I, household " who " can die")
                                     die
                                 ]
                                 [;print (word "There are still members in the old household " who " left. They are " members)
                                 ]
                              ]; if I was the last person in the household, the household dies as well
                            ;print (word who " has died and is leaving the old household")

                            ]
                            [;print "Dead person was not living in a household"
                            ]
                         ifelse marital = 15 ;if dead person was married, there is now a widow who has to compute a new life. Distinguish between migrant and non-migrant.
                           [ask [spouse] of self
                                    [set spouse []
                                     set marital 16 ; here, we do not distinguish between widowed and divorced as it does not make a difference for the rates
                                     ;print "*****************************************************"
                                     ;print (word "I AM A WIDOW, my who is: " who)
                                     ;if the widow is a woman she will get a new life course, thus her planned children will not be born. They have thus to be killed.
                                     ;But I only kill them now if the woman is self-scheduled, because otherwise it is easier to kill them once they are supposed to be born.
                                     if sex = 20 and selfscheduled = 1
                                       [;print "I am a selfscheduled woman"
                                         ;times have to be created first with "time-create"
                                         ;shorten popforlogo-private to only future events
                                         ;print (word "Popforlogo-private: " popforlogo-private)
                                         ifelse noMoreTransitions = 1
                                         []
                                         [set timeslist[]
                                         foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
                                         (foreach timeslist (item 2 popforlogo-private)
                                             [ifelse time:is-before ?1 current-time ; if the event has already passed, we don't need to worry about it
                                              [;print (word ?1 " has already passed")
                                               ]
                                              [ifelse ?2 < 14
                                                    [;print (word "Time: " ?1 " state: " ?2 " a child")
                                                    let timeTilBirthday time:difference-between current-time ?1 "days"
                                                   r:eval "roundedDay<-additional * 365.25"
                                                   let roundedDay r:get "roundedDay"
                                                   let UnbornBirthday roundedDay + ticks + timeTilBirthDay

                                                    ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  ;let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]

                                                 ]
                                                 [;print (word "state: " ?2 " ,not a child")
                                                 ]
                                              ]
                                             ])
                                        ]
                                       ]
                                      ;if sex = 20 and selfscheduled = 0 [print (word "I am a non-selfscheduled woman. My poplogo so far would have been " popforlogo-private ", but it will be changed now.")
                                       ;                                 ]
                                     set popforlogo-private [] ; children have already been killed
                                     ;print (word who " set popforlog-private []")
                                     ;compute new life
                                     ifelse migrant = 1
                                     [schedule-event-Mig
                                     ]
                                     [schedule-event
                                     ]
                                     if migrant = 0 and migrationstage > -1 ; if the person has not migrated and is still considering migration
                                        [set migrationeventticks ticks
                                          migrationstart]
                                     ]
                            set spouse []

                           ]
                         [;print "Dead person was not married"
                         ]

                       ]

                     ]
                   ]
  ]
end
;#####################################################################################################################################################################



;#####################################################################################################################################################################################
to schedule-event
set NoMoretransitions 0
set marriagestamp []
set inmarriagemarket 0
; First: take care of children that would have been born.
if selfscheduled = 1 and popforlogo-private != 0 and popforlogo-private != [] and sex = 20
 [set timeslist[]
        foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
        ;print "I schedule a new life; children that would have been born have to be killed"
        ;print timeslist
        (foreach timeslist (item 2 popforlogo-private)
         [ifelse ?2 < 14 and time:is-after ?1 current-time
           [ ; look for the child who would have been born at that time
             ;print "child would have been born"
             let timeToBirth time:difference-between current-time ?1 "days"
             ;print (word "days until child would have been born:" timeToBirth)
             let UnbornBirthday additional * 365.25 + ticks + timeToBirth
              ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]

           ]

           [; nothing happens
             ;print "No child or time has already passed"
           ]

            ])
 ]
set selfscheduled 1

set mylist (list id sex fert marital dead birthdate state ticks)
;print "NON-MIGRANT SCHEDULES NEW LIFE"
;print (word "current state " mylist)
r:put "currentevaluatedagent" mylist
r:eval "ID<-currentevaluatedagent[1]"
r:eval "birthdate<-currentevaluatedagent[6]"
r:eval "state<-paste(currentevaluatedagent[2:4],collapse='/')"
r:eval "initPop<-initialstatus(ID, birthdate, state)"
;current time has to be transformed to proper start time of new simulation for this person
r:put "currentTime" ticks
r:eval "currenttime<-timetransform(currentTime, additional)"
r:eval "pop<-newlife(initPop, currenttime, endtime)"; returns -1 if individual does not experience any furhter transition during simulation time
;print r:get "pop"
set pop r:get "pop"
r:eval"if (class(pop) =='numeric') {lasttransition <- 1}"
r:eval"if (class(pop) !='numeric') {lasttransition <- 0}"
set lasttransition r:get "lasttransition"
ifelse lasttransition = 0 [
;Now: Take care of newborn children!!! First, create the children and give them the life course you just created for them.
; check if in item 1 of popforlogo-private there is an element which is larger than your ID. This means, that children have been created.
;Again, pay attention to have a list of lists.
ifelse is-list? item 0 pop
                     [set poplist pop ;everything is fine
                     ]
                     [set poplist[]
                      foreach pop [set poplist lput (list (?)) poplist]  ;transform individual elements of popforlogo-global to lists
                     ]

if max (item 0 poplist) > id [;print "at least one new child"
  ; I have to go back to the pop Object in order to see if the newborn is male or female and to understand if the newborns are also scheduled to have children.
                                         r:eval "totalIndividuals<-length(unique(pop$ID))"
                                         set bornChildren r:get "totalIndividuals" - 1 ; subtract myself
                                          hatch bornChildren [setxy 0 0
                                          set color violet
                                          set size 3
                                          set waitingtime1[]
                                          set waitingtime2[]
                                          set id 0
                                          set migrant 0
                                          set migrantkid 0
                                          set selfscheduled 1
                                          set searchattempts 0
                                          set popforlogo-private []
                                          ;print (word who " set popforlog-private []")
                                          ]
                                          r:put "myID" id
                                          r:eval "popShort<- subset(pop, ID > myID)"
                                          r:eval "initChildrenLogo<-initChildren(popShort)"
                                         set initChildrenLogo r:get "initChildrenLogo"
                                          ifelse is-list? item 0 initChildrenLogo
                                             [set initChildrenLogoFinal initChildrenLogo
                                             ]
                                             [set initChildrenLogoFinal[]
                                              foreach initChildrenLogo [set initChildrenLogoFinal lput (list (?)) initChildrenLogoFinal]  ;transform individual elements of popforlogo-global to lists
                                             ]
                                          ;Create list of numbers to use later
                                          let maxID count persons with [color = violet]
                                          let numberlist []
                                          let counter 0
                                          while [counter < maxID]
                                             [set numberlist lput counter numberlist
                                               set counter counter + 1
                                             ]

(foreach (sort persons with [color = violet]) numberlist [ask ?1 [  ;print (word "who: " who)
                                                          set id (item ?2 (item 0 initChildrenLogoFinal))
                                                          ;print (word "ID new child " id)
                                         set birthdate item ?2 (item 1 initChildrenLogoFinal);
                                         set sex item ?2 (item 2 initChildrenLogoFinal)
                                         set fert 0
                                         set marital 14
                                         set parent []
                                         set child []
                                         set retired 0
                                         set migrationeventticks 0
                                         set marriagestamp []
                                         ;New individuals schedule their life course.
                                         r:put "myIDchild" id
                                         r:eval "popShortMe<- subset(pop, ID == myIDchild)"
                                         ;print (word "pop of new child " r:get "popShortMe")
                                         r:eval "popforlogoMe<-netlogoOutput(popShortMe)"
                                         ;print (word "popforlogoMeChild:" r:get "popforlogoMe")
                                         set popforlogo-global r:get "popforlogoMe"

                                         ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
                                         ifelse is-list? item 0 popforlogo-global
                                             [set popforlogo-private popforlogo-global
                                             ]
                                             [set popforlogo-private[]
                                               ;print (word who " set popforlog-private []")
                                              foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
                                             ]
                                          ;print (word "popforlogo-private of new child" popforlogo-private)
                                          foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]
                                          (foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
                                                 )
                                         if marriagestamp !=[] [enter-marriagemarket]
                                         schedule-retirement  ;only those who are born later. The other do this automatically in the beginning.
                                         schedule-migrationstart
                                         schedule-income
                                         ]
                                         ])
ask persons with [color = violet] [set color blue]
                                         ]
  ;Then, shorten your own life course so it only contains your own transitions.
  r:put "myID" id
  r:eval "popShort<- subset(pop, ID == myID)"
  r:eval "popforlogo<-netlogoOutput(popShort)"
  set popforlogo-global r:get "popforlogo"
  ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
  ifelse is-list? item 0 popforlogo-global
       [set popforlogo-private popforlogo-global]
       [set popforlogo-private[]
         ;print (word who " set popforlog-private []")
        foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
        ]


foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]

;print (word "I have the ID " id "popforlogo-private of myself " popforlogo-private )
;set marriage stamp
(foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
)
if marriagestamp !=[] [enter-marriagemarket]
                        ]
                        [set NoMoreTransitions 1
                          ;print (word " No more transitions ")
                          ;if it is the last transition, dont do anything.
                        ]



end


;#####################################################################################################################################################################################
to schedule-event-Mig

set NoMoretransitions 0
set marriagestamp []
set inmarriagemarket 0
; First: take care of children that would have been born.
if selfscheduled = 1 and popforlogo-private != 0 and popforlogo-private != []  and sex = 20
 [set timeslist[]
        foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
        ;print "I schedule a new life; children that would have been born have to be killed"
        ;print timeslist
        (foreach timeslist (item 2 popforlogo-private)
         [ifelse ?2 < 14 and time:is-after ?1 current-time
           [ ; look for the child who would have been born at that time
             ;print "child would have been born"
             let timeToBirth time:difference-between current-time ?1 "days"
             ;print (word "days until child would have been born:" timeToBirth)
             let UnbornBirthday additional * 365.25 + ticks + timeToBirth
             ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]

             ]
           [; nothing happens
             ;print "No child or time has already passed"
           ]

            ])
 ]
set selfscheduled 1
set mylist (list id sex fert marital dead birthdate state ticks)
;print "MIGRANT SCHEDULES NEW LIFE"
;print (word "who: " who)
;print (word "current state " mylist)
r:put "currentevaluatedagent" mylist
r:eval "ID<-currentevaluatedagent[1]"
r:eval "birthdate<-currentevaluatedagent[6]"
r:eval "state<-paste(currentevaluatedagent[2:4],collapse='/')"
r:eval "initPop<-initialstatus(ID, birthdate, state)"
;current time has to be transformed to proper start time of new simulation for this person
r:put "currentTime" ticks
r:eval "currenttime<-timetransform(currentTime, additional)"
r:eval "popMig<-newlifeMig(initPop, currenttime, endtime)"; returns -1 if individual does not experience any furhter transition during simulation time
;print r:get "popMig"
set popMig r:get "popMig"
r:eval"if (class(popMig) =='numeric') {lasttransition <- 1}"
r:eval"if (class(popMig) !='numeric') {lasttransition <- 0}"
set lasttransition r:get "lasttransition"
ifelse lasttransition = 0 [
;Now: Take care of newborn children!!! First, create the children and give them the life course you just created for them.
; check if in item 1 of popforlogo-private there is an element which is larger than your ID. This means, that children have been created.
;Again, pay attention to have a list of lists.
ifelse is-list? item 0 popMig
                     [set popMiglist popMig ;everything is fine
                     ]
                     [set popMiglist[]
                      foreach popMig [set popMiglist lput (list (?)) popMiglist]  ;transform individual elements of popforlogo-global to lists
                     ]


if max (item 0 popMiglist) > id [;print "at least one new child"
  ; I have to go back to the pop Object in order to see if the newborn is male or female and to understand if the newborns are also scheduled to have children.
                                         r:eval "totalIndividuals<-length(unique(popMig$ID))"
                                         set bornChildren r:get "totalIndividuals" - 1 ; subtract myself
                                          ;print (word "bornChildren: " bornChildren)
                                          hatch bornChildren [setxy 0 0
                                          set color violet
                                          set size 3
                                          set waitingtime1[]
                                          set waitingtime2[]
                                          set id 0
                                          set migrant 1
                                          set migrantkid 0
                                          set selfscheduled 1
                                          set indicator 0
                                          set searchattempts 0
                                          set popforlogo-private []
                                          ;print (word who " set popforlog-private []")
                                          ]
                                          r:put "myID" id
                                          r:eval "popShort<- subset(popMig, ID > myID)"
                                          ;print (word "popShort: " r:get "popShort")
                                          r:eval "initChildrenLogo<-initChildren(popShort)"
                                         set initChildrenLogo r:get "initChildrenLogo"
                                         ;print (word "initChildrenLogo: " r:get "initChildrenLogo")
                                         ; initChildrenLogo must be transformed into a list of lists if it isn't one yet
                                         ifelse is-list? item 0 initChildrenLogo
                                             [set initChildrenLogoFinal initChildrenLogo
                                             ]
                                             [set initChildrenLogoFinal[]
                                              foreach initChildrenLogo [set initChildrenLogoFinal lput (list (?)) initChildrenLogoFinal]  ;transform individual elements of popforlogo-global to lists
                                             ]

                                          ;Create list of numbers to use later
                                          let maxID count persons with [color = violet]
                                          let numberlist []
                                          let counter 0
                                          while [counter < maxID]
                                             [set numberlist lput counter numberlist
                                               set counter counter + 1
                                             ]

(foreach (sort persons with [color = violet]) numberlist [ask ?1 [  ;print (word "who: " who)
                                                          set id (item ?2 (item 0 initChildrenLogoFinal))
                                                          ;print (word "ID new child " id)
                                         set birthdate item ?2 (item 1 initChildrenLogoFinal);
                                         set sex item ?2 (item 2 initChildrenLogoFinal)
                                         set fert 0
                                         set marital 14
                                         set parent []
                                         set child []
                                         set retired 0
                                         set migrationeventticks 0
                                         set marriagestamp []
                                         set migrationticks ticks
                                         ;New individuals schedule their life course.
                                         r:put "myIDchild" id
                                         r:eval "popShortMe<- subset(popMig, ID == myIDchild)"
                                         ;print (word "pop of new child " r:get "popShortMe")
                                         r:eval "popforlogoMe<-netlogoOutput(popShortMe)"
                                         ;print (word "popforlogoMeChild:" r:get "popforlogoMe")
                                         set popforlogo-global r:get "popforlogoMe"
                                         ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
                                         ifelse is-list? item 0 popforlogo-global
                                             [set popforlogo-private popforlogo-global
                                             ]
                                             [set popforlogo-private[]
                                               ;print (word who " set popforlog-private []")
                                              foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
                                             ]
                                          ;print (word "popforlogo-private of new child" popforlogo-private)

                                          foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]
                                          (foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
                                                 )
                                         if marriagestamp !=[] [enter-marriagemarket]
                                         schedule-retirement
                                         schedule-income
                                         ]
                                         ])
ask persons with [color = violet] [set color blue]
                                         ]
  ;Then, shorten your own life course so it only contains your own transitions.
  r:put "myID" id
  r:eval "popShort<- subset(popMig, ID == myID)"
  r:eval "popforlogo<-netlogoOutput(popShort)"
  set popforlogo-global r:get "popforlogo"
  ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
  ifelse is-list? item 0 popforlogo-global
       [set popforlogo-private popforlogo-global]
       [set popforlogo-private[]
         ;print (word who " set popforlog-private []")
        foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
        ]


foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]

;print (word "I have the ID " id ", popforlogo-private of myself " popforlogo-private )

;Update marriage stamp
(foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
)
if marriagestamp !=[] [enter-marriagemarket]
                        ]
                        [set NoMoreTransitions 1
                          ;print " No more transitions "
                          ;if it is the last transition, dont do anything.
                        ]


end
;**********************************************************************************************************************************************************************************

to higher-mortality
if AlreadyHighMortality = 1 [;print (word " I am person " who " and my mortality is already high" )
                                                           stop]
set AlreadyHighMortality 1

set NoMoretransitions 0
set marriagestamp []
set inmarriagemarket 0
; First: take care of children that would have been born.
if selfscheduled = 1 and popforlogo-private != 0 and popforlogo-private != []  and sex = 20
 [set timeslist[]
        foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
        ;print "I schedule a new life; children that would have been born have to be killed"
        ;print timeslist
        (foreach timeslist (item 2 popforlogo-private)
         [ifelse ?2 < 14 and time:is-after ?1 current-time
           [ ; look for the child who would have been born at that time
             ;print "child would have been born"
             let timeToBirth time:difference-between current-time ?1 "days"
             ;print (word "days until child would have been born:" timeToBirth)
             let UnbornBirthday additional * 365.25 + ticks + timeToBirth
              ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]

             ]
           [; nothing happens
             ;print "No child or time has already passed"
           ]

            ])
 ]
set selfscheduled 1
;print "NON-MIGRANT SCHEDULES NEW LIFE WITH HIGHER MORTALITY"
set mylist (list id sex fert marital dead birthdate state ticks)
;print (word "current state " mylist)
r:put "currentevaluatedagent" mylist
r:eval "ID<-currentevaluatedagent[1]"
r:eval "birthdate<-currentevaluatedagent[6]"
r:eval "state<-paste(currentevaluatedagent[2:4],collapse='/')"
r:eval "initPop<-initialstatus(ID, birthdate, state)"
;current time has to be transformed to proper start time of new simulation for this person
r:put "currentTime" ticks
r:eval "currenttime<-timetransform(currentTime, additional)"
r:eval "pop<-newlifeMort(initPop, currenttime, endtime)"; returns -1 if individual does not experience any furhter transition during simulation time
;print r:get "pop"
set pop r:get "pop"
r:eval"if (class(pop) =='numeric') {lasttransition <- 1}"
r:eval"if (class(pop) !='numeric') {lasttransition <- 0}"
set lasttransition r:get "lasttransition"
ifelse lasttransition = 0 [
;Now: Take care of newborn children!!! First, create the children and give them the life course you just created for them.
; check if in item 1 of popforlogo-private there is an element which is larger than your ID. This means, that children have been created.
;Again, pay attention to have a list of lists.
ifelse is-list? item 0 pop
                     [set poplist pop ;everything is fine
                     ]
                     [set poplist[]
                      foreach pop [set poplist lput (list (?)) poplist]  ;transform individual elements of popforlogo-global to lists
                     ]

if max (item 0 poplist) > id [;print "at least one new child"
  ; I have to go back to the pop Object in order to see if the newborn is male or female and to understand if the newborns are also scheduled to have children.
                                         r:eval "totalIndividuals<-length(unique(pop$ID))"
                                         set bornChildren r:get "totalIndividuals" - 1 ; subtract myself
                                          hatch bornChildren [setxy 0 0
                                          set color violet
                                          set size 3
                                          set waitingtime1[]
                                          set waitingtime2[]
                                          set id 0
                                          set migrant 0
                                          set migrantkid 0
                                          set selfscheduled 1
                                          set searchattempts 0
                                          set popforlogo-private []
                                          ;print (word who " set popforlog-private []")
                                          ]
                                          r:put "myID" id
                                          r:eval "popShort<- subset(pop, ID > myID)"
                                          r:eval "initChildrenLogo<-initChildren(popShort)"
                                         set initChildrenLogo r:get "initChildrenLogo"
                                          ifelse is-list? item 0 initChildrenLogo
                                             [set initChildrenLogoFinal initChildrenLogo
                                             ]
                                             [set initChildrenLogoFinal[]
                                              foreach initChildrenLogo [set initChildrenLogoFinal lput (list (?)) initChildrenLogoFinal]  ;transform individual elements of popforlogo-global to lists
                                             ]
                                          ;Create list of numbers to use later
                                          let maxID count persons with [color = violet]
                                          let numberlist []
                                          let counter 0
                                          while [counter < maxID]
                                             [set numberlist lput counter numberlist
                                               set counter counter + 1
                                             ]

(foreach (sort persons with [color = violet]) numberlist [ask ?1 [  ;print (word "who: " who)
                                                          set id (item ?2 (item 0 initChildrenLogoFinal))
                                                          ;print (word "ID new child " id)
                                         set birthdate item ?2 (item 1 initChildrenLogoFinal);
                                         set sex item ?2 (item 2 initChildrenLogoFinal)
                                         set fert 0
                                         set marital 14
                                         set parent []
                                         set child []
                                         set retired 0
                                         set migrationeventticks 0
                                         set marriagestamp []
                                         ;New individuals schedule their life course.
                                         r:put "myIDchild" id
                                         r:eval "popShortMe<- subset(pop, ID == myIDchild)"
                                         ;print (word "pop of new child " r:get "popShortMe")
                                         r:eval "popforlogoMe<-netlogoOutput(popShortMe)"
                                         ;print (word "popforlogoMeChild:" r:get "popforlogoMe")
                                         set popforlogo-global r:get "popforlogoMe"
                                         ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
                                         ifelse is-list? item 0 popforlogo-global
                                             [set popforlogo-private popforlogo-global
                                             ]
                                             [set popforlogo-private[]
                                               ;print (word who " set popforlog-private []")
                                              foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
                                             ]
                                          ;print (word "popforlogo-private of new child" popforlogo-private)
                                          foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]
                                          (foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
                                                 )
                                         if marriagestamp !=[] [enter-marriagemarket]
                                         schedule-retirement
                                         schedule-migrationstart
                                         schedule-income
                                         ]
                                         ])
ask persons with [color = violet] [set color blue]
                                         ]
  ;Then, shorten your own life course so it only contains your own transitions.
  r:put "myID" id
  r:eval "popShort<- subset(pop, ID == myID)"
  r:eval "popforlogo<-netlogoOutput(popShort)"
  set popforlogo-global r:get "popforlogo"
  ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
  ifelse is-list? item 0 popforlogo-global
       [set popforlogo-private popforlogo-global]
       [set popforlogo-private[]
         ;print (word who " set popforlog-private []")
        foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
        ]


foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]

;print (word "I have the ID " id "popforlogo-private of myself " popforlogo-private )
;set marriage stamp
(foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
)
if marriagestamp !=[] [enter-marriagemarket]
                        ]
                        [set NoMoreTransitions 1
                          ;print (word "No more transitions")
                          ;if it is the last transition, dont do anything.
                        ]



end

;**********************************************************************************************************************************************************************************
to higher-mortality-Mig
if AlreadyHighMortality = 1 [;print (word " I am person " who " and my mortality is already high" )
                            stop]
set AlreadyHighMortality 1

set NoMoretransitions 0
set marriagestamp []
set inmarriagemarket 0
; First: take care of children that would have been born.
if selfscheduled = 1 and popforlogo-private != 0 and popforlogo-private != []  and sex = 20
 [set timeslist[]
        foreach (item 0 popforlogo-private) [set timeslist lput time:create ? timeslist]
        ;print "I schedule a new life; children that would have been born have to be killed"
        ;print timeslist
        (foreach timeslist (item 2 popforlogo-private)
         [ifelse ?2 < 14 and time:is-after ?1 current-time
           [ ; look for the child who would have been born at that time
             ;print "child would have been born"
             let timeToBirth time:difference-between current-time ?1 "days"
             ;print (word "days until child would have been born:" timeToBirth)
             let UnbornBirthday additional * 365.25 + ticks + timeToBirth
              ifelse any? persons with [color = blue]

                                                   [ifelse any? persons with [birthdate = round(UnbornBirthday) and color = blue]
                                                      [set myChild one-of persons with [birthdate = round(UnbornBirthday) and color = blue] ; identify children born on that day and unite with them
                                                      ]
                                                      [set myChild one-of persons with [color = blue] with-min [abs(birthdate - UnbornBirthday)] ; if, due to the leap-year issue, a child could not be assigned to a parent, pick the youngest unassigned child
                                                      ]
                                                   ask myChild [;print (word "They are looking for a person with birthdate " UnbornBirthday)
                                                                ;print (word "I, person " who "will not be born. My birthdate would have been " birthdate)
                                                                set unborn 1
                                                                set color grey
                                                                  let cemetary one-of patches with [pxcor = 0 and pycor = -50]
                                                                  move-to cemetary
                                                                 set inmarriagemarket 0
                                                                 set marriagestamp []

                                                                ]
                                                 ;print (word "I, mother " who "just killed a baby")
                                                 ]
                                                 [;print "No blue persons left"
                                                 ]


             ]
           [; nothing happens
             ;print "No child or time has already passed"
           ]

            ])
 ]
set selfscheduled 1
set mylist (list id sex fert marital dead birthdate state ticks)
;print "MIGRANT SCHEDULES NEW LIFE WITH HIGHER MORTALITY"
;print (word "who: " who)
;print (word "current state " mylist)
r:put "currentevaluatedagent" mylist
r:eval "ID<-currentevaluatedagent[1]"
r:eval "birthdate<-currentevaluatedagent[6]"
r:eval "state<-paste(currentevaluatedagent[2:4],collapse='/')"
r:eval "initPop<-initialstatus(ID, birthdate, state)"
;current time has to be transformed to proper start time of new simulation for this person
r:put "currentTime" ticks
r:eval "currenttime<-timetransform(currentTime, additional)"
r:eval "popMig<-newlifeMigMort(initPop, currenttime, endtime)"; returns -1 if individual does not experience any furhter transition during simulation time
;print r:get "popMig"
set popMig r:get "popMig"
r:eval"if (class(popMig) =='numeric') {lasttransition <- 1}"
r:eval"if (class(popMig) !='numeric') {lasttransition <- 0}"
set lasttransition r:get "lasttransition"
ifelse lasttransition = 0 [
;Now: Take care of newborn children!!! First, create the children and give them the life course you just created for them.
; check if in item 1 of popforlogo-private there is an element which is larger than your ID. This means, that children have been created.
;Again, pay attention to have a list of lists.
ifelse is-list? item 0 popMig
                     [set popMiglist popMig ;everything is fine
                     ]
                     [set popMiglist[]
                      foreach popMig [set popMiglist lput (list (?)) popMiglist]  ;transform individual elements of popforlogo-global to lists
                     ]


if max (item 0 popMiglist) > id [;print "at least one new child"
  ; I have to go back to the pop Object in order to see if the newborn is male or female and to understand if the newborns are also scheduled to have children.
                                         r:eval "totalIndividuals<-length(unique(popMig$ID))"
                                         set bornChildren r:get "totalIndividuals" - 1 ; subtract myself
                                          ;print (word "bornChildren: " bornChildren)
                                          hatch bornChildren [setxy 0 0
                                          set color violet
                                          set size 3
                                          set waitingtime1[]
                                          set waitingtime2[]
                                          set id 0
                                          set migrant 1
                                          set migrantkid 0
                                          set selfscheduled 1
                                          set searchattempts 0
                                          set popforlogo-private []
                                          ;print (word who " set popforlog-private []")
                                          ]
                                          r:put "myID" id
                                          r:eval "popShort<- subset(popMig, ID > myID)"
                                          ;print (word "popShort: " r:get "popShort")
                                          r:eval "initChildrenLogo<-initChildren(popShort)"
                                         set initChildrenLogo r:get "initChildrenLogo"
                                         ;print (word "initChildrenLogo: " r:get "initChildrenLogo")
                                         ; initChildrenLogo must be transformed into a list of lists if it isn't one yet
                                         ifelse is-list? item 0 initChildrenLogo
                                             [set initChildrenLogoFinal initChildrenLogo
                                             ]
                                             [set initChildrenLogoFinal[]
                                              foreach initChildrenLogo [set initChildrenLogoFinal lput (list (?)) initChildrenLogoFinal]  ;transform individual elements of popforlogo-global to lists
                                             ]

                                          ;Create list of numbers to use later
                                          let maxID count persons with [color = violet]
                                          let numberlist []
                                          let counter 0
                                          while [counter < maxID]
                                             [set numberlist lput counter numberlist
                                               set counter counter + 1
                                             ]

(foreach (sort persons with [color = violet]) numberlist [ask ?1 [  ;print (word "who: " who)
                                                          set id (item ?2 (item 0 initChildrenLogoFinal))
                                                          ;print (word "ID new child " id)
                                         set birthdate item ?2 (item 1 initChildrenLogoFinal);
                                         set sex item ?2 (item 2 initChildrenLogoFinal)
                                         set fert 0
                                         set marital 14
                                         set parent []
                                         set child []
                                         set retired 0
                                         set migrationeventticks 0
                                         set marriagestamp []
                                         set migrationticks ticks
                                         ;New individuals schedule their life course.
                                         r:put "myIDchild" id
                                         r:eval "popShortMe<- subset(popMig, ID == myIDchild)"
                                         ;print (word "pop of new child " r:get "popShortMe")
                                         r:eval "popforlogoMe<-netlogoOutput(popShortMe)"
                                         ;print (word "popforlogoMeChild:" r:get "popforlogoMe")
                                         set popforlogo-global r:get "popforlogoMe"
                                         ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
                                         ifelse is-list? item 0 popforlogo-global
                                             [set popforlogo-private popforlogo-global
                                             ]
                                             [set popforlogo-private[]
                                               ;print (word who " set popforlog-private []")
                                              foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
                                             ]
                                          ;print (word "popforlogo-private of new child" popforlogo-private)
                                          foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]
                                          (foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
                                                 )
                                         if marriagestamp !=[] [enter-marriagemarket]
                                         schedule-retirement
                                         schedule-income
                                         ]
                                         ])
ask persons with [color = violet] [set color blue]
                                         ]
  ;Then, shorten your own life course so it only contains your own transitions.
  r:put "myID" id
  r:eval "popShort<- subset(popMig, ID == myID)"
  r:eval "popforlogo<-netlogoOutput(popShort)"
  set popforlogo-global r:get "popforlogo"
  ; if popforlogo is just a simple list (and not a nested list), it has to be transformed into a nested list; i.e. all entries have to become lists
  ifelse is-list? item 0 popforlogo-global
       [set popforlogo-private popforlogo-global]
       [set popforlogo-private[]
         ;;print (word who " set popforlog-private []")
        foreach popforlogo-global [set popforlogo-private lput (list (?)) popforlogo-private]  ;transform individual elements of popforlogo-global to lists
        ]


foreach (item 0 popforlogo-private) [time:schedule-event self task perform-transition time:create ?]

;print (word "I have the ID " id ", popforlogo-private of myself " popforlogo-private )

;Update marriage stamp
(foreach (item 2 popforlogo-private) (item 0 popforlogo-private) [
                                                                 if ?1 = 15
                                                                 [set marriagestamp lput time:create ?2 marriagestamp
                                                                  ]
                                                                 ]
)
if marriagestamp !=[] [enter-marriagemarket]
                        ]
                        [set NoMoreTransitions 1
                          ;print (word "No more transitions")
                          ;if it is the last transition, dont do anything.
                        ]


end
;MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
;Here comes migration decision-making

to migrationstart
;print "MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
;print current-time
if dead = 1 or ticks < 1 or unborn = 1 [stop]
if migrationstage < 0 [
                       ;print (word "I have migrationstage -1: " migrationstage)
                       stop
                      ]
ifelse migrationeventticks = 0 or abs (migrationeventticks - ticks ) < 1
 [; this is happening as planned
   ;print (word "This is happening as plannend; migrationeventticks is " migrationeventticks " and current ticks is " ticks )
  ]
 [; migrationeventticks was overwritten, so this should not be happening
  ;print (word "This is an overwritten migration step; migrationeventticks is " migrationeventticks " and current ticks is " ticks)
  stop
  ]
;if ((ticks - (birthdate - additional * 365.25)) / 365.25) < 17 [stop] ; can happen if someone gets married before their 17th birthday
compute-attitude
compute-SN
compute-PBC
compute-intention
end


to compute-attitude
;print (word who " computes attitude; has migration stage"  migrationstage)
let ew 0
;let adultequivalent MonthlyConsumptionChildren / MonthlyConsumptionAdults
ifelse any? households with [member? myself members = true]
                           [let myhousehold one-of households with [member? myself members = true]
                            let myfolks turtle-set [members] of myhousehold
                            let count-adults 0
                            let count-kids 0
                            ask myfolks [let adulthood birthdate + 365.25 * 16
                            let adulthoodticks adulthood - (additional * 365.25)
                            ifelse ticks < adulthoodticks
                          [;print (word "I am part of this household, my who is " who " my birthdate is " birthdate "and I am a child." )
                            set count-kids count-kids + 1
                          ]
                          [;print (word "I am part of this household, my who is " who " my birthdate is " birthdate "and I am an adult.")
                            set count-adults count-adults + 1
                          ]
                          ]
                            set ew a1 - a2 * (([capital] of myhousehold )/(count-adults + count-kids ))

                           ]
                           [; later everyone will be part of a household, but this is not the case yet here. This can only be a single person or a single with kids
                             ifelse income > 0
                              [set ew a1 - a2 * (income /(1 + fert))]
                              [set ew a1  ]

                           ]

;print (word "ew is " ew ) ;evaluation of higher income
let previous-migrants 0
let migrantparents 0
let migrantsiblings 0
ifelse parent = []
    [set migrantparents 0
     ]
    [
      ifelse any? persons with [parent = [parent] of myself]
      [let mysiblings persons with [parent = [parent] of myself]
       ask mysiblings [if migrant = 1 [set migrantsiblings migrantsiblings + 1]]
      ]
      [set migrantsiblings 0
       ]
      let myparents turtle-set parent
      ask myparents [if migrant = 1 [set migrantparents migrantparents + 1]
                    ;check if their own parents are migrants
                     if parent !=[]
                     [let grandparents turtle-set parent
                       ask grandparents [if migrant = 1 [set migrantparents migrantparents + 1]]
                     ]
                    ]
    ]
;print (word "migrantparents: " migrantparents)
;print (word "migrantsiblings: " migrantsiblings)
let migrantchildren 0
ifelse child = []
  [set migrantchildren 0]
  [let mychildren turtle-set child
      ask mychildren [if migrant = 1 [set migrantchildren migrantchildren + 1]
                     if child !=[] ; check if they have children
                     [let grandchildren turtle-set child
                       ask grandchildren [if migrant = 1 [set migrantchildren migrantchildren + 1]]
                     ]
                     ]
  ]
;print (word "migrantchildren: " migrantchildren )
let migrantspouse 0
if spouse != 0 [let myspouse turtle-set spouse
                      ifelse [migrant] of myspouse = 1
                      [set migrantspouse 1]
                      [ ]
                ]

;print (word "migrantspouse: " migrantspouse)
let ef a3 * (migrantparents + migrantchildren + migrantspouse + migrantsiblings)
;print (word "ef is " ef)

let bw 0
let TotalDaysAbroad 0
let TotalDaysHigherIncome 0
ifelse any? link-neighbors with [migrant = 1 and dead = 0]
  [ask link-neighbors with [migrant = 1 and dead = 0]
   [let daysAbroad 0

     let incomestartday birthdate + 365.25 * 16
    set incomestartticks incomestartday - (additional * 365.25)
     ifelse incomestartticks < migrationticks
       [; migrated when they already received income
        set daysAbroad ticks - migrationticks
        ]
       [set daysAbroad ticks - incomestartticks
        ; is negative for some initial migrants who migrated as kids and do not have income yet. In this case: set to 0 (because they have no income yet)
        if daysAbroad < 0 [set daysAbroad 0]
        ]
       ;print (word "I am the network neighbor " who " my income is " income ", incomstartticks is " incomestartticks " and migrationstartticks is " migrationticks ", daysAbroad is thus " daysAbroad )
     set TotalDaysAbroad TotalDaysAbroad + daysAbroad
     ;print( word "My own income is " [income] of myself )
     if income > [income] of myself
     [set TotalDaysHigherIncome TotalDaysHigherIncome + daysAbroad]

   ]
   ifelse TotalDaysAbroad = 0
    [set bw 0.5]
    [set bw (TotalDaysHigherIncome / TotalDaysAbroad)]
   ]
  [set bw 0.5
  ]

;print (word "bw is " bw)

set attitude ew * bw + ef
;print (word "Attitude is " attitude )
end

to compute-SN
ifelse any? link-neighbors with [dead = 0]
[set socialnorm (count link-neighbors with [migrant = 1 and dead = 0] / count link-neighbors)]
[set socialnorm 0]
;print (word "Social norm:"  socialnorm)
end

to compute-PBC
let cb 0
ifelse any? link-neighbors with [migrationAttempt > 0]
[set cb (count link-neighbors with [migrationAttempt = 1] / count link-neighbors with [migrationAttempt > 0])]
[set cb 0.5]
;print (word "cb is " cb)
let pc 0
compute-migrationcost
 set pc migrationcostTotal
 ;print (word "pc is " pc)
;compute proportion of months since last household compostional change in which the household would have been able to afford the migration cost
let cc 0 ; subjective probability NOT to be able to afford the migration cost
let richmonths 0
let poormonths 0
ifelse any? households with [member? myself members = true]
[ifelse [capitallist] of one-of households with [member? myself members = true]  = []
  [set cc 1]
  [ask one-of households with [member? myself members = true]
         [foreach capitallist
            [ifelse ? >= pc
             [set richmonths richmonths + 1]
             [set poormonths poormonths + 1]
             ]
         ]
   ;print (word "richmonths: " richmonths "poormonths: " poormonths)
  set cc poormonths / (poormonths + richmonths)
  ]
]
[ifelse fert > 0
  [let savings income - fert * MonthlyConsumptionAdults - MonthlyConsumptionAdults
   ifelse savings > pc [set cc 0]
                       [set cc 1]
   ]
  [let savings income - MonthlyConsumptionAdults
   ifelse savings > pc [set cc 0]
                       [set cc 1]
    ]
]

set PBC (- (1000 * borderEnforcement * cb + pc * cc ))
;print (word "PBC: " PBC )

end

to compute-intention
set intention a4 * attitude + a5 * socialnorm + a6 * PBC
ifelse intention > 0
;THIS IS OLD VERSION. NOW: MOVE TO NEXT STAGE WITH PROB. 1
;[let prob 1 / (1 + exp (- intention))
; print (word "Intention: " intention "Prob of moving to next stage: " prob)
;  let rnumber random-float 1
;  print (word "rnumber is " rnumber)
;  ifelse rnumber < prob

 [
  set migrationstage migrationstage + 1
   ifelse migrationstage = 4
      [migration]
      [progress]
  ]
;    [print "No migration, return to first stage"
;      set migrationstage 0
;      progress
;      ;compute when he gets a chance for the second stage and schedule
;   ]
;]

 [;print "Intention negative"
  set migrationstage -1 ;he will not attempt again
  ]

end


to progress
;compute waiting time until transition to next stage
let lambda 0
ifelse migrationstage < 2
[set lambda rho1 * exp (a7 * intention)]
[set lambda rho2 * exp (a7 * intention)]
let u random-float 1
let waiting-time ( - ln u )/ lambda ;exponentially distributed waiting time in years
set waiting-time waiting-time * 365.25 ; transform to days
ifelse migrationstage < 2
[set waitingtime1 lput waiting-time waitingtime1]
[set waitingtime2 lput waiting-time waitingtime2]
;print (word "Waiting time: " waiting-time)
set migrationeventticks ticks + waiting-time
;print (word "Next stage is entered at ticks: " migrationeventticks)
;make sure there is nothing scheduled to happen after the final tick
ifelse migrationeventticks > endticks
[;print (word " next step would be entered after the final tick, so it is not entered at all")
 ]
[time:schedule-event self task migrationstart migrationeventticks
]
end


to migration
  ;print "Migration happens"
  set waitingtime2 lput 9999999 waitingtime2 ; to indicate migration attempt
 let relevantCapital 0
 ifelse any? households with [member? myself members = true]
  [;print "Yes, I am part of a household"
    set relevantCapital[capital] of one-of households with [member? myself members = true]
   ;print (word "Relevant capital: " relevantCapital)
  ]
  [;print "No, I am not part of a household"
    set relevantCapital income
  ]
  ;print (word "MigrationcostTotal: " migrationcostTotal "relevantCapital: " relevantCapital )
    ifelse migrationcostTotal < relevantCapital
  [border-control
   ]
   [;print "not enough capital"
     set migrationstage 0]
end

to compute-migrationcost
;ifelse any? link-neighbors with [migrant = 1]
; [set migrationcost pcNoMigrantFriends - dc]
; [set migrationcost pcNoMigrantFriends]
set migrationcostTotal pcMigrationCost
let count-kids 0
let count-adults 0
ifelse any? households with [member? myself members = true]
[
 let myhousehold one-of households with [member? myself members = true]
                            let myfolks turtle-set [members] of myhousehold

                            ask myfolks [let adulthood birthdate + 365.25 * 16
                            let adulthoodticks adulthood - (additional * 365.25)
                            ifelse ticks < adulthoodticks
                              [;print (word "I am a kid here, my who is " who)
                                set count-kids count-kids + 1
                                set indicator 1
                                ]
                              [set count-adults count-adults + 1
                                ;print (word "I am an adult here, my who is " who )
                                ]
                              ]
]
[set count-adults 1
 if child != [][let mykids turtle-set child
                ;print (word "My kids are" mykids)
                ask mykids [let adulthood birthdate + 365.25 * 16
                            let adulthoodticks adulthood - (additional * 365.25)
                             ifelse ticks < adulthoodticks
                                   [;print (word "I am a kid here, my who is " who)
                                    set count-kids count-kids + 1
                                    set indicator 1
                                   ]
                                   [set count-adults count-adults + 1
                                     ;print (word "I am an adult here, my who is " who )
                                   ]
                            ]
                 ]
]
;print (word "count kids " count-kids)
;print (word "count adults " count-adults)
if count-kids > 0 and count-adults < 2 ; only myself
[set migrationcostTotal migrationcostTotal + ( count-kids * pcMigrationCost)
 if migrationstage = 3[
                       ask persons with [indicator = 1] [set migrantkid 1
                                                         ;print (word "I, " who ", am a migrantkid")
                                                         ]

                      ]
 ]



; even if there are still more adults, my kids migrate with me, if my spouse has migrated

if any? persons with [indicator = 1]
[let myPotentialKids persons with [indicator = 1]
;print (word "Mypotentialkids:" myPotentialKids)
ask myPotentialKids
[
ifelse member? self [child] of myself
  [set indicator 2
   ;print (word who "I just set indicator 2")
   ]
  [;print (word who "not a child of the asking turtle")
  ]
]
]
if marital = 15 and [migrant] of spouse = 1 and any? persons with [indicator = 2]
[set migrationcostTotal migrationcostTotal + ( count persons with [indicator = 2] * pcMigrationCost)
 ask persons with [indicator = 2] [set migrantkid 1
                                   ;print (word "I, "who " , am a migrantkid because one of my parents has already migrated")
                                   ]
  ]
  ; households have to survive until the next payday after subtracting the migrationcost. Add the consumption of the household of one month

set migrationcostTotal migrationcostTotal + count-kids * MonthlyConsumptionAdults + count-adults * MonthlyConsumptionAdults
ask persons [set indicator 0]
if migrationstage < 3 [ask persons with [migrantkid = 1] [set migrantkid 0]]
end



to border-control
let MigProb  1 / (1 + exp (- 1 / borderEnforcement ))
;print (word "MigProb is " MigProb )

let randomdraw random-float 1

ifelse randomdraw < MigProb
 [ set migrationAttempt 1
   set migrant 1
   set migrationsperyear migrationsperyear + 1
   set ageprofile lput (((ticks - birthdate) / 365.25 ) + additional) ageprofile
   set MigrantsatAge lput (((ticks - birthdate) / 365.25 ) + additional) MigrantsatAge
   if sex = 20 [set FemaleMigrantsInYear lput (((ticks - birthdate) / 365.25 ) + additional) FemaleMigrantsInYear ]
   ;if birthdate > 4382 and birthdate < 4748
    ; [set ageprofilecohort lput (((ticks - birthdate) / 365.25 ) + additional) ageprofilecohort]
   set color pink
   ;print (word "I, person" who "migrated.")
   set migrationticks ticks
   draw-income
;   let ActualCost 0
;   ifelse any? link-neighbors with [migrant = 1]
;    [set ActualCost pcNoMigrantFriends - dc]
;    [set ActualCost pcNoMigrantFriends]
;    print (word "Actual cost: " ActualCost)
   ifelse any? households with [member? myself members = true]
     [ask one-of households with [member? myself members = true]
       [set capital capital - pcMigrationCost
         ;print (word "I am household " who " my capital decreased by " pcMigrationCost)
       set capitallist []
       ]
      ]
     [;later everyone will be in households
     ]
   schedule-event-Mig
   ;print "New life scheduled for migrant"
   ; if children go with me they do the same
  ifelse any? persons with [migrantkid = 1]
  [ask persons with [migrantkid = 1]
         [;print (word "I, kid" who ", migrate with my parent")
         set migrationAttempt 1
         set migrant 1
         set migrationsperyear migrationsperyear + 1
         set ageprofile lput (((ticks - birthdate) / 365.25 ) + additional) ageprofile
         if birthdate > 4382 and birthdate < 4748
           [set ageprofilecohort lput (((ticks - birthdate) / 365.25 ) + additional) ageprofilecohort]
         set color pink
         set migrationticks ticks
         if any? households with [member? myself members = true]
         [ask one-of households with [member? myself members = true]
              [set capital capital - pcMigrationCost
                set capitallist []
               ]
         ]
         ;print "New life scheduled for migrant kid"
         schedule-event-Mig

         ]
  ]
   [;print "No person with migrantkid = 1"
   ]

 ifelse marital = 15
  [ifelse [migrant] of spouse = 1
     [ ; both form a new household in the home-country
      form-household
      ; MAKE SURE OTHER KIDS WHO MIGRATED WITH ME JOIN THAT HOUSEHOLD, TOO
      if any? persons with [migrantkid = 1]
        [let myhousehold one-of households with [member? myself members = true]
          ask persons with [migrantkid = 1]
           [move-to myself
            while [any? persons with [migrantkid = 1]]
              [let currentchild one-of persons with [migrantkid = 1]
               ifelse any? households with [member? currentchild members = true]
                            [ask households with [member? currentchild members = true]
                              [set members remove currentchild members
                                ;print (word "I, " [who] of currentchild " , left the household " who)
                                set capitallist []
                                ifelse members = []
                                 [;print (word "no members left, thus I, household " who " can die")
                                   die
                                   ]
                                 [;print (word "There are still members in the old household " who " left. They are " members)
                                 ]
                               ]
                               ;print (word currentchild ", my child, is leaving the old household")
                              ]
                            [;print "no old household to leave for my child"
                            ]

           ask myhousehold  [set members lput currentchild members
                             ;print (word "I, " [who] of currentchild " , joint the household " who)
                            ]
           ask currentchild [set migrantkid 0]
         ]

         ]
        ]
     ]
     [; if the spouse is not a migrant, the migrant remains part of the old household
      ]
  ]
  [; remain part of old household
   ]

 ]

 [;print "unsuccessful migration"
   set migrationstage 0
   set migrationAttempt 2
  if any? persons with [migrantkid = 1]
  [ask persons with [migrantkid = 1]
                   [ ;print (word "I, kid" who ", would have migrated with my parent but we failed")
                     set migrationAttempt 2
                    set migrantkid 0
                   ]
                 ]
  ]

end





;###############################################################################################################################################################################




to go

;time:go-until 10131
;time:go-until 16131

r:eval "endDay<-floor((additionalEnd - additional) * 365.25)"
set endticks r:get "endDay"
;print (word "NOW WE START!!!, ENDTICKS: " endticks)
time:go-until endticks
write-to-file
end
@#$#@#$#@
GRAPHICS-WINDOW
256
110
1078
553
101
51
4.0
1
10
1
1
1
0
1
1
1
-101
101
-51
51
0
0
1
ticks
30.0

BUTTON
43
10
178
47
Press here to start
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

SLIDER
20
169
192
202
numberindividuals
numberindividuals
0
5000
2000
1
1
NIL
HORIZONTAL

SLIDER
35
273
207
306
startyear
startyear
1970
2020
1982
1
1
NIL
HORIZONTAL

SLIDER
34
335
206
368
endyear
endyear
2000
2100
2050
1
1
NIL
HORIZONTAL

SLIDER
32
389
204
422
initialHost
initialHost
0
1
0.034
0.001
1
NIL
HORIZONTAL

SLIDER
1092
338
1264
371
a1
a1
0
2000
1000
1
1
NIL
HORIZONTAL

SLIDER
1090
372
1280
405
a2
a2
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
1115
475
1287
508
a3
a3
0
100
100
1
1
NIL
HORIZONTAL

SLIDER
45
450
217
483
a4
a4
0
10
0.002
0.1
1
NIL
HORIZONTAL

SLIDER
52
490
224
523
a5
a5
0
100
50
0.1
1
NIL
HORIZONTAL

SLIDER
60
528
232
561
a6
a6
0
10
1.0E-4
0.1
1
NIL
HORIZONTAL

SLIDER
293
537
465
570
rho1
rho1
0
5
0.01
0.0001
1
NIL
HORIZONTAL

SLIDER
464
535
636
568
a7
a7
0
5
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
292
572
464
605
rho2
rho2
0
5
1.0384
0.0001
1
NIL
HORIZONTAL

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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>write-to-file
;export-output (word "output a1" a1 "a2" a2 "a3"a3 "a4"a4"a5"a5 "a6"a6"a7" a7 "rho1"rho1".txt")</final>
    <exitCondition>measure = 1</exitCondition>
    <metric>ageprofile</metric>
    <metric>PeopleatAgePerYear</metric>
    <metric>MigrantsatAgePerYear</metric>
    <metric>MigrantsTotal</metric>
    <metric>FemaleMigrantsTotal</metric>
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
