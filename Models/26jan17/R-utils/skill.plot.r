#==========================================================================================#
#==========================================================================================#
#     Function skill.plot.  This is based on Taylor diagrams, but instead of the model     #
# variance, the axes are observed variance and residual variance.                          #
#                                                                                          #
# INPUT:                                                                                   #
# obs            -- Observation, coerced to a single vector.                               #
# mod            -- Modelled data.  You can send multiple models, either as lists,         #
#                   data.frame, or arrays, as long as one and only one dimension matches   #
#                   the length of 'obs'.                                                   #
# mod.options    -- List with further options to be sent to points when we actually plot   #
#                   the data.                                                              #
# plot.obs       -- Plot the target sign on the "sweetest spot" (perfect model)            #
# obs.options    -- List with further options to be sent to points when we plot the data   #
# bias.lab       -- Label for bias axis                                                    #
# r2.lab         -- Label for coefficient of determination axis                            #
# rmse.lab       -- Label for root mean square error axis                                  #
# bias.lim       -- Limits for bias axis (if NULL, use defaults).                          #
# r2.lim         -- Limits for R2 axis (if NULL, use defaults).                            #
# main           -- Main title                                                             #
# nobias.line    -- Draw a line on zero bias?                                              #
# nobias.options -- List with further options to be sent to nobias line (abline)           #
# r2.grid        -- Plot R2 "grid"?                                                        #
# r2.options     -- List with further options to be sent to r2 grid plot (abline).         #
# rmse.grid      -- Plot the root mean square error [sqrt(bias^2+sigma_R^2)]               #
# n.rmse         -- Number of RMSE lines to draw (NULL means default).                     #
# rmse.options   -- Options to be passed to rmse grid plot (lines).                        #
# cex.main       -- Multiplication factor for the main title.                              #
# cex.xyzlab     -- Multiplication factor for the axes labels (axis "titles").             #
# cex.xyzat      -- Multiplication factor for xyz labels (axis "numbers")                  #
# n.parms        -- Number of parameters, used to find the adjusted R2 (for output only).  #
#                   The R2 scale in the plot is never the adjusted R2 so you can use the   #
#                   same plot for different observations.                                  #
# skill          -- In case you want to add more data to an existing skill plot, you must  #
#                   provide the object generated by a previous call, so it will adjust the #
#                   scale accordingly.  Otherwise, leave this as NULL.                     #
# normali(s/z)e  -- Should the axes be normalised?                                         #
# ...            -- Other par options that you may want to send to plot.window.            #
#------------------------------------------------------------------------------------------#
skill.plot  <<- function ( obs
                         , mod
                         , mod.options     = list( col = "red"
                                                 , pch = 19
                                                 , cex = 1.0
                                                 , lty = "solid"
                                                 , lwd = 2.0
                                                 )#end list
                         , plot.obs        = TRUE
                         , obs.options     = list(col="black",cex=2.0)
                         , bias.lab        = "Mean bias"
                         , r2.lab          = "Coefficient of determination"
                         , rmse.lab        = "Root mean square error"
                         , main            = "Skill diagram"
                         , bias.lim        = NULL
                         , r2.lim          = NULL
                         , nobias.line     = TRUE
                         , nobias.options  = list(col="mediumpurple1",lty="dotdash",lwd=2)
                         , sigma.grid      = TRUE
                         , sigma.options   = list(col="grey40",lty="dotted",lwd=1.2)
                         , r2.grid         = TRUE
                         , r2.options      = list(col="black",lty="dotdash",lwd=1.2)
                         , rmse.grid       = TRUE
                         , n.rmse          = NULL
                         , rmse.options    = list(col="purple3",lty="dashed",lwd=1.2)
                         , cex.main        = 1.0
                         , cex.xyzlab      = 1.0
                         , cex.xyzat       = 1.0
                         , n.parms         = NULL
                         , skill           = NULL
                         , normalize
                         , normalise       = ifelse( ! is.null(skill)
                                                   , skill$normalise
                                                   , ifelse( ! missing(normalize)
                                                           , normalize
                                                           , FALSE
                                                           )#end ifelse
                                                   )#end ifelse
                         , ...
                         ){
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Check that the user sent obs and mod.                                             #
   #---------------------------------------------------------------------------------------#
   dum = stopifnot(! missing(obs))
   dum = stopifnot(! missing(mod))
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #    Check whether to retrieve the previous information or not.                         #
   #---------------------------------------------------------------------------------------#
   add = ! is.null(skill)
   if (! add) skill    = list()
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #    Make sure that 'obs' is a vector, and that 'mod' is a list.                        #
   #---------------------------------------------------------------------------------------#
   #----- Reference. ----------------------------------------------------------------------#
   obs   = unlist   (obs)
   keep  = is.finite(obs)
   n.obs = length   (obs)
   #----- Check which type of variable "mod" is. ------------------------------------------#
   if (is.list(mod)){
      #----- Make sure that dimensions match, otherwise leave "mod" as a list. ------------#
      n.mod = sapply(X=mod,FUN=length)
      if (any(n.mod) != n.obs && sum(n.mod) != n.obs){
         cat(" - Length(mod): ",paste(n.mod,collapse=" "),"\n")
         cat(" - Length(obs):",n.obs,"\n")
         stop(" Dimensions of 'mod' and 'obs' must match!")
      }else if(sum(n.mod) == n.obs){
         warning(" Converting 'mod' from multiple lists to a single list...")
         mod = list(unlist(mod))
      }#end if
      #------------------------------------------------------------------------------------#
   }else if(is.array(mod) || is.data.frame(mod)){
      #------------------------------------------------------------------------------------#
      #     "mod" is a matrix or array, find the matching dimension convert it to list.    #
      #------------------------------------------------------------------------------------#
      dim.mod = dim(mod)
      n.mod   = length(mod)
      n.dim   = length(dim.mod)
      o.dim   = which(dim.mod == n.obs)
      if (length(o.dim) == 0 && n.obs != n.obs){
         cat(" - Dim(mod)   : ",paste(dim.mod,collapse=" "),"\n")
         cat(" - Length(mod): ",n.mod                      ,"\n")
         cat(" - Length(obs): ",n.obs                      ,"\n")
         stop(" Either the length or one dimension of 'mod' must match 'obs' size!")
      }else if(length(o.dim) == 0 && n.mod == n.obs){
         warning(" Converting array 'mod' to a vector...")
         mod = list(unlist(mod[keep]))
      }else if(length(o.dim) > 1){
         cat (" - Dim(mod)   : ",paste(dim.mod,collapse=" "),"\n")
         cat (" - Length(mod): ",n.mod                      ,"\n")
         cat (" - Length(obs): ",n.obs                      ,"\n")
         cat (" Ambiguous: 2 or more dimensions of 'mod' match the 'obs' length...","\n")
         stop(" Hint: split the array 'mod' into a list and try again...")
      }else{
         #----- Success! Split the array into lists. --------------------------------------#
         mod = aperm(a = mod, perm = c(sequence(n.dim)[-o.dim],o.dim))
         mod = t(matrix(mod,nrow=prod(dim.mod[-o.dim]),ncol=dim.mod[o.dim]))
         mod = split(mod, col(mod))
         #---------------------------------------------------------------------------------#
      }#end if
      #------------------------------------------------------------------------------------#
   }else{
      #------------------------------------------------------------------------------------#
      #      "mod" is something else (probably a  vector).  Convert it to a list and hope  #
      # for the best...                                                                    #
      #------------------------------------------------------------------------------------#
      mod   = unlist(mod)
      n.mod = length(mod)
      if (n.mod != n.obs){
         cat (" - Length(mod): ",n.mod,"\n")
         cat (" - Length(obs): ",n.obs,"\n")
         stop(" Dimensions of 'mod' and 'obs' must match...")
      }else{
         mod = list(unlist(mod))
      }#end if
      #------------------------------------------------------------------------------------#
   }#end if
   #---------------------------------------------------------------------------------------#



   #----- Keep only the valid observations. -----------------------------------------------#
   obs   = obs[keep]
   mod   = lapply(X=mod,FUN="[",keep)
   n.mod = sapply(X=mod,FUN=length)
   #---------------------------------------------------------------------------------------#


   #----- Find the residuals. -------------------------------------------------------------#
   res  = lapply(X=mod,FUN="-",obs )
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #      If this plot is to be added, and the original plot was not normalised, make sure #
   # that the sigma of the observations is the same.  Otherwise, stop since the R2 axis    #
   # will not make sense.  Also check whether the user gave a different 'normalise'        #
   # option from the original.  In case so, warn the user that the function will ignore    #
   # the option but otherwise continue.                                                    #
   #---------------------------------------------------------------------------------------#
   if (add){
      if (! skill$normalise){
         sigma.obs = sd(x=obs,na.rm=TRUE)
         if (skill$sigma.obs != sigma.obs){
            cat(" - Original sigma(obs) : ",skill$sigma.obs,"\n")
            cat(" - Current sigma(obs)  : ",sigma.obs      ,"\n")
            cat(" - Original 'normalise': ",skill$normalise,"\n")
            stop("When adding points, the original plot must be normalised!")
         }#end if (skill$sigma.obs != sigma.obs)
         #---------------------------------------------------------------------------------#
      }#end if (! skill$normalise)
      #------------------------------------------------------------------------------------#


      #----- Check for mismatch between options. ------------------------------------------#
      if (normalise != skill$normalise){
         warning(" Using 'normalise' option from original plot instead...")
         normalise = skill$normalise
      }#end if
      #------------------------------------------------------------------------------------#
   }else{
      #---- First plot, save the normalise option. ----------------------------------------#
      skill$normalise = normalise
      #------------------------------------------------------------------------------------#
   }#end if (add)
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   #    Find the coefficient of correlation and standard deviations, and a few additional  #
   # statistics to send back to the output.                                                #
   #---------------------------------------------------------------------------------------#
   skill$mean.obs      = mean  (x = obs            , na.rm = TRUE)
   skill$mean.mod      = sapply(X = mod, FUN = mean, na.rm = TRUE)
   skill$mean.res      = sapply(X = res, FUN = mean, na.rm = TRUE)
   skill$sigma.obs     = sd    (x = obs            , na.rm = TRUE)
   skill$sigma.mod     = sapply(X = mod, FUN = sd  , na.rm = TRUE)
   skill$sigma.res     = sapply(X = res, FUN = sd  , na.rm = TRUE)
   skill$rmse          = sqrt(skill$mean.res^2 + (n.mod - 1) * skill$sigma.res^2 / n.mod)
   skill$df.obs        = n.obs - 1
   skill$df.mod        = ifelse( is.null(n.parms), n.mod - 1,n.mod-n.parms)
   skill$r.squared     = 1. - ( skill$sigma.res / skill$sigma.obs ) ^ 2
   skill$adj.r.squared = ifelse( is.null(n.parms)
                               , NA
                               , 1. -   skill$df.obs    / skill$df.mod
                                    * ( skill$sigma.res / skill$sigma.obs ) ^ 2
                               )#end ifelse
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #    Check whether to normalise or not, then find some local variables for plotting.    #
   #---------------------------------------------------------------------------------------#
   skill$scale = ifelse(normalise,skill$sigma.obs,1.0)
   sigma.obs   = skill$sigma.obs / skill$scale
   sigma.res   = skill$sigma.res / skill$scale
   mean.res    = skill$mean.res  / skill$scale
   #---------------------------------------------------------------------------------------#




   #---------------------------------------------------------------------------------------#
   #     Check whether to draw a new plot or put more information on top of the previous   #
   # plot.                                                                                 #
   #---------------------------------------------------------------------------------------#
   if (! add){
      #------------------------------------------------------------------------------------#
      #     Check whether this is going to have bias (3D) or just the sigma of the errors. #
      #------------------------------------------------------------------------------------#
      #----- Save previous PAR settings. --------------------------------------------------#
      par.all  = par(no.readonly=FALSE)
      par.orig = par(no.readonly=TRUE )
      #------------------------------------------------------------------------------------#




      #------------------------------------------------------------------------------------#
      #     Find limits for bias.                                                          #
      #------------------------------------------------------------------------------------#
      if (is.null(bias.lim)){
         #------ Find the range, making sure that 0 is always included. -------------------#
         bias.max  = max(mean.res)
         bias.min  = min(mean.res)
         if (bias.min == bias.max && bias.min == 0){
            bias.min = -0.25
            bias.max =  0.25
         }else if (bias.min == bias.max){
            #----- Biases switch sign.  Coerce them to be simmetric. ----------------------#
            bias.min = -abs(bias.min)
            bias.max =  abs(bias.max)
         }else if (bias.min > 0 && bias.max > 0){
            #----- All biases are positive.  Coerce maximum to be zero. -------------------#
            bias.min = 0
         }else if (bias.min < 0 && bias.max < 0){
            #----- All biases are negative.  Coerce maximum to be zero. -------------------#
            bias.max = 0
         }else{
            #----- Biases switch sign.  Coerce them to be simmetric. ----------------------#
            bias.min = min(bias.min,-bias.max)
            bias.max = max(-bias.min,bias.max)
         }#end if
         #---------------------------------------------------------------------------------#



         #------ Correct the limits so the "pretty" axis has the last word. ---------------#
         bias.lim = c(bias.min,bias.max)
         bias.at  = sort(unique(c(0,pretty(bias.lim))))
         bias.lim = range(c(bias.lim,bias.at))
         #---------------------------------------------------------------------------------#
      }else{
         bias.lim = range(c(0,sort(bias.lim)))
         bias.at  = sort(unique(c(0,pretty(bias.lim))))
         bias.at  = bias.at[bias.at >= bias.lim[1] & bias.at <= bias.lim[2]]
      }#end if
      #------------------------------------------------------------------------------------#


      #------------------------------------------------------------------------------------#
      #     Find limits for R2.                                                            #
      #------------------------------------------------------------------------------------#
      if (is.null(r2.lim)){
         if (all(is.na(sigma.obs))){
            #----- Fix R2 to -1 to 1. -----------------------------------------------------#
            r2.lim = c(-1,1)
            #------------------------------------------------------------------------------#
         }else{
            #----- Expand the sigma a bit so edge points won't be cropped. ----------------#
            sigma.max = 1.04 * max(sigma.res)
            #------------------------------------------------------------------------------#

            #----- Find the R2 range associated with this sigma.max. ----------------------#
            r2.lim    = c(1.0 - ( sigma.max / sigma.obs )^2 , 1.0)
            #------------------------------------------------------------------------------#
         }#end if
         #---------------------------------------------------------------------------------#



         #---------------------------------------------------------------------------------#
         #      Find a nice range for R2, but force the maximum to be 1.0 and the scale to #
         # decrease (as high sigma means low R2).                                          #
         #---------------------------------------------------------------------------------#
         r2.at = pretty(r2.lim)
         r2.at = sort(unique(c(1.,r2.at[r2.at <= 1.])),decreasing=TRUE)
         #---------------------------------------------------------------------------------#


         #---------------------------------------------------------------------------------#
         #      Correct the sigma scale based on R2 and update the maximum sigma.          #
         #---------------------------------------------------------------------------------#
         if (all(is.na(sigma.obs))){
            sigma.at       = sqrt(1. - r2.at)
            sigma.lim      = range(sqrt(1. - r2.lim))
            sigma.max      = max(sigma.lim)
         }else{
            sigma.at       = sigma.obs * sqrt(1. - r2.at)
            sigma.lim      = range(sigma.obs * sqrt(1. - r2.lim))
            sigma.max      = max(sigma.lim)
         }#end if
         #---------------------------------------------------------------------------------#
      }else{
         r2.lim = range(pmin(r2.lim,1))
         r2.at  = sort(unique(c(pretty(r2.lim),1.)),decreasing=TRUE)
         r2.at  = sort  (r2.at[r2.at >= r2.lim[1] & r2.at <= 1.],decreasing=TRUE)
         #---------------------------------------------------------------------------------#


         #---------------------------------------------------------------------------------#
         #      Correct the sigma scale based on R2 and update the maximum sigma.          #
         #---------------------------------------------------------------------------------#
         if (all(is.na(sigma.obs))){
            sigma.at       = sqrt(1. - r2.at)
            sigma.lim      = range(sqrt(1. - r2.lim))
            sigma.max      = max(sigma.lim)
         }else{
            sigma.at       = sigma.obs * sqrt(1. - r2.at)
            sigma.lim      = range(sigma.obs * sqrt(1. - r2.lim))
            sigma.max      = max(sigma.lim)
         }#end if
         #---------------------------------------------------------------------------------#
      }#end if
      #------------------------------------------------------------------------------------#



      #------------------------------------------------------------------------------------#
      #      Find the limits for RMSE.                                                     #
      #------------------------------------------------------------------------------------#
      rmse.lim    = c(0,max(sqrt(bias.lim^2 + sigma.max^2)))
      if (is.null(n.rmse)){
         rmse.at  = pretty(rmse.lim)
      }else{
         rmse.at  = pretty(c(0,max(rmse)),n=n.rmse)
      }#end if
      #------------------------------------------------------------------------------------#



      #------------------------------------------------------------------------------------#
      #     Save all plot ranges to the output.                                            #
      #------------------------------------------------------------------------------------#
      skill$plot           = list( bias.lim  = bias.lim , bias.at  = bias.at
                                 , r2.lim    = r2.lim   , r2.at    = r2.at
                                 , sigma.lim = sigma.lim, sigma.at = sigma.at
                                 , rmse.lim  = rmse.lim , rmse.at  = rmse.at
                                 )#end list
      #------------------------------------------------------------------------------------#



      #------------------------------------------------------------------------------------#
      #      Define some settings that will be useful throughout the function.             #
      #------------------------------------------------------------------------------------#
      half           = seq(from=0,to=180,by=0.5) * pio180
      quarter        = seq(from=0,to= 90,by=0.5) * pio180
      #------------------------------------------------------------------------------------#



      #------------------------------------------------------------------------------------#
      #    Open the plotting and start the plot.                                           #
      #------------------------------------------------------------------------------------#
      par(...)
      plot.new()
      if (! ( all(is.finite(bias.lim)) && all(is.finite(sigma.lim)))) browser()
      plot.window(x=bias.lim,y=sigma.lim,xaxs="i",yaxs="i",...)
      box()
      title(main=main,xlab=bias.lab,ylab=r2.lab,cex.lab=cex.xyzlab,cex.main=cex.main)
      axis(side=1,at=bias.at ,labels=bias.at,cex.axis=cex.xyzat,las=1)
      axis(side=2,at=sigma.at,labels=r2.at  ,cex.axis=cex.xyzat,las=1)
      #------------------------------------------------------------------------------------#





      #------------------------------------------------------------------------------------#
      #     Plot the bias and R2 grid.                                                     #
      #------------------------------------------------------------------------------------#
      if (r2.grid){
         r2.options.now = modifyList(x=r2.options,val=list(h=sigma.at))
         do.call(what="abline",args=r2.options.now)
      }#end if
      if (nobias.line){
         nobias.options.now = modifyList(x=nobias.options,val=list(v=0))
         do.call(what="abline",args=nobias.options.now)
      }#end if
      #------------------------------------------------------------------------------------#



      #------------------------------------------------------------------------------------#
      #     Root mean square error grid.                                                   #
      #------------------------------------------------------------------------------------#
      if (rmse.grid){
         rmse.use = rmse.at[rmse.at > 0]
         n.rmse = length(rmse.use)
         for (n in 1:n.rmse){
            #----- Find the curve for this RMSE. ------------------------------------------#
            x.rmse = rmse.use[n] * cos(half)
            y.rmse = rmse.use[n] * sin(half)
            #------------------------------------------------------------------------------#



            #----- Discard points that would go outside the plot. -------------------------#
            bye         = ( x.rmse < bias.lim[1] | x.rmse > bias.lim[2]
                          | y.rmse < 0           | y.rmse > sigma.max   )
            x.rmse[bye] = NA
            y.rmse[bye] = NA
            #------------------------------------------------------------------------------#


            if (! all(bye)){
               #----- Plot lines. ---------------------------------------------------------#
               rmse.options.now = modifyList(x = rmse.options,val=list(x=x.rmse,y=y.rmse))
               do.call(what="lines",args=rmse.options.now)
               #---------------------------------------------------------------------------#



               #----- Plot label. ---------------------------------------------------------#
               idx         = floor(quantile(which(! bye),probs=1/4))
               boxed.options = modifyList( x   = rmse.options
                                         , val = list( x      = x.rmse[idx]
                                                     , y      = y.rmse[idx]
                                                     , labels = rmse.use[n]
                                                     , border = FALSE
                                                     )#end list
                                         )#end modifyList
               do.call(what="boxed.labels",args=boxed.options)
               #---------------------------------------------------------------------------#
            }#end if (! all(bye))
            #------------------------------------------------------------------------------#
         }#end for (n in 1:n.rmse)
         #---------------------------------------------------------------------------------#

         #----- Plot RMSE title on the right side. ----------------------------------------#
         rmse.options.now = modifyList( x    = rmse.options
                                      , val  = list( text  = rmse.lab
                                                   , side  = 4
                                                   , srt   = -90
                                                   , outer = FALSE
                                                   , line  = 1
                                                   )#end list
                                      )#end modifyList
         do.call(what="mtext",args=rmse.options.now)
         #---------------------------------------------------------------------------------#

      }#end if (sigma.grid)
      #------------------------------------------------------------------------------------#




      #------------------------------------------------------------------------------------#
      #     Check whether to plot a target point showing the sweetest spot.                #
      #------------------------------------------------------------------------------------#
      if (plot.obs){
         xyz = list(x = 0, y = 0)

         #----- Correct point size and append to the lists. -------------------------------#
         cex.big   = 1.0 * ifelse("cex" %in% names(obs.options),obs.options$cex,1.0)
         cex.small = 2/3 * ifelse("cex" %in% names(obs.options),obs.options$cex,1.0)
         xyz.big   = list(x=0,y=0,cex=cex.big  ,type="p",pch=21)
         xyz.small = list(x=0,y=0,cex=cex.small,type="p",pch=16)
         obs.options.big   = modifyList(x=obs.options,val=xyz.big  )
         obs.options.small = modifyList(x=obs.options,val=xyz.small)
         #---------------------------------------------------------------------------------#


         #---------------------------------------------------------------------------------#
         #     Draw points.                                                                #
         #---------------------------------------------------------------------------------#
         par(xpd=TRUE)
         do.call (what="points",args=obs.options.small)
         do.call (what="points",args=obs.options.big  )
         par(xpd=par.all$xpd)
         #---------------------------------------------------------------------------------#
      }#end if (plot.obs)
      #------------------------------------------------------------------------------------#
   }#end if (! add)
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Check whether there will be any point falling outside the plot region and warn    #
   # the user.                                                                             #
   #---------------------------------------------------------------------------------------#
   if ( any(mean.res < skill$bias.lim[1] | mean.res > skill$bias.lim[2])
      | any(sigma.res < skill$sigma.lim[1] | sigma.res > skill$sigma.lim[2]) ){
      warning(" Some points are outside the plotting area!")
   }#end if
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Plot the points summarising the errors.                                           #
   #---------------------------------------------------------------------------------------#
   mod.options.now = modifyList(x=mod.options,val=list(x=mean.res,y=sigma.res,type="p"))
   do.call(what="points",args=mod.options.now)
   #---------------------------------------------------------------------------------------#

   return(skill)
}#end function
#==========================================================================================#
#==========================================================================================#
