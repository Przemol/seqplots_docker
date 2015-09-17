require(RSQLite)

root = "/var/shiny-server/DATA"
debug = FALSE

oldwd <- getwd()
on.exit( {
    rm(list=c(
        "doFileOperations", "GENOMES", "mcCalcStart", "mcDoParallel", 
        "renderHTMLgrid"
    ), envir=.GlobalEnv)
    setwd(oldwd) 
})

Sys.setenv(
    root=root, 
    web=system.file('seqplots', package='seqplots'), 
    seqplots_debug=debug
)

if ( !file.exists(root) | any( !file.exists(file.path(root, c(
    'files.sqlite', 'removedFiles','files','publicFiles', 'tmp'
))) ) ) {
    dir.create(root)
    setwd(root)
    sqlite <- RSQLite::SQLite()
    con <- dbConnect(sqlite, dbname = 'files.sqlite')
    dbGetQuery(con, paste(
        'CREATE TABLE files (id INTEGER PRIMARY KEY ASC, name TEXT UNIQUE,',
        'ctime TEXT, type TEXT, format TEXT, genome TEXT, user TEXT,',
        'comment TEXT)'
    ))
    if (!dbListTables(con) == "files") warning('Database not created!')
    dbDisconnect(con)
    if(!all( 
        sapply(c('removedFiles','files','publicFiles', 'tmp'), dir.create) 
    )) warning('Folders not created!')
}

if( !file.exists(file.path(root, 'genomes')) ) {
    dir.create(file.path(root, 'genomes'))
}
.libPaths(c( .libPaths(), file.path(root, 'genomes') ))

message('\nData loaction: ', root)