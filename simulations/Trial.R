set.seed(42)

n_A <- 1000
n_B <- 1000

p_A <- 0.10
p_B <- 0.12

A <- rbinom(n_A, size = 1, prob = p_A)
B <- rbinom(n_B, size = 1, prob = p_B)

sum(A)       # Number of conversions in A
sum(B)       # Number of conversions in B

mean(A)      # Observed conversion rate in A
mean(B)      # Observed conversion rate in B

set.seed(123)

# True conversion probabilities
p_A <- 0.10
p_B <- 0.12

# Number of users per group
n_A <- 5000
n_B <- 5000

# Number of simulated experiments
N_sim <- 1000

# Store p-values
p_values <- numeric(N_sim)

for (i in 1:N_sim) {
  
  # Generate one experiment
  A <- rbinom(n_A, size = 1, prob = p_A)
  B <- rbinom(n_B, size = 1, prob = p_B)
  
  # Count conversions
  x_A <- sum(A)
  x_B <- sum(B)
  
  # Two-proportion hypothesis test
  test <- prop.test(
    x = c(x_A, x_B),
    n = c(n_A, n_B),
    correct = FALSE
  )
  
  # Save the p-value
  p_values[i] <- test$p.value
}

# Estimate statistical power
power_estimate <- mean(p_values < 0.05)

power_estimate

set.seed(123)

p_A <- 0.10
p_B <- 0.12
N_sim <- 1000

sample_sizes <- seq(500, 6000, by = 500)

power_values <- numeric(length(sample_sizes))

for (j in seq_along(sample_sizes)) {
  
  n <- sample_sizes[j]
  p_values <- numeric(N_sim)
  
  for (i in 1:N_sim) {
    
    x_A <- rbinom(1, size = n, prob = p_A)
    x_B <- rbinom(1, size = n, prob = p_B)
    
    test <- prop.test(
      x = c(x_A, x_B),
      n = c(n, n),
      correct = FALSE
    )
    
    p_values[i] <- test$p.value
  }
  
  power_values[j] <- mean(p_values < 0.05)
}

plot(
  sample_sizes, power_values,
  type = "b",
  pch = 19,
  ylim = c(0, 1),
  xlab = "Sample size per group",
  ylab = "Estimated statistical power",
  main = "Power Curve for an A/B Test"
)

abline(h = 0.80, lty = 2)


set.seed(123)

p_A <- 0.10
p_B_values <- c(0.11, 0.12, 0.13)

sample_sizes <- seq(500, 15000, by = 500)
N_sim <- 2000
alpha <- 0.05

# Store the estimated power for every combination
power_matrix <- matrix(
  NA_real_,
  nrow = length(sample_sizes),
  ncol = length(p_B_values)
)

for (j in seq_along(p_B_values)) {
  
  p_B <- p_B_values[j]
  
  for (k in seq_along(sample_sizes)) {
    
    n <- sample_sizes[k]
    p_values <- numeric(N_sim)
    
    for (i in 1:N_sim) {
      
      # Generate conversion counts
      x_A <- rbinom(1, size = n, prob = p_A)
      x_B <- rbinom(1, size = n, prob = p_B)
      
      # Perform the two-proportion test
      test <- prop.test(
        x = c(x_A, x_B),
        n = c(n, n),
        correct = FALSE
      )
      
      p_values[i] <- test$p.value
    }
    
    # Estimate power
    power_matrix[k, j] <- mean(p_values < alpha)
  }
}

# Plot all three power curves
matplot(
  sample_sizes,
  power_matrix,
  type = "b",
  pch = c(16, 17, 15),
  lty = 1,
  lwd = 2,
  col = c("blue", "red", "darkgreen"),
  ylim = c(0, 1),
  xlab = "Sample size per group",
  ylab = "Estimated statistical power",
  main = "Power Curves for Different Effect Sizes"
)

abline(h = 0.80, lty = 2)

legend(
  "bottomright",
  legend = c(
    "Effect = 1 percentage point",
    "Effect = 2 percentage points",
    "Effect = 3 percentage points"
  ),
  col = c("blue", "red", "darkgreen"),
  pch = c(16, 17, 15),
  lty = 1,
  cex = 0.8
)


target_power <- 0.80

for (j in seq_along(p_B_values)) {
  
  reached <- which(power_matrix[, j] >= target_power)
  
  if (length(reached) == 0) {
    cat(
      "Treatment rate:", p_B_values[j],
      "- target power not reached\n"
    )
  } else {
    n_required <- sample_sizes[min(reached)]
    
    cat(
      "Treatment rate:", p_B_values[j],
      "- required sample size per group:", n_required, "\n"
    )
  }
}


sample_size_approx <- function(p_A, p_B,
                               alpha = 0.05,
                               target_power = 0.80) {
  
  p_bar <- (p_A + p_B) / 2
  
  z_alpha <- qnorm(1 - alpha / 2)
  z_power <- qnorm(target_power)
  
  n <- (
    z_alpha * sqrt(2 * p_bar * (1 - p_bar)) +
      z_power * sqrt(
        p_A * (1 - p_A) +
          p_B * (1 - p_B)
      )
  )^2 / (p_B - p_A)^2
  
  ceiling(n)
}

sample_size_approx(0.10, 0.11)
sample_size_approx(0.10, 0.12)
sample_size_approx(0.10, 0.13)


set.seed(123)

N_sim <- 5000
max_n <- 1000

p_A <- 0.10
p_B <- 0.10

checkpoints <- c(200, 400, 600, 800, 1000)

fixed_rejections <- logical(N_sim)
peeking_rejections <- logical(N_sim)

all_p_values <- matrix(
  NA,
  nrow = N_sim,
  ncol = length(checkpoints)
)
for (i in 1:N_sim) {
  
  # Generate one complete experiment under H0
  A <- rbinom(max_n, size = 1, prob = p_A)
  B <- rbinom(max_n, size = 1, prob = p_B)
  
  # Test only once, at the end
  final_test <- prop.test(
    x = c(sum(A), sum(B)),
    n = c(max_n, max_n),
    correct = FALSE
  )
  
  fixed_rejections[i] <- final_test$p.value < 0.05
  
  # Repeatedly test at each checkpoint
  p_values <- numeric(length(checkpoints))
  
  for (j in seq_along(checkpoints)) {
    
    n <- checkpoints[j]
    
    test <- prop.test(
      x = c(sum(A[1:n]), sum(B[1:n])),
      n = c(n, n),
      correct = FALSE
    )
    
    p_values[j] <- test$p.value
  }
  all_p_values[i, ] <- p_values
  
  # Reject if ANY checkpoint gives p < 0.05
  peeking_rejections[i] <- any(p_values < 0.05)
}

fixed_error_rate <- mean(fixed_rejections)
peeking_error_rate <- mean(peeking_rejections)

fixed_error_rate
peeking_error_rate


error_rates <- c(
  fixed_error_rate,
  peeking_error_rate
)

barplot(
  error_rates,
  names.arg = c(
    "Fixed-horizon",
    "Repeated peeking"
  ),
  ylim = c(0, 0.16),
  col = c("steelblue", "tomato"),
  ylab = "Estimated Type I error rate",
  main = "Effect of Repeated Peeking on Type I Error"
)

abline(h = 0.05, lty = 2, lwd = 2)

text(
  x = c(0.7, 1.9),
  y = error_rates + 0.008,
  labels = paste0(
    round(error_rates * 100, 2), "%"
  )
)


lrt_test <- function(x_A, x_B, n_A, n_B) {
  
  # Pooled conversion probability under H0
  p_pool <- (x_A + x_B) / (n_A + n_B)
  
  # Observed counts
  observed <- c(
    x_A,
    n_A - x_A,
    x_B,
    n_B - x_B
  )
  
  # Expected counts under H0
  expected <- c(
    n_A * p_pool,
    n_A * (1 - p_pool),
    n_B * p_pool,
    n_B * (1 - p_pool)
  )
  
  # Calculate O * log(O/E), treating O = 0 as contribution 0
  terms <- numeric(length(observed))
  
  positive <- observed > 0
  
  terms[positive] <- observed[positive] *
    log(observed[positive] / expected[positive])
  
  G2 <- 2 * sum(terms)
  
  # Chi-square p-value with 1 degree of freedom
  p_value <- pchisq(
    G2,
    df = 1,
    lower.tail = FALSE
  )
  
  return(list(
    statistic = G2,
    p_value = p_value
  ))
}


set.seed(42)

n_A <- 1000
n_B <- 1000

A <- rbinom(n_A, size = 1, prob = 0.10)
B <- rbinom(n_B, size = 1, prob = 0.12)

x_A <- sum(A)
x_B <- sum(B)

# Perform LRT
lrt_result <- lrt_test(x_A, x_B, n_A, n_B)

lrt_result


prop_result <- prop.test(
  x = c(x_A, x_B),
  n = c(n_A, n_B),
  correct = FALSE
)

prop_result


lrt_result$statistic

prop_result$statistic


chisq.test(
  matrix(
    c(x_A, n_A - x_A,
      x_B, n_B - x_B),
    nrow = 2,
    byrow = TRUE
  ),
  correct = FALSE
)


set.seed(123)

N_sim <- 5000
n <- 1000

p_A <- 0.10
p_B <- 0.10

lrt_rejections <- logical(N_sim)
pearson_rejections <- logical(N_sim)

for (i in 1:N_sim) {
  
  # Generate data under the null hypothesis
  A <- rbinom(n, size = 1, prob = p_A)
  B <- rbinom(n, size = 1, prob = p_B)
  
  x_A <- sum(A)
  x_B <- sum(B)
  
  # Likelihood Ratio Test
  lrt_result <- lrt_test(x_A, x_B, n, n)
  
  # Pearson two-proportion test
  pearson_result <- prop.test(
    x = c(x_A, x_B),
    n = c(n, n),
    correct = FALSE
  )
  
  # Record whether each test rejects H0
  lrt_rejections[i] <- lrt_result$p_value < 0.05
  
  pearson_rejections[i] <-
    pearson_result$p.value < 0.05
}

# Estimate Type I error rates
lrt_error_rate <- mean(lrt_rejections)
pearson_error_rate <- mean(pearson_rejections)

lrt_error_rate
pearson_error_rate


set.seed(123)

N_sim <- 5000
n <- 1000

p_A <- 0.10
p_B <- 0.12

lrt_rejections <- logical(N_sim)
pearson_rejections <- logical(N_sim)

for (i in 1:N_sim) {
  
  # Generate data under the alternative hypothesis
  A <- rbinom(n, size = 1, prob = p_A)
  B <- rbinom(n, size = 1, prob = p_B)
  
  x_A <- sum(A)
  x_B <- sum(B)
  
  # Likelihood Ratio Test
  lrt_result <- lrt_test(x_A, x_B, n, n)
  
  # Pearson two-proportion test
  pearson_result <- prop.test(
    x = c(x_A, x_B),
    n = c(n, n),
    correct = FALSE
  )
  
  # Record rejections
  lrt_rejections[i] <- lrt_result$p_value < 0.05
  
  pearson_rejections[i] <-
    pearson_result$p.value < 0.05
}

# Estimate statistical power
lrt_power <- mean(lrt_rejections)
pearson_power <- mean(pearson_rejections)

lrt_power
pearson_power


set.seed(123)

N_sim <- 2000

p_A <- 0.10
p_B <- 0.12

sample_sizes <- seq(500, 6000, by = 500)

lrt_power <- numeric(length(sample_sizes))
pearson_power <- numeric(length(sample_sizes))

for (j in seq_along(sample_sizes)) {
  
  n <- sample_sizes[j]
  
  lrt_rejections <- logical(N_sim)
  pearson_rejections <- logical(N_sim)
  
  for (i in 1:N_sim) {
    
    A <- rbinom(n, 1, p_A)
    B <- rbinom(n, 1, p_B)
    
    x_A <- sum(A)
    x_B <- sum(B)
    
    lrt_result <- lrt_test(x_A, x_B, n, n)
    
    pearson_result <- prop.test(
      x = c(x_A, x_B),
      n = c(n, n),
      correct = FALSE
    )
    
    lrt_rejections[i] <- lrt_result$p_value < 0.05
    pearson_rejections[i] <- pearson_result$p.value < 0.05
  }
  
  lrt_power[j] <- mean(lrt_rejections)
  pearson_power[j] <- mean(pearson_rejections)
}


matplot(
  sample_sizes,
  cbind(lrt_power, pearson_power),
  type = "b",
  pch = c(16, 17),
  lty = 1,
  col = c("blue", "red"),
  ylim = c(0, 1),
  xlab = "Sample size per group",
  ylab = "Estimated statistical power",
  main = "Power Comparison: LRT vs Pearson Test"
)

abline(h = 0.80, lty = 2)

legend(
  "bottomright",
  legend = c("Likelihood Ratio Test", "Pearson Test"),
  col = c("blue", "red"),
  pch = c(16, 17),
  lty = 1
)


set.seed(123)

N_sim <- 2000

p_A <- 0.10
p_B_values <- c(0.11, 0.12, 0.13)

# sample_sizes <- seq(500, 15000, by = 500)
sample_sizes <- seq(500, 20000, by = 500)

# Store power estimates
lrt_power_matrix <- matrix(
  NA_real_,
  nrow = length(sample_sizes),
  ncol = length(p_B_values)
)

pearson_power_matrix <- matrix(
  NA_real_,
  nrow = length(sample_sizes),
  ncol = length(p_B_values)
)

for (j in seq_along(p_B_values)) {
  
  p_B <- p_B_values[j]
  
  for (k in seq_along(sample_sizes)) {
    
    n <- sample_sizes[k]
    
    lrt_rejections <- logical(N_sim)
    pearson_rejections <- logical(N_sim)
    
    for (i in 1:N_sim) {
      
      # Generate data
      A <- rbinom(n, 1, p_A)
      B <- rbinom(n, 1, p_B)
      
      x_A <- sum(A)
      x_B <- sum(B)
      
      # LRT
      lrt_result <- lrt_test(x_A, x_B, n, n)
      
      # Pearson test
      pearson_result <- prop.test(
        x = c(x_A, x_B),
        n = c(n, n),
        correct = FALSE
      )
      
      lrt_rejections[i] <-
        lrt_result$p_value < 0.05
      
      pearson_rejections[i] <-
        pearson_result$p.value < 0.05
    }
    
    lrt_power_matrix[k, j] <-
      mean(lrt_rejections)
    
    pearson_power_matrix[k, j] <-
      mean(pearson_rejections)
  }
}


par(mfrow = c(1, 3))

for (j in 1:3) {
  
  matplot(
    sample_sizes,
    cbind(
      lrt_power_matrix[, j],
      pearson_power_matrix[, j]
    ),
    type = "b",
    pch = c(16, 17),
    lty = 1,
    col = c("blue", "red"),
    ylim = c(0, 1),
    xlab = "Sample size per group",
    ylab = "Estimated power",
    main = paste(
      "Treatment effect:",
      (p_B_values[j] - p_A) * 100,
      "percentage point(s)"
    )
  )
  
  abline(h = 0.80, lty = 2)
  
  legend(
    "bottomright",
    legend = c("LRT", "Pearson"),
    col = c("blue", "red"),
    pch = c(16, 17),
    lty = 1,
    cex = 0.8
  )
}

par(mfrow = c(1, 1))


for (j in 1:3) {
  
  lrt_n <- sample_sizes[
    which(lrt_power_matrix[, j] >= 0.80)[1]
  ]
  
  pearson_n <- sample_sizes[
    which(pearson_power_matrix[, j] >= 0.80)[1]
  ]
  
  cat(
    "Effect:",
    (p_B_values[j] - p_A) * 100,
    "percentage points\n"
  )
  
  cat("LRT:", lrt_n, "\n")
  cat("Pearson:", pearson_n, "\n\n")
}


for (j in 1:3) {
  
  lrt_indices <- which(lrt_power_matrix[, j] >= 0.80)
  pearson_indices <- which(pearson_power_matrix[, j] >= 0.80)
  
  lrt_n <- if (length(lrt_indices) > 0) {
    sample_sizes[min(lrt_indices)]
  } else {
    NA
  }
  
  pearson_n <- if (length(pearson_indices) > 0) {
    sample_sizes[min(pearson_indices)]
  } else {
    NA
  }
  
  cat("Effect:", (p_B_values[j] - p_A) * 100,
      "percentage points\n")
  
  cat("LRT:", lrt_n, "\n")
  cat("Pearson:", pearson_n, "\n\n")
}


set.seed(123)

max_n <- 1000
p_A <- 0.10
p_B <- 0.10

checkpoints <- c(200, 400, 600, 800, 1000)

# Generate one complete experiment under H0
A <- rbinom(max_n, size = 1, prob = p_A)
B <- rbinom(max_n, size = 1, prob = p_B)

# Calculate p-values at each checkpoint
p_values <- numeric(length(checkpoints))

for (j in seq_along(checkpoints)) {
  
  n <- checkpoints[j]
  
  test <- prop.test(
    x = c(sum(A[1:n]), sum(B[1:n])),
    n = c(n, n),
    correct = FALSE
  )
  
  p_values[j] <- test$p.value
}

# Display the values
data.frame(
  Checkpoint = checkpoints,
  P_value = p_values
)


plot(
  checkpoints,
  p_values,
  type = "b",
  pch = 19,
  lwd = 2,
  col = "blue",
  ylim = c(0, 1),
  xlab = "Sample size per group",
  ylab = "P-value",
  main = "P-value Evolution During Repeated Checking"
)

# Significance threshold
abline(h = 0.05, col = "red", lty = 2, lwd = 2)

legend(
  "topright",
  legend = c("Observed p-values", "Significance level (0.05)"),
  col = c("blue", "red"),
  lty = c(1, 2),
  pch = c(19, NA),
  bty = "n"
)


# Proportion of simulations with p-value < 0.05
rejection_rates <- colMeans(all_p_values < 0.05)

plot(
  checkpoints,
  rejection_rates,
  type = "b",
  pch = 19,
  lwd = 2,
  col = "blue",
  ylim = c(0, max(rejection_rates, 0.05) + 0.03),
  xlab = "Sample size per group",
  ylab = "Proportion of significant tests",
  main = "Effect of Repeated Checking on Rejection Rate"
)

abline(h = 0.05, col = "red", lty = 2, lwd = 2)

legend(
  "topleft",
  legend = c("Observed rejection rate", "Nominal 5% level"),
  col = c("blue", "red"),
  lty = c(1, 2),
  pch = c(19, NA),
  bty = "n"
)