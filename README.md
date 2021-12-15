# QUEFTS AWS Lambda Function







## R Documentation

- [CRAN QUEFTS](https://cran.r-project.org/web/packages/Rquefts/index.html)
- [QUEFTS Reference Manual](https://cran.r-project.org/web/packages/Rquefts/Rquefts.pdf)

## Input JSON

The input JSON consists of 6 fields:

1. "functions_used" : This field contains boolean (True/False) field, selecting which functions will be used in the Lambda Function run.
1. "fertilizers" : This field contains the parameters to run the *fertilizers()* and *nutrientRates()* functions.
2. "fertApp" : This field contains the parameters to run the *fertApp()* function.
3. "nutSupply" :  This field contains the parameters to run the *nutSupply1()* or the *nutSupply2()* functions. The user can select which one of the two functions to run by providing in the field *which_nutSupply* the corresponding number (1 or 2).
4. "quefts_model" : This field contains the parameters to run the *quefts_model()* function. Inside this field exist another 4 fields that each one contain the parameters for the arguments of the *quefts_model()* function:
   - "soil" : This field contains the parameters to run the *quefts_soil()* function. An option is provided to use the default parameters by assigning "use_default_params" to True.
   - "crop" : This field contains the parameters to run the *quefts_crop()* function. The crop under examination must be provided.
   - "fert" : This field contains the parameters to run the *quefts_fert()* function. The values of N, P, and K fertilizer must be provided. Refer to the documentation for further and more specific information.
   - "biom" : This field contains the parameters to run the *quefts_biom()* function. An option is provided to use the default parameters by assigning "use_default_params" to True.
5. "predict_tif" : This field contains the parameters to run the *predict()* function. Inside this field, the following fields are contained:
   - "rasters" : This field contains the parameters to select the *nutSupply1()* or the *nutSupply2()* by providing in the field *which_nutSupply* the corresponding number (1 or 2). Depending on the nutSupply selection the user must provide the corresponding **url** for each of the parameter tifs needed paying attention to the correct naming of the field, so as to be compatible with the model naming. In the input JSON  example the correct naming can be seen. Refer to the documentation for further information on each one of the model's parameters.
   - "crop" : This field contains the parameters to run the *quefts_crop()* function, to create the quefts model which is then used by the *predict()* function.
   - "fert" : This field contains the parameters to run the *quefts_fert()* function, to create the quefts model which is then used by the *predict()* function.
   - "var" : Contains the option of either "yield" or "gap" for the prediction run.

**Important Note** : Each one of the five field of the input JSON contain an option named "use_*<<FIELD_NAME>>*". With this option the user can specify if the corresponding function will be used or not. If the user specifies this option with false, then there is no need to provide any more input data for the specific field. The user is able to enable or disable any combination of the five fields, because their execution is independent from the others. If the user want to use the outputs of any of the five function as the input to any of the five functions, then two calls of the lambda function are required in a two-step logic.

1. Call the Lambda function and produce the intermediate results of the selected function(s).
2. Use the intermediate results as inputs to call the Lambda function and produce the final results of the function(s).

Example of input JSON:

~~~json
{
  "functions_used" : [
    {"use_fertilizers" : true},
    {"use_fertApp" : true},
    {"use_nutSupply" : true},
    {"use_quefts_model" : true},
    {"use_predict_tif" : true}
  ],
  "fertilizers" : [
    {"fertilizers" : [8,15,16,17]},
    {"supply_amounts" : [100,50,50,50]}
  ],
  "fertApp" : [
    {"nutrients" : [
        {"N" : [0,50,100,150,200]},
        {"P" : 50},
        {"K" : 50}
      ]},
    {"fertilizers_prices" : [1,1.5,1.25,1]},
    {"exact" : null},
    {"retCost" : false},
    {"fertilizers" : [8,15,16,17]}
  ],
  "nutSupply" : [
    {"which_nutSupply" : 2},
    {"nut_1" : [
        {"ph" : 6},
        {"SOC" : [23,11,35]},
        {"Kex" : 15},
        {"Polsen" : [1.6,2.6,2.4]}
      ]
    },
    {"nut_2" : [
        {"ph" : 6},
        {"SOC" : [23,11,35]},
        {"Kex" : 15},
        {"Polsen" : [1.6,2.6,2.4]},
        {"temp" : 20},
        {"Ptotal" : 225}
      ]
    }
  ],
  "quefts_model" : [
    {"soil" : [
      {"use_default_params" : false},
      {"N_base_supply" : 60},
      {"P_base_supply" : 10},
      {"K_base_supply" : 60},
      {"N_recovery" : 0.5},
      {"P_recovery" : 0.1},
      {"K_recovery" : 0.5},
      {"UptakeAdjust" : [
        [0,40,80,120,240,360,100],
        [0,0.4,0.7,1,1.6,2,2]
      ]}
    ]},
    {"crop" : "Barley"},
    {"fert" : [
      {"N" : 0},
      {"P" : 10},
      {"K" : 20}
    ]},
    {"biom" : [
      {"use_default_params" : false},
      {"leaf_att" : 2200},
      {"stem_att" : 2700},
      {"store_att" : 4800},
      {"SeasonLength" : 110}
    ]}
  ],
  "predict_tif" : [
    {"rasters" : [
      {"which_nutSupply" : 2},
      {"nut_1" : [
        {"ph" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/PH.tif"},
        {"SOC" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/soc.tif"},
        {"Kex" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/kex.tif"},
        {"Polsen" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/pex.tif"},
        {"Yatt" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/Ya.tif"}
      ]},
      {"nut_2" : [
        {"ph" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/PH.tif"},
        {"SOC" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/soc.tif"},
        {"Kex" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/kex.tif"},
        {"Polsen" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/pex.tif"},
        {"temp" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/tavg.tif"},
        {"Ptotal" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/ptot.tif"},
        {"Yatt" : "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/Ya.tif"}
      ]}
    ]},
    {"crop" : "Maize"},
    {"fert" : [
      {"N" : 100},
      {"P" : 110},
      {"K" : 120}
      ]},
    {"var" : "yield"}
  ]
}

~~~

## Using the Lambda Function in R

The proper way to use the Lambda function through an R script is shown below:

~~~R
# required libraries
library("httr")
library("jsonlite")

## 1st way to send data, with a URL of the JSON file
post_input_json = "https://r-lambdas-dummy.s3.eu-central-1.amazonaws.com/quefts_parameters.json"

## 2nd way to send data, loading from local JSON file and converting it to the appropriate format for the POST call
input_local_file_path = "quefts_parameters.json" #provide the correct path to JSON
input_json = fromJSON(input_local_file_path)
post_input_json = toJSON(input_json)

## create the headers for the POST call
header = add_headers(.headers = c('Authorization'= 'SCiO_CROP_LAMBDAS', 'Content-Type' = 'application/json'))
## execute the POST call
response = POST(url = "https://lambda.qvantum.quefts.scio.services", config = header , body = post_input_json)

## get the returned data as a R list
data_list = content(response)
## get the returned data as a json variable (can be saved as local JSON file)
data_json = toJSON(data_list)

~~~

## Output

The output of the Lambda Function is a JSON with up to five fields, depending on which QUEFTS functions the user selected with the input JSON. If a QUEFTS function was not selected with the input JSON then it will not produce any output. Below there are examples of the outputs of each QUEFTS functions. They will be shown separately for better understanding, but in reality they will be fields in the output JSON produced by the Lambda Function.

1. If "use_fertilizers" is set to True then, in the output JSON there will be a field like the following. Refer to the documentation for further information regarding the returned values.
   
   ~~~json
     "fertilizers_output": {
       "K": [
         [
           17.43
         ]
       ],
       "N": [
         [
           56
         ]
       ],
       "P": [
         [
           13.9585
         ]
       ]
     }
   ~~~
   
   
   
2. If "use_fertApp" is set to True then, in the output JSON there will be a field like the following. Refer to the documentation for further information regarding the returned values.
   
   ~~~json
   "fertApp_output": [
       {
         "name": [
           "Urea (U-46)"
         ],
         "X1": [
           0
         ],
         "X2": [
           0
         ],
         "X3": [
           86.4327
         ],
         "X4": [
           195.1283
         ],
         "X5": [
           303.824
         ]
       },
       {
         "name": [
           "Triple superphosphat"
         ],
         "X1": [
           260.6339
         ],
         "X2": [
           146.8281
         ],
         "X3": [
           123.5185
         ],
         "X4": [
           123.5185
         ],
         "X5": [
           123.5185
         ]
       },
       {
         "name": [
           "Potassium magnesium "
         ],
         "X1": [
           273.8226
         ],
         "X2": [
           46.5498
         ],
         "X3": [
           0
         ],
         "X4": [
           0
         ],
         "X5": [
           0
         ]
       },
       {
         "name": [
           "NPK 20-20-20"
         ],
         "X1": [
           0
         ],
         "X2": [
           250
         ],
         "X3": [
           301.2048
         ],
         "X4": [
           301.2048
         ],
         "X5": [
           301.2048
         ]
       }
     ]
   ~~~
   
   
   
3. If "nutSupply" is set to True then, in the output JSON there will be a field like the following. Refer to the documentation for further information regarding the returned values.
   
   ~~~json
   "nutSupply_output": [
       {
         "N_base_supply": [
           79.324
         ],
         "P_base_supply": [
           3.95
         ],
         "K_base_supply": [
           187.6652
         ]
       },
       {
         "N_base_supply": [
           37.9376
         ],
         "P_base_supply": [
           4.45
         ],
         "K_base_supply": [
           357.9832
         ]
       },
       {
         "N_base_supply": [
           120.7104
         ],
         "P_base_supply": [
           4.35
         ],
         "K_base_supply": [
           127.1642
         ]
       }
     ]
   ~~~
   
   
   
4. If "quefts_model" is set to True then, in the output JSON there will be a field like the following. Refer to the documentation for further information regarding the returned values.
   
   ~~~json
    "quefts_model_output": [
       {
         "leaf_lim": [
           1178.4812
         ],
         "stem_lim": [
           1446.3178
         ],
         "store_lim": [
           2476.3904
         ],
         "N_supply": [
           55.5
         ],
         "P_supply": [
           10.25
         ],
         "K_supply": [
           65.5
         ],
         "N_uptake": [
           53.937
         ],
         "P_uptake": [
           9.7471
         ],
         "K_uptake": [
           60.1793
         ],
         "N_gap": [
           185.75
         ],
         "P_gap": [
           150.95
         ],
         "K_gap": [
           93.3
         ]
       }
     ]
   ~~~
   
   
   
5. If "predict_tif" is set to True then, in the output JSON there will be a field like the following. This output will be a **url** pointing at the produced tif from the QUEFTS function selected. The file is given an ID and is followed by the time the creation took place. The file can be downloaded and use appropriately from the user.
   
   ~~~json
   "predict_tif_output": [
       [
         "https://lambda-quefts.s3.eu-central-1.amazonaws.com/quefts_result_NXXXB1836X_2021_11_10_09_31_11.tif"
       ]
     ]
   ~~~

## Deployment

![](https://scio-images.s3.us-east-2.amazonaws.com/quefts.png)

### Prerequistes

- AWS Account
- AWS CLI
- Node.js
- Python
- AWS CDK Toolkit
- Docker

The AWS services that are being used are the the ones below:

- CloudFormation
- Lambda
- Elastic Container Registry
- API Gateway
- S3

Those are being combined by utilizing AWS Cloud Development Kit (CDK), a software development framework for defining cloud infrastructure in code and provisioning it through AWS CloudFormation.

You can read more about AWS CDK in its official documentation page and you can also the below relevant workshop to get you started.

[What is the AWS CDK?](https://docs.aws.amazon.com/cdk/latest/guide/home.html)

[AWS CDK Workshop](https://cdkworkshop.com/)



We are using Python as our code hence all the workflow will be demonstrated with it. 

The steps are not different if you are using any other language that the toolkit supports although relevant debugging will be needed from the code's perspective.

First, you will need to generate AWS access keys. Make sure that the user account that will be used has IAM permissions for access to the resources and services mentioned.

Once you have generated the keys, you may install AWS CLI and add them to your machine.

You can read more in the official documentation for its installation and configuration.

[AWS Command Line Interface documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)



Since the architecture of this function includes integration with S3, you will have to manually create a bucket and also make sure that the AWS access keys that will be used will have access to it.



Once you have this set up, you may proceed with the below steps.

```bash
# Installation of CDK toolkit
npm install -g aws-cdk@1.85.0

# Confirm successful installation of CDK
cdk version 

# Creating virtual environemnt for Python
python3 -m venv .venv 

# Activating the virtual environment for CDK
source .venv/bin/activate 

# Installing Python CDK dependencies 
pip3 install -r requirements.txt 
```



You will now need to add your AWS access keys to the Dockerfile in order for the container to have access to the defined S3 bucket.

```dockerfile
RUN aws configure set aws_access_key_id <<Access key ID>>
RUN aws configure set aws_secret_access_key <<Secret access key>>
```



Now you can deploy by using CDK.

```bash
# Getting AWS account information for CDK
ACCOUNT_ID=$(aws sts get-caller-identity --query Account | tr -d '"')
AWS_REGION=$(aws configure get region)

# Deploying
cdk bootstrap aws://${ACCOUNT_ID}/${AWS_REGION}
cdk deploy --require-approval never
```

With `cdk bootstrap` command, a CloudFormation stack is creating based on the `app.py`.  

Then with `cdk deploy` the resources of the CloudFormation stack are being created and deployed. This process will take time as the container is being built and the completion is depending  and in the internal operations of the container (installing and running the needed dependencies as those are defined in the Dockerfile) and on the resources of the host machine.

Afterwards, the container will be pushed to AWS ECR (Elastic Container Registry) which is the container registry service of AWS. This will take some time as well as it depends on the internet connection you have.



Once the above complete, you may navigate to API Gateway service from the AWS console and you will find the API with the name "wofost-lambda". The name of the API, lambda function & container is being set in the *app.py* (line 13).

You will then see URL that has been created in the form of:

 `https://<random text>.execute-api.<your aws region>.amazonaws.com`

The lambda function is now ready to be used! 

Fore more detailed information about the ecosystem, you may check [this article](https://medium.com/swlh/deploying-a-serverless-r-inference-service-using-aws-lambda-amazon-api-gateway-and-the-aws-cdk-65db916ea02c).

