library(survival)
library(tidyverse)
library(ggfortify)
# library(knitr)


setwd('~/Desktop/SpendMend/projects/call-reports/R')
activities <- read_csv('../csv/ACTIVITY.csv', na = "NA")

activities %>%
  filter(StopTime != 0) -> activity

  # sample_n(size = 1e6) -> activity

activity %>%
  filter(
    if_else(StopTime - StartTime > 300 & Event == 0, FALSE, TRUE)
  ) -> activity
  # filter(ReferenceNumber == 1205710) %>%
  # arrange(ReferenceNumber, CreatedDate) %>%
  # head(10) %>%
  # View()

activity %>%
  count(Event)


activity %>%
  count(User, Outcome)

activity %>%
  filter(Outcome == 'Statement Received') %>%
  count(ContactType) # N/A, second is call
  # count(ActivityType) # N/A

# Significant number OnBase Processing Service
# Certain users responsible on statement received
activity %>%
  filter(Outcome == 'Statement Received') %>%
  count(ActivityUser, name = 'Counts', sort = TRUE)

# Almost all SVC_WORKFLOW
activity %>%
  filter(Outcome == 'Statement Received') %>%
  count(CreatedBy, name = 'Counts', sort = TRUE)

activity %>%
  filter(Event == 1) %>%
  head() %>%
  View()


# activity %>%
#   filter(Event == 1) %>%
#   filter(StartTime > 86400 & StopTime < 7 * 86400) %>%
#   mutate(Days = StartTime / 86400) %>%
#   ggplot(aes(Days)) +
#     geom_density() +
#     scale_x_log10()


activity %>%
  count(StatementRequestObjectID, name = "Counts", sort = TRUE)

activity %>%
  filter(ReferenceNumber == 1205710) %>%
  View()


# succeed first shot
activities %>%
  filter(StopTime == 0) %>%
  count(Outcome)

activities %>%
  count()


# table(activity$ContactType)

activity %>%
  filter(ContactType == "Client Email") %>%
  count(Outcome)

ContactTypes <- c(
  "N/A",
  "Fax",
  "Call",
  "Client Email",
  "Email"
)

# table(activities$ActivityType)

ActivityTypes <- c(
  "N/A",
  "Call / Email",
  "Note Only",
  "Called Vendor"
)

Users <- c(
  "N/A",
  "OnBase"
)

Creations <- c(
  "N/A",
  "WORKFLOW"
)


activity %>%
  mutate(
    ContactType = factor(ContactType, labels = ContactTypes),
    ActivityType = factor(ActivityType, labels = ActivityTypes),
    User = factor(User, labels = Users),
    Created = factor(Created, labels = Creations)
  ) -> activity



# activity <- read_csv('../csv/ACTIVITY.csv')

# activities %>%
#   sample_n(size = 1e2) -> activity

activity %>%
  sample_n(size = 1e3) -> sample.activity

.Survfit <- survfit(Surv(StartTime, Event) ~ 1, data = activity)

autoplot(.Survfit)



.Survfit <- survfit(Surv(StartTime, Event) ~ User, data = sample.activity)

# survminer::ggforest(model = .Survfit, data = activity)

survminer::ggsurvplot(.Survfit)

# autoplot(.Survfit)

survdiff(Surv(StartTime, Event) ~ User, data = activity)


.Survfit <- survfit(Surv(StartTime, Event) ~ User, data = activity)

survminer::ggsurvplot(.Survfit)

activity %>%
  filter(ContactType != "Email") %>%
  count(Event)


# 
activity %>%
  filter(Event == 1) %>%
  count(ContactType)


# library(ranger)
# 
# random.forest.fit <- ranger(
#   Surv(StartTime, Event) ~ ContactType + ActivityType + Created + User,
#   # Surv(StartTime, Event) ~ CreatedBy,
#   # Surv(StartTime, Event) ~ ContactType + ActivityType + CreatedBy + ActivityUser,
#   data = sample.activity,
#   mtry = 4,
#   importance = "permutation",
#   splitrule = "extratrees",
#   verbose = TRUE
# )
# 
# random.forest.fit$variable.importance

# ?model.matrix

# model <- model.matrix(
#   Surv(StartTime, Event) ~ ContactType + ActivityType + Created + User - 1,
#   activity
# )

# ?coxph

fit.coxph <- coxph(
  Surv(StartTime, Event) ~ ContactType + ActivityType + Created + User,
  data = activity
)

# fit.coxph <- coxph(
#   Surv(StartTime, Event) ~ CreatedBy,
#   data = activity
# )

# CreatedBy=Workflow and ContactType=Call
coxph.summary <- summary(fit.coxph)

as.data.frame(coxph.summary$coefficients)

# coxph.summary$conf.int

?survminer::ggforest

survminer::ggforest(model = fit.coxph, data = activity)


# fit.coxph <- coxph(
#   Surv(StartTime, Event) ~ CreatedBy,
#   data = sample.activity
# )

# summary(fit.coxph)



