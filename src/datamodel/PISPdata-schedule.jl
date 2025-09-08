# ============================== #
# GENERATOR SCHEDULES 
# ============================== #
# Generator maximum power schedule
MOD_GEN_PMAX            = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_gen"            => "INTEGER REFERENCES Generator (id_gen)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL"
                                    )
# Generator units n schedule
MOD_GEN_N               = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_gen"            => "INTEGER REFERENCES Generator (id_gen)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "INTEGER NOT NULL"
                                    )
# =============================== #
# DEMAND SCHEDULES
# =============================== #
MOD_DEMAND_LOAD         = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_dem"            => "INTEGER REFERENCES Demand (id_dem)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL",
                                    )

# =============================== #
# ESS SCHEDULES
# =============================== #
MOD_ESS_PMAX            = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_ess"            => "INTEGER REFERENCES ESS (id_ess)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL",
                                    )

MOD_ESS_LMAX            = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_ess"            => "INTEGER REFERENCES ESS (id_ess)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL",
                                    )

MOD_ESS_EMAX            = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_ess"            => "INTEGER REFERENCES ESS (id_ess)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL",
                                    )

MOD_ESS_N               = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_ess"            => "INTEGER REFERENCES ESS (id_ess)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "INTEGER NOT NULL",
                                    )
# ================================ #
# LINE SCHEDULES
# ================================ #
MOD_LINE_TMAX           = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_lin"            => "INTEGER REFERENCES Line (id_lin)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL",
                                    )

MOD_LINE_TMIN           = OrderedDict(  
                                        "id"                => "INTEGER PRIMARY KEY", 
                                        "id_lin"            => "INTEGER REFERENCES Line (id_lin)",
                                        "scenario"          => "INTEGER NOT NULL", 
                                        "date"              => "DATETIME NOT NULL",
                                        "value"             => "REAL NOT NULL"
                                    )

TABLES_POWERSYSTEM_SCH = OrderedDict(
                                        "Generator_pmax_sched"      => MOD_GEN_PMAX,
                                        "Generator_n_sched"         => MOD_GEN_N,
                                        "Demand_load_sched"         => MOD_DEMAND_LOAD,
                                        "ESS_pmax_sched"            => MOD_ESS_PMAX,
                                        "ESS_lmax_sched"            => MOD_ESS_LMAX,
                                        "ESS_emax_sched"            => MOD_ESS_EMAX,
                                        "ESS_n_sched"               => MOD_ESS_N,
                                        "Line_tmax_sched"           => MOD_LINE_TMAX,
                                        "Line_tmin_sched"           => MOD_LINE_TMIN,
)