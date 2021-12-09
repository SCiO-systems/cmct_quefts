library("Rquefts")
library("jsonlite")
library("limSolve")
library("terra")
library("aws.s3")
library("stringi")

handler = function(body, ...){
  
  tryCatch(
    {
      input_json = fromJSON(txt = body)
      return_list = list()
      
      fertilizer_used = input_json$functions_used$use_fertilizers[1]
      fertApp_used = input_json$functions_used$use_fertApp[2]
      nutSupply_used = input_json$functions_used$use_nutSupply[3]
      quefts_model_used = input_json$functions_used$use_quefts_model[4]
      predict_tif_used = input_json$functions_used$use_predict_tif[5]
      
      # calculate with Fertilizers
      #-------------------------------------
      if (fertilizer_used){
        ferilizers_selected = input_json$fertilizers$fertilizers[[1]]
        
        my_ferts <- fertilizers()[c(ferilizers_selected), ]
        my_ferts[,2] = substr(my_ferts[,2], 1, 20)
        # my_ferts
        my_ferts_NPK_columns = my_ferts[,2:5]
        # my_ferts_NPK_columns
        
        nutrients = nutrientRates(my_ferts, c(input_json$fertilizers$supply_amounts[[2]]))
        nutrients
        
        return_list = c(return_list, fertilizers_output = list(split(unname(nutrients),names(nutrients),drop=F)))
      }


      #-------------------------------------
      
      # calculate with fertApp
      #-------------------------------------
      if (fertApp_used){
        nutrients_list = unlist(input_json$fertApp$nutrients[1],recursive = F)
        #get N,P,K from json list
        if (is.list(nutrients_list$N)) {
          N = nutrients_list$N[[1]]
        } else {
          N = nutrients_list$N[1]
        }
        if (is.list(nutrients_list$P)) {
          P = nutrients_list$P[[2]]
        } else {
          P = nutrients_list$P[2]
        }
        if (is.list(nutrients_list$K)) {
          K = nutrients_list$K[[3]]
        } else {
          K = nutrients_list$K[3]
        }
        #check if fertData params: exact and retCost are defined by user
        if(!is.na(input_json$fertApp$exact[3])){
          exact = input_json$fertApp$exact[3]
        } else {
          exact = TRUE  
        }
        if(!is.na(input_json$fertApp$retCost[4])){
          retCost = input_json$fertApp$retCost[4]
        } else {
          retCost = FALSE  
        }
        
        ferilizers_selected = input_json$fertApp$fertilizers[[5]]
        ferilizers_selected <- fertilizers()[c(ferilizers_selected), ]
        ferilizers_selected[,2] = substr(ferilizers_selected[,2], 1, 20)
        ferilizers_selected_NPK_columns = ferilizers_selected[,2:5]
        
        
        x <- fertApp(data.frame(N=N, P=P, K=K), ferilizers_selected_NPK_columns, c(1, 1.5, 1.25, 1),exact,retCost)
        # x
        
        # show that it is correct
        # nutrientRates(ferilizers_selected_NPK_columns, x[,5])
        
        return_list = c(return_list, fertApp_output = list(x))
      }
      #-------------------------------------
      
      # calculate nutSupply
      #-------------------------------------
      if (nutSupply_used){
        #define which nutSupply to use
        if (input_json$nutSupply$which_nutSupply[[1]]==1){
          nut_sup_1_params = unlist(input_json$nutSupply$nut_1,recursive = F)
          if (is.list(nut_sup_1_params$ph)) {
            ph = nut_sup_1_params$ph[[1]]
          } else {
            ph = nut_sup_1_params$ph[1]
          }
          if (is.list(nut_sup_1_params$SOC)) {
            SOC = nut_sup_1_params$SOC[[2]]
          } else {
            SOC = nut_sup_1_params$SOC[2]
          }
          if (is.list(nut_sup_1_params$Kex)) {
            Kex = nut_sup_1_params$Kex[[3]]
          } else {
            Kex = nut_sup_1_params$Kex[3]
          }
          if (is.list(nut_sup_1_params$Polsen)) {
            Polsen = nut_sup_1_params$Polsen[[4]]
          } else {
            Polsen = nut_sup_1_params$Polsen[4]
          }
          nut_supply = nutSupply1(ph,SOC,Kex,Polsen)
        } else {
          nut_sup_2_params = unlist(input_json$nutSupply$nut_2,recursive = F)
          if (is.list(nut_sup_2_params$ph)) {
            ph = nut_sup_2_params$ph[[1]]
          } else {
            ph = nut_sup_2_params$ph[1]
          }
          if (is.list(nut_sup_2_params$SOC)) {
            SOC = nut_sup_2_params$SOC[[2]]
          } else {
            SOC = nut_sup_2_params$SOC[2]
          }
          if (is.list(nut_sup_2_params$Kex)) {
            Kex = nut_sup_2_params$Kex[[3]]
          } else {
            Kex = nut_sup_2_params$Kex[3]
          }
          if (is.list(nut_sup_2_params$Polsen)) {
            Polsen = nut_sup_2_params$Polsen[[4]]
          } else {
            Polsen = nut_sup_2_params$Polsen[4]
          }
          if (is.list(nut_sup_2_params$temp)) {
            temp = nut_sup_2_params$temp[[5]]
          } else {
            temp = nut_sup_2_params$temp[5]
          }
          if (is.list(nut_sup_2_params$Ptotal )) {
            Ptotal = nut_sup_2_params$Ptotal[[6]]
          } else {
            Ptotal = nut_sup_2_params$Ptotal[6]
          }
          nut_supply = nutSupply2(temp,ph,SOC,Kex,Polsen,Ptotal)
        }
        # nut_supply
        df_nut_supply = as.data.frame(nut_supply)
        # df_nut_supply
        return_list = c(return_list, nutSupply_output = list(df_nut_supply))
      }
      
      #-------------------------------------
      
      
      # calculate quefts model
      #-------------------------------------
      #for quefts_crop for now only the defaults crops are supported
      # soil parameters configuration
      if (quefts_model_used){
        use_default_soil = input_json$quefts_model$soil[[1]]$use_default_params[1]
        if (use_default_soil){
          soiltype <- quefts_soil()
        } else {
          soiltype <- quefts_soil()
          soiltype$N_base_supply = input_json$quefts_model$soil[[1]]$N_base_supply[2]
          soiltype$P_base_supply = input_json$quefts_model$soil[[1]]$P_base_supply[3]
          soiltype$K_base_supply = input_json$quefts_model$soil[[1]]$K_base_supply[4]
          soiltype$N_recovery = input_json$quefts_model$soil[[1]]$N_recovery[5]
          soiltype$P_recovery = input_json$quefts_model$soil[[1]]$P_recovery[6]
          soiltype$K_recovery = input_json$quefts_model$soil[[1]]$K_recovery[7]
          soiltype$UptakeAdjust = t(input_json$quefts_model$soil[[1]]$UptakeAdjust[8][[1]])
        }
        
        #crop selection
        crop_selected <- quefts_crop(input_json$quefts_model$crop[2])
        
        # management/fertilizers configuration
        N = input_json$quefts_model$fert[[3]]$N[1]
        P = input_json$quefts_model$fert[[3]]$P[2]
        K = input_json$quefts_model$fert[[3]]$K[3]
        fertilizer <- list(N=N, P=P, K=K)
        
        #crop yield/biom configuration
        use_default_biom = input_json$quefts_model$biom[[4]]$use_default_params[1]
        if (use_default_biom){
          att_yield <- quefts_biom()
        } else {
          att_yield <- quefts_biom()
          att_yield$leaf_att = input_json$quefts_model$biom[[4]]$leaf_att[2]
          att_yield$stem_att = input_json$quefts_model$biom[[4]]$stem_att[3]
          att_yield$store_att = input_json$quefts_model$biom[[4]]$store_att[4]
          att_yield$SeasonLength = input_json$quefts_model$biom[[4]]$SeasonLength[5]
        }
        
        
        # 2. create a model
        q <- quefts(soiltype, crop_selected, fertilizer, att_yield)
        
        # 3. run the model
        model_output = run(q)
        
        return_list = c(return_list, quefts_model_output = list(as.data.frame(t(model_output))))
      }
      #-------------------------------------
      
      
      # calcualte tifs with predict
      #-------------------------------------
      if(predict_tif_used) {
        which_soil_nutSupply = input_json$predict_tif$rasters[[1]]$which_nutSupply[1]
        if (which_soil_nutSupply==1){
          
          #creating supply tif from soil tif data
          ph_url = input_json$predict_tif$rasters[[1]]$nut_1[[2]]$ph[1]
          ph_local = "/tmp/ph.tif"
          download.file(url = ph_url,ph_local)
          
          SOC_url = input_json$predict_tif$rasters[[1]]$nut_1[[2]]$SOC[2]
          soc_local = "/tmp/soc.tif"
          download.file(url = SOC_url,soc_local)
          
          Kex_url = input_json$predict_tif$rasters[[1]]$nut_1[[2]]$Kex[3]
          kex_local = "/tmp/kex.tif"
          download.file(url = Kex_url,kex_local)
          
          Polsen_url = input_json$predict_tif$rasters[[1]]$nut_1[[2]]$Polsen[4]
          polsen_local = "/tmp/pex.tif"
          download.file(url = Polsen_url,polsen_local)
          
          #create supply tif
          raster_names = c(ph_local,soc_local,kex_local,polsen_local)    
          soil_tif = rast(raster_names)
          supply = lapp(soil_tif,nutSupply1)
          
          #creating attainable yield tif
          yatt_url = input_json$predict_tif$rasters[[1]]$nut_1[[2]]$Yatt[5]
          yatt_local = "/tmp/Ya.tif"
          download.file(url = yatt_url,yatt_local)
          yatt <- rast(yatt_local)
          
        } else {
          tifs_variables_names = names(input_json$predict_tif$rasters[[1]]$nut_2[[3]])
          
          #creating supply tif from soil tif data
          ph_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$ph[1]
          ph_local = "/tmp/ph.tif"
          download.file(url = ph_url,ph_local)
          
          SOC_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$SOC[2]
          soc_local = "/tmp/soc.tif"
          download.file(url = SOC_url,soc_local)
          
          Kex_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$Kex[3]
          kex_local = "/tmp/kex.tif"
          download.file(url = Kex_url,kex_local)
          
          Polsen_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$Polsen[4]
          polsen_local = "/tmp/pex.tif"
          download.file(url = Polsen_url,polsen_local)
          
          temp_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$temp[5]
          temp_local = "/tmp/tavg.tif"
          download.file(url = temp_url,temp_local)
          
          Ptotal_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$Ptotal[6]
          ptotal_local = "/tmp/ptot.tif"
          download.file(url = Ptotal_url,ptotal_local)
          
          #create supply tif
          raster_names = c(temp_local,ph_local,soc_local,kex_local,polsen_local,ptotal_local)    
          soil_tif = rast(raster_names)
          supply = lapp(soil_tif,nutSupply2)
          
          #creating attainable yield tif
          yatt_url = input_json$predict_tif$rasters[[1]]$nut_2[[3]]$Yatt[7]
          yatt_local = "/tmp/Ya.tif"
          download.file(url = yatt_url,yatt_local)
          yatt <- rast(yatt_local)
        }
        
        #selecting crop
        crop_selected = quefts_crop(input_json$predict_tif$crop[2])
        
        #configuring fertilizers
        N = input_json$predict_tif$fert[[3]]$N[1]
        P = input_json$predict_tif$fert[[3]]$P[2]
        K = input_json$predict_tif$fert[[3]]$K[3]
        fertilizer <- list(N=N, P=P, K=K)
        
        q <- quefts(crop=crop_selected, fert=fertilizer)
        
        if(input_json$predict_tif$var[4]=="gap"){
          p = predict(q, supply, yatt, "gap", "/tmp/output.tif",overwrite=TRUE)
        } else {
          p = predict(q, supply, yatt, "yield", "/tmp/output.tif",overwrite=TRUE)
        }
        
        
        date_time = gsub(" ","_",format(Sys.time()))
        date_time = gsub(":","_",date_time)
        date_time = gsub("-","_",date_time)
        random_string_ID = do.call(paste0, Map(stri_rand_strings, n=1, length=c(5, 4, 1),
                                               pattern = c('[A-Z]', '[0-9]', '[A-Z]')))
        S3_bucket = "lambda-quefts"
        path_to_saved_file_in_S3 = paste0("https://",S3_bucket)  
        
        
        
        # name_without_file_extension =  substr(input_json$predict_tif$tif_output_filename[5],1,nchar(input_json$predict_tif$tif_output_filename[5])-4)
        
        output_file_save_name = paste0("quefts_result_",random_string_ID)
        output_file_save_name = paste(output_file_save_name,date_time,sep="_")
        output_file_save_name = paste0(output_file_save_name,".tif")
        
        path_to_saved_file_in_S3 = paste0(path_to_saved_file_in_S3,".s3.eu-central-1.amazonaws.com/")
        path_to_saved_file_in_S3 = paste0(path_to_saved_file_in_S3,output_file_save_name)
        
        #upload the file to S3
        put_object(          
          file = "/tmp/output.tif",
          object = output_file_save_name,
          bucket = S3_bucket
        )
        return_list = c(return_list, predict_tif_output = path_to_saved_file_in_S3)  
      }
      #-------------------------------------

      if (length(return_list)==0){
        return_list = "No QUEFTS library function was selected for execution"
      }
      
      return(
        list(
          statusCode = 200,
          headers = list("Content-Type" = "application/json"),
          body = toJSON(return_list)
        )
      )

    },
    error=function(error_message) {
      
      response = toString(error_message)
      response = substr(response,1,nchar(response)-1)
      return(
        list(
          statusCode = 400,
          headers = list("Content-Type" = "application/json"),
          body = toJSON(response)
        )
      )
    }
  )
    
}


t = handler("/home/christos/Desktop/SCiO_Projects/qvantum/quefts_parameters.json")
t
