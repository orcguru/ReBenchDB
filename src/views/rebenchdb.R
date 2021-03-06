## Interface to ReBenchDB
## Exposes standardized data sets for access by reports.
library(RPostgres)
library(DBI)

connect_to_rebenchdb <- function(dbname, user, pass) {
  DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = dbname,
    user = user,
    password = pass)
}

get_measures_for_comparison <- function(rebenchdb, hash_1, hash_2) {
  qry <- dbSendQuery(rebenchdb, "
    SELECT expId, runId, trialId, substring(commitId, 1, 6) as commitid,
      benchmark.name as bench, executor.name as exe, suite.name as suite,
      cmdline, varValue, cores, inputSize, extraArgs,
      invocation, iteration, warmup,
      criterion.name as criterion, criterion.unit as unit,
      value
    FROM Measurement
        JOIN Trial ON trialId = Trial.id
      JOIN Experiment ON expId = Experiment.id
      JOIN Source ON source.id = sourceId
      JOIN Criterion ON criterion = criterion.id
      JOIN Run ON runId = run.id
      JOIN Suite ON suiteId = suite.id
      JOIN Benchmark ON benchmarkId = benchmark.id
      JOIN Executor ON execId = executor.id
    WHERE criterion.name = 'total' AND (commitId = $1 OR commitid = $2)
    ORDER BY expId, runId, invocation, iteration, criterion")
  dbBind(qry, list(hash_1, hash_2))
  result <- dbFetch(qry)
  dbClearResult(qry)

  factorize_result(result)
}

factorize_result <- function(result) {
  result$expid <- factor(result$expid)
  result$trialid <- factor(result$trialid)
  result$runid <- factor(result$runid)
  result$commitid <- factor(result$commitid)
  result$bench <- factor(result$bench)
  result$suite <- factor(result$suite)
  result$exe <- factor(result$exe)
  result$cmdline <- factor(result$cmdline)
  result$varvalue <- factor(result$varvalue)
  result$cores <- factor(result$cores)
  result$inputsize <- factor(result$inputsize)
  result$extraargs <- factor(result$extraargs)
  result$criterion <- factor(result$criterion)
  result$unit <- factor(result$unit)

  result
}

disconnect_rebenchdb <- function(rebenchdb) {
  dbDisconnect(rebenchdb)
}
