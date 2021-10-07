dataFrame <- read.csv(
  file = "../csv/REQUEST-ACTIVITY.csv",
  stringsAsFactors = TRUE
)


dataFrame <- as_tibble(dataFrame)

dataFrame %>%
  mutate_all(~ na_if(., "N/A")) -> dataFrame

# Superceded as
dataFrame %>%
  count(Status, sort = TRUE)


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
    # geom_point(colour = "black") +
      ggrepel::geom_text_repel(aes(label = label)) +
      geom_hline(yintercept = 0) +
      geom_vline(xintercept = 0)
    # coord_equal()  
}


correspondanceAnalysis(dataFrame, "CallerStatus", "Status")
correspondanceAnalysis(dataFrame, "RequestMethod", "Status")

# Caller similar to a `Partial Receipt`
correspondanceAnalysis(dataFrame, "RequestType", "Status")

# correspondanceAnalysis(dataFrame, "RequesterFullName", "Status")

# correspondanceAnalysis(dataFrame, "ActivityUser", "Status")

# correspondanceAnalysis(dataFrame, "ActivityType", "Status")

# correspondanceAnalysis(dataFrame, "CustomerName", "Status")

# correspondanceAnalysis(dataFrame, "CurrentAssigneeName", "Status")

correspondanceAnalysis(dataFrame, "Outcome", "Status")

# correspondanceAnalysis(dataFrame, "ContactType", "Status")

correspondanceAnalysis(dataFrame, "ActivityUser", "Outcome")

correspondanceAnalysis(dataFrame, "ContactType", "Outcome")

# Mass... closely related to Received
# Macro as well
dataFrame %>%
  filter(ActivityUser == "OnBase Processing Service") %>%
  correspondanceAnalysis(., "RequestMethod", "Status")
  # correspondanceAnalysis(., "RequesterFullName", "Status") # No Receipt?
  # Account Identification


dataFrame %>%
  filter(RequesterFullName == "OnBase Processing Service") %>%
  correspondanceAnalysis(., "ActivityUser", "Status") # Account Identification


dataFrame %>%
  filter(RequestType == "Caller") %>%
  # MassEmail -> Fully Received
  # ClientEmail -> Partial Receipt
  correspondanceAnalysis(., "RequestMethod", "Status")
  # some relations amount Superceeded
  # correspondanceAnalysis(., "Outcome", "Status")








