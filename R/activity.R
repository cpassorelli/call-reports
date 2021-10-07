
dataFrame <- read.csv(
  file = "../csv/ACTIVITY-NARROW.csv",
  stringsAsFactors = TRUE
)

dataFrame <- as_tibble(dataFrame)

dataFrame %>%
  count(Outcome, sort = TRUE)


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
    ggrepel::geom_text_repel(aes(label = label), max.overlaps = 5) +
    geom_hline(yintercept = 0) +
    geom_vline(xintercept = 0)
  # coord_equal()  
}


correspondanceAnalysis(dataFrame, "ContactType", "Outcome")

correspondanceAnalysis(dataFrame, "ActivityType", "Outcome")

correspondanceAnalysis(dataFrame, "ActivityUser", "Outcome")


dataFrame %>%
  filter(ActivityUser == "OnBase Processing Service") %>%
  head() %>%
  View()

# either `Statement Received` or `NA`
dataFrame %>%
  filter(ActivityUser == "OnBase Processing Service") %>%
  count(Outcome, sort = TRUE)


# `N/A` or `Client Email`
dataFrame %>%
  filter(ActivityUser == "OnBase Processing Service") %>%
  count(ContactType, sort = TRUE)


# All `SVC_WORKFLOW`
dataFrame %>%
  filter(ActivityUser == "OnBase Processing Service") %>%
  count(CreatedBy, sort = TRUE)


dataFrame %>%
  filter(ActivityUser == "JVIG") %>%
  count(Outcome, sort = TRUE)


# `OnBase Processing Service` most
dataFrame %>%
  filter(Outcome == "Statement Received") %>%
  count(ActivityUser, sort = TRUE)


# `N/A` or `Client Email`
dataFrame %>%
  filter(ActivityUser == "fbishop") %>%
  count(ContactType, sort = TRUE)



dataFrame %>%
  select(ActivityUser, Outcome) %>%
  ftable() %>%
  as.table() -> contingencyTable

contingencyTable

# perform Correspondence Analysis
contingencyTable %>%
  FactoMineR::CA(graph = FALSE) -> correspondance




correspondance$row$coord %>%
  as.data.frame() %>%
  ggplot(aes(`Dim 1`, `Dim 2`)) +
    geom_point()




