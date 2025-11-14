# Mapping of PISP generator id (hydro) to Hydro files (4006)
HYDRO2FILE = Dict(
    23 => "MaxEnergyYear_LT_RefYear4006",
    24 => "MonthlyNaturalInflow_Anthony_Pieman_RefYear4006",
    25 => "MaxEnergyYear_LT_RefYear4006",
    26 => "MaxEnergyYear_LT_RefYear4006",
    27 => "MonthlyNaturalInflow_Lower_Derwent_RefYear4006",
    28 => "MonthlyNaturalInflow_MF_Low_RefYear4006",
    29 => "MaxEnergyYear_LT_RefYear4006",
    30 => "MonthlyNaturalInflow_MF_Low_RefYear4006",
    31 => "MaxEnergyYear_LT_RefYear4006",
    32 => "MonthlyNaturalInflow_MF_Top_RefYear4006",
    33 => "MaxEnergyYear_LT_RefYear4006",
    34 => "MaxEnergyYear_LT_RefYear4006",
    35 => "MaxEnergyYear_LT_RefYear4006",
    36 => "MaxEnergyYear_LT_RefYear4006",
    37 => "MaxEnergyYear_LT_RefYear4006",
    38 => "MaxEnergyYear_LT_RefYear4006",
    39 => "MaxEnergyYear_LT_RefYear4006",
    40 => "MonthlyNaturalInflow_MF_Top_RefYear4006",
    41 => "MonthlyNaturalInflow_Anthony_Pieman_RefYear4006",
    42 => "MonthlyNaturalInflow_Lower_Derwent_RefYear4006",
    43 => "SNOWY_SCHEME", # MURRAY 1
    44 => "SNOWY_SCHEME", # MURRAY 2
    45 => "MaxEnergyYear_LT_RefYear4006",
    46 => "MonthlyNaturalInflow_Anthony_Pieman_RefYear4006",
    47 => "MonthlyNaturalInflow_Tarraleah_RefYear4006",
    48 => "MaxEnergyYear_LT_RefYear4006",
    49 => "MonthlyNaturalInflow_Anthony_Pieman_RefYear4006",
    50 => "MonthlyNaturalInflow_Tungatinah_RefYear4006",
    51 => "SNOWY_SCHEME", # UPPER TUMUT
    52 => "MaxEnergyYear_LT_RefYear4006",
)

PS2FILE = Dict( 59 => "SNOWY_SCHEME" ) # TUMUT 3 PUMPED STORAGE

# Constraints from MaxEnergyYear_LT
HYDRO2CNS = Dict(
    23 => "Barron Gorge Constraint",
    25 => "Blowering Constraint",
    26 => "Bogong - Mackay Constraint",
    29 => "Dartmouth Constraint",
    31 => "Eildon Constraint",
    34 => "Guthega Constraint",
    33 => "HT Annual Storage Constraint",
    37 => "HT Annual Storage Constraint",
    39 => "HT Annual Storage Constraint",
    45 => "HT Annual Storage Constraint",
    48 => "HT Annual Storage Constraint",
    35 => "Hume Dam NSW Constraint",
    36 => "Hume Dam VIC Constraint",
    38 => "Kareeya Constraint",
    52 => "West Kiewa Constraint"
)

# 4006 : CALENDAR YEAR => WEATHER YEAR
WEATHER_YEARS = Dict(
    ("2024-07-01", "2025-06-30") => "2019",
    ("2025-07-01", "2026-06-30") => "2020",
    ("2026-07-01", "2027-06-30") => "2021",
    ("2027-07-01", "2028-06-30") => "2022",
    ("2028-07-01", "2029-06-30") => "2013",
    ("2029-07-01", "2030-06-30") => "Dry",
    ("2030-07-01", "2031-06-30") => "2011",
    ("2031-07-01", "2032-06-30") => "2012",
    ("2032-07-01", "2033-06-30") => "2013",
    ("2033-07-01", "2034-06-30") => "2014",
    ("2034-07-01", "2035-06-30") => "Dry",
    ("2035-07-01", "2036-06-30") => "2016",
    ("2036-07-01", "2037-06-30") => "2017",
    ("2037-07-01", "2038-06-30") => "2018",
    ("2038-07-01", "2039-06-30") => "2019",
    ("2039-07-01", "2040-06-30") => "2020",
    ("2040-07-01", "2041-06-30") => "2021",
    ("2041-07-01", "2042-06-30") => "2022",
    ("2042-07-01", "2043-06-30") => "2013",
    ("2043-07-01", "2044-06-30") => "Dry",
    ("2044-07-01", "2045-06-30") => "2011",
    ("2045-07-01", "2046-06-30") => "2012",
    ("2046-07-01", "2047-06-30") => "2013",
    ("2047-07-01", "2048-06-30") => "2014",
    ("2048-07-01", "2049-06-30") => "Dry",
    ("2049-07-01", "2050-06-30") => "2016",
    ("2050-07-01", "2051-06-30") => "2017",
    ("2051-07-01", "2052-06-30") => "2018",
)
# Dam shares sourced from
# https://www.snowyhydro.com.au/wp-content/uploads/2020/09/SH1771_Snowy-fact-sheet_website.pdf
# https://www.waternsw.com.au/documents/publications/education/our-dams/blowering/Blowering-Dam-Fact-Sheet.pdf
# Shared total is 6428 GL; Snowy scheme from AEMO data is formed by Blowering (1628 GL) and Eucumbene (4800 GL) and 
DAM_SHARES = Dict(
    "Blowering" => 1628/6428, # Gigalitres
    "Eucumbene" => 4800/6428, # Gigalitres
)

# Dams feeding specific generators
HYDRO_DAMS_GENS = Dict(
    43 => "Eucumbene", # Murray 1
    44 => "Eucumbene", # Murray 2
    51 => "Eucumbene", # Upper Tumut
)

SNOWY_HYDRO_GROUPS = Dict(
    "MURRAY" => [43, 44],   # Murray 1 and Murray 2
    "TUMUT"  => [51]         # Upper Tumut
)

# Dams feeding specific pumped storage units
HYDRO_DAMS_STORAGE = Dict(
    59 => ["Eucumbene", "Blowering"] # Tumut 3
)

HYDRO_STORAGE_GEN = Dict(
    59 => 51 # Tumut 3 => Upper Tumut (Upper Tumut releases used for Tumut 3 pumping)
)
