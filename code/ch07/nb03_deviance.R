library(rethinking)

# Create the data
sppnames <- c("afarensis",
              "africanus",
              "habilis",
              "boisei",
              "rudolfensis",
              "ergaster",
              "sapiens")
brainvolcc <- c(438 , 452 , 612, 521, 752, 871, 1350)
masskg <- c(37.0 , 35.5 , 34.5 , 41.5 , 55.5 , 61.0 , 53.5)

d <- data.frame(species = sppnames ,
                brain = brainvolcc ,
                mass = masskg)

# Normalize
d$mass_std <- (d$mass - mean(d$mass)) / sd(d$mass)
d$brain_std <- d$brain / max(d$brain)

# utility functions
R2_is_bad <- function(quap_fit) {
  s <- sim(quap_fit , refresh = 0)
  r <- apply(s, 2, mean) - d$brain_std
  1 - var2(r) / var2(d$brain_std)
}

# Models
m7.1 <- quap(
  alist(
    brain_std ~ dnorm(mu , exp(log_sigma)),
    mu <- a + b * mass_std,
    a ~ dnorm(0.5 , 1),
    b ~ dnorm(0 , 10),
    log_sigma ~ dnorm(0 , 1)
  ),
  data = d
)


m7.2 <- quap(
  alist(
    brain_std ~ dnorm(mu , exp(log_sigma)),
    mu <- a + b[1] * mass_std + b[2] * mass_std ^ 2,
    a ~ dnorm(0.5 , 1),
    b ~ dnorm(0 , 10),
    log_sigma ~ dnorm(0 , 1)
  ),
  data = d ,
  start = list(b = rep(0, 2))
)


m7.3 <- quap(
  alist(
    brain_std ~ dnorm( mu , exp(log_sigma) ),
    mu <- a + b[1]*mass_std + b[2]*mass_std^2 +
      b[3]*mass_std^3,
    a ~ dnorm( 0.5 , 1 ),
    b ~ dnorm( 0 , 10 ),
    log_sigma ~ dnorm( 0 , 1 )
  ), data=d , start=list(b=rep(0,3)) )



m7.4 <- quap(
  alist(
    brain_std ~ dnorm( mu , exp(log_sigma) ),
    mu <- a + b[1]*mass_std + b[2]*mass_std^2 +
      b[3]*mass_std^3 + b[4]*mass_std^4,
    a ~ dnorm( 0.5 , 1 ),
    b ~ dnorm( 0 , 10 ),
    log_sigma ~ dnorm( 0 , 1 )
  ), data=d , start=list(b=rep(0,4)) )


m7.5 <- quap(
  alist(
    brain_std ~ dnorm( mu , exp(log_sigma) ),
    mu <- a + b[1]*mass_std + b[2]*mass_std^2 +
      b[3]*mass_std^3 + b[4]*mass_std^4 +
      b[5]*mass_std^5,
    a ~ dnorm( 0.5 , 1 ),
    b ~ dnorm( 0 , 10 ),
    log_sigma ~ dnorm( 0 , 1 )
  ), data=d , start=list(b=rep(0,5)) )


m7.6 <- quap(
  alist(
    brain_std ~ dnorm( mu , 0.001 ),
    mu <- a + b[1]*mass_std + b[2]*mass_std^2 +
      b[3]*mass_std^3 + b[4]*mass_std^4 +
      b[5]*mass_std^5 + b[6]*mass_std^6,
    a ~ dnorm( 0.5 , 1 ),
    b ~ dnorm( 0 , 10 )
  ), data=d , start=list(b=rep(0,6)) )

# LPPD calculations
set.seed(1)
lppd( m7.1 , n=1e4 )

set.seed(1)
sapply( list(m7.1,m7.2,m7.3,m7.4,m7.5,m7.6) , function(m) {sum(lppd(m))} )

# Simulations
N <- 20
kseq <- 1:5
dev <- sapply( kseq , function(k) {
  print(k);
  r <- mcreplicate( 100 , sim_train_test( N=N, k=k ) , mc.cores=6 )
  c( mean(r[1,]) , mean(r[2,]) , sd(r[1,]) , sd(r[2,]) )
} )

plot( 1:5 , dev[1,] , ylim=c( min(dev[1:2,])-5 , max(dev[1:2,])+10 ) ,
      xlim=c(1,5.1) , xlab="number of parameters" , ylab="deviance" ,
      
      pch=16 , col=rangi2 )
mtext( concat( "N = ",N ) )
points( (1:5)+0.1 , dev[2,] )

for ( i in kseq ) {
  pts_in <- dev[1,i] + c(-1,+1)*dev[3,i]
  pts_out <- dev[2,i] + c(-1,+1)*dev[4,i]
  lines( c(i,i) , pts_in , col=rangi2 )
  lines( c(i,i)+0.1 , pts_out )
}
