function bus_table(ts::PISPtimeStatic)
    idx = 1
    for b in keys(PISP.NEMBUSES)
        push!(ts.bus,(idx, b, PISP.NEMBUSNAME[b], true, PISP.NEMBUSES[b][1], PISP.NEMBUSES[b][2], PISP.STID[PISP.BUS2AREA[b]]))
        idx += 1
    end
end

function line_table(ts::PISPtimeStatic, tv::PISPtimeVarying, ispdata24::String)
    bust = ts.bus
    # Read XLSX with line capacities
    DATALINES = PISP.read_xlsx_with_header(ispdata24, "Network Capability", "B6:H21")
    Results = DataFrame(name = String[], busA = String[], busB = String[], idbusA = Int64[], idbusB = Int64[], fwd_peak = Float64[], fwd_summer = Float64[], fwd_winter = Float64[], rev_peak = Float64[], rev_summer = Float64[], rev_winter = Float64[])
    # Link names
    NEMTX = ["CQ->NQ", "CQ->GG", "SQ->CQ", "QNI North", "Terranora", "QNI South","CNSW->SNW North","CNSW->SNW South", "VNI North","VNI South","Heywood","SESA->CSA","Murraylink", "Basslink"]
    # Link is Interconnector?
    INT = [false, false, false, true, true, false, false, false, false, true, true, false, true, true]
    NEMTYPE = ["DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC", "DC"]
    #Build summary of capacities
    for a in 2:nrow(DATALINES)
        aux = []
        nar = split(DATALINES[a,1]," "); 
        length(nar) == 1 ? nar = split(DATALINES[a,1],"-") : nar = nar
        if length(nar) > 2 deleteat!(nar, 2) end
        bn1 = string(nar[1]); bn2 = string(nar[2]);
        # NAME_LINK, BUS_FROM, BUS_TO, BUS_ID_FROM, BUS_ID_TO
        aux = [string(bn1, "->", bn2), bn1, bn2, bust[bust[!,:name] .== bn1,:id_bus][1], bust[bust[!,:name] .== bn2,:id_bus][1]]
        # Add columns 
        for b in 2:ncol(DATALINES)
            #FWD_PEAK, FWD_SUMMER, FWD_WINTER, REV_PEAK, REV_SUMMER, REV_WINTER
            data = parse(Int64, replace(split(string(DATALINES[a, b]),['.', ' ', '\n'])[1], "," => ""))
            append!(aux, data)
        end
        push!(Results, aux)
    end

    #Populate Line table
    for a in 1:nrow(Results)
        #ID, NAME, ALIAS, TECH, CAPACITY, BUS_ID_FROM, BUS_ID_TO, INVESTMENT, ACTIVE, R, X, TMIN, TMAX, VOLTAGE, SEGMENTS, LATITUDE, LONGITUDE, LENGTH, N, CONTINGENCY
        maxcap = maximum([Results[a, :fwd_winter], Results[a, :rev_winter]])
        vallin = (
                id_lin     = a,
                name        = Results[a, :name],
                alias       = NEMTX[a],
                tech        = NEMTYPE[a],
                capacity    = maxcap,
                id_bus_from = Results[a, :idbusA],
                id_bus_to   = Results[a, :idbusB],
                investment  = 0,
                active      = true,
                r           = 0.01,
                x           = 0.1,
                tmin        = Results[a, :rev_winter],
                tmax        = Results[a, :fwd_winter],
                voltage     = 220.0,
                segments    = 1,
                latitude    = "",
                longitude   = "",
                length      = 1.0,
                n           = 1,
                contingency = 0
            )
            push!(ts.line, vallin)
    end

    # Manual register of Project EnergyConnect 
    npln        = nrow(ts.line) 
    maxidlin    = isempty(ts.line) ? 0 : maximum(ts.line.id_lin)

    # Build the new row
    new_line = (
        id_lin      = maxidlin + 1,
        name        = "SNSW->CSA",
        alias       = "Project EnergyConnect",
        tech        = "DC",
        capacity    = 800,
        id_bus_from = 8,
        id_bus_to   = 11,
        investment  = 0,
        active      = 1,
        r           = 0.01,
        x           = 0.1,
        tmin        = 800,
        tmax        = 800,
        voltage     = 220.0,
        segments    = 1,
        latitude    = "",
        longitude   = "",
        length      = 1.0,
        n           = 1,
        contingency = 0
    )
    push!(ts.line, new_line)

    function insert_line_schedule!(df::DataFrame, line_id, scenario, date, capacity)
        newrow = (
            id       = nrow(df) + 1,
            id_lin   = line_id,
            scenario = scenario,
            date     = date,
            value    = capacity
        )
        push!(df, newrow)
    end

    # Project EnergyConnect Stage 1: 150MW in 2024
    for s in 1:3
        insert_line_schedule!(tv.line_tmax, 15, s, DateTime(2024, 7, 1), 150)
        insert_line_schedule!(tv.line_tmin, 15, s, DateTime(2024, 7, 1), 150)
    end

    # Stage 2
    for s in 1:3
        insert_line_schedule!(tv.line_tmax, 15, s, DateTime(2026, 7, 1), 800)
        insert_line_schedule!(tv.line_tmin, 15, s, DateTime(2026, 7, 1), 800)
    end
    return Results
end

function line_sched_table(tc::PISPtimeConfig, tv::PISPtimeVarying, TXdata::DataFrame)
    wmonths = [4,5,6,7,8,9]     # Winter months
    smonths = [10,11,12,1,2,3]  # Summer months
    probs   = tc.problem        # Call problem table 

    txd_max = maximum(tv.line_tmax.id) + 1
    txd_min = maximum(tv.line_tmin.id) + 1

    for txid in 1:nrow(TXdata)
        for p in 1:nrow(probs)
            scid = probs[p,:scenario][1]    # Scenario ID
            dstart = probs[p,:dstart]       # Start date of a week
            dend = probs[p,:dend]           # End date of a week
            ys = Dates.year(dstart)         # Start year of a week
            ds = Dates.day(dstart)          # Start day of a week
            de = Dates.day(dend)            # End day of a week
            ms = Dates.month(dstart)        # Start month of a week
            me = Dates.month(dend)          # End month of a week

            if ms in wmonths                # If starting month is in winter months
                push!(tv.line_tmax, (id=txd_max, id_lin=txid, scenario=scid, date=DateTime(dstart), value=TXdata[txid,8]))
                push!(tv.line_tmin, (id=txd_min, id_lin=txid, scenario=scid, date=DateTime(dstart), value=TXdata[txid,11]))
            else
                push!(tv.line_tmax, (id=txd_max, id_lin=txid, scenario=scid, date=DateTime(dstart), value=TXdata[txid,7]))
                push!(tv.line_tmin, (id=txd_min, id_lin=txid, scenario=scid, date=DateTime(dstart), value=TXdata[txid,10]))
            end
            txd_max += 1
            txd_min += 1

            if (ms in wmonths && me in smonths) || (ms in smonths && me in wmonths)
                # @warn "Problem start month is in winter and end month is in summer, check written data."
                if me in wmonths
                    push!(tv.line_tmax, (id=txd, id_lin=txid, scenario=scid, date=DateTime(ys,me,1), value=TXdata[txid,8]))
                    push!(tv.line_tmin, (id=txd, id_lin=txid, scenario=scid, date=DateTime(ys,me,1), value=TXdata[txid,11]))
                else
                    push!(tv.line_tmax, (id=txd, id_lin=txid, scenario=scid, date=DateTime(ys,me,1), value=TXdata[txid,7]))
                    push!(tv.line_tmin, (id=txd, id_lin=txid, scenario=scid, date=DateTime(ys,me,1), value=TXdata[txid,10]))
                end
                txd_max += 1
                txd_min += 1
            end
        end
    end
end

function line_invoptions(ts::PISPtimeStatic, ispdata24::String)
    bust = ts.bus
    maxidlin = isempty(ts.line) ? 0 : maximum(ts.line.id_lin)
    DATALININV = PISP.read_xlsx_with_header(ispdata24, "Flow Path Augmentation options", "B11:N94")
    skip = ["Option Name",""]
    df = DataFrame(Option = String[], Direction = String[], Forward = Float64[], Reverse = Float64[], Cost = Float64[], LeadYears = Float64[])

    Results = DataFrame(name = String[], busA = String[], busB = String[], idbusA = Int64[], idbusB = Int64[],fwd = Float64[], rev = Float64[], invcost = Float64[], lead = Float64[])
    bn1 = ""; bn2 = "";
    # Loop over every possible candidate line
    for a in 1:nrow(DATALININV)
        #Just select the options that are not MISSING or not are in SKIP (i.e, only real options)
        if ismissing(DATALININV[a, 4]) || DATALININV[a, 4] in skip continue end
        # Bus FROM -> TO of candidates.
        if !ismissing(DATALININV[a, 6]) 
            bn1 = split(string(DATALININV[a, 6]),[' '])[1]
            bn2 = split(string(DATALININV[a, 6]),[' '])[3]
        end
        
        # Modified the input data sheet for Augmentation options, project energyconnect goes from SNSW to SA
        aux = [split(string(DATALININV[a,4]),['(','\n'])[1],
            bn1,                                                                     # BUS_FROM_NAME
                bn2,                                                                 # BUS_TO_NAME
                bust[bust[!, :name] .== bn1,:id_bus][1],                                 # BUS_FROM_ID
                bust[bust[!, :name] .== bn2,:id_bus][1],                                 # BUS_TO_ID
                PISP.flow2num(split(string(DATALININV[a, 7]),    ['(','\n'])[1]),    # FWD POWER
                PISP.flow2num(split(string(DATALININV[a, 8]),    ['(','\n'])[1]),    # REV POWER
                PISP.inv2num(split(string(DATALININV[a, 9]),     ['(','\n'])),       # INDICATIVE_COST_ESTIMATE
                PISP.lead2year(split(string(DATALININV[a, 13]),  ['(','\n'])[1])]    # LEAD TIME
        push!(Results, aux)
    end

    #MODIFY INVESTMENT OPTIONS COST (The issue was resolved in function inv2num)
    factive(x) = x in ["SQ-CQ Option 3", "NNSW–SQ Option 3"] ?  0 : 1 # Non-network options deactivated, no investment cost info
    idx = 0
    for a in 1:nrow(Results)
        maxidlin+=1
        idx+=1
        # Element to add to table LINE
        linename = string(strip(Results[a,1]))
        invname = "NL_$(Results[a,4])$(Results[a,5])_INV$(idx)"

        vline = [maxidlin, linename, invname, "DC", max(Results[a,6],Results[a,7]), Results[a,4], Results[a,5], factive(Results[a,1]), factive(Results[a,1]), 0.01, 0.1, Results[a,7], Results[a,6], 220, 1, "", "", 1, 1, 0]

        push!(ts.line, vline)
    end
end

function generator_table(ts::PISPtimeStatic, ispdata19::String, ispdata24::String)
    # ============================================ #
    # ============== Generator data ============== #
    # ============================================ #
    mkdir(".tmp")
    bust = ts.bus
    # areat = PSO.gettable(socketSYS, "Area")

    # Month to number dict
    m2n = Dict( "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4, "may" => 5, "jun" => 6, "jul" => 7, "aug" => 8, "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12,
                "january" => 1, "february" => 2, "march" => 3, "april" => 4, "may" => 5, "june" => 6, "july" => 7, "august" => 8, "september" => 9, "october" => 10, "november" => 11, "december" => 12)

    str2date(date) = date isa Number ? Dates.DateTime(1899, 12, 30) + Dates.Day(date) : DateTime(parse(Int64,split(date,' ')[2]),m2n[lowercase(split(date,' ')[1])])
    MAPPING  = PISP.read_xlsx_with_header(ispdata24, "Summary Mapping", "B6:B680")      # EXISTING GENERATOR
    MAPPING2 = PISP.read_xlsx_with_header(ispdata24, "Summary Mapping", "AA6:AA680")    # MLF
    namedict = PISP.OrderedDict(zip(MAPPING[!,1], MAPPING2[!,1]))

    # ====================================== #
    # ==== General list of Power Plants ==== #
    # ====================================== #
    GENS = PISP.read_xlsx_with_header(ispdata24, "Maximum capacity", "B8:D260")
    GENS[!, :Generator] = [k == "Bogong / Mackay" ? "Bogong / MacKay" : k for k in GENS[!, :Generator]] # Fix for Bogong / Mackay
    GENS[!, :Generator] = [k == "Lincoln Gap Wind Farm - Stage 2" ? "Lincoln Gap Wind Farm - stage 2" : k for k in GENS[!, :Generator]] # Fix for Bogong / Mackay

    COMGEN_MAXCAP = PISP.read_xlsx_with_header(ispdata24, "Maximum capacity", "F8:I35")
    ADVGEN_MAXCAP = PISP.read_xlsx_with_header(ispdata24, "Maximum capacity", "K8:N24")

    MAPPING3 = PISP.read_xlsx_with_header(ispdata24, "Summary Mapping", "B4:I680")
    MAPPING3 = MAPPING3[completecases(MAPPING3),:]                              # SELECT ONLY ROWS OF MAPPING3 WITHOUT MISSING VALUES
    rename!(MAPPING3, 1 => :Generator)                                          # Rename first column to "Generator" 

    ngen = size(GENS, 1) # Number of existing generators
    GENS[!, Symbol("Commissioning date")] = [DateTime(2020) for k in 1:ngen]
    rename!(COMGEN_MAXCAP, [1,2,3,4] .=> names(GENS)) # Rename columns as columns in GENS
    rename!(ADVGEN_MAXCAP, [1,2,3,4] .=> names(GENS))

    append!(GENS, COMGEN_MAXCAP) # Create a unique dataframe with existing, commited and anticipated projects 
    append!(GENS, ADVGEN_MAXCAP) # TOTAL = EXISTING + COMMITED + ANTICIPATED = 295 GENERATORS

    GENS = leftjoin(GENS, MAPPING3, on = :Generator, makeunique=true)

    rename!(GENS, Symbol("Sub-region") => :Bus)
    select!(GENS, Not([:Region_1])) 
    GENS.id_bus = [bust[bust[!,:name] .== k, :id_bus][1] for k in GENS.Bus] 
    GENS.area_id .= 0
    GENS[!,:Generator] = [namedict[n] for n in GENS[!,:Generator]]
    # Transform columns id_bus and area_id to Int64 to save in database
    GENS.id_bus = Int64.(GENS.id_bus)
    GENS.area_id = Int64.(GENS.area_id)

    GENS[!, :Generator] = [k == "Devils Gate" ? "Devils gate" : k for k in GENS[!, :Generator]]
    GENS[!, :Generator] = [k == "Bungala One Solar Farm" ? "Bungala one Solar Farm" : k for k in GENS[!, :Generator]]
    GENS[!, :Generator] = [k == "Tallawarra B*" ? "Tallawarra B" : k for k in GENS[!, :Generator]] 

    XLSX.writetable(".tmp/GENS.xlsx", Tables.columntable(GENS); sheetname="Generators", overwrite=true)

    # ====================================== #
    # Units with unit commitment and ramping #
    # ====================================== #
    # Generation limits and stable levels for coal and gas generators
    DATA_COALMSG = PISP.read_xlsx_with_header(ispdata24, "Generation limits", "B8:D52")
    DATA_GPGMSG = PISP.read_xlsx_with_header(ispdata24, "GPG Min Stable Level", "B9:E34")
    select!(DATA_GPGMSG, Not(Symbol("Technology Type")))

    # Minimum up times for different units
    DATA_MINUP_UNITS = PISP.read_xlsx_with_header(ispdata24, "Min Up&Down Times", "B8:E25")
    DATA_MINUP_UNITS19 = PISP.read_xlsx_with_header(ispdata19, "Generation limits", "O9:Q69") # Min UP and DW - GAS+COAL UNITS (2019)
    select!(DATA_MINUP_UNITS, Not(Symbol("Technology Type")))
    XLSX.writetable(".tmp/DATA_MINUP_UNITS19.xlsx", Tables.columntable(DATA_MINUP_UNITS19); sheetname="Generators19", overwrite=true)
    # Ramp rates for different units
    UC = PISP.read_xlsx_with_header(ispdata24, "Max Ramp Rates", "B8:F72")
    select!(UC, Not(Symbol("Technology Type")))
    XLSX.writetable(".tmp/UC.xlsx", Tables.columntable(UC); sheetname="UC", overwrite=true)

    #DUID -> Dispatchable Unit Identifier
    rename!(UC, Dict(2 => Symbol("DUID"), 3 => :rup, 4 => :rdw));
    rename!(DATA_COALMSG, 2 => Symbol("DUID")); 
    rename!(DATA_GPGMSG, 2 => Symbol("DUID")); 
    rename!(DATA_MINUP_UNITS, [2,3] .=> [Symbol("DUID"),Symbol("MinUpTime")]); 
    rename!(DATA_COALMSG, 3 => Symbol("MSG")); 
    rename!(DATA_GPGMSG, 3 => Symbol("MSG")); 
    rename!(DATA_MINUP_UNITS19, [2,3] .=> [Symbol("DUID"),Symbol("MinUpTime")]);

    # ==> 5 DATAFRAMES: UC, DATA_COALMSG, DATA_GPGMSG, DATA_MINUP_UNITS, DATA_MINUP_UNITS19
    ## DATA_COALMSG -> Limits of Coal generation (Minimum Stable Generation)
    ## DATA_GPGMSG -> Limits of Gas turbines (Minimum Stable Generation)
    ## DATA_MINUP_UNITS -> Min UP and DW - GAS UNITS
    ## DATA_MINUP_UNITS19 -> Min UP and DW - GAS+COAL UNITS (2019)
    ## UC -> Max ramp up and down of generators

    # DATA_COALMSG contains the minimum stable generation for coal and gas
    append!(DATA_COALMSG, DATA_GPGMSG)
    XLSX.writetable(".tmp/DATA_COALGASMSG.xlsx", Tables.columntable(DATA_COALMSG); sheetname="CoalGasMSG", overwrite=true)

    # DATA_MINUP_UNITS contains the minimum up time for coal and gas units
    append!(DATA_MINUP_UNITS, DATA_MINUP_UNITS19)
    XLSX.writetable(".tmp/DATA_MINUP_UNITS.xlsx", Tables.columntable(DATA_MINUP_UNITS); sheetname="MinUpUnits", overwrite=true)

    # JOIN UC (Ramp Rates) with DATA_COALMSG (Minimum Stable Generation)
    UC = outerjoin(UC, DATA_COALMSG,on = :DUID,makeunique=true)
    XLSX.writetable(".tmp/UC1.xlsx", Tables.columntable(UC); sheetname="UC1", overwrite=true)

    # JOIN UC with DATA_MINUP_UNITS (Minimum Up Time)
    UC = outerjoin(UC,DATA_MINUP_UNITS,on = :DUID,makeunique=true)
    XLSX.writetable(".tmp/UC2.xlsx", Tables.columntable(UC); sheetname="UC2", overwrite=true)
    # Delete rows that if the string in column DUID contains "LD" - Asociated with Lidell Station (decommissioned)
    UC = UC[.!occursin.("LD",UC[!,:DUID]),:]
    # Create a unique column with the generator station name 
    UC[!,1] = [ismissing(UC[k,1]) ? UC[k,5] : UC[k,1] for k in eachindex(UC[:,1])]
    UC[!,1] = [ismissing(UC[k,1]) ? UC[k,7] : UC[k,1] for k in eachindex(UC[:,1])]
    select!(UC, Not([5,7])) # Eliminate columns 5 and 7
    UC = unique(UC) # Eliminate rows with the exact same information 
    filter!((row) -> !(row[1] == "Tallawarra" && row[6] == 6), UC)
    filter!((row) -> !(row[1] == "Townsville Power Station" && row[2] == "YABULU" && row[6] == 3), UC)
    filter!((row) -> !(row[1] == "Condamine A" && row[2] == "CPSA" && row[6] == 6), UC)
    filter!((row) -> !(row[1] == "Darling Downs" && row[2] == "DDPS1" && row[6] == 6), UC)
    filter!((row) -> !(row[1] == "Osborne" && row[2] == "OSB-AG" && row[6] == 6), UC)
    filter!((row) -> !(row[1] == "Pelican Point" && row[2] == "PPCCGT" && row[6] == 4), UC)
    filter!((row) -> !(row[1] == "Tamar Valley Combined Cycle" && row[2] == "TVCC201" && row[6] == 6), UC)
    XLSX.writetable(".tmp/UC2__.xlsx", Tables.columntable(UC); sheetname="UC2__", overwrite=true)
    # ➡️➡️➡️➡️➡️➡️➡️➡️➡️➡️ CHECK IF THIS IS WORKING OK
    # this is the rename as per the DUIDs are in the Retirement sheet
    DUIDar = Dict(      "CPSA_GT1"      => "CPSA", 
                        "CPSA_GT2"      => "CPSA", 
                        "CPSA_ST"      => "CPSA", 
                        "DDPS1_GT1"     => "DDPS1", 
                        "DDPS1_GT2"     => "DDPS1", 
                        "DDPS1_GT3"     => "DDPS1", 
                        "DDPS1_ST"     => "DDPS1",
                        "OsborneGT"     => "OSB-AG", 
                        "OsborneST"     => "OSB-AG",
                        "PPCCGTGT1"     => "PPCCGT", 
                        "PPCCGTGT2"     => "PPCCGT", 
                        "PPCCGTST"     => "PPCCGT",
                        "TVCC201_GT"    => "TVCC201")
    UC[!,:DUID] = [n in keys(DUIDar) ? DUIDar[n] : n for n in UC[!,:DUID]]
    XLSX.writetable(".tmp/UC3.xlsx", Tables.columntable(UC); sheetname="UC3", overwrite=true)

    # ====================================== #
    # ============= RETIREMENTS ============ #
    # ====================================== #
    UNITS = PISP.read_xlsx_with_header(ispdata24, "Retirement", "B9:D460")
    rename!(UNITS, 1 => "Generator")
    UNITS[!,:RETIRE] = DateTime.(PISP.parseif(UNITS[:,3]))

    # FIX SOME MISMATCHES BETWEEN NAMES IN SHEETS
    UNITS[!,:Generator] = [n == "Bogong / Mackay" ? "Bogong / MacKay" : n for n in UNITS[!,:Generator]]
    UNITS[!,:Generator] = [n == "Eraring*" ? "Eraring" : n for n in UNITS[!,:Generator]]

    # FIX DUID OF SOME UNITS THAT DO NOT HAVE DUID
    UNITS[UNITS[!,:Generator] .== "Kogan Gas", :DUID] .= "Kogan Gas"
    UNITS[UNITS[!,:Generator] .== "SA Hydrogen Turbine", :DUID] .= "SA Hydrogen Turbine"

    select!(UNITS,Not(3))
    XLSX.writetable(".tmp/RETIREMENTS.xlsx", Tables.columntable(UNITS); sheetname="Retirements", overwrite=true)

    # ====================================== #
    # ============= RELIABILITY ============ #
    # ====================================== #
    RELIA = PISP.read_xlsx_with_header(ispdata24, "Generator Reliability Settings", "B20:G28")
    RELIANEW = PISP.read_xlsx_with_header(ispdata24, "Generator Reliability Settings", "I20:N40")


    # ====================================== #
    # ========= GENERATION SUMMARY ========= #
    # ====================================== #
    GENSUM = PISP.read_xlsx_with_header(ispdata24, "Existing Gen Data Summary", "B10:U319")
    GENSUM_ADD = PISP.read_xlsx_with_header(ispdata24, "Existing Gen Data Summary", "B382:U397")
    GENSUM = vcat(GENSUM, GENSUM_ADD)
    GENSUM = GENSUM[3:end,:]
    flagrow = [!all(ismissing.(Matrix(GENSUM[k:k,2:end]))) for k in 1:nrow(GENSUM)]
    GENSUM = GENSUM[flagrow,:]
    GENSUM = GENSUM[.!ismissing.(GENSUM[!,2]),:]
    GENSUM = GENSUM[GENSUM[!,2] .!= "Generator type",:]
    GENSUM = GENSUM[GENSUM[!,2] .!= "Battery Storage",:]
    GENSUM[!,:Generator] = [namedict[n] for n in GENSUM[!,:Generator]]
    GENSUM[!,:Generator] = [n == "Tallawarra B*" ? "Tallawarra B" : n for n in GENSUM[!,:Generator]]
    GENSUM[!,:Generator] = [n == "Bungala One Solar Farm" ? "Bungala one Solar Farm" : n for n in GENSUM[!,:Generator]]
    GENSUM[!,:Generator] = [n == "Devils Gate" ? "Devils gate" : n for n in GENSUM[!,:Generator]]
    XLSX.writetable(".tmp/GENSUM.xlsx", Tables.columntable(GENSUM); sheetname="GENSUM", overwrite=true)

    FULL = outerjoin(UNITS, GENS, on = :Generator)
    XLSX.writetable(".tmp/FULL.xlsx", Tables.columntable(FULL); sheetname="FULL", overwrite=true)

    FULL = outerjoin(FULL, UC, on = :DUID, matchmissing=:equal)
    rename!(FULL, Dict(:Region => :Area,  Symbol("Installed capacity (MW)") => :CAPACITY, Symbol("Generator Station") => :NAME))
    XLSX.writetable(".tmp/FULL2.xlsx", Tables.columntable(FULL); sheetname="FULL2", overwrite=true)

    FULL = outerjoin(FULL, GENSUM, on = :Generator, matchmissing=:equal, makeunique=true)
    FULL.id_bus = [ismissing(k) ? missing : bust[bust[!,:name] .== k, :id_bus][1] for k in FULL[!,Symbol("ISP \nsub-region")]] 
    # FULL.area_id = [ismissing(k) ? missing : areat[areat[!,:name] .== k, :id][1] for k in FULL[!,Symbol("Region")]]
    FULL.id_bus = [ismissing(k) ? missing : Int64(k) for k in FULL.id_bus]
    # FULL.area_id = [ismissing(k) ? missing : Int64(k) for k in FULL.area_id]
    FULL.Area = [ismissing(k) ? missing : k for k in FULL.Region]
    FULL[!,Symbol("Technology type")] = [ismissing(k) ? missing : k for k in FULL[!,Symbol("Generator type")]]
    FULL[!,Symbol("Fuel type")] = [ismissing(k) ? missing : k for k in FULL[!,Symbol("Fuel/technology type")]]
    FULL.Bus = [ismissing(k) ? missing : k for k in FULL[!,Symbol("ISP \nsub-region")]]
    FULL[!,Symbol("REZ location")] = [ismissing(k) ? missing : k for k in FULL[!,Symbol("REZ location_1")]]
    XLSX.writetable(".tmp/FULL3.xlsx", Tables.columntable(FULL); sheetname="FULL3", overwrite=true)

    for c in [:NAME,:Region,Symbol("Generator type"),Symbol("Regional build cost zone"),
        Symbol("ISP \nsub-region"), Symbol("Fuel/technology type"), Symbol("REZ location_1")] select!(FULL, Not(c)) end 
    FULL[!,:CAPACITY] = coalesce.(FULL[!,:CAPACITY], FULL[!,18]) # Assign maximum capacity to generators with missing capacity
    # remove rows with missing values in column Generator
    FULL = FULL[.!ismissing.(FULL[!,:Generator]),:]
    # @warn("Deleted Steam Turbines from generator table due to missing information. CHECK!")
    XLSX.writetable(".tmp/GENERATORS.xlsx", Tables.columntable(FULL); sheetname="Generators", overwrite=true)

    # ====================================== #
    # ======== RENEWABLE GENERATION ======== #
    # ====================================== #
    GENLIST = FULL[!,:Generator]
    vretunit = (occursin.("solar",  GENLIST) .| 
                occursin.("wind",   GENLIST) .| 
                occursin.("Solar",  GENLIST) .| 
                occursin.("Wind",   GENLIST) .|
                occursin.("Wind",   coalesce.(FULL[!,Symbol("Technology type")],"")) .| 
                occursin.("solar",  coalesce.(FULL[!,Symbol("Technology type")],"")) .| 
                occursin.("Solar",  coalesce.(FULL[!,Symbol("Technology type")],""))
                )

    bessunit = (    occursin.("Hornsdale Power Reserve",    FULL[!,:Generator]) .| 
                    occursin.("BESS",                       FULL[!,:Generator]) .| 
                    occursin.("Storage",                    FULL[!,:Generator]) .| 
                    occursin.("Battery",                    FULL[!,:Generator]) .|
                    occursin.("Renewable Energy Hub",                       FULL[!,:Generator])
                    )

    syncunit = vretunit .| bessunit

    VRET = FULL[vretunit,:]
    BESS = FULL[bessunit,:]
    SYNC = FULL[.!syncunit,:]

    XLSX.writetable(".tmp/VRET.xlsx", Tables.columntable(VRET); sheetname="VRET", overwrite=true)
    XLSX.writetable(".tmp/BESS.xlsx", Tables.columntable(BESS); sheetname="BESS", overwrite=true)
    XLSX.writetable(".tmp/SYNC.xlsx", Tables.columntable(SYNC); sheetname="SYNC", overwrite=true)

    sort!(SYNC, [Symbol("Fuel type"), :Generator]) #sort table
    gens = unique(SYNC[!,:Generator])
    gensfreq = PISP.OrderedDict([(g,count(x->x==g,SYNC[!,:Generator])) for g in gens]) # Count number of units per generator

    selar = Bool[]
    nar = Int64[]
    for r in keys(gensfreq) 
        append!(selar,true); append!(nar,gensfreq[r]);
        for k in 1:(gensfreq[r]-1) append!(selar,false); append!(nar,0); end
    end

    SYNC[!,:n] = nar
    SYNC2 = SYNC[selar,:]
    sort!(SYNC2, [Symbol("Fuel type"), :Generator])
    XLSX.writetable(".tmp/SYNC3.xlsx", Tables.columntable(SYNC2); sheetname="SYNC3", overwrite=true)


    SYNC3 = copy(SYNC2)
    lat = Union{Missing, Float64}[]
    lon = Union{Missing, Float64}[]
    fuel = String[]
    tech = String[]
    type = String[]

    for r in 1:nrow(SYNC3)
        # println(r)
        gty = SYNC3[r, :Generator]                  # Generator name
        fty = SYNC3[r, Symbol("Technology type")]   # Technologytype
        tty = SYNC3[r, Symbol("Fuel type")]         #  Fuel type
        # println(gty, " // ", fty, " // ", tty)

        if gty in keys(PISP.units)
            SYNC3[r,:n] = PISP.units[gty][1]
            push!(fuel, PISP.units[gty][2])
            push!(tech, PISP.units[gty][3])
            push!(type, PISP.units[gty][4])
            push!(lat,  PISP.units[gty][5])
            push!(lon,  PISP.units[gty][6])
        else
            for t in PISP.fueltype
                if fty in t[2]
                    push!(fuel,t[1])
                    if t[1] == "Coal" 
                        push!(tech,tty) 
                    else 
                        push!(tech,fty) 
                    end
                    push!(type,fty)
                else
                    # println("NO DATA ---> ", gty, " ", fty, " ", tty)
                end
            end
            push!(lat, 0.0); push!(lon, 0.0);
        end
    end

    SYNC3[!,:fuel] = fuel
    SYNC3[!,:tech] = tech
    SYNC3[!,:type] = type
    SYNC3[!,:lat]  = lat
    SYNC3[!,:lon]  = lon

    for k in 1:length(SYNC3[!,:fuel])
        if SYNC3[k,:fuel] == "Diesel" 
            SYNC3[k,:tech] = "Diesel" 
        end
        if SYNC3[k,:tech] == "Gas-powered steam turbine" 
            SYNC3[k,:tech] = "OCGT" 
        end
    end

    SYNC3[!,:cap] = SYNC3[!,:CAPACITY] ./ SYNC3[!,:n]
    XLSX.writetable(".tmp/SYNC4.xlsx", Tables.columntable(SYNC3); sheetname="SYNC4", overwrite=true)

    # ====================================== #
    # ============ EMMISSIONS ============== #
    # ====================================== #
    EMI = PISP.read_xlsx_with_header(ispdata24, "Emissions intensity", "B7:D73")
    select!(EMI, Not(2))
    rename!(EMI, 2 => "Emissions")
    EMI[!,:Generator] = strip.(EMI[!,:Generator])
    EMI[!,:Generator] = [string(k) for k in EMI[!,:Generator]]

    genemi =  Dict( 
                    # "Mt Piper" => "Mount Piper", 
                    "Callide C" => "Callide C", 
                    # "Loy Yang A Power Station" => "Loy Yang A", 
                    "Yabulu Steam Turbine" => "Yabulu Steam Turbine ", 
                    "Port Lincoln Gt" => "Port Lincoln GT", 
                    "Yarwun Cogen" => "Yarwun 1" )
    for k in 1:length(EMI[!,:Generator]) EMI[k,:Generator] in keys(genemi) ? EMI[k,:Generator] = genemi[EMI[k,:Generator]] : 0.0 end
    filteremi = .![n in [k+j for k in 1:length(EMI[!,:Generator]) for j in 0:2 if ismissing.(EMI[!,:Generator])[k]] for n in 1:length(EMI[!,:Generator])]
    EMI = EMI[filteremi,:]
    SYNC3 = leftjoin(SYNC3, EMI, on = :Generator)
    SYNC3[!,:Emissions] = [ismissing(e) ? 0.0 : e for e in SYNC3[!,:Emissions]]
    XLSX.writetable(".tmp/SYNC5.xlsx", Tables.columntable(SYNC3); sheetname="SYNC5", overwrite=true)

    SYNC4 = SYNC3[.!(SYNC3[!,:tech] .== "Pumped-Storage"),:]
    PS = SYNC3[(SYNC3[!,:tech] .== "Pumped-Storage"),:]
    XLSX.writetable(".tmp/SYNC6.xlsx", Tables.columntable(SYNC4); sheetname="SYNC6", overwrite=true)
    XLSX.writetable(".tmp/PS.xlsx", Tables.columntable(PS); sheetname="PS", overwrite=true)

    # ====================================== #
    # ======== FILLING GENERATORS ========== #
    # ====================================== #
    slopear = Dict( "OCGT"              => 0.6, 
                    "Black Coal"        => 0.3,
                    "Black Coal NSW"    => 0.3, 
                    "Black Coal QLD"    => 0.3,
                    "Brown Coal"        => 0.3, 
                    "Brown Coal VIC"    => 0.3,
                    "Reservoir"         => 0.6, 
                    "Run-of-River"      => 0.6, 
                    "Pumped-Storage"    => 0.6, 
                    "Diesel"            => 0.6, 
                    "CCGT"              => 0.4,
                    "Hydrogen-based gas turbines" => 0.4)
                    
    # @warn("Slope for Hydrogen-based gas turbines is defined as 0.4. CHECK!")
    inertiaar = Dict(   "OCGT"              => 4.0, 
                        "Black Coal"        => 4.0, 
                        "Black Coal NSW"    => 4.0,
                        "Black Coal QLD"    => 4.0,
                        "Brown Coal"        => 4.0, 
                        "Brown Coal VIC"    => 4.0,
                        "Reservoir"         => 2.5, 
                        "Run-of-River"      => 2.5, 
                        "Pumped-Storage"    => 2.2, 
                        "Diesel"            => 4.0, 
                        "CCGT"              => 4.0,
                        "Hydrogen-based gas turbines" => 4.0)
    # @warn("Inertia for Hydrogen-based gas turbines is defined as 4.0. CHECK!")
    sort!(SYNC4, [Symbol("fuel"), :Generator]) #sort table to solve problem with unit Quarantine


    GENERATORS = DataFrame(id_gen = 1:nrow(SYNC4))
    GENERATORS[!,:name] = SYNC4[!,:Generator]
    GENERATORS[!,:alias] = [ismissing(SYNC4[n,:DUID]) ? SYNC4[n,:Generator] : SYNC4[n,:DUID] for n in 1:length(SYNC4[!,:DUID])]
    GENERATORS[!,:fuel] = SYNC4[!,:fuel]
    GENERATORS[!,:tech] = SYNC4[!,:tech]
    GENERATORS[!,:type] = SYNC4[!,:type]
    GENERATORS[!,:capacity] = SYNC4[!,:cap]

    fullout = []
    partialout = []
    derate = []
    mttrfull = []
    mttrpart = []
    for k in 1:nrow(GENERATORS)
        if ((GENERATORS[k,:tech] == "OCGT" || GENERATORS[k,:tech] == "Diesel") && GENERATORS[k,:capacity] >= 150)       tgt = (RELIA[!,1] .== "OCGT");                              push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif ((GENERATORS[k,:tech] == "OCGT" || GENERATORS[k,:tech] == "Diesel") && GENERATORS[k,:capacity] < 150)    tgt = (RELIA[!,1] .== "Small peaking plants");              push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "CCGT"                                                                            tgt = (RELIA[!,1] .== "CCGT + Steam Turbine");              push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:fuel] == "Hydro"                                                                           tgt = (RELIA[!,1] .== "Hydro");                             push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "Reciprocating Engine"                                                            tgt = (RELIA[!,1] .== "Small peaking plants");              push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "Brown Coal"                                                                      tgt = (RELIA[!,1] .== "Brown Coal");                        push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "Brown Coal VIC"                                                                  tgt = (RELIA[!,1] .== "Brown Coal");                        push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "Black Coal NSW"                                                                  tgt = (RELIA[!,1] .== "Black Coal NSW");                    push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "Black Coal QLD"                                                                  tgt = (RELIA[!,1] .== "Black Coal QLD");                    push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(mttrfull, RELIA[tgt, 4][1]); push!(mttrpart, RELIA[tgt, 5][1]); push!(derate, RELIA[tgt, 6][1])
        elseif GENERATORS[k,:tech] == "Hydrogen-based gas turbines"                                                     tgt = (RELIANEW[!,1] .== "Hydrogen-based gas turbines");    push!(fullout, RELIANEW[tgt, 2][1]/100); push!(partialout, RELIANEW[tgt, 3][1]/100); push!(mttrfull, RELIANEW[tgt, 4][1]); push!(mttrpart, RELIANEW[tgt, 5][1]); push!(derate, RELIANEW[tgt, 6][1]/100)
        else 
            push!(derate, "XXX")
            # println(GENERATORS[k,:name]," ", GENERATORS[k,:tech]," ", GENERATORS[k,:capacity]," ", GENERATORS[k,:fuel])
        end
    end

    # @warn("Partialout and derating factor are missing for some hydrogen-based generators. Replacing with 0.0")
    fullout     = [ismissing(k) ? 0.0 : k for k in fullout]
    partialout  = [ismissing(k) ? 0.0 : k for k in partialout]
    derate      = [ismissing(k) ? 0.0 : k for k in derate]
    mttrfull    = [ismissing(k) ? 0.0 : k for k in mttrfull]
    mttrpart    = [ismissing(k) ? 0.0 : k for k in mttrpart]

    GENERATORS[!,:forate] = ones(nrow(SYNC4)) .- (fullout  .+ partialout  .* (ones(nrow(SYNC4)) .- derate))
    GENERATORS[!,:fullout]      = fullout
    GENERATORS[!,:partialout]   = partialout
    GENERATORS[!,:derate]       = derate
    GENERATORS[!,:mttrfull]     = mttrfull
    GENERATORS[!,:mttrpart]     = mttrpart
    XLSX.writetable(".tmp/GENERATORS2.xlsx", Tables.columntable(GENERATORS); sheetname="GENERATORS2", overwrite=true)

    GENERATORS[!,:id_bus] = SYNC4[!,:id_bus]
    GENERATORS[!,:pmin] = coalesce.(SYNC4[!,:MSG], 0.0)
    GENERATORS[!,:pmax] = SYNC4[!,:cap]
    GENERATORS[!,:rup] = coalesce.(SYNC4[!,:rup], 9999.0)
    GENERATORS[!,:rdw] = coalesce.(SYNC4[!,:rdw], 9999.0)
    GENERATORS[!,:investment] = Int64.([ false for k in 1:nrow(SYNC4)])
    GENERATORS[!,:active] = Int64.([ true for k in 1:nrow(SYNC4)])
    GENERATORS[!,:cvar] = SYNC4[!,Symbol("SRMC (\$/MWh)")]
    GENERATORS[!,:cfuel] = SYNC4[!, Symbol("Fuel cost (\$/GJ)")]
    GENERATORS[!,:cvom] = SYNC4[!, Symbol("VOM (\$/MWh sent-out)")]
    GENERATORS[!,:cfom] = SYNC4[!, Symbol("FOM (\$/kW/annum)")]./1000
    GENERATORS[!,:co2] = SYNC4[!,:Emissions]
    GENERATORS[!,:slope] = [slopear[GENERATORS[k,:tech]] for k in 1:nrow(SYNC4) ]
    GENERATORS[!,:hrate] = SYNC4[!, Symbol("Heat rate (GJ/MWh HHV s.o.)")]
    GENERATORS[!,:pfrmax] = GENERATORS[!,:pmax] * 0.1
    # @warn("PFRMAX is set to 10% of Pmax")
    GENERATORS[!,:g] = zeros(nrow(SYNC4))
    GENERATORS[!,:inertia] = [inertiaar[GENERATORS[k,:tech]] for k in 1:nrow(SYNC4) ]
    GENERATORS[!,:ffr] = Int64.([ false for k in 1:nrow(SYNC4)])
    GENERATORS[!,:pfr] = Int64.([ true for k in 1:nrow(SYNC4)])
    GENERATORS[!,:res2] = Int64.([ true for k in 1:nrow(SYNC4)])
    GENERATORS[!,:res3] = Int64.([ false for k in 1:nrow(SYNC4)])
    GENERATORS[!,:powerfactor] = ones(nrow(SYNC4)) * 0.85
    # @warn("Power factor is set to 85%")
    GENERATORS[!,:latitude] = SYNC4[!,:lat]
    GENERATORS[!,:longitude] = SYNC4[!,:lon]
    GENERATORS[!,:n] = SYNC4[!,:n]
    GENERATORS[!,:contingency] = Int64.([ true for k in 1:nrow(SYNC4)])
    XLSX.writetable(".tmp/GENERATORS3.xlsx", Tables.columntable(GENERATORS); sheetname="GENERATORS3", overwrite=true)
    # @warn("Check fuel cost for Hydrogen-based units")

    for r in 1:nrow(GENERATORS)
        if GENERATORS[r,:fuel] == "Natural Gas"
            if GENERATORS[r,:tech] == "CCGT" && GENERATORS[r,:pmin] == 0.0
                GENERATORS[r,:pmin] = round(0.52 * GENERATORS[r,:pmax], digits=2)
            elseif GENERATORS[r,:tech] == "OCGT" && GENERATORS[r,:pmin] == 0.0
                GENERATORS[r,:pmin] = round(0.33 * GENERATORS[r,:pmax], digits=2)
            end
        elseif GENERATORS[r,:fuel] == "Hydro" && GENERATORS[r,:pmin] == 0.0
            GENERATORS[r,:pmin] = round(0.2 * GENERATORS[r,:pmax], digits=2)
        elseif GENERATORS[r,:fuel] == "Diesel" && GENERATORS[r,:pmin] == 0.0
            GENERATORS[r,:pmin] = round(0.2 * GENERATORS[r,:pmax], digits=2)
        end
    end

    # @warn("Pmin for CCGT is set to 52% of Pmax")
    # @warn("Pmin for OCGT is set to 33% of Pmax")
    # @warn("Pmin for Hydro is set to 20% of Pmax")
    # @warn("Pmin for Diesel is set to 20% of Pmax")

    # ====================================== #
    # ============= COMMITMENT ============= #
    # ====================================== #

    COMMITMENT = DataFrame(id = 1:nrow(SYNC4))
    COMMITMENT[!,:gen_id] = 1:nrow(SYNC4)
    COMMITMENT[!,:down_time] = zeros(nrow(SYNC4))
    COMMITMENT[!,:up_time] = coalesce.(SYNC4[!,:MinUpTime], 0.0)
    COMMITMENT[!,:last_state] = zeros(nrow(SYNC4))
    COMMITMENT[!,:last_state_period] = zeros(nrow(SYNC4))
    COMMITMENT[!,:last_state_output] = zeros(nrow(SYNC4))
    COMMITMENT[!,:start_up_cost] = [GENERATORS[GENERATORS[!,:id_gen] .== k, :fuel][1] == "Coal" ? GENERATORS[GENERATORS[!,:id_gen] .== k, :cvar][1] * GENERATORS[GENERATORS[!,:id_gen] .== k, :pmax][1] * 4.0 : 0.0 for k in COMMITMENT[!,:gen_id] ] # 
    COMMITMENT[!,:shut_down_cost] = zeros(nrow(SYNC4))
    COMMITMENT[!,:start_up_time] = zeros(nrow(SYNC4))
    COMMITMENT[!,:shut_down_time] = zeros(nrow(SYNC4))

    # @warn("No minimum down time for any generator")
    # @warn("Start up cost for coal generators is set to 4 times the variable cost times the maximum capacity")
    # @warn("No shut down cost for any generator")
    # @warn("No start up time for any generator")
    # @warn("No shut down time for any generator")

    # MERGE GENERATOR AND COMMITMENT IN left `id` and right `gen_id`. Fill missing values in COMMITMENT with 0
    merged = leftjoin(GENERATORS, COMMITMENT, on = [:id_gen => :gen_id], makeunique=true)
    select!(merged, Not(:id))
    # rename!(merged, :id => :id_gen)
    ts.gen = merged
    XLSX.writetable(".tmp/GENERATORS_FULL.xlsx", Tables.columntable(merged); sheetname="GENERATORS", overwrite=true)
    rm(".tmp"; recursive=true)
    return SYNC4, GENERATORS, PS
end

function gen_n_sched_table(tv::PISPtimeVarying, SYNC4::DataFrame, GENERATORS::DataFrame)
    # COMMITED AND ANTICIPATED PROJECTS DATES
    MISSING_DATES = PISP.OrderedDict("Kogan Gas" => "2026-07-01T00:00:00")
    N_SCHED_COMM = DataFrame([Symbol(k) => Vector{Any}() for k in keys(PISP.MOD_GEN_N)])
    i = isempty(tv.gen_n.id) ? 1 : maximum(tv.gen_n.id) + 1
    for r in 1:nrow(SYNC4) 
        # FIX COMMISSIONING DATE FOR GENERATORS
        d = SYNC4[r, Symbol("Commissioning date")] # Comissioning date
        if ismissing(d)
            if SYNC4[r,:Generator] in keys(MISSING_DATES)
                SYNC4[r, Symbol("Commissioning date")] = DateTime(MISSING_DATES[SYNC4[r,:Generator]])
            else
                @warn("No commissioning date for ", SYNC4[r,:Generator])
            end
        end
        # GENERATE DATAFRAME WITH SCHEDULED COMMISSIONING
        d = SYNC4[r, Symbol("Commissioning date")] # Comissioning date
        if d > DateTime("2020-01-01T01:00:00")
            genid = GENERATORS[GENERATORS[!,:name] .== SYNC4[r,:Generator], :id_gen][1]
            genname = GENERATORS[GENERATORS[!,:name] .== SYNC4[r,:Generator], :name][1]
            # @warn("Setting commissioning date for $(SYNC4[r,:Generator]) to $(d)")
            for sc in keys(PISP.ID2SCE)
                # BEFORE COMMISSIONING -> deactivated
                row = [i, genid, sc, DateTime("2020-01-01T00:00:00"), 0]
                push!(N_SCHED_COMM, row)
                i+=1
                # COMMISSIONING DATE -> activated
                if genname == "Kurri Kurri OCGT"
                    row = [i, genid, sc, d, 2]
                    push!(N_SCHED_COMM, row)
                else
                    row = [i, genid, sc, d, 1]
                    push!(N_SCHED_COMM, row)
                end
                i+=1
            end
        end
    end
    # @info("\n✓ GENERATOR_n_sched - Commissioned & Anticipated projects")

    # Fill commitment table
    for k in 1:nrow(N_SCHED_COMM) push!(tv.gen_n, collect(N_SCHED_COMM[k,:])) end
end

function gen_retirements(ts, tv)
    gent = ts.gen

    pnid    = isempty(tv.gen_n) ? 0 : maximum(tv.gen_n.id)
    ppmaxid = isempty(tv.gen_pmax) ? 0 : maximum(tv.gen_pmax.id)

    for scid in keys(PISP.ID2SCE)
        for unit in PISP.Retirements2024[scid]
            genid = gent[gent[!,:name] .== unit[1], :id_gen][1]
            for ndata in unit[2]
                pnid+=1; 
                push!(tv.gen_n, [pnid, genid, scid, DateTime(ndata[3],ndata[2],ndata[1]), ndata[4]])
            end
        end

        for unit in PISP.Reduction2024[scid]
            genid = gent[gent[!,:name] .== unit[1], :id_gen][1]
            for ndata in unit[2]
                ppmaxid+=1; 
                push!(tv.gen_pmax, [ppmaxid, genid, scid, DateTime(ndata[3],ndata[2],ndata[1]), ndata[4]])
            end
        end
    end
end

function ess_tables(ts::PISPtimeStatic, tv::PISPtimeVarying, PSESS::DataFrame, ispdata24::String)
    bust = ts.bus

    BESS_PROP   = PISP.read_xlsx_with_header(ispdata24, "Storage properties", "B4:H13")
    PS_PROP     = PISP.read_xlsx_with_header(ispdata24, "Storage properties", "B22:K26")
    BESS_CAP    = PISP.read_xlsx_with_header(ispdata24, "Maximum capacity", "P8:U62")
    BESS_SUM    = PISP.read_xlsx_with_header(ispdata24, "Summary Mapping", "B314:AB370")
    RELIANEW    = PISP.read_xlsx_with_header(ispdata24, "Generator Reliability Settings", "I20:N40")

    BESS_SUM = BESS_SUM[3:end,:]
    BESS_SUM[!,:cheff] = [replace(BESS_SUM[i,Symbol("VOM (\$/MWh sent-out)")], "All " => "") for i in 1:nrow(BESS_SUM)]
    BESS_SUM[!,:dcheff] = [replace(BESS_SUM[i,Symbol("VOM (\$/MWh sent-out)")], "All " => "") for i in 1:nrow(BESS_SUM)]

    BESS = BESS_CAP
    BESS_FOR = DataFrame(id_ess = 1:nrow(BESS))
    BESS_FOR[!,:name] = BESS[!,:Storage]
    BESS_FOR[!,:alias] = [PISP.databess[BESS[!,:Storage][k]][2] for k in 1:length(BESS[!,:Storage])]
    BESS_FOR[!,:tech] = ["BESS" for k in 1:nrow(BESS)]
    BESS_FOR[!,:type] = ["SHALLOW" for k in 1:nrow(BESS)]
    BESS_FOR[!,:capacity] = BESS[!,Symbol("Installed capacity (MW)")]
    BESS_FOR[!,:investment] = [0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:active] = [ 1 for k in 1:nrow(BESS)]
    BESS_FOR[!,:id_bus] = Int64.([bust[bust[!,:name] .== BESS_SUM[BESS_SUM[!,:Batteries] .== k, Symbol("Sub-region")][1],:id_bus][1] for k in BESS[!,:Storage]])
    BESS_FOR[!,:ch_eff] = round.([BESS_PROP[BESS_PROP[!,:Property] .== "Charge efficiency (utility)", Symbol(BESS_SUM[k,:cheff])][1] for k in 1:nrow(BESS)],digits=4) ./ 100
    BESS_FOR[!,:dch_eff] = round.([BESS_PROP[BESS_PROP[!,:Property] .== "Discharge efficiency (utility)", Symbol(BESS_SUM[k,:dcheff])][1] for k in 1:nrow(BESS)],digits=4) ./ 100
    BESS_FOR[!,:eini] = [BESS_PROP[BESS_PROP[!,:Property] .== "Allowable min state of charge", Symbol("Battery storage (2hrs storage)")][1] for k in 1:nrow(BESS)] 
    BESS_FOR[!,:emin] = [BESS_PROP[BESS_PROP[!,:Property] .== "Allowable min state of charge", Symbol("Battery storage (2hrs storage)")][1] for k in 1:nrow(BESS)]
    BESS_FOR[!,:emax] = BESS[!,Symbol("Energy (MWh)")] 
    BESS_FOR[!,:pmin] = [ 0.0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:pmax] = BESS[!,Symbol("Installed capacity (MW)")] 
    BESS_FOR[!,:lmin] = [ 0.0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:lmax] = BESS[!,Symbol("Installed capacity (MW)")]
    BESS_FOR[!,:fullout] = [RELIANEW[8,2] for k in 1:nrow(BESS)]
    BESS_FOR[!,:partialout] = [0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:mttrfull] = [RELIANEW[8,4] for k in 1:nrow(BESS)]
    BESS_FOR[!,:mttrpart] = [0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:inertia] = [ 0.0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:powerfactor] = [ 1.0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:ffr] = [ 1 for k in 1:nrow(BESS)]
    BESS_FOR[!,:pfr] = [ 0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:res2] = [ 1 for k in 1:nrow(BESS)]
    BESS_FOR[!,:res3] = [ 0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:fr_db] = [ 0.0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:fr_ad] = [ 0.3 for k in 1:nrow(BESS)]
    BESS_FOR[!,:fr_dt] = [ 0.05 for k in 1:nrow(BESS)]
    BESS_FOR[!,:fr_frt] = [ 1000.0 for k in 1:nrow(BESS)]
    BESS_FOR[!,:fr_fr] = [ 70 for k in 1:nrow(BESS)]
    BESS_FOR[!,:longitude] = [ PISP.databess[k][1][2] for k in BESS[!,:Storage]]
    BESS_FOR[!,:latitude] = [ PISP.databess[k][1][1] for k in BESS[!,:Storage]]
    BESS_FOR[!,:n] = Int64.(BESS_CAP[!,Symbol("Project status")] .!= "Anticipated")
    # @warn("Anticipated BESS projects are deactivated initially")
    BESS_FOR[!,:contingency] = [ 0 for k in 1:nrow(BESS)]

    PS_FOR = DataFrame(id_ess = (nrow(BESS)+1):(nrow(BESS)+nrow(PSESS)))
    PS_FOR[!,:name] = string.(PSESS[!,:Generator])
    PS_FOR[!,:alias] = [PISP.dataps[k][8] for k in PSESS[!,:Generator]]
    PS_FOR[!,:tech] = ["PS" for k in 1:nrow(PSESS)]
    PS_FOR[!,:type] = [PISP.dataps[k][9] for k in PSESS[!,:Generator] ]
    PS_FOR[!,:capacity] = [Float64(max(PISP.dataps[k][3], PISP.dataps[k][4])) for k in PSESS[!,:Generator] ]#PSESS[!,Symbol("CAPACITY")] 
    PS_FOR[!,:investment] = [ 0 for k in 1:nrow(PSESS) ]
    PS_FOR[!,:active] = [ 1 for k in 1:nrow(PSESS) ]
    PS_FOR[!,:id_bus] = Int64.(PSESS[!,:id_bus])
    PS_FOR[!,:ch_eff] = [ PISP.dataps[k][1] for k in PSESS[!,:Generator] ] ./ 100
    PS_FOR[!,:dch_eff] = [ PISP.dataps[k][2] for k in PSESS[!,:Generator] ] ./ 100
    PS_FOR[!,:eini] = [10.0 for k in PSESS[!,:Generator] ]
    PS_FOR[!,:emin] = [10.0 for k in PSESS[!,:Generator] ]
    PS_FOR[!,:emax] = [ PISP.dataps[k][5] for k in PSESS[!,:Generator] ]
    PS_FOR[!,:pmin] = [ 0.0 for k in PSESS[!,:Generator] ]
    PS_FOR[!,:pmax] = [ PISP.dataps[k][3] for k in PSESS[!,:Generator] ]
    PS_FOR[!,:lmin] = [ 0.0 for k in PSESS[!,:Generator] ]
    PS_FOR[!,:lmax] = [ PISP.dataps[k][4] for k in PSESS[!,:Generator] ]
    PS_FOR[!,:fullout] = [RELIANEW[15,2] for k in 1:nrow(PSESS)]
    PS_FOR[!,:partialout] = [0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:mttrfull] = [RELIANEW[15,4] for k in 1:nrow(PSESS)]
    PS_FOR[!,:mttrpart] = [0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:inertia] = [ 2.2 for k in PSESS[!,:Generator] ]
    PS_FOR[!,:powerfactor] = [ 0.85 for k in 1:nrow(PSESS)]
    PS_FOR[!,:ffr] = [ 0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:pfr] = [ 1 for k in 1:nrow(PSESS)]
    PS_FOR[!,:res2] = [ 1 for k in 1:nrow(PSESS)]
    PS_FOR[!,:res3] = [ 0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:fr_db] = [ 0.0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:fr_ad] = [ 0.0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:fr_dt] = [ 0.0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:fr_frt] = [ 0.0 for k in 1:nrow(PSESS)]
    PS_FOR[!,:fr_fr] = [ 70 for k in 1:nrow(PSESS)]
    PS_FOR[!,:longitude] = [ PISP.dataps[k][7] for k in PSESS[!,:Generator]]
    PS_FOR[!,:latitude] = [ PISP.dataps[k][6] for k in PSESS[!,:Generator]]
    PS_FOR[!,:n] = Int64.(PSESS[!,Symbol("Commissioning date")] .< DateTime(2024,1,1))
    # @warn("Storage comissioned after 01-01-2024 is set as inactive")
    PS_FOR[!,:contingency] = [ 0 for k in 1:nrow(PSESS)]

    l_cethana = [maximum(PS_FOR[!,:id_ess])+1, "Cethana", PISP.dataps["Cethana"][end-1], "PS", PISP.dataps["Cethana"][end], PISP.dataps["Cethana"][3], 0, 0, 10,PISP.dataps["Cethana"][1]/100, PISP.dataps["Cethana"][2]/100, 10,10,PISP.dataps["Cethana"][5],0,PISP.dataps["Cethana"][3], 0, PISP.dataps["Cethana"][4],RELIANEW[15,2],0,RELIANEW[15,4],0 , 2.2,0.85,0,1,1,0,0,0,0,0,70,PISP.dataps["Cethana"][7],PISP.dataps["Cethana"][6],1,0]
    push!(PS_FOR, l_cethana)

    # Combine BESS and PS DataFrames
    ts.ess = vcat(ts.ess, BESS_FOR, PS_FOR)

    # ENTRY DATES FOR ANTICIPATED/COMMISSIONED ENERGY STORAGE 
    idk = isempty(tv.ess_n) ? 1 : maximum(tv.ess_n[!,:id]) + 1
    for k in 1:nrow(BESS_CAP) 
        if BESS_FOR[k,:n] == 0 
            for sc in keys(PISP.ID2SCE)
                tgtdate = BESS_CAP[k,Symbol("Indicative commissioning date")]
                push!(tv.ess_n, [idk, BESS_FOR[k,:id_ess], sc, DateTime(Dates.year(tgtdate), Dates.month(tgtdate), 1, 0, 0, 0), 1])
                idk+=1
            end
        end
    end

    for k in 1:nrow(PS_FOR)
        if PS_FOR[k,:name] == "Cethana"
            continue
        end 
        tgtdate = PSESS[k,Symbol("Commissioning date")]
        if tgtdate >= DateTime(2024,1,1)
            for sc in keys(PISP.ID2SCE)
                push!(tv.ess_n, [idk, PS_FOR[k,:id_ess], sc, DateTime(Dates.year(tgtdate), Dates.month(tgtdate), 1, 0, 0, 0), 1])
                idk+=1
            end
        end
    end
end

function gen_pmax_distpv(tc::PISPtimeConfig, ts::PISPtimeStatic, tv::PISPtimeVarying, profilespath::String)
    probs = tc.problem;
    bust = ts.bus;

    gid = isempty(ts.gen.id_gen) ? 0 : maximum(ts.gen.id_gen);
    pmaxid = isempty(tv.gen_pmax.id) ? 0 : maximum(tv.gen_pmax.id);

    for st in keys(PISP.NEMBUSNAME)
        gid += 1
        bus_data = bust[bust[!,:name] .== st, :]
        bus_id = bus_data[!, :id_bus][1]
        bus_lat = bus_data[!, :latitude][1]
        bus_lon = bus_data[!, :longitude][1]
        arrgen = [gid,"RTPV_$(st)","RTPV_$(st)","Solar","RoofPV","RoofPV", 100.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, bus_id, 0.0, 100.0, 9999.9, 9999.9, 0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 1.0, bus_lat, bus_lon, 1, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        push!(ts.gen, arrgen)
        for p in 1:nrow(probs)
            scid = probs[p,:scenario][1]
            sc = PISP.ID2SCE[scid]

            df = CSV.File(string(profilespath,"demand_$(st)_$(sc)/",st,"_RefYear_4006_",replace(uppercase(PISP.ID2SCE2[scid]), " " => "_"),"_POE10_PV_TOT.csv")) |> DataFrame

            dstart = probs[p,:dstart]
            dend = probs[p,:dend]
            yr = Dates.year(dstart)
            ds = Dates.day(dstart)
            de = Dates.day(dend)
            ms = Dates.month(dstart)
            me = Dates.month(dend)

            df1 = df[((df[!,:Year] .== yr) .& ((df[!,:Month] .>= ms) .| (df[!,:Month] .<= me)) ),:]

            if ms == me
                df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .& ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
            elseif me == ms + 1
                df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
            else 
                df2 = df1[ .!( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .< ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .> de)) ) ,:]
            end

            data = vec(permutedims(Tables.matrix(df2[:,4:end])))
            data2 = round.([ (data[2*i-1]+data[2*i])/2 for i in 1:Int64(length(data)/2) ], digits=4)

            for h in 1:Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)
                pmaxid += 1
                push!(tv.gen_pmax, [pmaxid, gid, scid, dstart+Dates.Hour(h-1), data2[h]])
            end
        end
    end
end

function dem_load(tc::PISPtimeConfig, ts::PISPtimeStatic, tv::PISPtimeVarying, profilespath::String)
    probs = tc.problem
    bust = ts.bus

    did     = isempty(ts.dem.id_dem) ? 0 : maximum(ts.dem.id_dem)
    lmaxid  = isempty(tv.dem_load.id) ? 0 : maximum(tv.dem_load.id)

    for st in keys(PISP.NEMBUSNAME)
        did += 1
        bus_data = bust[bust[!,:name] .== st, :]
        bus_id = bus_data[!, :id_bus][1]

        arrdem = [did,"DEM_$(st)", 100.0, bus_id, 1, 0, 17500.0, 1]
        push!(ts.dem, arrdem)
        for p in 1:nrow(probs)
            scid = probs[p,:scenario][1]
            sc = PISP.ID2SCE[scid]

            df = CSV.File(string(profilespath,"demand_$(st)_$(sc)/",st,"_RefYear_4006_",replace(uppercase(PISP.ID2SCE2[scid]), " " => "_"),"_POE10_OPSO_MODELLING_PVLITE.csv")) |> DataFrame

            dstart = probs[p,:dstart]
            dend = probs[p,:dend]
            yr = Dates.year(dstart)
            ds = Dates.day(dstart)
            de = Dates.day(dend)
            ms = Dates.month(dstart)
            me = Dates.month(dend)

            df1 = df[((df[!,:Year] .== yr) .& ((df[!,:Month] .>= ms) .| (df[!,:Month] .<= me)) ),:]

            if ms == me
                df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .& ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
            elseif me == ms + 1
                df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
            else 
                df2 = df1[ .!( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .< ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .> de)) ) ,:]
            end

            data = vec(permutedims(Tables.matrix(df2[:,4:end])))
            data2 = [ (data[2*i-1]+data[2*i])/2 for i in 1:Int64(length(data)/2) ]

            for h in 1:Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)
                lmaxid += 1
                push!(tv.dem_load, [lmaxid, did, scid, dstart+Dates.Hour(h-1), data2[h]])
            end
        end
    end
end

function gen_pmax_solar(tc::PISPtimeConfig, ts::PISPtimeStatic, tv::PISPtimeVarying, ispdata24::String, outlookdata::String, outlookAEMO::String, profilespath::String)
    probs = tc.problem
    bust = ts.bus

    gid = isempty(ts.gen.id_gen) ? 0 : maximum(ts.gen.id_gen);
    pmaxid = isempty(tv.gen_pmax.id) ? 0 : maximum(tv.gen_pmax.id);

    tch = "Solar"
    EXIST_TECH = PISP.read_xlsx_with_header(ispdata24, "Existing Gen Data Summary", "B11:K297")
    EXIST_SOLAR = EXIST_TECH[occursin.(tch[2:end], coalesce.(EXIST_TECH[!,2],"")),:]
    # @warn("Anticipated solar PV projects not considered in the existing data")

    REZ_BUS = PISP.read_xlsx_with_header(ispdata24, "Renewable Energy Zones", "B7:G50")
    # println(REZ_BUS)

    genid = Dict()
    for st in setdiff(keys(PISP.NEMBUSNAME),["GG", "SNW"]) ## Buses with no large-scale solar projects or REZ are not considered
        gid += 1
        bus_data = bust[bust[!,:name] .== st, :]
        bus_id = bus_data[!, :id_bus][1]    
        bus_lat = bus_data[!, :latitude][1]
        bus_lon = bus_data[!, :longitude][1]
        exs_gen_sol = EXIST_SOLAR[EXIST_SOLAR[!,4] .== st,:];
        if st == "TAS" capaux = 0.0 else capaux = sum(EXIST_SOLAR[EXIST_SOLAR[!,4] .== st,7]) end
        genid[st] = [gid, capaux]
        arrgen = [gid,"LSPV_$(st)","LSPV_$(st)","Solar","LargePV","LargePV", capaux, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, bus_id, 0.0, capaux, 9999.9,  9999.9, 0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 1.0, bus_lat, bus_lon, 1, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        push!(ts.gen, arrgen)
    end

    name_ex = Dict()

    foldertech = string(profilespath, "solar/solar/")

    scid2cdp = Dict(1 => "CDP14", 2 => "CDP14", 3 => "CDP14", 4 => "CDP14")
    auxf = []
    auxk = []

    for p in 1:nrow(probs)
        scid = probs[p,:scenario][1]
        sc = PISP.ID2SCE[scid]
        dstart = probs[p,:dstart]
        dend = probs[p,:dend]
        yr = Dates.year(dstart)
        ds = Dates.day(dstart)
        de = Dates.day(dend)
        ms = Dates.month(dstart)
        me = Dates.month(dend)
        outlookfile = string(outlookdata,"/2024 ISP - ",sc," - Core_RED.xlsx")

        TECH_CAP = PISP.read_xlsx_with_header(outlookAEMO, "CapacityOutlook", "A1:G14356")
        SOLAR_CAP = PISP.read_xlsx_with_header(outlookfile, "REZ Generation Capacity", "B3:AG2238")
        SOLAR_CAP = dropmissing(SOLAR_CAP,:CDP)
        
        y = ms < 7 ? yr - 1 : yr

        for st in setdiff(keys(PISP.NEMBUSNAME),["GG", "SNW"]) # Buses with no large-scale solar projects are not considered

            REZs = REZ_BUS[(REZ_BUS[!,Symbol("ISP Sub-region")] .== st),:ID]
            REZSUM = REZ_BUS[(REZ_BUS[!,Symbol("ISP Sub-region")] .== st),[:ID,:Name,Symbol("ISP Sub-region")]]

            SOLARAUX = SOLAR_CAP[in.(SOLAR_CAP[!,:REZ],[REZs]) .& (SOLAR_CAP[!,:CDP] .== scid2cdp[scid]) .& (SOLAR_CAP[!,:Technology] .== tch), [:REZ,Symbol("$(y)-$(string(y+1)[3:end])")]]

            rename!(SOLARAUX, Dict(:REZ => :ID))
            SOLARAUX = innerjoin(SOLARAUX,REZSUM, on = :ID)
            SOLARAUX[!,:EXISTING] = [0.0 for s in 1:nrow(SOLARAUX)]

            dataexi = zeros(Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)*2)
            exi_cap = 0.0
            df2 = DataFrame()
            for r in 1:nrow(EXIST_SOLAR)
                k = EXIST_SOLAR[r,1]
                reg = EXIST_SOLAR[r,5]

                if EXIST_SOLAR[r,4] == st # IF GENERATOR IS IN THE SUBREGION
                    for sexp in 1:nrow(SOLARAUX)
                        if SOLARAUX[sexp,:Name] == reg # IF THE REZ IS EQUAL TO THE REZ OF THE GENERATOR
                            SOLARAUX[sexp,:EXISTING] = SOLARAUX[sexp,:EXISTING] + EXIST_SOLAR[r,10] # ADD CAPACITY TO THE REZ IF THE GENERATOR IS IN THE REZ
                        end
                    end

                    file = ""
                    if k in keys(name_ex)
                        file = name_ex[k]
                    else
                        for f in readdir(foldertech)
                            if f[1:3] != "REZ" && occursin(split(k," ")[1],f)
                                push!(auxf,f)
                                push!(auxk,k)
                                file = f
                                break
                            end
                        end
                    end

                    df = CSV.File(string(foldertech,file)) |> DataFrame

                    df1 = DataFrame()
                    df1 = df[((df[!,:Year] .== yr) .& ((df[!,:Month] .>= ms) .& (df[!,:Month] .<= me)) ),:] #select data for the year and problems 

                    if ms == me
                        df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .& ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                    elseif me == ms + 1
                        df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                    else 
                        df2 = df1[ .!( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .< ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .> de)) ) ,:]
                    end
                    dataexi = dataexi .+ vec(permutedims(Tables.matrix(df2[:,4:end]))) * EXIST_SOLAR[r,10]
                    exi_cap += EXIST_SOLAR[r,10] # EXISTING CAPACITY FROM WINTER RATING
                end
            end
            SOLARAUX[!,:DIFF] = SOLARAUX[!,2] .- SOLARAUX[!,:EXISTING] # REZ capacity utilised 

            naux = 0    
            datanew = zeros(Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)*2)
            nauxrez = 0
            datarez = zeros(Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)*2)  

            drezcap = 0
            rezcap = 0
            tch_ = "Utility solar"

            if dstart > DateTime(2024,7,1,0,0,0)
                instcap = TECH_CAP[(TECH_CAP[!,:Scenario] .== sc) .& (TECH_CAP[!,:Subregion] .== st) .& (TECH_CAP[!,:Technology] .== tch_) .& (year.(TECH_CAP[!,:date]) .== y), 7][1]
                # future capacity profile (average of REZ profiles in the area)
                for f in readdir(foldertech)
                    sub = split(f,['_','.'])
                    if "REZ" in sub && "SAT" in sub && sub[2] in REZs
                        df = CSV.File(string(foldertech,f)) |> DataFrame
                        df1 = df[((df[!,:Year] .== yr) .& ((df[!,:Month] .>= ms) .& (df[!,:Month] .<= me)) ),:]

                        if ms == me
                            df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .& ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                        elseif me == ms + 1
                            df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                        else 
                            df2 = df1[ .!( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .< ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .> de)) ) ,:]
                        end
                        datanew = datanew .+ vec(permutedims(Tables.matrix(df2[:,4:end])))
                        naux += 1

                        #check if specific REZ capacity is available
                        if nrow(SOLARAUX) > 0
                            for r in 1:nrow(SOLARAUX)
                                if SOLARAUX[r,:ID] == sub[2] && SOLARAUX[r,:DIFF] >= 0.01
                                    datarez = datarez .+ vec(permutedims(Tables.matrix(df2[:,4:end]))) * SOLARAUX[r,:DIFF]
                                    drezcap += SOLARAUX[r,:DIFF]
                                end
                            end
                        end

                    end
                end
            else
                instcap = exi_cap
            end

            if (instcap - exi_cap - drezcap) > 0
                dataN = datanew / naux * (instcap - exi_cap - drezcap)
                data = (dataexi .+ datarez) .+ dataN
            elseif instcap - exi_cap < drezcap
                dataN = datanew / naux * abs(instcap - exi_cap)
                data = dataexi .+ dataN
                if ((instcap - exi_cap) < 0 )&& (abs(instcap - exi_cap) > 100)  end #@warn("$(st) $(sc) $(abs(instcap - exi_cap))")
            else
                dataN = naux == 0 ? datanew : datanew / naux * 0.0
                data = (dataexi .+ datarez) .+ dataN
            end

            data2 = [ (data[2*i-1]+data[2*i])/2 for i in 1:Int64(length(data)/2) ]
            for h in 1:Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)
                pmaxid += 1
                push!(tv.gen_pmax, [pmaxid, genid[st][1], scid, dstart+Dates.Hour(h-1), data2[h]])
            end
        end
    end
end

function gen_pmax_wind(tc::PISPtimeConfig, ts::PISPtimeStatic, tv::PISPtimeVarying, ispdata24::String, outlookdata::String, outlookAEMO::String, profilespath::String)
    probs = tc.problem
    bust = ts.bus

    gid = isempty(ts.gen.id_gen) ? 0 : maximum(ts.gen.id_gen);
    pmaxid = isempty(tv.gen_pmax.id) ? 0 : maximum(tv.gen_pmax.id);

    tch = "Wind"
    EXIST_TECH = PISP.read_xlsx_with_header(ispdata24, "Existing Gen Data Summary", "B11:K297")
    EXIST_WIND = EXIST_TECH[occursin.(tch[2:end], coalesce.(EXIST_TECH[!,2],"")),:]
    REZ_BUS = PISP.read_xlsx_with_header(ispdata24, "Renewable Energy Zones", "B7:G50")

    genid = Dict()
    for st in setdiff(keys(PISP.NEMBUSNAME),["GG"]) ## Buses with no large-scale solar projects or REZ are not considered
        gid += 1
        bus_data = bust[bust[!,:name] .== st, :]
        bus_id = bus_data[!, :id_bus][1]    
        bus_lat = bus_data[!, :latitude][1]
        bus_lon = bus_data[!, :longitude][1]

        arrgen = []
        if st == "SNW"
            capaux = 0.0
            genid[st] = [gid, capaux]
            arrgen = [gid,"WIND_$(st)","WIND_$(st)","Wind","Wind","Wind",        capaux, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, bus_id, 0.0, capaux, 9999.9,  9999.9, 0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 1.0, bus_lat, bus_lon, 1, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        else
            capaux = sum(EXIST_WIND[EXIST_WIND[!,4] .== st,7])
            genid[st] = [gid, capaux]
            arrgen = [gid,"WIND_$(st)","WIND_$(st)","Wind","Wind","Wind",        capaux, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, bus_id, 0.0, capaux, 9999.9,  9999.9, 0, 1, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 1.0, bus_lat, bus_lon, 1, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        end
        push!(ts.gen, arrgen)
    end

    foldertech = string(profilespath, "wind/wind/")

    scid2cdp = Dict(1 => "CDP14", 2 => "CDP14", 3 => "CDP14", 4 => "CDP14")
    auxf = []
    auxk = []

    for p in 1:nrow(probs)
        scid = probs[p,:scenario][1]
        sc = PISP.ID2SCE[scid]
        dstart = probs[p,:dstart]
        dend = probs[p,:dend]
        yr = Dates.year(dstart)
        ds = Dates.day(dstart)
        de = Dates.day(dend)
        ms = Dates.month(dstart)
        me = Dates.month(dend)
        outlookfile = string(outlookdata,"/2024 ISP - ",sc," - Core_RED.xlsx")

        TECH_CAP = PISP.read_xlsx_with_header(outlookAEMO, "CapacityOutlook", "A1:G14356")
        WIND_CAP = PISP.read_xlsx_with_header(outlookfile, "REZ Generation Capacity", "B3:AG2238")
        WIND_CAP = dropmissing(WIND_CAP,:CDP)
        
        y = ms < 7 ? yr - 1 : yr

        for st in setdiff(keys(PISP.NEMBUSNAME),["GG"]) # Buses with no large-scale wind are not considered

            REZs = REZ_BUS[(REZ_BUS[!,Symbol("ISP Sub-region")] .== st),:ID]
            REZSUM = REZ_BUS[(REZ_BUS[!,Symbol("ISP Sub-region")] .== st),[:ID,:Name,Symbol("ISP Sub-region")]]

            WINDAUX = WIND_CAP[in.(WIND_CAP[!,:REZ],[REZs]) .& (WIND_CAP[!,:CDP] .== scid2cdp[scid]) .& (WIND_CAP[!,:Technology] .== tch), [:REZ,Symbol("$(y)-$(string(y+1)[3:end])")]]

            rename!(WINDAUX, Dict(:REZ => :ID))
            WINDAUX = innerjoin(WINDAUX,REZSUM, on = :ID)
            WINDAUX[!,:EXISTING] = [0.0 for s in 1:nrow(WINDAUX)]

            dataexi = zeros(Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)*2)
            exi_cap = 0.0
            df2 = DataFrame()
            for r in 1:nrow(EXIST_WIND)
                k = EXIST_WIND[r,1]
                reg = EXIST_WIND[r,5]
                if EXIST_WIND[r,4] == st # IF GENERATOR IS IN THE SUBREGION
                    for sexp in 1:nrow(WINDAUX)
                        if WINDAUX[sexp,:Name] == reg # IF THE REZ IS EQUAL TO THE REZ OF THE GENERATOR
                            WINDAUX[sexp,:EXISTING] = WINDAUX[sexp,:EXISTING] + EXIST_WIND[r,7] # ADD CAPACITY TO THE REZ IF THE GENERATOR IS IN THE REZ
                        end
                    end
                    # println(" =============== $(k) ============== ")
                    file = ""
                    if k in keys(PISP.name_ex)
                        file = PISP.name_ex[k]
                    else
                        for f in readdir(foldertech)
                            if f[1:3] != "REZ" && occursin(split(k," ")[1],f)
                                push!(auxf,f)
                                push!(auxk,k)
                                file = f
                                # println(k, " ==> ", f)
                                break
                            end
                        end
                    end
                    # println(" $(k) ======>", file)

                    df = CSV.File(string(foldertech,file)) |> DataFrame

                    df1 = DataFrame()
                    df1 = df[((df[!,:Year] .== yr) .& ((df[!,:Month] .>= ms) .& (df[!,:Month] .<= me)) ),:] #select data for the year and problems 

                    if ms == me
                        df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .& ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                    elseif me == ms + 1
                        df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                    else 
                        df2 = df1[ .!( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .< ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .> de)) ) ,:]
                    end
                    dataexi = dataexi .+ vec(permutedims(Tables.matrix(df2[:,4:end]))) * EXIST_WIND[r,7]
                    exi_cap += EXIST_WIND[r,7] # EXISTING CAPACITY FROM WINTER RATING
                end
            end
            WINDAUX[!,:DIFF] = WINDAUX[!,2] .- WINDAUX[!,:EXISTING] # REZ capacity utilised 

            naux = 0    
            datanew = zeros(Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)*2)
            nauxrez = 0
            datarez = zeros(Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)*2)  

            drezcap = 0
            rezcap = 0
            tch_ = "Wind"

            if dstart > DateTime(2024,7,1,0,0,0)
                instcap = TECH_CAP[(TECH_CAP[!,:Scenario] .== sc) .& (TECH_CAP[!,:Subregion] .== st) .& (TECH_CAP[!,:Technology] .== tch_) .& (year.(TECH_CAP[!,:date]) .== y), 7][1]
                # future capacity profile (average of REZ profiles in the area)
                for f in readdir(foldertech)
                    sub = split(f,['_','.'])
                    if sub[1] in REZs && "WH" in sub#f[1] == st[1]
                        df = CSV.File(string(foldertech,f)) |> DataFrame
                        df1 = df[((df[!,:Year] .== yr) .& ((df[!,:Month] .>= ms) .& (df[!,:Month] .<= me)) ),:]

                        if ms == me
                            df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .& ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                        elseif me == ms + 1
                            df2 = df1[ ( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .>= ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .<= de)) ) ,:]
                        else 
                            df2 = df1[ .!( ((df1[!,:Month] .== ms) .& (df1[!,:Day] .< ds)) .| ((df1[!,:Month] .== me) .& (df1[!,:Day] .> de)) ) ,:]
                        end
                        datanew = datanew .+ vec(permutedims(Tables.matrix(df2[:,4:end])))
                        naux += 1

                        #check if specific REZ capacity is available
                        if nrow(WINDAUX) > 0
                            for r in 1:nrow(WINDAUX)
                                if WINDAUX[r,:ID] == sub[1] && WINDAUX[r,:DIFF] >= 0.01
                                    datarez = datarez .+ vec(permutedims(Tables.matrix(df2[:,4:end]))) * WINDAUX[r,:DIFF]
                                    drezcap += WINDAUX[r,:DIFF]
                                end
                            end
                        end

                    end
                end
            else
                instcap = exi_cap
            end

            if (instcap - exi_cap - drezcap) > 0
                dataN = datanew / naux * (instcap - exi_cap - drezcap)
                data = (dataexi .+ datarez) .+ dataN
            elseif instcap - exi_cap < drezcap
                # print(instcap - exi_cap)
                dataN = datanew / naux * abs(instcap - exi_cap)
                data = dataexi .+ dataN
                if ((instcap - exi_cap) < 0 )&& (abs(instcap - exi_cap) > 100) end #@warn("$(st) $(sc) $(abs(instcap - exi_cap))") 
            else
                dataN = naux == 0 ? datanew : datanew / naux * 0.0
                data = (dataexi .+ datarez) .+ dataN
            end

            data2 = [ (data[2*i-1]+data[2*i])/2 for i in 1:Int64(length(data)/2) ]
            for h in 1:Int64(Dates.Hour(dend - dstart)/Dates.Hour(1)+1)
                pmaxid += 1
                push!(tv.gen_pmax, [pmaxid, genid[st][1], scid, dstart+Dates.Hour(h-1), data2[h]])
            end
        end
    end
end

function ess_vpps(tc::PISPtimeConfig, ts::PISPtimeStatic, tv::PISPtimeVarying, vpp_cap::String, vpp_ene::String)
    bust = ts.bus
    probs = tc.problem

    bmid = isempty(ts.ess.id_ess) ? 0 : maximum(ts.ess.id_ess)
    bmpmid = isempty(tv.ess_pmax.id) ? 0 : maximum(tv.ess_pmax.id)
    bmlmid = isempty(tv.ess_lmax.id) ? 0 : maximum(tv.ess_lmax.id)
    bmemid = isempty(tv.ess_emax.id) ? 0 : maximum(tv.ess_emax.id)
    BMBESSid = Dict()

    sc = collect(keys(PISP.SCE))[2]
    # CER STORAGE CAPACITY
    VPPCAP = PISP.read_xlsx_with_header(vpp_cap, "$(sc)", "A1:AE2080")
    VPPCAP = VPPCAP[(VPPCAP[!,1] .== "CDP14") .& (VPPCAP[!,Symbol("storage category")] .== "Coordinated CER storage"),:]
    rename!(VPPCAP, Dict(:Subregion => :bus))

    #CER STORAGE ENERGY
    VPPENE = PISP.read_xlsx_with_header(vpp_ene, "$(sc)", "A1:AE2080")
    VPPENE = VPPENE[(VPPENE[!,1] .== "CDP14") .& (VPPENE[!,Symbol("Technology")] .== "Coordinated CER storage"),:]
    rename!(VPPENE, Dict(:Subregion => :bus))

    for st in keys(PISP.NEMBUSES)
        yr = 2024
        bmid += 1
        bus_id = bust[bust[!,:name] .== st, :id_bus][1]
        data_cap = VPPCAP[VPPCAP[!,:bus] .== st, Symbol("$(yr)-$(string(yr+1)[3:end])")][1]
        data_ene = VPPENE[VPPENE[!,:bus] .== st, Symbol("$(yr)-$(string(yr+1)[3:end])")][1]*1000
        BMBESSid[st] = [bmid, data_cap, data_ene]
        arrbmss = [bmid,"VPP_CER_$(st)","VPP_CER_$(st)","BESS","SHALLOW", data_cap, 0, 1, bus_id, 0.9, 0.9, 10.0, 10.0, data_ene, 0.0, data_cap, 0.0, data_cap, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, PISP.NEMBUSES[st][2], PISP.NEMBUSES[st][1], 1, 0]
        push!(ts.ess, arrbmss)
    end

    for p in 1:nrow(probs)
        scid = probs[p,:scenario][1]
        sc = PISP.ID2SCE[scid]
        dstart = probs[p,:dstart]
        dend = probs[p,:dend]
        yr = Dates.year(dstart)
        ds = Dates.day(dstart)
        de = Dates.day(dend)
        ms = Dates.month(dstart)
        me = Dates.month(dend)

        yr = ms < 7 ? yr - 1 : yr
        VPPCAP = PISP.read_xlsx_with_header(vpp_cap, "$(sc)", "A1:AE2080")
        VPPENE = PISP.read_xlsx_with_header(vpp_ene, "$(sc)", "A1:AE2080")
        for st in keys(PISP.NEMBUSES)
            # CER STORAGE CAPACITY
            VPPCAP = VPPCAP[(VPPCAP[!,1] .== "CDP14") .& (VPPCAP[!,Symbol("storage category")] .== "Coordinated CER storage"),:]
            rename!(VPPCAP, names(VPPCAP)[3] => :bus)

            #CER STORAGE ENERGY
            VPPENE = VPPENE[(VPPENE[!,1] .== "CDP14") .& (VPPENE[!,Symbol("Technology")] .== "Coordinated CER storage"),:]
            rename!(VPPENE, names(VPPENE)[3] => :bus)

            data_cap = VPPCAP[VPPCAP[!,:bus] .== st, Symbol("$(yr)-$(string(yr+1)[3:end])")][1]
            data_ene = VPPENE[VPPENE[!,:bus] .== st, Symbol("$(yr)-$(string(yr+1)[3:end])")][1]*1000

            bmpmid+=1; bmlmid+=1; bmemid+=1;
            push!(tv.ess_pmax, [bmpmid, BMBESSid[st][1], scid, dstart, data_cap])
            push!(tv.ess_lmax, [bmlmid, BMBESSid[st][1], scid, dstart, data_cap])
            push!(tv.ess_emax, [bmemid, BMBESSid[st][1], scid, dstart, data_ene])
        end
    end
end