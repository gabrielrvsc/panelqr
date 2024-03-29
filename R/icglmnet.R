#' Estimate a GLM with lasso, elasticnet or ridge regularization using information criterion
#'
#' Uses the glmnet (for family = "gaussian") function from the glmnet package to estimate models through all the regularization path and selects the best model using some information criterion. The glmnet package chooses the best model only by cross validation (cv.glmnet). Choosing with information criterion is faster and more adequate for some aplications, especially time-series.
#'
#' @details Selecting the model using information criterion is faster than using cross validation and it has some theoretical advantages in some cases. For example, Zou, Hastie, Tibshirani (2007) show that one can consistently estimate the degrees of freedom of the LASSO using the BIC. Moreover, Information Criterions are becoming very popular, especially on time-series applications where cross-validation may impose further complications.
#'
#' The information criterions implmemented are the Bayesian Information Criterion (bic), the Akaike Information Criterion (aic) and its sample size correction (aicc) and the Hannah and Quinn Criterion (hqc).
#'
#' @param x Matrix of independent variables. Each row is an observation and each column is a variable.
#' @param y Response variable equivalent to the function.
#' @param crit Information criterion.
#' @param ... Aditional arguments to be passed to glmnet.
#' @return An object with S3 class ic.glmnet.
#' \item{coefficients}{Coefficients from the selected model.}
#' \item{ic}{All information criterions.}
#' \item{lambda}{Lambda from the selected model.}
#' \item{nvar}{Number of variables on the selected model including the intercept.}
#' \item{glmnet}{glmnet object.}
#' \item{residuals}{Residuals from the selected model.}
#' \item{fitted.values}{Fitted values from the selected model.}
#' \item{ic.range}{Chosen information criterion calculated through all the regularization path.}
#' \item{call}{The matched call.}
#' @keywords glmnet, LASSO, Elasticnet, Ridge, Regularization
#' @export
#' @import Matrix glmnet
#' @importFrom stats coef fitted var
#' @examples
#' x=matrix(rnorm(100*20),100,20)
#' y=rnorm(100)
#' fit1=ic.glmnet(x,y)
#'
#' @references
#'
#' Jerome Friedman, Trevor Hastie, Robert Tibshirani (2010). Regularization Paths for Generalized Linear Models via Coordinate Descent. Journal of Statistical Software, 33(1), 1-22. URL \url{http://www.jstatsoft.org/v33/i01/}.
#'
#' Zou, Hui, Trevor Hastie, and Robert Tibshirani. "On the “degrees of freedom” of the lasso." The Annals of Statistics 35.5 (2007): 2173-2192.
#' @seealso \code{\link[glmnet]{glmnet}}, \code{\link[glmnet]{cv.glmnet}}, \code{\link{predict}}, \code{\link{plot}}



ic.glmnet = function (x, y, crit=c("bic","aic","aicc","hqc"),...)
{
  if (is.matrix(x) == FALSE) {
    x = as.matrix(x)
  }
  if (is.vector(y) == FALSE) {
    y = as.vector(y)
  }
  crit=match.arg(crit)
  n=length(y)
  model = glmnet(x = x, y = y, ...)
  coef = coef(model)
  lambda = model$lambda
  df = model$df

  yhat=cbind(1,x)%*%coef
  residuals = (y- yhat)
  mse = colMeans(residuals^2)
  sse = colSums(residuals^2)

  nvar = df + 1
  bic = n*log(mse)+nvar*log(n)
  aic = n*log(mse)+2*nvar
  aicc = aic+(2*nvar*(nvar+1))/(n-nvar-1)
  hqc = n*log(mse)+2*nvar*log(log(n))

  sst = (n-1)*var(y)
  r2 = 1 - (sse/sst)
  adjr2 = (1 - (1 - r2) * (n - 1)/(nrow(x) - nvar - 1))

  crit=switch(crit,bic=bic,aic=aic,aicc=aicc,hqc=hqc)

  selected=best.model = which(crit == min(crit))

  ic=c(bic=bic[selected],aic=aic[selected],aicc=aicc[selected],hqc=hqc[selected])

  result=list(coefficients=coef[,selected],ic=ic,lambda = lambda[selected], nvar=nvar[selected],
              glmnet=model,residuals=residuals[,selected],fitted.values=yhat[,selected],ic.range=crit, call = match.call())

  class(result)="ic.glmnet"
  return(result)
}
