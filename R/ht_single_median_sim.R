#' Hypothesis testing for one median, using shifted bootstrapping
#' 
#' Helper for the `inference()` function
#' 
#' @param y Response variable, can be numerical or categorical
#' @param null null value for a hypothesis test
#' @param alternative direction of the alternative hypothesis; "less", 
#' "greater", or "twosided"
#' @param y_name Name of response variable as a character string (passed 
#' from inference function)
#' @param nsim number of simulations
#' @param seed seed to be set, default is NULL
#' @param show_var_types print variable types, set to verbose by default
#' @param show_summ_stats print summary stats, set to verbose by default
#' @param show_eda_plot print EDA plot, set to verbose by default
#' @param show_inf_plot print inference plot, set to verbose by default
#' @param show_res print results, set to verbose by default

ht_single_median_sim <- function(y, null, alternative, y_name,
                                 nsim, seed, 
                                 show_var_types, show_summ_stats, show_res,
                                 show_eda_plot, show_inf_plot){

  # set seed
  if(!is.null(seed)){ set.seed(seed) }
  
  # calculate sample size
  n <- length(y) 
  
  # calculate y-bar
  y_med <- median(y)
  
  # create bootstrap distribution
  sim_dist <- rep(NA, nsim)
  for(i in 1:nsim){
    boot_samp <- sample(y, size = n, replace = TRUE)
    sim_dist[i] <- median(boot_samp)
  }
  
  # center bootstrap distribution at null
  sim_dist_temp <- sim_dist
  sim_dist <- sim_dist_temp - (mean(sim_dist_temp) - null)
  
  # shading cutoffs
  if(alternative == "greater"){ x_min = y_med; x_max = Inf }
  if(alternative == "less"){ x_min = -Inf; x_max = y_med }
  if(alternative == "twosided"){
    if(y_med >= null){
      x_min = c(null - (y_med - null), y_med)
      x_max = c(-Inf, Inf)
    }
    if(y_med <= null){
      x_min = c(y_med, null + (null - y_med))
      x_max = c(-Inf, Inf)
    }    
  }
  
  # calculate p-value
  if(alternative == "greater"){ p_value <- sum(sim_dist >= y_med) / nsim }
  if(alternative == "less"){ p_value <- sum(sim_dist <= y_med) / nsim }
  if(alternative == "twosided"){
    if(y_med > null){
      p_value <- min(2 * (sum(sim_dist >= y_med) / nsim), 1)
    }
    if(y_med < null){
      p_value <- min(2 * (sum(sim_dist <= y_med) / nsim), 1)
    }
    if(y_med == null){ p_value <- 1 }
  }

  # print variable types
  if(show_var_types == TRUE){
    cat("Single numerical variable\n")
  }
  
  # print summary statistics
  if(show_summ_stats == TRUE){
    q_25 <- quantile(y, 0.25)
    q_75 <- quantile(y, 0.75)
    cat(paste0("n = ", n, ", y_med = ", round(y_med, 4), 
               ", Q1 = ", round(q_25, 4), ", Q3 = ", round(q_75, 4), "\n"))
  }
  
  # print results
  if(show_res == TRUE){
    if(alternative == "greater"){
      alt_sign <- ">"
    } else if(alternative == "less"){
      alt_sign <- "<"
    } else {
      alt_sign <- "!="
    }
    cat(paste0("H0: pop_med = ", null, "\n"))
    cat(paste0("HA: pop_med ", alt_sign, " ", null, "\n"))
    p_val_to_print <- ifelse(round(p_value, 4) == 0, "< 0.0001", round(p_value, 4))
    cat(paste0("p_value = ", p_val_to_print))
  }
  
  # eda_plot
  d_eda <- data.frame(y = y)
  
  eda_plot <- ggplot2::ggplot(data = d_eda, ggplot2::aes(x = y), environment = environment()) +
    ggplot2::geom_histogram(fill = "#8FDEE1", binwidth = diff(range(y)) / 20) +
    ggplot2::xlab(y_name) +
    ggplot2::ylab("") +
    ggplot2::ggtitle("Sample Distribution") +
    ggplot2::geom_vline(xintercept = y_med, col = "#1FBEC3", lwd = 1.5)
  
  # inf_plot
  d_inf <- data.frame(sim_dist = sim_dist)
  
  inf_plot <- ggplot2::ggplot(data = d_inf, ggplot2::aes(x = sim_dist), environment = environment()) +
    ggplot2::geom_histogram(fill = "#CCCCCC", binwidth = max(diff(range(sim_dist)) / 20, 1)) +
    ggplot2::annotate("rect", xmin = x_min, xmax = x_max, ymin = 0, ymax = Inf, 
             alpha = 0.3, fill = "#FABAB8") +
    ggplot2::xlab("simulated medians") +
    ggplot2::ylab("") +
    ggplot2::ggtitle("Null Distribution") +
    ggplot2::geom_vline(xintercept = y_med, color = "#F57670", lwd = 1.5)
  
  # print plots
  if(show_eda_plot & !show_inf_plot){ 
    suppressWarnings(print(eda_plot))
  }
  if(!show_eda_plot & show_inf_plot){ 
    print(inf_plot)
  }
  if(show_eda_plot & show_inf_plot){
    gridExtra::grid.arrange(eda_plot, inf_plot, ncol = 2)
  }
  
  # return
  return(list(sim_dist = sim_dist, p_value = p_value))
  
}