#Time series project - VECM for imports and exports of Bulgaria - 60 monthly observations (2020-2024)
library(tidyverse)
library(zoo)
library(urca)
library(vars)
library(tsDyn)
library(lmtest)



#Data (fileEncoding removes the invisible Excel character before "Date")
ts_trade = read.csv("data/Trade.csv", sep = ";", fileEncoding = "UTF-8-BOM")

class(ts_trade$Date)

ts_trade$Date = as.Date(ts_trade$Date, format = "%d.%m.%Y")

class(ts_trade$Date)

trade_plot = ggplot(data = ts_trade, aes(x = Date)) +
  geom_line(aes(y = Imports_mln_euro, color = "Imports"), linewidth = 1) +
  geom_line(aes(y = Exports_mln_euro, color = "Exports"), linewidth = 1) +
  labs(
    title = "Imports and Exports of Bulgaria",
    x = "Date",
    y = "Million EUR",
    color = NULL
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

trade_plot

#Save the graph for the README
ggsave("output/figures/exports_imports.png", plot = trade_plot,
       width = 9, height = 5, bg = "white", dpi = 150)
ggsave("D:/books_FMI/Time Series/Project/exports_imports.png", plot = trade_plot,
       width = 9, height = 5, bg = "white", dpi = 150)


#Dickey-Fuller - not reliable with structural breaks

#nonstationary
summary(ur.df(ts_trade$Exports_mln_euro, selectlags = "BIC", type = c("trend")))
#nonstationary
summary(ur.df(ts_trade$Imports_mln_euro, selectlags = "BIC", type = c("trend")))



#stationary
summary(ur.df(diff(ts_trade$Exports_mln_euro), selectlags = "BIC", type = c("trend")))
#stationary
summary(ur.df(diff(ts_trade$Imports_mln_euro), selectlags = "BIC", type = c("trend")))



#Zivot-Andrews - 12 lags

#nonstationary
summary(ur.za(ts_trade$Exports_mln_euro, model = c("both"), lag = 12))
#nonstationary
summary(ur.za(ts_trade$Imports_mln_euro, model = c("both"), lag = 12))



#nonstationary
summary(ur.za(diff(ts_trade$Exports_mln_euro), model = c("both"), lag = 12))
#stationary
summary(ur.za(diff(ts_trade$Imports_mln_euro), model = c("both"), lag = 12))



#Zivot-Andrews - 6 lags

#stationary
summary(ur.za(ts_trade$Exports_mln_euro, model = c("both"), lag = 6))
#nonstationary
summary(ur.za(ts_trade$Imports_mln_euro, model = c("both"), lag = 6))



#stationary
summary(ur.za(diff(ts_trade$Exports_mln_euro), model = c("both"), lag = 6))
#stationary
summary(ur.za(diff(ts_trade$Imports_mln_euro), model = c("both"), lag = 6))



#KPSS - not reliable with structural breaks

#nonstationary
summary(ur.kpss(ts_trade$Exports_mln_euro, type = "tau", lags = "long"))
#nonstationary at 10%, closer to 5%
summary(ur.kpss(ts_trade$Imports_mln_euro, type = "tau", lags = "long"))



#stationary
summary(ur.kpss(diff(ts_trade$Exports_mln_euro), type = "tau", lags = "long"))
#stationary
summary(ur.kpss(diff(ts_trade$Imports_mln_euro), type = "tau", lags = "long"))



#overall, the conclusion is that the variables are nonstationary at levels,
#and stationary after first difference



#We can now test for cointegration for a VEC model



trade_matrix = cbind(ts_trade$Exports_mln_euro, ts_trade$Imports_mln_euro)
colnames(trade_matrix) = c("Exports", "Imports")

lag_select = VARselect(trade_matrix, lag.max = 12, type = "both")
lag_select$selection
#AIC - 11, HQ - 1, SC - 1, FPE - 4



# Trace test
summary(ca.jo(trade_matrix, type = "trace", ecdet = "const", K = 2, spec = "transitory"))



# Maximum eigenvalue test
summary(ca.jo(trade_matrix, type = "eigen", ecdet = "const", K = 2, spec = "transitory"))

#Cointegration exists barely


ts_trade$ln_Exports = log(ts_trade$Exports_mln_euro)

ts_trade$ln_Imports = log(ts_trade$Imports_mln_euro)




ln_trade_matrix = cbind(ts_trade$ln_Exports, ts_trade$ln_Imports)
colnames(ln_trade_matrix) = c("ln_Exports", "ln_Imports")

ln_lag_select = VARselect(ln_trade_matrix, lag.max = 12, type = "both")
ln_lag_select$selection
#AIC - 11, HQ - 1, SC - 1, FPE - 4



# Trace test
summary(ca.jo(ln_trade_matrix, type = "trace", ecdet = "const", K = 2, spec = "transitory"))



# Maximum eigenvalue test
summary(ca.jo(ln_trade_matrix, type = "eigen", ecdet = "const", K = 2, spec = "transitory"))


#Cointegration is again weak


model = VECM(trade_matrix, r = 1, include = "const", lag = 1, estim = "2OLS")
summary(model)



model1 = ca.jo(trade_matrix, type = "eigen", ecdet = "const", K = 2, spec = "transitory")



VECM1 = cajorls(model1, r = 1)
summary(VECM1$rlm)



model2 = ca.jo(ln_trade_matrix, type = "eigen", ecdet = "const", K = 2, spec = "transitory")
summary(model2)



VECM2 = cajorls(model2, r = 1)
summary(VECM2$rlm)



#Adjustments - dummy for the structural break
dummy_2022_2023 = ifelse(ts_trade$Date >= as.Date("2022-01-01") & ts_trade$Date <= as.Date("2023-12-31"), 1, 0)


dummy_2022_2023 = as.matrix(dummy_2022_2023)
colnames(dummy_2022_2023) = "D_2022_2023"



# Trace test
summary(ca.jo(ln_trade_matrix,
              type = "trace",
              ecdet = "const",
              K = 2,
              spec = "transitory",
              season = 12,
              dumvar = dummy_2022_2023))



# Maximum eigenvalue test
summary(ca.jo(ln_trade_matrix,
              type = "eigen",
              ecdet = "const",
              K = 2,
              spec = "transitory",
              season = 12,
              dumvar = dummy_2022_2023))



model3 = ca.jo(trade_matrix,
               type = "trace",
               ecdet = "const",
               K = 2,
               spec = "transitory",
               season = 12,
               dumvar = dummy_2022_2023)



model4 = ca.jo(ln_trade_matrix,
               type = "trace",
               ecdet = "const",
               K = 2,
               spec = "transitory",
               season = 12,
               dumvar = dummy_2022_2023)



VECM3 = cajorls(model3, r = 1)
summary(VECM3$rlm)



VECM4 = cajorls(model4, r = 1)
summary(VECM4$rlm)


#Dummy is not needed with seasonal dummies



model5 = ca.jo(trade_matrix,
               type = "trace",
               ecdet = "const",
               K = 2,
               spec = "transitory",
               season = 12)



model6 = ca.jo(ln_trade_matrix,
               type = "trace",
               ecdet = "const",
               K = 2,
               spec = "transitory",
               season = 12)

#With seasonal dummies: trace = 28.54 > 24.60 (1% c.v.) -> one cointegrating relationship



VECM5 = cajorls(model5, r = 1)
summary(VECM5$rlm)
VAR5 = vec2var(model5, r = 1)



#Final model
VECM6 = cajorls(model6, r = 1)
summary(VECM6$rlm)
#ECT in the exports equation: -0.69 (p = 0.08) -> exports adjust to equilibrium
#ECT in the imports equation: 0.41 (p = 0.31) -> imports do not adjust (weakly exogenous)



VAR6 = vec2var(model6, r = 1)
VECM6$beta #long-run coefficients
#ln_Exports = 0.93*ln_Imports + 0.49



plot(VAR6$resid)



serial.test(VAR6, lags.pt = 12, type = "PT.asymptotic")
normality.test(VAR6)
arch.test(VAR6)
plot(fevd(VAR6, n.ahead = 12))

serial.test(VAR5, lags.pt = 12, type = "PT.asymptotic")
normality.test(VAR5)
arch.test(VAR5)
plot(fevd(VAR5, n.ahead = 12))



irf_exports = irf(
  VAR6,
  impulse = "ln_Exports",
  response = c("ln_Exports", "ln_Imports"),
  n.ahead = 12,
  boot = TRUE,
  runs = 1000,
  ci = 0.95
)
plot(irf_exports)



irf_imports = irf(
  VAR6,
  impulse = "ln_Imports",
  response = c("ln_Exports", "ln_Imports"),
  n.ahead = 12,
  boot = TRUE,
  runs = 1000,
  ci = 0.95
)
plot(irf_imports)



irf_exports_levels = irf(
  VAR5,
  impulse = "Exports",
  response = c("Exports", "Imports"),
  n.ahead = 12,
  boot = TRUE,
  runs = 1000,
  ci = 0.95
)
plot(irf_exports_levels)



irf_imports_levels = irf(
  VAR5,
  impulse = "Imports",
  response = c("Exports", "Imports"),
  n.ahead = 12,
  boot = TRUE,
  runs = 1000,
  ci = 0.95
)
plot(irf_imports_levels)

plot(predict(VAR5, n.ahead = 12, ci = 0.95))
plot(predict(VAR6, n.ahead = 12, ci = 0.95))



#Granger causality on levels with 1 lag - for reference only
#Not valid for I(1) series: with cointegration at least one variable must Granger-cause the other,
#and this runs through the error correction term. The VECM shows that imports lead exports.
grangertest(ln_Exports ~ ln_Imports, order = 1, data = ts_trade)
grangertest(ln_Imports ~ ln_Exports, order = 1, data = ts_trade)