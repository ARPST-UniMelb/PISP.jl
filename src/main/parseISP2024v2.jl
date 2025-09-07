using PISP
using DataFrames
using Dates
using XLSX

# Initialise DataFrames
tc = PISPtimeConfig();
ts = PISPtimeStatic();
tv = PISPtimeVarying();

# ======================================== #
# FILE PATHS    
# ======================================== #
datapath    = normpath(@__DIR__, "..", "..", "data");
ispdata24   = normpath(datapath, "2024 ISP Inputs and Assumptions workbook.xlsx");
ispdata19   = normpath(datapath, "2019InputandAssumptionsworkbookv13Dec19.xlsx");
profiledata = "/Users/papablaza/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Modelling/ISP24/Traces/";

# ============================================ #
# === Fill problem table with information  === #
# ============================================ #
PISP.problem_table(tc);
PISP.bus_table(ts); 
txdata = PISP.line_table(ts, tv, ispdata24);
PISP.line_sched_table(tc, tv, txdata);
PISP.line_invoptions(ts, ispdata24);
# ============================================ #
# ============== Generator data ============== #
# ============================================ #
# mktempdir() do tmpdir
#     println("Temporary directory: $tmpdir")

#     # You can use this directory for files
#     tmpfile = joinpath(tmpdir, "example.txt")
#     write(tmpfile, "Hello, world!")

#     println("Contents written to $tmpfile")
# end

# Here tmpdir no longer exists
println("Temporary directory has been deleted")
# files_to_delete = [
#     "GENS.xlsx", "DATA_MINUP_UNITS19.xlsx", "UC.xlsx", "DATA_COALGASMSG.xlsx", 
#     "DATA_MINUP_UNITS.xlsx", "UC1.xlsx", "UC2.xlsx", "UC2__.xlsx", "UC3.xlsx", 
#     "RETIREMENTS.xlsx", "GENSUM.xlsx", "FULL.xlsx", "FULL2.xlsx", "FULL3.xlsx", 
#     "GENERATORS.xlsx", "VRET.xlsx", "BESS.xlsx", "SYNC.xlsx", "SYNC3.xlsx", 
#     "SYNC4.xlsx", "SYNC5.xlsx", "SYNC6.xlsx", "PS.xlsx", "GENERATORS2.xlsx", 
#     "GENERATORS3.xlsx"
#     ]

# for file in files_to_delete
#     if isfile(file)
#         rm(file)
#     end
# end
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
GENS.bus_id = [bust[bust[!,:name] .== k, :id_bus][1] for k in GENS.Bus] 
GENS.area_id .= 0
GENS[!,:Generator] = [namedict[n] for n in GENS[!,:Generator]]
# Transform columns bus_id and area_id to Int64 to save in database
GENS.bus_id = Int64.(GENS.bus_id)
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
# UNITS = load(ispdata24, "Retirement!B9:D460") |> DataFrame
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
# Filter CELLS OF GENSUM WHERE THE VALUE IS EQUAL TO Missing in any column
# for r in eachrow(GENSUM)
#     println(r)
# end

FULL = outerjoin(UNITS, GENS, on = :Generator)
XLSX.writetable(".tmp/FULL.xlsx", Tables.columntable(FULL); sheetname="FULL", overwrite=true)

FULL = outerjoin(FULL, UC, on = :DUID, matchmissing=:equal)
rename!(FULL, Dict(:Region => :Area,  Symbol("Installed capacity (MW)") => :CAPACITY, Symbol("Generator Station") => :NAME))
XLSX.writetable(".tmp/FULL2.xlsx", Tables.columntable(FULL); sheetname="FULL2", overwrite=true)

FULL = outerjoin(FULL, GENSUM, on = :Generator, matchmissing=:equal, makeunique=true)
FULL.bus_id = [ismissing(k) ? missing : bust[bust[!,:name] .== k, :id_bus][1] for k in FULL[!,Symbol("ISP \nsub-region")]] 
# FULL.area_id = [ismissing(k) ? missing : areat[areat[!,:name] .== k, :id][1] for k in FULL[!,Symbol("Region")]]
FULL.bus_id = [ismissing(k) ? missing : Int64(k) for k in FULL.bus_id]
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
@warn("Deleted Steam Turbines from generator table due to missing information. CHECK!")
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

units = Dict(
                "Angaston"                          => [1, "Diesel", "Diesel", "Reciprocating Engine", -34.5035, 139.0245],
                "Barcaldine Power Station"          => [1, "Natural Gas", "OCGT", "OCGT", -23.55245, 145.314186],
                "Barker Inlet Power Station"        => [1, "Natural Gas", "OCGT", "OCGT", -34.804443, 138.525566],
                "Barron Gorge"                      => [2, "Hydro", "Run-of-River", "Vertical Francis", -16.85086, 145.6469],
                "Bastyan"                           => [1, "Hydro", "Reservoir", "Francis", -41.736, 145.5321],
                "Blowering"                         => [1, "Hydro", "Reservoir", "Francis", -35.39860, 148.246272],
                "Bogong / MacKay"                   => [12, "Hydro", "Run-of-River", "Francis / Pelton", -36.8067, 147.2287],
                "Borumba"                           => [4, "Hydro", "Pumped-Storage", "Francis", -26.5394, 152.5542],
                "Braemar 2 Power Station"           => [3, "Natural Gas", "OCGT", "OCGT", -27.1109, 150.9053],
                "Callide C1"                        => [2, "Coal", "Coal", "Steam Super Critical", -24.3449, 150.6197],
                "Catagunya / Liapootah / Wayatinah" => [8, "Hydro", "Reservoir", "Francis", -42.4522, 146.5977],
                "Cethana"                           => [1, "Hydro", "Reservoir", "Francis", -41.481, 146.1338],
                "Dartmouth"                         => [8, "Hydro", "Reservoir", "Francis", -36.558, 147.5236],
                "Devils gate"                       => [1, "Hydro", "Reservoir", "Francis", -41.3505, 146.2633],
                "Dry Creek GT"                      => [3, "Natural Gas", "OCGT", "OCGT", -34.847463, 138.581758],
                "Eildon"                            => [2, "Hydro", "Reservoir", "Francis", -37.22186, 145.92137],
                "Fisher"                            => [1, "Hydro", "Reservoir", "Pelton", -41.6732, 146.2686],
                "Gordon"                            => [3, "Hydro", "Reservoir", "Francis", -42.7405, 145.9819],
                "Guthega"                           => [2, "Hydro", "Reservoir", "Francis", -36.35, 148.41353],
                "Hallett GT"                        => [12, "Natural Gas", "OCGT", "GE Frame 5", -33.3397, 138.732],
                "Hume Dam NSW"                      => [1, "Hydro", "Reservoir", "Kaplan", -36.1067, 147.0327],
                "Hume Dam VIC"                      => [1, "Hydro", "Reservoir", "Kaplan", -36.1067, 147.0327],
                "Hunter Valley GT"                  => [1, "Diesel", "Diesel", "Reciprocating Engine", -32.389253, 150.966396],
                "John Butters"                      => [1, "Hydro", "Reservoir", "Francis", -42.1548, 145.5344],
                "Kareeya"                           => [4, "Hydro", "Run-of-River", "Pelton", -17.76716, 145.5777],
                "Kidston "                          => [2, "Hydro", "Pumped-Storage", "Francis", -18.881970, 144.148635],
                "Kurri Kurri OCGT"                  => [2, "Natural Gas", "OCGT", "OCGT", -32.780599, 151.484749],
                "Lake Echo"                         => [1, "Hydro", "Reservoir", "Francis", -42.2536, 146.6206],
                "Lemonthyme / Wilmot"               => [2, "Hydro", "Reservoir", "Francis", -41.6038, 146.139],
                "Lonsdale"                          => [1, "Diesel", "Diesel", "Reciprocating Engine", -35.1097, 138.491],
                "Mackay GT"                         => [1, "Diesel", "Diesel", "Reciprocating Engine", -21.144566, 149.159097],
                "Mackintosh"                        => [1, "Hydro", "Reservoir", "Francis", -41.6994, 145.6472],
                "Meadowbank"                        => [1, "Hydro", "Reservoir", "Francis", -42.6111, 146.8457],
                "Mintaro GT"                        => [1, "Natural Gas", "OCGT", "OCGT", -33.9031, 138.7383],
                "Mount Piper"                       => [2, "Coal", "Black Coal", "Steam Sub Critical", -33.35889, 150.0313],
                "Mt Stuart"                         => [3, "Diesel", "Diesel", "Reciprocating Engine", -19.337998, 146.851171],
                "Murray 1"                            => [10, "Hydro", "Reservoir", "Francis", -36.2468, 148.1902],
                "Murray 2"                          => [4, "Hydro", "Reservoir", "Francis", -36.2425, 148.1364],
                "Oakey Power Station"               => [2, "Natural Gas", "OCGT", "OCGT", -27.418362, 151.679767],
                "Poatina"                           => [6, "Hydro", "Reservoir", "Nozzle-spear Pelton", -41.8115, 146.9192],
                "Port Lincoln GT"                   => [2, "Diesel", "Diesel", "Reciprocating Engine", -34.70019, 135.804728],
                "Port Stanvac 1"                    => [1, "Diesel", "Diesel", "Reciprocating Engine", -35.1104, 138.49146],
                "Reece"                             => [2, "Hydro", "Reservoir", "Francis", -41.7242, 145.1354],
                "Shoalhaven"                        => [4, "Hydro", "Pumped-Storage", "Reversible Francis", -34.7338, 150.46677],
                "Smithfield Energy Facility"        => [2, "Natural Gas", "OCGT", "OCGT", -33.85004, 150.949466],
                "Snowy 2.0"                         => [6, "Hydro", "Pumped-Storage", "Francis", -35.674518, 148.358518],
                "Snuggery"                          => [3, "Diesel", "Diesel", "Reciprocating Engine", -37.66455, 140.415558],
                "Somerton"                          => [3, "Natural Gas", "OCGT", "Frame 6B", -37.631822, 144.953077],
                "Snapper Point Power Station"       => [5, "Diesel", "Diesel", "Reciprocating Engine", -34.765, 138.5053],
                "Swanbank E GT"                     => [1, "Natural Gas", "CCGT", "CCGT", -27.660065, 152.814452],
                "Tamar Valley Combined Cycle"       => [1, "Natural Gas", "CCGT", "CCGT", -41.140125, 146.903636],
                "Tamar Valley Peaking"              => [1, "Natural Gas", "OCGT", "OCGT", -41.140125, 146.903636],
                "Tallawarra"                        => [2, "Natural Gas", "CCGT", "CCGT", -34.5228,	150.8081],
                "Tallawarra B"                      => [1, "Natural Gas", "OCGT", "OCGT", -34.5228, 150.8081],
                "Tarraleah"                         => [6, "Hydro", "Reservoir", "Pelton", -42.3012, 146.457],
                "Temporary Generation South"        => [4, "Diesel", "Diesel", "Reciprocating Engine", -35.1, 138.487],
                "Trevallyn"                         => [4, "Hydro", "Reservoir", "Francis", -41.4227, 147.1118],
                "Tribute"                           => [1, "Hydro", "Reservoir", "Francis", -41.8175, 145.6502],
                "Tumut 3"                           => [6, "Hydro", "Pumped-Storage", "Francis", -35.6112, 148.2917],
                "Tungatinah"                        => [5, "Hydro", "Reservoir", "Francis", -42.2967, 146.4565],
                "Upper Tumut"                       => [8, "Hydro", "Reservoir", "Francis", -35.94096, 148.3638],
                "Valley Power"                      => [6, "Natural Gas", "OCGT", "OCGT", -38.25362, 146.589166],
                "West Kiewa"                        => [4, "Hydro", "Reservoir", "Francis", -36.7601, 147.1861],
                "Wivenhoe"                          => [2, "Hydro", "Pumped-Storage", "Francis", -27.3722, 152.63194],
                "Yabulu PS"                         => [1, "Natural Gas", "CCGT", "CCGT", -19.201056, 146.618707],
                "Yabulu Steam Turbine "             => [1, "Natural Gas", "CCGT", "CCGT", -19.201056, 146.618707],
                "Yallourn W"                        => [4, "Coal", "Brown Coal", "Steam Sub Critical", -38.177015, 146.342783],
                "Yarwun 1"                          => [1, "Natural Gas", "CCGT", "CCGT", -23.830645, 151.15193]
            )

                
fueltype = Dict(    "Natural Gas"           => ["CCGT", "OCGT", "Gas-powered steam turbine", "Reciprocating Engine"],    
                    "Coal"                  => ["Steam Sub Critical", "Steam Super Critical"],
                    "Hydro"                 => ["Pumped Hydro", "Hydro"],
                    "Hydrogen"              => ["Hydrogen-based gas turbines"]
                )

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

    if gty in keys(units)
        SYNC3[r,:n] = units[gty][1]
        push!(fuel, units[gty][2])
        push!(tech, units[gty][3])
        push!(type, units[gty][4])
        push!(lat,  units[gty][5])
        push!(lon,  units[gty][6])
    else
        for t in fueltype
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
# EMI = load(ispdata24, "Emissions intensity!B7:D73" ) |> DataFrame
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
                
@warn("Slope for Hydrogen-based gas turbines is defined as 0.4. CHECK!")
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
@warn("Inertia for Hydrogen-based gas turbines is defined as 4.0. CHECK!")
sort!(SYNC4, [Symbol("fuel"), :Generator]) #sort table to solve problem with unit Quarantine


GENERATORS = DataFrame(id = 1:nrow(SYNC4))
GENERATORS[!,:name] = SYNC4[!,:Generator]
GENERATORS[!,:alias] = [ismissing(SYNC4[n,:DUID]) ? SYNC4[n,:Generator] : SYNC4[n,:DUID] for n in 1:length(SYNC4[!,:DUID])]
GENERATORS[!,:fuel] = SYNC4[!,:fuel]
GENERATORS[!,:tech] = SYNC4[!,:tech]
GENERATORS[!,:type] = SYNC4[!,:type]
GENERATORS[!,:capacity] = SYNC4[!,:cap]

fullout = []
partialout = []
derate = []
for k in 1:nrow(GENERATORS)
    if ((GENERATORS[k,:tech] == "OCGT" || GENERATORS[k,:tech] == "Diesel") && GENERATORS[k,:capacity] >= 150)       tgt = (RELIA[!,1] .== "OCGT");                  push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif ((GENERATORS[k,:tech] == "OCGT" || GENERATORS[k,:tech] == "Diesel") && GENERATORS[k,:capacity] < 150)    tgt = (RELIA[!,1] .== "Small peaking plants");  push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "CCGT"                                                                            tgt = (RELIA[!,1] .== "CCGT + Steam Turbine");  push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:fuel] == "Hydro"                                                                           tgt = (RELIA[!,1] .== "Hydro");                 push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "Reciprocating Engine"                                                            tgt = (RELIA[!,1] .== "Small peaking plants");  push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "Brown Coal"                                                                      tgt = (RELIA[!,1] .== "Brown Coal");            push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "Brown Coal VIC"                                                                      tgt = (RELIA[!,1] .== "Brown Coal");            push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "Black Coal NSW"                                          tgt = (RELIA[!,1] .== "Black Coal NSW");        push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "Black Coal QLD"                                          tgt = (RELIA[!,1] .== "Black Coal QLD");        push!(fullout, RELIA[tgt, 2][1]); push!(partialout, RELIA[tgt, 3][1]); push!(derate, RELIA[tgt, 6][1])
    elseif GENERATORS[k,:tech] == "Hydrogen-based gas turbines"                                          tgt = (RELIANEW[!,1] .== "Hydrogen-based gas turbines");        push!(fullout, RELIANEW[tgt, 2][1]/100); push!(partialout, RELIANEW[tgt, 3][1]/100); push!(derate, RELIANEW[tgt, 6][1]/100)
    else 
        push!(derate, "XXX")
        # println(GENERATORS[k,:name]," ", GENERATORS[k,:tech]," ", GENERATORS[k,:capacity]," ", GENERATORS[k,:fuel])
    end
end

@warn("Partialout and derating factor are missing for some hydrogen-based generators. Replacing with 0.0")
fullout = [ismissing(k) ? 0.0 : k for k in fullout]
partialout = [ismissing(k) ? 0.0 : k for k in partialout]
derate = [ismissing(k) ? 0.0 : k for k in derate]

GENERATORS[!,:forate] = ones(nrow(SYNC4)) .- (fullout  .+ partialout  .* (ones(nrow(SYNC4)) .- derate))
XLSX.writetable(".tmp/GENERATORS2.xlsx", Tables.columntable(GENERATORS); sheetname="GENERATORS2", overwrite=true)

GENERATORS[!,:bus_id] = SYNC4[!,:bus_id]
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
@warn("PFRMAX is set to 10% of Pmax")
GENERATORS[!,:g] = zeros(nrow(SYNC4))
GENERATORS[!,:inertia] = [inertiaar[GENERATORS[k,:tech]] for k in 1:nrow(SYNC4) ]
GENERATORS[!,:ffr] = Int64.([ false for k in 1:nrow(SYNC4)])
GENERATORS[!,:pfr] = Int64.([ true for k in 1:nrow(SYNC4)])
GENERATORS[!,:res2] = Int64.([ true for k in 1:nrow(SYNC4)])
GENERATORS[!,:res3] = Int64.([ false for k in 1:nrow(SYNC4)])
GENERATORS[!,:powerfactor] = ones(nrow(SYNC4)) * 0.85
@warn("Power factor is set to 85%")
GENERATORS[!,:latitude] = SYNC4[!,:lat]
GENERATORS[!,:longitude] = SYNC4[!,:lon]
GENERATORS[!,:n] = SYNC4[!,:n]
GENERATORS[!,:contingency] = Int64.([ true for k in 1:nrow(SYNC4)])
# save("GENERATORS3.xlsx", GENERATORS)
XLSX.writetable(".tmp/GENERATORS3.xlsx", Tables.columntable(GENERATORS); sheetname="GENERATORS3", overwrite=true)
@warn("Check fuel cost for Hydrogen-based units")

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

@warn("Pmin for CCGT is set to 52% of Pmax")
@warn("Pmin for OCGT is set to 33% of Pmax")
@warn("Pmin for Hydro is set to 20% of Pmax")
@warn("Pmin for Diesel is set to 20% of Pmax")

# ====================================== #
# ============= COMMITMENT ============= #
# ====================================== #

COMMITMENT = DataFrame(id = 1:nrow(SYNC4))
# COMMITMENT[!,:active] = Int64.([true for k in 1:nrow(SYNC4)])
COMMITMENT[!,:gen_id] = 1:nrow(SYNC4)
COMMITMENT[!,:down_time] = zeros(nrow(SYNC4))
COMMITMENT[!,:up_time] = coalesce.(SYNC4[!,:MinUpTime], 0.0)
COMMITMENT[!,:last_state] = zeros(nrow(SYNC4))
COMMITMENT[!,:last_state_period] = zeros(nrow(SYNC4))
COMMITMENT[!,:last_state_output] = zeros(nrow(SYNC4))
COMMITMENT[!,:start_up_cost] = [GENERATORS[GENERATORS[!,:id] .== k, :fuel][1] == "Coal" ? GENERATORS[GENERATORS[!,:id] .== k, :cvar][1] * GENERATORS[GENERATORS[!,:id] .== k, :pmax][1] * 4.0 : 0.0 for k in COMMITMENT[!,:gen_id] ] # 
COMMITMENT[!,:shut_down_cost] = zeros(nrow(SYNC4))
COMMITMENT[!,:start_up_time] = zeros(nrow(SYNC4))
COMMITMENT[!,:shut_down_time] = zeros(nrow(SYNC4))

@warn("No minimum down time for any generator")
@warn("Start up cost for coal generators is set to 4 times the variable cost times the maximum capacity")
@warn("No shut down cost for any generator")
@warn("No start up time for any generator")
@warn("No shut down time for any generator")

# MERGE GENERATOR AND COMMITMENT IN left `id` and right `gen_id`. Fill missing values in COMMITMENT with 0
merged = leftjoin(GENERATORS, COMMITMENT, on = [:id => :gen_id], makeunique=true)
select!(merged, Not(:id_1))
XLSX.writetable(".tmp/GENERATORS_FULL.xlsx", Tables.columntable(merged); sheetname="GENERATORS", overwrite=true)

# DBInterface.execute(socketSYS, "CREATE TABLE IF NOT EXISTS Generator_commitment($(PSO.strsql(MOD_GEN_COMMIT)))")
# stmt_commit = DBInterface.prepare(socketSYS, "INSERT INTO Generator_commitment VALUES ($(qm(length(MOD_GEN_COMMIT))));")

# Fill commitment table
# for k in 1:nrow(COMMITMENT) DBInterface.execute(stmt_commit, collect(COMMITMENT[k,:])) end
# @info "\n✓ GENERATOR \n✓ GENERATOR_COMMITMENT"

# return SYNC3, SYNC4, GENERATORS, BESS, PS