library(tidyverse)

# http://www.sthda.com/english/wiki/wiki.php?id_contents=7851
# library(FactoMineR)

dataFrame <- read.csv(
  file = "../csv/REQUESTS-NARROW.csv",
  stringsAsFactors = TRUE
)

dataFrame <- as_tibble(dataFrame)

dataFrame %>%
  count(Status, sort = TRUE)

dataFrame %>%
  count(CallerStatus, sort = TRUE)

dataFrame %>%
  count(Status, sort = TRUE)


dataFrame %>%
  count(RequesterFullName, sort = TRUE) %>%
  print(n = Inf)


# all Caller
# assigned to multiple CurrentAssigneeName
dataFrame %>%
  filter(RequesterFullName == "OnBase Processing Service") %>%
  count(RequestType, sort = TRUE)

dataFrame %>%
  filter(RequestType == "Caller") %>%
  count(RequesterFullName, sort = TRUE)

dataFrame %>%
  filter(RequestType == "Caller") %>%
  count(RequesterFullName, sort = TRUE)



# AdHoc or WNC
dataFrame %>%
  filter(RequesterFullName == "OnBase Processing Service") %>%
  count(RequestMethod, sort = TRUE)

# Majority `No Receipt`
dataFrame %>%
  filter(RequesterFullName == "OnBase Processing Service") %>%
  count(Status, sort = TRUE)

# Removed From Scope
dataFrame %>%
  filter(RequesterFullName == "OnBase Processing Service") %>%
  count(CallerStatus, sort = TRUE)


dataFrame %>%
  select(CallerStatus, Status) %>%
  ftable() -> contingencyTable


# perform Correspondence Analysis
contingencyTable %>%
  as.table() %>%
  FactoMineR::CA(graph = FALSE) -> correspondance


correspondance$row$coord %>%
  as.data.frame() %>%
    mutate(
      label = rownames(correspondance$row$coord),
      variable = "CallerStatus"
    ) -> correspondanceCallerStatus


correspondance$col$coord %>%
  as.data.frame() %>%
  mutate(
    label = rownames(correspondance$col$coord),
    variable = "Status"
  ) -> correspondanceStatus


# CallerStatus = "Statement Received" highest predictor
# CallerStatus = "Remove From Scope" is third highest predictor
correspondanceCallerStatus %>%
  bind_rows(correspondanceStatus) %>%
  ggplot(aes(`Dim 1`, `Dim 2`, colour = variable)) +
    geom_point(colour = "black") +
    ggrepel::geom_text_repel(aes(label = label)) +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = 0) +
    coord_equal()




# RequestMethod and Status

dataFrame %>%
  select(RequestMethod, Status) %>%
  ftable() -> contingencyTable


# perform Correspondence Analysis
contingencyTable %>%
  as.table() %>%
  FactoMineR::CA(graph = FALSE) -> correspondance


correspondance$row$coord %>%
  as.data.frame() %>%
  mutate(
    label = rownames(correspondance$row$coord),
    variable = "RequestMethod"
  ) -> correspondanceRequestMethod


correspondance$col$coord %>%
  as.data.frame() %>%
  mutate(
    label = rownames(correspondance$col$coord),
    variable = "Status"
  ) -> correspondanceStatus


correspondanceRequestMethod %>%
  bind_rows(correspondanceStatus) %>%
  ggplot(aes(`Dim 1`, `Dim 2`, colour = variable)) +
    geom_point(colour = "black") +
    ggrepel::geom_text_repel(aes(label = label)) +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = 0)






correspondanceAnalysis <- function(dataFrame, rows, columns) {
  
  dataFrame %>%
    select(rows, columns) %>%
    ftable() %>%
    as.table() -> contingencyTable
  
  
  # perform Correspondence Analysis
  contingencyTable %>%
    FactoMineR::CA(graph = FALSE) -> correspondance
  
  
  correspondance$row$coord %>%
    as.data.frame() %>%
    mutate(
      label = rownames(correspondance$row$coord),
      variable = rows
    ) -> correspondanceRows
  
  
  correspondance$col$coord %>%
    as.data.frame() %>%
    mutate(
      label = rownames(correspondance$col$coord),
      variable = columns
    ) -> correspondanceColumns
  
  correspondanceRows %>%
    bind_rows(correspondanceColumns) %>%
    ggplot(aes(`Dim 1`, `Dim 2`, colour = variable)) +
    geom_point(colour = "black") +
      ggrepel::geom_text_repel(aes(label = label)) +
      geom_hline(yintercept = 0) +
      geom_vline(xintercept = 0)
      # coord_equal()  
}

# correspondanceAnalysis(dataFrame, "RequestType", "CallerStatus")
# correspondanceAnalysis(dataFrame, "RequestType", "RequestMethod")
# correspondanceAnalysis(dataFrame, "RequestMethod", "CallerStatus")

correspondanceAnalysis(dataFrame, "CallerStatus", "Status")
correspondanceAnalysis(dataFrame, "RequestMethod", "Status")
correspondanceAnalysis(dataFrame, "RequestType", "Status")

correspondanceAnalysis(dataFrame, "RequesterFullName", "Status")



# only certain people requesting Mass Email
dataFrame %>%
  filter(RequestMethod == "MassEmail") %>%
  count(RequesterFullName, sort = TRUE)

dataFrame %>%
  filter(RequestMethod == "MassEmail") %>%
  count(Status, sort = TRUE)
